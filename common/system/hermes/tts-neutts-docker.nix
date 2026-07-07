{ lib, pkgs, ... }:

let
  neuttsDockerImage = "hermes-neutts:latest";

  neuttsRefText = pkgs.writeText "neutts-reference-text.txt" ''
    Morning. Four tasks: finish the landing page by end of day, review the Márquez contract, fix nexus permissions, renew the SSL cert. Meeting at 2 PM with design. Saturday is Emilio's thing — bring food. And no, the contract review can't move to tomorrow. It's been sitting since Monday and Márquez is waiting.
  '';

  neuttsDockerProvider = pkgs.writeShellScriptBin "hermes-neutts-docker" ''
    set -euo pipefail

    if [ "$#" -ne 2 ]; then
      echo "usage: hermes-neutts-docker INPUT_TEXT_PATH OUTPUT_AUDIO_PATH" >&2
      exit 64
    fi

    input_path="$1"
    output_path="$2"
    state_root="/var/lib/hermes/.hermes"
    work_root="$state_root/tts/docker-work"
    cache_root="$state_root/cache/huggingface"
    run_dir="$work_root/$(date +%s)-$$"

    mkdir -p "$run_dir" "$cache_root" "$(dirname "$output_path")"
    trap 'rm -rf "$run_dir"' EXIT

    cp "$input_path" "$run_dir/input.txt"
    cp ${neuttsRefText} "$run_dir/ref.txt"

    ${pkgs.docker-client}/bin/docker run --rm \
      --user "$(${pkgs.coreutils}/bin/id -u):$(${pkgs.coreutils}/bin/id -g)" \
      --volume "$run_dir:/work:rw" \
      --volume "$cache_root:/cache:rw" \
      --volume "$state_root/tts:/voice:ro" \
      --env HF_HOME=/cache \
      --env NUMBA_CACHE_DIR=/tmp/numba-cache \
      --env TORCHINDUCTOR_CACHE_DIR=/tmp/torch-cache \
      ${neuttsDockerImage} \
      --text-file /work/input.txt \
      --out /work/output.wav \
      --ref-audio /voice/voice-message.wav \
      --ref-text /work/ref.txt \
      --model neuphonic/neutts-air-q4-gguf \
      --device cpu

    cp "$run_dir/output.wav" "$output_path"
  '';
in
{
  services.hermes-agent = {
    container.extraVolumes = [
      "/var/lib/hermes:/var/lib/hermes:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];

    settings.tts = {
      provider = "neutts-docker";
      providers.neutts-docker = {
        type = "command";
        command = "${pkgs.lib.getExe neuttsDockerProvider} {input_path} {output_path}";
        output_format = "wav";
        timeout = 300;
        voice_compatible = true;
        max_text_length = 2000;
      };
    };

    extraPackages = [
      neuttsDockerProvider
    ];
  };

  # Hermes starts as uid/gid hermes inside its container after dropping
  # supplementary groups, so Docker socket access must be granted by uid.
  systemd.services.hermes-agent.preStart = lib.mkBefore ''
    if [ -S /var/run/docker.sock ]; then
      ${pkgs.acl}/bin/setfacl -m u:hermes:rw /var/run/docker.sock
    fi
  '';

  systemd.services.hermes-neutts-image = {
    description = "Build Hermes NeuTTS Docker image";
    wantedBy = [ "multi-user.target" ];
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
}
