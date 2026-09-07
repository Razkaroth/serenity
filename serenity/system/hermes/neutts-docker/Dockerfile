FROM python:3.12.13-slim

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

COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip \
  && pip install -r /tmp/requirements.txt

WORKDIR /app
COPY synth.py /app/synth.py
RUN python -c "from neutts import NeuTTS"

ENTRYPOINT ["python", "/app/synth.py"]
