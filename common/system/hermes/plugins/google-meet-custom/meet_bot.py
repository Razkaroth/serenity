"""Headless Google Meet bot — Playwright + live-caption scraping.

Runs as a standalone subprocess spawned by ``process_manager.py``. Reads config
from env vars, writes status + transcript to files under
``$HERMES_HOME/workspace/meetings/<meeting-id>/``. The main hermes process
reads those files via the ``meet_*`` tools — no IPC beyond filesystem.

The scraping strategy mirrors OpenUtter (sumansid/openutter): we don't parse
WebRTC audio, we enable Google Meet's built-in live captions and observe the
captions container in the DOM via a MutationObserver. This is lossy and
English-biased but it is:

* deterministic (no API keys, no STT billing),
* works behind Meet's normal login / admission,
* survives Meet UI rewrites fairly well because the caption container has a
  stable ARIA role.

Run standalone for debugging::

    HERMES_MEET_URL=https://meet.google.com/abc-defg-hij \\
    HERMES_MEET_OUT_DIR=/tmp/meet-debug \\
    HERMES_MEET_HEADED=1 \\
    python -m <loaded plugin package>.meet_bot

No meet.google.com URL → exits non-zero. Any URL that doesn't start with
``https://meet.google.com/`` is rejected (explicit-by-design).
"""

from __future__ import annotations

import json
import os
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Optional

# Match ``https://meet.google.com/abc-defg-hij`` or ``.../lookup/...`` — the
# short three-segment code or a lookup URL. Anything else is rejected.
MEET_URL_RE = re.compile(
    r"^https://meet\.google\.com/("
    r"[a-z0-9]{3,}-[a-z0-9]{3,}-[a-z0-9]{3,}"
    r"|lookup/[^/?#]+"
    r"|new"
    r")(?:[/?#].*)?$"
)


# Filenames the bot reads/writes in ``HERMES_MEET_OUT_DIR``.
SAY_QUEUE_FILENAME = "say_queue.jsonl"
SAY_PCM_FILENAME = "speaker.pcm"


def _is_safe_meet_url(url: str) -> bool:
    """Return True if *url* is a Google Meet URL we're willing to navigate to."""
    if not isinstance(url, str):
        return False
    return bool(MEET_URL_RE.match(url.strip()))


def _meeting_id_from_url(url: str) -> str:
    """Extract the 3-segment meeting code from a Meet URL.

    For ``https://meet.google.com/abc-defg-hij`` → ``abc-defg-hij``.
    For ``.../lookup/<id>`` or ``/new`` we fall back to a timestamped id — the
    bot won't know the real code until after redirect, and callers pass this
    through to filename anyway.
    """
    m = re.search(
        r"meet\.google\.com/([a-z0-9]{3,}-[a-z0-9]{3,}-[a-z0-9]{3,})",
        url or "",
    )
    if m:
        return m.group(1)
    return f"meet-{int(time.time())}"


# ---------------------------------------------------------------------------
# Status + transcript file writers
# ---------------------------------------------------------------------------

