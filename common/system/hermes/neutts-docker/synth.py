#!/usr/bin/env python3
import argparse
import io
import json
import re
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def split_text(text: str, max_chars: int) -> list[tuple[str, str]]:
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return []

    sentences = re.split(r"(?<=[.!?])\s+", text)
    chunks: list[tuple[str, str]] = []
    current: list[str] = []
    current_len = 0

    def flush_words(value: str) -> None:
        words = value.split()
        piece = ""
        for word in words:
            candidate = f"{piece} {word}".strip()
            if len(candidate) > max_chars and piece:
                chunks.append((piece, "word"))
                piece = word
            else:
                piece = candidate
        if piece:
            chunks.append((piece, "word"))

    def flush_current() -> None:
        nonlocal current, current_len
        if current:
            chunks.append((" ".join(current), "sentence"))
            current = []
            current_len = 0

    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue

        if len(sentence) > max_chars:
            flush_current()
            flush_words(sentence)
        else:
            candidate_len = len(sentence) if not current else current_len + 1 + len(sentence)
            if current and candidate_len > max_chars:
                flush_current()

            if current:
                current.append(sentence)
                current_len += 1 + len(sentence)
            else:
                current = [sentence]
                current_len = len(sentence)

    flush_current()

    return chunks


class NeuTTSEngine:
    def __init__(self, args: argparse.Namespace) -> None:
        from neutts import NeuTTS

        self.args = args
        self.ref_audio_path = Path(args.ref_audio)
        self.ref_text_path = Path(args.ref_text)
        self.reference_mtime: tuple[int, int] | None = None
        self.tts = NeuTTS(
            backbone_repo=args.model,
            backbone_device=args.device,
            codec_repo="neuphonic/neucodec",
            codec_device=args.device,
        )
        self.lock = threading.Lock()
        self.reload_reference()

        if args.warmup_text:
            print("Warming up NeuTTS inference", flush=True)
            self.tts.infer(args.warmup_text, self.ref_codes, self.ref_text)

    def reload_reference(self) -> None:
        """Refresh reference data when the alter updates its sample files."""
        mtime = (
            self.ref_audio_path.stat().st_mtime_ns,
            self.ref_text_path.stat().st_mtime_ns,
        )
        if mtime == self.reference_mtime:
            return

        self.ref_text = self.ref_text_path.read_text(encoding="utf-8").strip()
        self.ref_codes = self.tts.encode_reference(str(self.ref_audio_path))
        self.reference_mtime = mtime
        print("Reloaded NeuTTS reference sample", flush=True)

    def synthesize(self, text: str) -> bytes:
        import numpy as np
        import soundfile as sf

        chunks = split_text(text, max(80, self.args.max_chars))
        if not chunks:
            raise ValueError("No text to synthesize")

        with self.lock:
            self.reload_reference()
            wavs = []
            for index, (chunk, boundary) in enumerate(chunks, start=1):
                print(
                    f"Synthesizing chunk {index}/{len(chunks)} "
                    f"({len(chunk)} chars, {boundary})",
                    flush=True,
                )
                for attempt in range(1, self.args.hum_retries + 2):
                    chunk_wav = np.asarray(
                        self.tts.infer(chunk, self.ref_codes, self.ref_text),
                        dtype=np.float32,
                    )

                    # Kept dormant until real hum samples establish thresholds.
                    # A hum has unusually stable volume, spectral centroid, and
                    # dominant-frequency energy across its short-time frames.
                    if not self.args.detect_hum or not is_probable_hum(chunk_wav):
                        break

                    print(
                        f"Rejecting probable hum in chunk {index}, "
                        f"attempt {attempt}/{self.args.hum_retries + 1}",
                        flush=True,
                    )
                else:
                    raise RuntimeError(
                        f"Chunk {index} remained a probable hum after "
                        f"{self.args.hum_retries + 1} attempts"
                    )

                print(
                    f"Chunk {index} duration: {len(chunk_wav) / 24000:.2f}s",
                    flush=True,
                )
                wavs.append(chunk_wav)
                if index != len(chunks):
                    pause_ms = (
                        self.args.sentence_pause_ms
                        if boundary == "sentence"
                        else self.args.word_pause_ms
                    )
                    pause = np.zeros(
                        int(24000 * max(0, pause_ms) / 1000), dtype=np.float32
                    )
                    wavs.append(pause)

            wav = np.concatenate(wavs)

        output = io.BytesIO()
        sf.write(output, wav, 24000, format="WAV")
        return output.getvalue()


