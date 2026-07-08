You’re right. I presented general TTS providers as though Hermes could use them directly, which was wrong. I should have separated **providers available in the TTS market** from **providers actually supported by Hermes**.

For Cartesia, the good news is that the Hermes codebase already has the correct extension point. You should add Cartesia as a **Python TTS provider plugin**, not patch `tools/tts_tool.py` and not maintain a Hermes fork. The current provider interface explicitly supports external backends, and the repository even mentions Cartesia as an intended consumer of that infrastructure.

## Recommended architecture

For a NixOS-module installation:

```text
your-nixos-config/
├── flake.nix
├── modules/
│   └── hermes.nix
└── hermes-plugins/
    └── cartesia-tts/
        ├── plugin.yaml
        └── __init__.py
```

The flow becomes:

```text
Hermes text_to_speech tool
        │
        ▼
TTS plugin registry
        │
        ▼
CartesiaTTSProvider.synthesize()
        │
        ▼
POST /tts/bytes
        │
        ▼
WAV audio
        │
        ▼
Hermes delivery pipeline
        │
        └── ffmpeg → Opus when needed for voice bubbles
```

Hermes's plugin ABC expects `synthesize()` to write audio to the requested output path and return the resulting path; it also exposes `voice_compatible` for the gateway's voice-message delivery pipeline.

---

# 1. Plugin manifest

`hermes-plugins/cartesia-tts/plugin.yaml`:

```yaml
name: cartesia-tts
version: "0.1.0"
description: Cartesia Sonic TTS backend for Hermes Agent
kind: backend

requires_env:
  - CARTESIA_API_KEY
```

I would call the **plugin** `cartesia-tts`, while the actual **provider name** is simply `cartesia`.

That distinction matters because:

```yaml
plugins:
  enabled:
    - cartesia-tts

tts:
  provider: cartesia
```

Hermes allows the plugin registration code to expose a TTS provider whose name is matched against `tts.provider`.

---

# 2. Cartesia adapter

I recommend starting without the Cartesia Python SDK.

For your NixOS deployment, using Python's standard library avoids having to package an extra Python dependency into Hermes's sealed environment. The Nix module supports directory plugins directly through `extraPlugins`, while external Python packages require separate interpreter-compatible packaging through `extraPythonPackages`.

`hermes-plugins/cartesia-tts/__init__.py`:

```python
from __future__ import annotations

import json
import os
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from agent.tts_provider import TTSProvider


API_BASE = "https://api.cartesia.ai"
API_VERSION = "2026-03-01"
DEFAULT_MODEL = "sonic-3.5"


class CartesiaTTSProvider(TTSProvider):
    @property
    def name(self) -> str:
        # This is what `tts.provider` must match.
        return "cartesia"

    @property
    def display_name(self) -> str:
        return "Cartesia Sonic"

    @property
    def voice_compatible(self) -> bool:
        # Hermes may convert WAV/MP3 to the format required by
        # a messaging platform's voice-message pipeline.
        return True

    def is_available(self) -> bool:
        return bool(os.environ.get("CARTESIA_API_KEY"))

    def list_models(self):
        return [
            {
                "id": "sonic-3.5",
                "display": "Sonic 3.5",
            },
            {
                "id": "sonic-3",
                "display": "Sonic 3",
            },
            {
                "id": "sonic-latest",
                "display": "Sonic Latest",
            },
        ]

    def get_setup_schema(self):
        return {
            "name": "Cartesia Sonic",
            "badge": "paid",
            "tag": "Low-latency conversational TTS",
            "env_vars": [
                {
                    "key": "CARTESIA_API_KEY",
                    "prompt": "Cartesia API key",
                    "url": "https://play.cartesia.ai/keys",
                }
            ],
        }

    def synthesize(
        self,
        text: str,
        output_path: str,
        *,
        voice: str | None = None,
        model: str | None = None,
        speed: float | None = None,
        format: str = "mp3",
        **extra,
    ) -> str:
        # The initial adapter deliberately emits WAV.
        # Hermes can convert it when the destination requires Opus.
        del format, extra

        api_key = os.environ.get("CARTESIA_API_KEY")
        if not api_key:
            raise RuntimeError("CARTESIA_API_KEY is not set")

        voice_id = voice or os.environ.get("CARTESIA_VOICE_ID")
        if not voice_id:
            raise RuntimeError(
                "No Cartesia voice configured. "
                "Set tts.voice or CARTESIA_VOICE_ID."
            )

        target = str(Path(output_path).with_suffix(".wav"))

        payload: dict = {
            "model_id": model or DEFAULT_MODEL,
            "transcript": text,
            "voice": {
                "mode": "id",
                "id": voice_id,
            },
            "output_format": {
                "container": "wav",
                "encoding": "pcm_s16le",
                "sample_rate": 44100,
            },
        }

        if speed is not None:
            payload["generation_config"] = {
                "speed": float(speed),
            }

        request = Request(
            f"{API_BASE}/tts/bytes",
            data=json.dumps(payload).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Cartesia-Version": API_VERSION,
                "Content-Type": "application/json",
            },
        )

        try:
            with urlopen(request, timeout=60) as response:
                audio = response.read()

        except HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")

            try:
                parsed = json.loads(body)
                detail = (
                    parsed.get("message")
                    or parsed.get("title")
                    or body
                )
            except json.JSONDecodeError:
                detail = body

            raise RuntimeError(
                f"Cartesia TTS failed with HTTP {exc.code}: {detail}"
            ) from exc

        except URLError as exc:
            raise RuntimeError(
                f"Cartesia TTS network error: {exc.reason}"
            ) from exc

        Path(target).write_bytes(audio)

        return target


def register(ctx):
    ctx.register_tts_provider(CartesiaTTSProvider())
```