class _BotState:
    """Single-process mutable state, flushed to ``status.json`` on each change."""

    def __init__(self, out_dir: Path, meeting_id: str, url: str):
        self.out_dir = out_dir
        self.meeting_id = meeting_id
        self.url = url
        self.in_call = False
        self.captioning = False
        self.captions_enabled_attempted = False
        self.lobby_waiting = False
        self.join_attempted_at: Optional[float] = None
        self.joined_at: Optional[float] = None
        self.last_caption_at: Optional[float] = None
        self.transcript_lines = 0
        self.error: Optional[str] = None
        self.exited = False
        # v2 realtime fields.
        self.realtime = False
        self.realtime_ready = False
        self.realtime_device: Optional[str] = None
        self.audio_bytes_out: int = 0
        self.last_audio_out_at: Optional[float] = None
        self.last_barge_in_at: Optional[float] = None
        self.leave_reason: Optional[str] = None
        self.language = os.environ.get("HERMES_MEET_LANGUAGE", "es-MX")
        self.language_verified = False
        self._active_caption: Optional[dict] = None
        out_dir.mkdir(parents=True, exist_ok=True)
        self.transcript_path = out_dir / "transcript.txt"
        self.transcript_jsonl_path = out_dir / "transcript.jsonl"
        self.status_path = out_dir / "status.json"
        self._flush()

    # -------- transcript ------------------------------------------------

    def record_caption(self, speaker: str, text: str) -> None:
        """Coalesce incremental Meet caption updates into finalized segments."""
        speaker = (speaker or "").strip() or "Unknown"
        text = (text or "").strip()
        if not text:
            return
        now = time.time()
        active = self._active_caption
        if active and active["speaker"] == speaker and text.startswith(active["text"]):
            active["text"] = text
            active["updated_at"] = now
            self.last_caption_at = now
            return
        self.finalize_caption()
        self._active_caption = {"speaker": speaker, "text": text, "ts": now, "updated_at": now}
        self.last_caption_at = now

    def finalize_caption(self) -> None:
        """Write current caption once, as a final structured and text segment."""
        active = self._active_caption
        if not active:
            return
        self.transcript_lines += 1
        ts = time.strftime("%H:%M:%S", time.localtime(active["ts"]))
        line = f"[{ts}] {active['speaker']}: {active['text']}\n"
        record = {
            "ts": active["ts"], "speaker": active["speaker"],
            "text": active["text"], "language": self.language, "final": True,
        }
        with self.transcript_path.open("a", encoding="utf-8") as f:
            f.write(line)
        with self.transcript_jsonl_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
        self._active_caption = None
        self._flush()

    # -------- status file ----------------------------------------------

    def _flush(self) -> None:
        data = {
            "meetingId": self.meeting_id,
            "url": self.url,
            "inCall": self.in_call,
            "captioning": self.captioning,
            "captionsEnabledAttempted": self.captions_enabled_attempted,
            "lobbyWaiting": self.lobby_waiting,
            "joinAttemptedAt": self.join_attempted_at,
            "joinedAt": self.joined_at,
            "lastCaptionAt": self.last_caption_at,
            "transcriptLines": self.transcript_lines,
            "transcriptPath": str(self.transcript_path),
            "transcriptJsonlPath": str(self.transcript_jsonl_path),
            "language": self.language,
            "languageVerified": self.language_verified,
            "error": self.error,
            "exited": self.exited,
            "pid": os.getpid(),
            # v2 realtime telemetry.
            "realtime": self.realtime,
            "realtimeReady": self.realtime_ready,
            "realtimeDevice": self.realtime_device,
            "audioBytesOut": self.audio_bytes_out,
            "lastAudioOutAt": self.last_audio_out_at,
            "lastBargeInAt": self.last_barge_in_at,
            "leaveReason": self.leave_reason,
        }
        tmp = self.status_path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
        tmp.replace(self.status_path)

    def set(self, **kwargs) -> None:
        for k, v in kwargs.items():
            setattr(self, k, v)
        self._flush()


# ---------------------------------------------------------------------------
# Playwright bot entry point
# ---------------------------------------------------------------------------

# JavaScript injected into the Meet tab to observe captions. Captures
# {speaker, text} tuples via a MutationObserver on the caption container,
# and exposes ``window.__hermesMeetDrain()`` to pull new entries. This
# mirrors the OpenUtter caption scraping approach.
_CAPTION_OBSERVER_JS = r"""
(() => {
  if (window.__hermesMeetInstalled) return;
  window.__hermesMeetInstalled = true;
  window.__hermesMeetQueue = [];

  const captionSelector = '[role="region"][aria-label*="aption" i], ' +
                          'div[jsname="YSxPC"], ' +  // legacy
                          'div[jsname="tgaKEf"]';    // current (Apr 2026)

  function pushEntry(speaker, text) {
    if (!text || !text.trim()) return;
    window.__hermesMeetQueue.push({
      ts: Date.now(),
      speaker: (speaker || '').trim(),
      text: text.trim(),
    });
  }

  function scan(root) {
    // Meet captions render as a list of rows; each row contains a speaker
    // label and a text block. Selectors vary across Meet rewrites; we try
    // a few shapes and fall back to raw text.
    const rows = root.querySelectorAll('div[jsname="dsyhDe"], div.CNusmb, div.TBMuR');
    if (rows.length) {
      rows.forEach((row) => {
        const spkEl = row.querySelector('div.KcIKyf, div.zs7s8d, span[jsname="YSxPC"]');
        const txtEl = row.querySelector('div.bh44bd, span[jsname="tgaKEf"], div.iTTPOb');
        const speaker = spkEl ? spkEl.innerText : '';
        const text = txtEl ? txtEl.innerText : row.innerText;
        pushEntry(speaker, text);
      });
      return;
    }
    // Fallback: treat the whole region's innerText as one anonymous line.
    const text = (root.innerText || '').split('\n').filter(Boolean).pop();
    pushEntry('', text);
  }

  function attach() {
    const el = document.querySelector(captionSelector);
    if (!el) return false;
    const obs = new MutationObserver(() => scan(el));
    obs.observe(el, { childList: true, subtree: true, characterData: true });
    scan(el);
    return true;
  }

  // Try now and retry on interval — the caption region only appears after
  // captions are enabled and someone speaks.
  if (!attach()) {
    const iv = setInterval(() => { if (attach()) clearInterval(iv); }, 1500);
  }

  window.__hermesMeetDrain = () => {
    const out = window.__hermesMeetQueue.slice();
    window.__hermesMeetQueue = [];
    return out;
  };
})();
"""


