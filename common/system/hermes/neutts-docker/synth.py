#!/usr/bin/env python3
import argparse
import re
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


def main() -> None:
    parser = argparse.ArgumentParser(description="NeuTTS Docker synthesis helper")
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--ref-audio", required=True)
    parser.add_argument("--ref-text", required=True)
    parser.add_argument("--model", default="neuphonic/neutts-air-q4-gguf")
    parser.add_argument("--device", default="cpu")
    parser.add_argument("--max-chars", type=int, default=320)
    parser.add_argument("--sentence-pause-ms", type=int, default=250)
    parser.add_argument("--word-pause-ms", type=int, default=30)
    parser.add_argument("--warmup-text", default="The voice is ready.")
    args = parser.parse_args()

    text = Path(args.text_file).read_text(encoding="utf-8").strip()
    ref_text = Path(args.ref_text).read_text(encoding="utf-8").strip()

    from neutts import NeuTTS
    import numpy as np
    import soundfile as sf

    tts = NeuTTS(
        backbone_repo=args.model,
        backbone_device=args.device,
        codec_repo="neuphonic/neucodec",
        codec_device=args.device,
    )
    ref_codes = tts.encode_reference(args.ref_audio)
    chunks = split_text(text, max(80, args.max_chars))
    if not chunks:
        raise ValueError("No text to synthesize")

    if args.warmup_text:
        print("Warming up NeuTTS inference", flush=True)
        tts.infer(args.warmup_text, ref_codes, ref_text)

    wavs = []
    for index, (chunk, boundary) in enumerate(chunks, start=1):
        print(
            f"Synthesizing chunk {index}/{len(chunks)} ({len(chunk)} chars, {boundary})",
            flush=True,
        )
        chunk_wav = np.asarray(tts.infer(chunk, ref_codes, ref_text), dtype=np.float32)
        print(
            f"Chunk {index} duration: {len(chunk_wav) / 24000:.2f}s",
            flush=True,
        )
        wavs.append(chunk_wav)
        if index != len(chunks):
            pause_ms = (
                args.sentence_pause_ms if boundary == "sentence" else args.word_pause_ms
            )
            pause = np.zeros(int(24000 * max(0, pause_ms) / 1000), dtype=np.float32)
            wavs.append(pause)

    wav = np.concatenate(wavs)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(out_path), wav, 24000)


if __name__ == "__main__":
    main()
