---
name: voice-update
description: Update this alter's NeuTTS reference voice sample without rebuilding NixOS.
---

# Voice Update

Your NeuTTS reference sample is persistent and editable from this container:

- Audio: `/data/neutts/audio.wav`
- Transcript: `/data/neutts/text.txt`

To change your voice:

1. Replace `audio.wav` with a clean WAV recording of the desired voice.
2. Replace `text.txt` with the exact spoken transcript for that recording.
3. Write replacement files in `/data/neutts/` and atomically rename them into place when possible, so a synthesis request never reads a partial upload.
4. Make another TTS request. NeuTTS detects file changes and reloads the reference automatically. Do not rebuild NixOS or restart services.

Keep the recording and transcript aligned. Use only voice material you are authorized to use.
