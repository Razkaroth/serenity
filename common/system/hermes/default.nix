{ pkgs, ... }:

let
  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"
    cp ${./plugins/cartesia-tts/plugin.yaml} "$out/plugin.yaml"
    cp ${./plugins/cartesia-tts/__init__.py} "$out/__init__.py"
  '';
  neuttsRefText = pkgs.writeText "neutts-reference-text.txt" ''
    Morning. Four tasks: finish the landing page by end of day, review the Márquez contract, fix nexus permissions, renew the SSL cert. Meeting at 2 PM with design. Saturday is Emilio's thing — bring food. And no, the contract review can't move to tomorrow. It's been sitting since Monday and Márquez is waiting.
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
        provider = "neutts";
        neutts = {
          ref_audio = "/data/.hermes/tts/voice-message.wav";
          ref_text = "${neuttsRefText}";
          model = "neuphonic/neutts-air-q4-gguf";
          device = "cpu";
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
      nodejs_22
      ripgrep
      uv
    ];
  };

  # Hermes hardens its env/auth parent with chmod 0700 at startup, but the NixOS
  # module exposes that state to hostUsers via ~/.hermes -> /var/lib/hermes/.hermes.
  # Restore group traversal after service start so raz can run the host CLI.
  systemd.services.hermes-agent.postStart = ''
    sleep 2
    chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes
    chown hermes:hermes /var/lib/hermes /var/lib/hermes/.hermes
  '';
}
