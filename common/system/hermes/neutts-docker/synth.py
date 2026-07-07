#!/usr/bin/env python3
import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="NeuTTS Docker synthesis helper")
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--ref-audio", required=True)
    parser.add_argument("--ref-text", required=True)
    parser.add_argument("--model", default="neuphonic/neutts-air-q4-gguf")
    parser.add_argument("--device", default="cpu")
    args = parser.parse_args()

    text = Path(args.text_file).read_text(encoding="utf-8").strip()
    ref_text = Path(args.ref_text).read_text(encoding="utf-8").strip()

    from neutts import NeuTTS
    import soundfile as sf

    tts = NeuTTS(
        backbone_repo=args.model,
        backbone_device=args.device,
        codec_repo="neuphonic/neucodec",
        codec_device=args.device,
    )
    ref_codes = tts.encode_reference(args.ref_audio)
    wav = tts.infer(text, ref_codes, ref_text)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(out_path), wav, 24000)


if __name__ == "__main__":
    main()
