#!/usr/bin/env python3
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ENDPOINT = "http://127.0.0.1:8765/synthesize"


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: hermes-neutts-http INPUT_TEXT_PATH OUTPUT_AUDIO_PATH")

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    payload = json.dumps(
        {"text": input_path.read_text(encoding="utf-8")}
    ).encode("utf-8")
    request = Request(
        ENDPOINT,
        data=payload,
        method="POST",
        headers={"Content-Type": "application/json"},
    )

    try:
        with urlopen(request, timeout=290) as response:
            audio = response.read()
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"NeuTTS returned HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"NeuTTS service unavailable: {exc.reason}") from exc

    if not audio:
        raise RuntimeError("NeuTTS returned empty audio")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(audio)


if __name__ == "__main__":
    main()
