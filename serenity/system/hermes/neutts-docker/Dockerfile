FROM python:3.12-slim

ENV PIP_NO_CACHE_DIR=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    espeak-ng \
    ffmpeg \
    git \
    libsndfile1 \
    ninja-build \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip \
  && pip install 'neutts[all]==1.2.1' llama-cpp-python

WORKDIR /app
COPY synth.py /app/synth.py

ENTRYPOINT ["python", "/app/synth.py"]