def is_probable_hum(wav) -> bool:
    """Return true for a likely steady, narrowband artifact.

    Thresholds are intentionally conservative placeholders. Keep this detector
    disabled until good and bad NeuTTS chunks are available for calibration.
    """
    import numpy as np

    sample_rate = 24000
    frame_size = int(sample_rate * 0.04)
    hop_size = int(sample_rate * 0.02)
    if len(wav) < frame_size:
        return False

    frames = np.lib.stride_tricks.sliding_window_view(wav, frame_size)[::hop_size]
    frame_rms = np.sqrt(np.mean(np.square(frames), axis=1))
    voiced = frame_rms > 1e-4
    if np.count_nonzero(voiced) < 3:
        return False

    # Hum volume barely changes. Speech has changing syllable energy and pauses.
    rms_db = 20 * np.log10(np.maximum(frame_rms[voiced], 1e-8))

    window = np.hanning(frame_size)
    spectrum = np.abs(np.fft.rfft(frames[voiced] * window, axis=1)) ** 2
    frequencies = np.fft.rfftfreq(frame_size, 1 / sample_rate)
    spectral_energy = np.sum(spectrum, axis=1)
    centroids = np.sum(spectrum * frequencies, axis=1) / np.maximum(
        spectral_energy, 1e-12
    )

    # A pure or near-pure tone concentrates energy in one FFT bin. Speech spreads
    # energy over harmonics, formants, and consonants.
    dominant_energy = np.max(spectrum, axis=1) / np.maximum(spectral_energy, 1e-12)

    return (
        np.std(rms_db) < 2.0
        and np.std(centroids) < 120.0
        and np.median(dominant_energy) > 0.65
    )


def make_handler(engine: NeuTTSEngine, max_text_length: int):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            if self.path != "/health":
                self.send_error(404)
                return

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"ready"}')

        def do_POST(self) -> None:
            if self.path != "/synthesize":
                self.send_error(404)
                return

            try:
                content_length = int(self.headers.get("Content-Length", "0"))
                if content_length <= 0 or content_length > 16384:
                    raise ValueError("Invalid request size")

                payload = json.loads(self.rfile.read(content_length))
                if not isinstance(payload, dict):
                    raise ValueError("request body must be a JSON object")
                text = payload.get("text", "")
                if not isinstance(text, str) or not text.strip():
                    raise ValueError("text must be a non-empty string")
                if len(text) > max_text_length:
                    raise ValueError(f"text exceeds {max_text_length} characters")

                audio = engine.synthesize(text)
            except (json.JSONDecodeError, UnicodeDecodeError, ValueError) as exc:
                self.send_error(400, str(exc))
                return
            except Exception as exc:
                print(f"Synthesis failed: {exc}", flush=True)
                self.send_error(500, "Synthesis failed")
                return

            self.send_response(200)
            self.send_header("Content-Type", "audio/wav")
            self.send_header("Content-Length", str(len(audio)))
            self.end_headers()
            self.wfile.write(audio)

        def log_message(self, format: str, *args) -> None:
            print(f"{self.address_string()} - {format % args}", flush=True)

    return Handler


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="NeuTTS synthesis service")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--serve", metavar="HOST:PORT")
    mode.add_argument("--text-file")
    parser.add_argument("--out")
    parser.add_argument("--ref-audio", required=True)
    parser.add_argument("--ref-text", required=True)
    parser.add_argument("--model", default="neuphonic/neutts-air-q4-gguf")
    parser.add_argument("--device", default="cpu")
    parser.add_argument("--max-chars", type=int, default=320)
    parser.add_argument("--max-text-length", type=int, default=2000)
    parser.add_argument("--sentence-pause-ms", type=int, default=250)
    parser.add_argument("--word-pause-ms", type=int, default=30)
    parser.add_argument("--warmup-text", default="The voice is ready.")
    parser.add_argument(
        "--detect-hum",
        action="store_true",
        help="Reject and regenerate chunks matching experimental hum heuristics",
    )
    parser.add_argument(
        "--hum-retries",
        type=int,
        default=2,
        help="Additional synthesis attempts after a detected hum",
    )
    args = parser.parse_args()

    if args.text_file and not args.out:
        parser.error("--out is required with --text-file")
    if args.hum_retries < 0:
        parser.error("--hum-retries must be non-negative")

    return args


def main() -> None:
    args = parse_args()
    engine = NeuTTSEngine(args)

    if args.serve:
        host, separator, port = args.serve.rpartition(":")
        if not separator or not host:
            raise ValueError("--serve must use HOST:PORT")

        server = ThreadingHTTPServer(
            (host, int(port)), make_handler(engine, args.max_text_length)
        )
        print(f"NeuTTS listening on http://{host}:{port}", flush=True)
        server.serve_forever()
        return

    text = Path(args.text_file).read_text(encoding="utf-8").strip()
    audio = engine.synthesize(text)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(audio)


if __name__ == "__main__":
    main()