def _enable_captions_js() -> str:
    """Return a small JS snippet that tries to click the 'Turn on captions' button.

    Best-effort — Meet's caption toggle is keyboard-accessible via ``c``. We
    dispatch that keystroke as a cheap fallback. Real click targeting is too
    brittle to rely on.
    """
    return r"""
    (() => {
      const ev = new KeyboardEvent('keydown', {
        key: 'c', code: 'KeyC', keyCode: 67, which: 67, bubbles: true,
      });
      document.body.dispatchEvent(ev);
      return true;
    })();
    """


_LANGUAGE_LABELS = {
    "es-MX": re.compile(r"Spanish.*Mexico|Espa.ol.*M.xico", re.I),
    "en-US": re.compile(r"English.*United States|English", re.I),
}


def _configure_captions(page, state: _BotState, language: str, translated: bool, target: Optional[str]) -> None:
    """Use only controls scoped to Meet's settings dialog, then verify value."""
    wanted = _LANGUAGE_LABELS[language]
    more = page.get_by_role("button", name=re.compile("More options", re.I)).first
    more.click(timeout=5_000)
    page.get_by_role("menuitem", name=re.compile("Settings", re.I)).first.click(timeout=5_000)
    dialog = page.get_by_role("dialog").last
    dialog.get_by_role("tab", name=re.compile("Captions", re.I)).click(timeout=5_000)
    language_box = dialog.get_by_role(
        "combobox", name=re.compile("Language of the meeting", re.I)
    ).first
    language_box.click(timeout=5_000)
    page.get_by_role("option", name=wanted).first.click(timeout=5_000)
    # UI variants expose selected text through inner_text or aria-valuetext.
    selected = " ".join(filter(None, [
        language_box.get_attribute("aria-valuetext"),
        language_box.get_attribute("aria-label"),
        language_box.inner_text(),
    ]))
    if not wanted.search(selected):
        raise RuntimeError(f"caption language verification failed: expected {language}, got {selected!r}")
    switch = dialog.get_by_role("switch", name=re.compile("Translated captions", re.I)).first
    if switch.count():
        enabled = switch.get_attribute("aria-checked") == "true"
        if enabled != translated:
            switch.click(timeout=5_000)
    if translated and target:
        target_box = dialog.get_by_role("combobox", name=re.compile("Translated captions", re.I)).last
        target_box.click(timeout=5_000)
        page.get_by_role("option", name=_LANGUAGE_LABELS[target]).first.click(timeout=5_000)
    state.set(language=language, language_verified=True)


def _drain_commands(out_dir: Path) -> list[dict]:
    """Atomically consume manager-to-bot commands."""
    path = out_dir / "commands.jsonl"
    if not path.exists():
        return []
    consumed = path.with_suffix(".processing")
    try:
        path.replace(consumed)
    except FileNotFoundError:
        return []
    try:
        return [json.loads(line) for line in consumed.read_text(encoding="utf-8").splitlines() if line.strip()]
    finally:
        consumed.unlink(missing_ok=True)


def _write_command_result(out_dir: Path, command: dict, **result) -> None:
    """Publish language-switch completion for the originating tool call."""
    record = {"id": command.get("id"), **result}
    with (out_dir / "command_results.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")


