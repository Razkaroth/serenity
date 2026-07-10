{ pkgs, ... }:

let
  neuttsDockerImage = "hermes-neutts:latest";

  neuttsHttpBridge = pkgs.writeShellApplication {
    name = "hermes-neutts-http";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python ${./neutts-http-bridge.py} "$@"
    '';
  };
in
{
  services.hermes-agent = {
    settings.tts = {
      provider = "neutts-http";
      providers.neutts-http = {
        type = "command";
        command = "${pkgs.lib.getExe neuttsHttpBridge} {input_path} {output_path}";
        output_format = "wav";
        timeout = 300;
        voice_compatible = true;
        max_text_length = 2000;
      };
    };

    extraPackages = [
      neuttsHttpBridge
    ];
  };

  systemd.services.hermes-neutts-image = {
    description = "Build Hermes NeuTTS Docker image";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      docker build -t ${neuttsDockerImage} ${./neutts-docker}
    '';
  };

  systemd.services.hermes-neutts = {
    description = "NeuTTS loopback HTTP service";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "hermes-neutts-image.service"
    ];
    requires = [
      "docker.service"
      "hermes-neutts-image.service"
    ];
    path = [ pkgs.docker-client ];

    preStart = ''
      docker rm --force hermes-neutts 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name hermes-neutts \
        --network host \
        --read-only \
        --tmpfs /tmp:rw,nosuid,nodev \
        --volume /var/lib/hermes-neutts/cache:/cache:rw \
        --volume ${./neutts/C2-voicea/audio.wav}:/voice/audio.wav:ro \
        --volume ${./neutts/C2-voicea/text.txt}:/voice/text.txt:ro \
        --env HF_HOME=/cache \
        --env NUMBA_CACHE_DIR=/tmp/numba-cache \
        --env TORCHINDUCTOR_CACHE_DIR=/tmp/torch-cache \
        ${neuttsDockerImage} \
        --serve 127.0.0.1:8765 \
        --ref-audio /voice/audio.wav \
        --ref-text /voice/text.txt \
        --model neuphonic/neutts-air-q4-gguf \
        --device cpu
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "hermes-neutts";
    };
  };
}
