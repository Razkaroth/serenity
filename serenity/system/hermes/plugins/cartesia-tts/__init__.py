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
        return "cartesia"

    @property
    def display_name(self) -> str:
        return "Cartesia Sonic"

    @property
    def voice_compatible(self) -> bool:
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
        del format, extra

        api_key = os.environ.get("CARTESIA_API_KEY")
        if not api_key:
            raise RuntimeError("CARTESIA_API_KEY is not set")

        voice_id = voice or os.environ.get("CARTESIA_VOICE_ID")
        if not voice_id:
            raise RuntimeError(
                "No Cartesia voice configured. Set tts.voice or CARTESIA_VOICE_ID."
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
            detail = body

            try:
                parsed = json.loads(body)
                detail = parsed.get("message") or parsed.get("title") or body
            except json.JSONDecodeError:
                pass

            raise RuntimeError(
                f"Cartesia TTS failed with HTTP {exc.code}: {detail}"
            ) from exc
        except URLError as exc:
            raise RuntimeError(f"Cartesia TTS network error: {exc.reason}") from exc

        Path(target).write_bytes(audio)

        return target


def register(ctx):
    ctx.register_tts_provider(CartesiaTTSProvider())
