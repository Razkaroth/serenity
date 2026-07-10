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
        self.ref_text = Path(args.ref_text).read_text(encoding="utf-8").strip()
        self.tts = NeuTTS(
            backbone_repo=args.model,
            backbone_device=args.device,
            codec_repo="neuphonic/neucodec",
            codec_device=args.device,
        )
        self.ref_codes = self.tts.encode_reference(args.ref_audio)
        self.lock = threading.Lock()

        if args.warmup_text:
            print("Warming up NeuTTS inference", flush=True)
            self.tts.infer(args.warmup_text, self.ref_codes, self.ref_text)

    def synthesize(self, text: str) -> bytes:
        import numpy as np
        import soundfile as sf

        chunks = split_text(text, max(80, self.args.max_chars))
        if not chunks:
            raise ValueError("No text to synthesize")

        with self.lock:
            wavs = []
            for index, (chunk, boundary) in enumerate(chunks, start=1):
                print(
                    f"Synthesizing chunk {index}/{len(chunks)} "
                    f"({len(chunk)} chars, {boundary})",
                    flush=True,
                )
                chunk_wav = np.asarray(
                    self.tts.infer(chunk, self.ref_codes, self.ref_text),
                    dtype=np.float32,
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
    args = parser.parse_args()

    if args.text_file and not args.out:
        parser.error("--out is required with --text-file")

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
