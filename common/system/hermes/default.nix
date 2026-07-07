{ lib, pkgs, ... }:

let
  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"
    cp ${./plugins/cartesia-tts/plugin.yaml} "$out/plugin.yaml"
    cp ${./plugins/cartesia-tts/__init__.py} "$out/__init__.py"
  '';

  neuttsRefText = pkgs.writeText "neutts-reference-text.txt" ''
    Morning. Four tasks: finish the landing page by end of day, review the Márquez contract, fix nexus permissions, renew the SSL cert. Meeting at 2 PM with design. Saturday is Emilio's thing — bring food. And no, the contract review can't move to tomorrow. It's been sitting since Monday and Márquez is waiting.
  '';

  neuttsDockerImage = "hermes-neutts:latest";

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
  security.sudo.extraRules = [
    {
      users = [ "raz" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/docker";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    container = {
      enable = true;
      backend = "docker";
      hostUsers = [ "raz" ];
      extraVolumes = [
        "/home/raz/.agents:/home/raz/.agents:rw"
        "/home/raz/nexus:/home/raz/nexus:rw"
        "/var/lib/hermes:/var/lib/hermes:rw"
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];
    };

    extraPlugins = [
      cartesiaTtsPlugin
    ];

    environmentFiles = [
      "/home/raz/.config/hermes/hermes.env"
    ];

    settings = {
      plugins.enabled = [
        "cartesia-tts"
      ];

      custom_providers = [
        {
          name = "opencode-go";
          base_url = "https://opencode.ai/zen/go/v1";
          key_env = "OPENCODE_API_KEY";
        }
      ];

      model = {
        provider = "custom:opencode-go";
        default = "deepseek-v4-pro";
      };

      toolsets = [ "all" ];

      discord = {
        reply_to_mode = "off";
      };

      tts = {
        provider = "neutts-docker";
        providers = {
          neutts-docker = {
            type = "command";
            command = "${pkgs.lib.getExe neuttsDockerProvider} {input_path} {output_path}";
            output_format = "wav";
            timeout = 300;
            voice_compatible = true;
            max_text_length = 2000;
          };
        };
      };

      terminal = {
        backend = "local";
        timeout = 180;
      };

      compression = {
        enabled = true;
        threshold = 0.85;
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    extraPackages = with pkgs; [
      bashInteractive
      coreutils
      curl
      espeak-ng
      ffmpeg
      git
      neuttsDockerProvider
      nodejs_22
      ripgrep
      uv
    ];

    extraPythonPackages = [ ];
  };

  # Hermes hardens its env/auth parent with chmod 0700 at startup, but the NixOS
  # module exposes that state to hostUsers via ~/.hermes -> /var/lib/hermes/.hermes.
  # Restore group traversal after service start so raz can run the host CLI.
  systemd.services.hermes-agent = {
    preStart = lib.mkBefore ''
      if [ -S /var/run/docker.sock ]; then
        ${pkgs.acl}/bin/setfacl -m u:hermes:rw /var/run/docker.sock
      fi
    '';

    postStart = ''
      sleep 2
      chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes
      chown hermes:hermes /var/lib/hermes /var/lib/hermes/.hermes
    '';
  };

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