def _prepare_fake_video(profile_dir: Path) -> Optional[Path]:
    """Convert packaged static avatar once; Chrome only accepts Y4M fake video."""
    source = Path(__file__).parent / "media" / "c2_avatar.png"
    target = profile_dir / "c2_avatar.y4m"
    if target.is_file() or not source.is_file():
        return target if target.is_file() else None
    profile_dir.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run([
            "ffmpeg", "-y", "-loop", "1", "-i", str(source), "-t", "5",
            "-f", "yuv4mpegpipe", "-pix_fmt", "yuv420p", "-r", "15", "-s", "640x360", str(target),
        ], check=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return target
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
def _start_realtime_speaker(
    *,
    rt: dict,
    out_dir: Path,
    bridge_info: dict,
    api_key: str,
    model: str,
    voice: str,
    instructions: str,
    stop_flag: dict,
    state: "_BotState",
) -> None:
    """Wire up the OpenAI Realtime session + speaker thread + PCM pump.

    The speaker thread reads text lines from ``say_queue.jsonl``, sends each
    to OpenAI Realtime, and writes PCM audio into ``speaker.pcm``. A
    separate *pump* thread forwards that PCM into the OS audio sink so
    Chrome's fake mic picks it up. On Linux we pipe to ``paplay`` against
    the null-sink; on macOS the caller is expected to have the BlackHole
    device selected as default input.
    """
    try:
        from .realtime.openai_client import (
            RealtimeSession,
            RealtimeSpeaker,
        )
    except Exception as e:
        state.set(error=f"realtime import failed: {e}")
        return

    pcm_path = out_dir / SAY_PCM_FILENAME
    queue_path = out_dir / SAY_QUEUE_FILENAME
    processed_path = out_dir / "say_processed.jsonl"
    # Reset the sink file so we start clean each session.
    pcm_path.write_bytes(b"")
    # Make sure the queue exists so the speaker poller doesn't error on
    # first iteration.
    queue_path.touch()

    try:
        session = RealtimeSession(
            api_key=api_key,
            model=model,
            voice=voice,
            instructions=instructions,
            audio_sink_path=pcm_path,
            sample_rate=24000,
        )
        session.connect()
    except Exception as e:
        state.set(error=f"realtime connect failed: {e}")
        return

    rt["session"] = session

    def _stop_fn():
        return stop_flag.get("stop", False)

    rt["speaker_stop"] = lambda: stop_flag.__setitem__("stop", stop_flag.get("stop", False))

    speaker = RealtimeSpeaker(
        session=session,
        queue_path=queue_path,
        processed_path=processed_path,
    )

    def _speaker_loop():
        try:
            speaker.run_until_stopped(_stop_fn)
        except Exception as e:
            state.set(error=f"realtime speaker crashed: {e}")

    t_speaker = threading.Thread(target=_speaker_loop, name="meet-speaker", daemon=True)
    t_speaker.start()
    rt["speaker_thread"] = t_speaker

    # PCM pump: feeds speaker.pcm (24kHz s16le mono) into the OS audio
    # device that Chrome's fake mic reads from. Different tools per
    # platform, but the contract is the same — block-read the growing
    # PCM file and stream it to the device in near-real-time.
    platform_tag = (bridge_info or {}).get("platform")
    if platform_tag == "linux":
        import subprocess as _sp

        sink = (bridge_info or {}).get("write_target") or "hermes_meet_sink"
        try:
            proc = _sp.Popen(
                [
                    "paplay",
                    "--raw",
                    "--rate=24000",
                    "--format=s16le",
                    "--channels=1",
                    f"--device={sink}",
                    str(pcm_path),
                ],
                stdin=_sp.DEVNULL,
                stdout=_sp.DEVNULL,
                stderr=_sp.DEVNULL,
            )
            rt["pcm_pump"] = proc
        except FileNotFoundError:
            state.set(error="paplay not found — install pulseaudio-utils for realtime on Linux")
    elif platform_tag == "darwin":
        # macOS: use ffmpeg to tail-read speaker.pcm and write it to the
        # BlackHole output device. The user must have BlackHole selected
        # as the default input in System Settings → Sound for Chrome to
        # pick it up. We prefer ffmpeg because it's scriptable and can
        # target AVFoundation devices by name; fall back to afplay-ing
        # the file in a tight loop if ffmpeg is absent.
        import shutil as _shutil
        import subprocess as _sp

        device_name = (bridge_info or {}).get("write_target") or "BlackHole 2ch"
        if _shutil.which("ffmpeg"):
            try:
                # -re: read input at native frame rate.
                # -f avfoundation -i: speaker path as raw PCM.
                # -f s16le -ar 24000 -ac 1 -i <pcm>: interpret the file.
                # -f audiotoolbox -audio_device_index: write to BlackHole.
                # Simpler: output as raw via coreaudio using "-f audiotoolbox".
                # ffmpeg's audiotoolbox output picks the current default
                # output device, which isn't what we want. Instead we use
                # -f avfoundation with the named device as OUTPUT via
                # -vn and the device name.
                proc = _sp.Popen(
                    [
                        "ffmpeg",
                        "-nostdin", "-hide_banner", "-loglevel", "error",
                        "-re",
                        "-f", "s16le", "-ar", "24000", "-ac", "1",
                        "-i", str(pcm_path),
                        "-f", "audiotoolbox",
                        "-audio_device_index", _mac_audio_device_index(device_name),
                        "-",
                    ],
                    stdin=_sp.DEVNULL,
                    stdout=_sp.DEVNULL,
                    stderr=_sp.DEVNULL,
                )
                rt["pcm_pump"] = proc
            except FileNotFoundError:
                state.set(error="ffmpeg not found — install via `brew install ffmpeg` for realtime on macOS")
            except Exception as e:
                state.set(error=f"macOS pcm pump failed to start: {e}")
        else:
            state.set(error="ffmpeg not found — install via `brew install ffmpeg` for realtime on macOS")


def _mac_audio_device_index(device_name: str) -> str:
    """Return the ffmpeg ``-audio_device_index`` for *device_name*, as a string.

    Probes ``ffmpeg -f avfoundation -list_devices true -i ''`` (which prints
    the device table on stderr) and matches *device_name* case-insensitively.
    Defaults to ``"0"`` if the device can't be found — caller will get a
    misrouted stream but not a crash, and the error will be obvious.
    """
    import subprocess as _sp

    try:
        out = _sp.run(
            ["ffmpeg", "-f", "avfoundation", "-list_devices", "true", "-i", ""],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except Exception:
        return "0"
    # ffmpeg prints the table on stderr. Lines look like:
    #   [AVFoundation indev @ 0x...] [0] BlackHole 2ch
    import re as _re

    needle = device_name.strip().lower()
    for line in (out.stderr or "").splitlines():
        m = _re.search(r"\[(\d+)\]\s+(.+)$", line)
        if not m:
            continue
        if m.group(2).strip().lower() == needle:
            return m.group(1)
    return "0"


def run_bot() -> int:  # noqa: C901 — orchestration, explicit branches
    url = os.environ.get("HERMES_MEET_URL", "").strip()
    out_dir_env = os.environ.get("HERMES_MEET_OUT_DIR", "").strip()
    headed = os.environ.get("HERMES_MEET_HEADED", "").lower() in {"1", "true", "yes"}
    auth_state = os.environ.get("HERMES_MEET_AUTH_STATE", "").strip()
    profile_dir_env = os.environ.get("HERMES_MEET_PROFILE_DIR", "").strip()
    language = os.environ.get("HERMES_MEET_LANGUAGE", "es-MX")
    translated_captions = os.environ.get("HERMES_MEET_TRANSLATED_CAPTIONS", "").lower() in {"1", "true", "yes"}
    translation_target = os.environ.get("HERMES_MEET_TRANSLATION_TARGET") or None
    guest_name = os.environ.get("HERMES_MEET_GUEST_NAME", "Hermes Agent")
    duration_s = _parse_duration(os.environ.get("HERMES_MEET_DURATION", ""))
    # v2: optional realtime mode. Enabled when HERMES_MEET_MODE=realtime.
    mode = os.environ.get("HERMES_MEET_MODE", "transcribe").strip().lower()
    realtime_model = os.environ.get("HERMES_MEET_REALTIME_MODEL", "gpt-realtime")
    realtime_voice = os.environ.get("HERMES_MEET_REALTIME_VOICE", "alloy")
    realtime_instructions = os.environ.get("HERMES_MEET_REALTIME_INSTRUCTIONS", "")
    realtime_api_key = os.environ.get("HERMES_MEET_REALTIME_KEY") or os.environ.get("OPENAI_API_KEY", "")

    if not url or not _is_safe_meet_url(url):
        sys.stderr.write(
            "google_meet bot: refusing to launch — HERMES_MEET_URL must be a "
            "meet.google.com URL. got: %r\n" % url
        )
        return 2
    if not out_dir_env:
        sys.stderr.write("google_meet bot: HERMES_MEET_OUT_DIR is required\n")
        return 2

    out_dir = Path(out_dir_env)
    profile_dir = Path(profile_dir_env) if profile_dir_env else out_dir / "profile"
    meeting_id = _meeting_id_from_url(url)
    state = _BotState(out_dir=out_dir, meeting_id=meeting_id, url=url)

    # SIGTERM → exit cleanly so the parent ``meet_leave`` gets a finalized
    # transcript. We set a flag instead of raising so the Playwright context
    # teardown runs in the finally block below.
    stop_flag = {"stop": False}

    def _on_signal(_sig, _frame):
        stop_flag["stop"] = True

    signal.signal(signal.SIGTERM, _on_signal)
    signal.signal(signal.SIGINT, _on_signal)

    # v2 realtime: provision virtual audio device + start speaker thread.
    # We track these in a dict so the finally block can tear them down
    # regardless of how we exit. If anything in the realtime setup fails we
    # fall back to transcribe mode with a status flag.
    rt = {
        "enabled": mode == "realtime",
        "bridge": None,            # AudioBridge | None
        "bridge_info": None,       # dict | None
        "session": None,           # RealtimeSession | None
        "speaker_thread": None,    # threading.Thread | None
        "speaker_stop": None,      # callable | None
    }
    if rt["enabled"]:
        if not realtime_api_key:
            state.set(error="realtime mode requested but no API key in HERMES_MEET_REALTIME_KEY/OPENAI_API_KEY — falling back to transcribe")
            rt["enabled"] = False
        else:
            try:
                from .audio_bridge import AudioBridge
                bridge = AudioBridge()
                rt["bridge_info"] = bridge.setup()
                rt["bridge"] = bridge
                state.set(realtime=True, realtime_device=rt["bridge_info"].get("device_name"))
            except Exception as e:
                state.set(error=f"audio bridge setup failed: {e} — falling back to transcribe")
                rt["enabled"] = False

    try:
        from playwright.sync_api import sync_playwright
    except ImportError as e:
        state.set(error=f"playwright not installed: {e}", exited=True)
        sys.stderr.write(
            "google_meet bot: playwright is not installed. Run "
            "`pip install playwright && python -m playwright install chromium`\n"
        )
        if rt["bridge"]:
            rt["bridge"].teardown()
        return 3

    # Chrome env: if realtime is live on Linux, point PULSE_SOURCE at the
    # virtual source so Chrome's fake mic reads the audio we generate.
    chrome_env = os.environ.copy()
    chrome_args = [
        "--use-fake-ui-for-media-stream",
        "--disable-blink-features=AutomationControlled",
    ]
    fake_video = _prepare_fake_video(profile_dir)
    fake_audio = Path(__file__).parent / "media" / "silence.wav"
    if fake_video:
        chrome_args.append(f"--use-file-for-fake-video-capture={fake_video}")
    if fake_audio.is_file():
        chrome_args.append(f"--use-file-for-fake-audio-capture={fake_audio}")
    if not rt["enabled"]:
        # v1-style fake device (silence) — we don't care about mic content
        # when we're not speaking.
        chrome_args.insert(1, "--use-fake-device-for-media-stream")
    elif rt["bridge_info"] and rt["bridge_info"].get("platform") == "linux":
        chrome_env["PULSE_SOURCE"] = rt["bridge_info"].get("device_name", "")

    try:
        with sync_playwright() as pw:
            # Playwright's launch() doesn't take env; we set PULSE_SOURCE
            # via the process env before launch so the child Chrome inherits it.
            for k, v in chrome_env.items():
                os.environ[k] = v
            context_args = {
                "viewport": {"width": 1280, "height": 800},
                "user_agent": (
                    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
                ),
                "permissions": ["microphone", "camera"],
            }
            context = pw.chromium.launch_persistent_context(
                user_data_dir=str(profile_dir), headless=not headed, args=chrome_args, **context_args
            )
            if auth_state and Path(auth_state).is_file():
                # Bootstrap cookie auth once into persistent profile. Local storage
                # cannot be safely inferred from opaque Google preference blobs.
                try:
                    storage = json.loads(Path(auth_state).read_text(encoding="utf-8"))
                    cookies = storage.get("cookies", [])
                    if cookies:
                        context.add_cookies(cookies)
                except (OSError, ValueError, TypeError) as e:
                    state.set(error=f"auth bootstrap failed: {e}")
            page = context.new_page()

            try:
                page.goto(url, wait_until="domcontentloaded", timeout=30_000)
            except Exception as e:
                state.set(error=f"navigate failed: {e}", exited=True)
                return 4

            # Guest-mode: Meet shows a name field before "Ask to join". When
            # we're authed, we instead see "Join now".
            _try_guest_name(page, guest_name)
            _click_join(page, state)

            # Install before captions are enabled; observer attaches lazily.
            try:
                page.evaluate(_CAPTION_OBSERVER_JS)
            except Exception as e:
                state.set(error=f"caption observer install failed: {e}")

            # Note: in_call=False until admission is confirmed (we detect
            # either the Leave button or the caption region, signalling we
            # made it past the lobby).
            state.set(captioning=True, join_attempted_at=time.time())

            # v2 realtime: start the speaker thread reading from the
            # plugin-side say queue. The thread reads JSONL lines written by
            # meet_say, calls OpenAI Realtime, and streams the audio PCM to
            # the virtual sink that Chrome's fake-mic is pointed at.
            if rt["enabled"]:
                _start_realtime_speaker(
                    rt=rt,
                    out_dir=out_dir,
                    bridge_info=rt["bridge_info"],
                    api_key=realtime_api_key,
                    model=realtime_model,
                    voice=realtime_voice,
                    instructions=realtime_instructions,
                    stop_flag=stop_flag,
                    state=state,
                )
                if rt["session"] is not None:
                    state.set(realtime_ready=True)

            # Admission + drain loop. Runs until SIGTERM, duration expiry,
            # or the page detects "You were removed / you left the
            # meeting". Responsible for:
            #   * detecting admission (Leave button visible → in_call=True)
            #   * timing out stuck-in-lobby (default 5 minutes)
            #   * draining scraped captions into the transcript
            #   * triggering realtime barge-in when a human speaks while
            #     the bot is generating audio
            #   * periodically flushing realtime counters into status.json
            deadline = (time.time() + duration_s) if duration_s else None
            lobby_deadline = time.time() + float(
                os.environ.get("HERMES_MEET_LOBBY_TIMEOUT", "300")
            )
            last_admission_check = 0.0
            while not stop_flag["stop"]:
                now = time.time()
                if deadline and now > deadline:
                    state.set(leave_reason="duration_expired")
                    break

                # Admission detection every ~3s until admitted.
                if not state.in_call and (now - last_admission_check) > 3.0:
                    last_admission_check = now
                    admitted = _detect_admission(page)
                    if admitted:
                        state.set(
                            in_call=True,
                            lobby_waiting=False,
                            joined_at=now,
                        )
                        try:
                            _configure_captions(page, state, language, translated_captions, translation_target)
                            page.evaluate(_enable_captions_js())
                            state.set(captions_enabled_attempted=True)
                        except Exception as e:
                            state.set(error=f"caption configuration failed: {e}")
                    elif now > lobby_deadline:
                        state.set(
                            error=(
                                "lobby timeout — host never admitted the bot "
                                f"within {int(lobby_deadline - state.join_attempted_at) if state.join_attempted_at else 0}s"
                            ),
                            leave_reason="lobby_timeout",
                        )
                        break
                    elif _detect_denied(page):
                        state.set(
                            error="host denied admission",
                            leave_reason="denied",
                        )
                        break

                try:
                    for command in _drain_commands(out_dir):
                        if command.get("command") == "set_language":
                            try:
                                _configure_captions(
                                    page, state, command["language"],
                                    bool(command.get("translated_captions")), command.get("translation_target"),
                                )
                                _write_command_result(
                                    out_dir, command, ok=True, language=command["language"]
                                )
                            except Exception as e:
                                state.set(error=f"live caption configuration failed: {e}")
                                _write_command_result(out_dir, command, ok=False, error=str(e))
                    queued = page.evaluate("window.__hermesMeetDrain && window.__hermesMeetDrain()")
                    if isinstance(queued, list):
                        for entry in queued:
                            if not isinstance(entry, dict):
                                continue
                            speaker = str(entry.get("speaker", ""))
                            text = str(entry.get("text", ""))
                            state.record_caption(speaker=speaker, text=text)
                            # Barge-in: if the bot is currently generating
                            # audio AND a real human just spoke, cancel the
                            # in-flight response so we don't talk over them.
                            if rt["enabled"] and rt["session"] is not None:
                                if _looks_like_human_speaker(speaker, guest_name):
                                    try:
                                        cancelled = rt["session"].cancel_response()
                                        if cancelled:
                                            state.set(last_barge_in_at=now)
                                    except Exception:
                                        pass
                except Exception:
                    # Meet reloaded or we got booted — try to detect and
                    # exit gracefully rather than spinning.
                    if page.is_closed():
                        state.set(leave_reason="page_closed")
                        break

                if state._active_caption and now - state._active_caption["updated_at"] >= 2:
                    state.finalize_caption()

                # Fold the realtime session's byte/timestamp counters into
                # the status file so meet_status can surface them.
                if rt["session"] is not None:
                    state.set(
                        audio_bytes_out=getattr(rt["session"], "audio_bytes_out", 0),
                        last_audio_out_at=getattr(rt["session"], "last_audio_out_at", None),
                    )

                time.sleep(1.0)

            # Try to leave cleanly — click "Leave call" button if present.
            try:
                page.evaluate(
                    "() => { const b = document.querySelector('button[aria-label*=\"eave call\"]');"
                    " if (b) b.click(); }"
                )
            except Exception:
                pass

            context.close()
            # v2: teardown PCM pump, speaker thread, and audio bridge.
            if rt.get("pcm_pump"):
                try:
                    rt["pcm_pump"].terminate()
                    rt["pcm_pump"].wait(timeout=3)
                except Exception:
                    pass
            if rt["speaker_stop"]:
                try:
                    rt["speaker_stop"]()
                except Exception:
                    pass
            if rt["speaker_thread"] is not None:
                try:
                    rt["speaker_thread"].join(timeout=5.0)
                except Exception:
                    pass
            if rt["session"]:
                try:
                    rt["session"].close()
                except Exception:
                    pass
            if rt["bridge"]:
                try:
                    rt["bridge"].teardown()
                except Exception:
                    pass
            state.finalize_caption()
            state.set(in_call=False, captioning=False, exited=True)
            return 0

    except Exception as e:
        state.set(error=f"unhandled: {e}", exited=True)
        return 1


def _try_guest_name(page, guest_name: str) -> None:
    """If Meet is showing a guest-name input, type *guest_name* into it."""
    try:
        # Meet's guest name input has placeholder "Your name".
        locator = page.locator('input[aria-label*="name" i]').first
        if locator.count() and locator.is_visible():
            locator.fill(guest_name, timeout=2_000)
    except Exception:
        pass


def _detect_admission(page) -> bool:
    """True if we're clearly past the lobby and in the call itself.

    Uses a JS-side probe because Meet's DOM structure varies by client
    version. We check several high-signal indicators and declare admission
    on the first hit:

      1. Leave-call button is present (``aria-label`` contains "eave call").

    Conservative by default — returns False on any error.
    """
    probe = r"""
    (() => {
      const leave = document.querySelector('button[aria-label*="eave call" i]');
      if (leave) return true;
      return false;
    })();
    """
    try:
        return bool(page.evaluate(probe))
    except Exception:
        return False


def _detect_denied(page) -> bool:
    """True only for explicit removal, not transient lobby wording.

    Other rejection-like text is left to the lobby timeout. Meet reuses it
    while a host can still admit the participant, which caused false denials.
    """
    probe = r"""
    (() => {
      const text = document.body ? document.body.innerText || '' : '';
      // English only. Do not treat generic "can't join" or unanswered lobby
      // text as terminal: those have appeared before successful admission.
      if (/You were removed from the meeting/i.test(text)) return true;
      return false;
    })();
    """
    try:
        return bool(page.evaluate(probe))
    except Exception:
        return False


def _looks_like_human_speaker(speaker: str, bot_guest_name: str) -> bool:
    """Whether a caption line's speaker is probably a human, not our bot echo.

    Meet attributes captions to the speaker's display name. When Chrome is
    reading our fake mic, Meet still attributes captions to *our* bot name
    (because the bot is the one "speaking"). We don't want those to trigger
    barge-in. Anything else — real participant names — does.

    Conservative: unknown / blank speakers (common when caption scraping
    falls back to raw text) do NOT trigger barge-in, because we can't tell
    whether it was a human or us.
    """
    if not speaker or not speaker.strip():
        return False
    spk = speaker.strip().lower()
    if spk in {"unknown", "you", bot_guest_name.strip().lower()}:
        return False
    return True


def _click_join(page, state: _BotState) -> None:
    """Click 'Join now' or 'Ask to join' if either button is visible.

    Flags ``lobby_waiting`` when we hit the "waiting for host to admit you"
    state so the agent can surface that in status.
    """
    for label in ("Join now", "Ask to join"):
        try:
            btn = page.get_by_role("button", name=label, exact=False).first
            if btn.count() and btn.is_visible():
                btn.click(timeout=3_000)
                if label == "Ask to join":
                    state.set(lobby_waiting=True)
                break
        except Exception:
            continue


def _parse_duration(raw: str) -> Optional[float]:
    """Parse ``30m`` / ``2h`` / ``90`` (seconds) → float seconds, or None."""
    if not raw:
        return None
    raw = raw.strip().lower()
    try:
        if raw.endswith("h"):
            return float(raw[:-1]) * 3600
        if raw.endswith("m"):
            return float(raw[:-1]) * 60
        if raw.endswith("s"):
            return float(raw[:-1])
        return float(raw)
    except ValueError:
        return None


if __name__ == "__main__":  # pragma: no cover — subprocess entry point
    sys.exit(run_bot())