This uses Cartesia's documented byte-generation endpoint, bearer-key authentication, version header, model/voice payload structure, and documented WAV output structure. ([Cartesia Docs][1]) ([Cartesia Docs][2]) ([Cartesia Docs][3])

Hermes explicitly supports a plugin returning a rewritten output path—for example, changing the requested `.mp3` path to `.wav`—so the adapter returning `target` is compatible with the dispatch contract.

---

# 3. Add the plugin to the Hermes NixOS module

In your Hermes module:

```nix
{ config, pkgs, ... }:

let
  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"

    cp \
      ${../hermes-plugins/cartesia-tts/plugin.yaml} \
      "$out/plugin.yaml"

    cp \
      ${../hermes-plugins/cartesia-tts/__init__.py} \
      "$out/__init__.py"
  '';
in
{
  services.hermes-agent = {
    enable = true;

    extraPlugins = [
      cartesiaTtsPlugin
    ];

    settings = {
      plugins.enabled = [
        "cartesia-tts"
      ];

      tts = {
        provider = "cartesia";

        # Cartesia voice UUID
        voice = "YOUR_CARTESIA_VOICE_ID";

        model = "sonic-3.5";
        speed = 1.0;
        output_format = "wav";
      };
    };

    environmentFiles = [
      config.sops.secrets."hermes-env".path
    ];
  };
}
```

The NixOS module requires each `extraPlugins` package to have `plugin.yaml` and `__init__.py` at its root, and activation symlinks those packages into Hermes's plugin directory.

## Important config quirk

For plugin TTS providers, these options currently need to be at the **top level of `tts`**:

```nix
tts = {
  provider = "cartesia";
  voice = "...";
  model = "sonic-3.5";
  speed = 1.0;
};
```

Not:

```nix
tts = {
  provider = "cartesia";

  cartesia = {
    voice = "...";
    model = "sonic-3.5";
  };
};
```

The current plugin dispatcher forwards `tts.voice`, `tts.model`, `tts.speed`, and `tts.output_format` directly to the registered provider.

You can still use:

```nix
tts.cartesia.max_text_length = 1234;
```

for the provider-specific truncation override, but I would leave that unset until we confirm Cartesia's current per-request limit rather than invent a value.

---

# 4. Add the API key through your existing secrets flow

Your environment file should contain:

```dotenv
CARTESIA_API_KEY=sk_car_...
```

Do **not** put it here:

```nix
services.hermes-agent.environment.CARTESIA_API_KEY = "...";
```

or inside `settings`.

The Hermes Nix module documentation explicitly warns that secrets placed directly in Nix expressions can end up in the world-readable Nix store; `environmentFiles` is the intended route.

The Cartesia voice ID itself does not need to be treated as a secret, so keeping that in the normal TTS settings is fine.

---

# 5. Rebuild and inspect

```bash
sudo nixos-rebuild switch --flake .#ascension
```

Then inspect the service:

```bash
systemctl status hermes-agent
```

and:

```bash
journalctl -u hermes-agent -f
```

To inspect plugin state interactively:

```bash
hermes plugins
```

The plugin should appear as `cartesia-tts`, and the active TTS provider should be `cartesia`.

Third-party/user-installed plugins are opt-in even when they are backend plugins, so `plugins.enabled = [ "cartesia-tts" ];` is necessary. Only repository-bundled backend plugins auto-load automatically.

For plugin discovery debugging, temporarily add:

```nix
services.hermes-agent.environment.HERMES_PLUGINS_DEBUG = "1";
```

The plugin loader has a dedicated `HERMES_PLUGINS_DEBUG` mode that exposes discovery and registration details.

---

## One important latency caveat

I would implement the ordinary `synthesize()` path first.

Hermes's `TTSProvider` interface does expose an optional:

```python
def stream(...):
    ...
```

method.

However, the standard plugin dispatch path I inspected currently invokes:

```python
plugin_provider.synthesize(...)
```

rather than consuming `plugin_provider.stream()`.

So I would **not spend time implementing Cartesia WebSocket/SSE streaming immediately**. Simply adding `stream()` to the adapter may not reduce Hermes's end-to-end voice latency until the relevant gateway/TTS delivery path is also wired to consume streamed provider chunks.

That would be phase two:

```text
Phase 1
Hermes reply complete
    → Cartesia /tts/bytes
    → WAV
    → delivery

Phase 2
Hermes token stream
    → sentence chunker
    → Cartesia streaming TTS
    → audio chunk delivery/playback
```

For Telegram or WhatsApp voice replies, phase 1 is probably completely adequate. For a future always-listening desktop voice incarnation of Hermes, phase 2 becomes much more worthwhile.

## Brief summary

The path I recommend is:

1. **Do not fork Hermes.**
2. Build `cartesia-tts` as a `TTSProvider` plugin.
3. Initially call Cartesia's `/tts/bytes` API directly using the Python standard library.
4. Package the two-file plugin with `pkgs.runCommand`.
5. Add it through `services.hermes-agent.extraPlugins`.
6. Enable `cartesia-tts` under `plugins.enabled`.
7. Select `tts.provider = "cartesia"`.
8. Keep the API key in your existing `environmentFiles` secret.
9. Only investigate true streaming after the basic adapter is working, because the current standard plugin dispatcher still calls `synthesize()`.

The adapter is quite small—roughly 100 lines—and the current Hermes architecture is already prepared for exactly this kind of addition.

[1]: https://docs.cartesia.ai/api-reference/tts/bytes "Text-to-Speech (Bytes) - Cartesia Docs"
[2]: https://docs.cartesia.ai/use-the-api/api-conventions "API Conventions - Cartesia Docs"
[3]: https://docs.cartesia.ai/examples/tts-generate-to-file "Generate to File - Cartesia Docs"
