{ pkgs, ... }:

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

    environmentFiles = [
      "/home/raz/.config/hermes/hermes.env"
    ];

    settings = {
      custom_providers = [
        {
          name = "opencode-go";
          base_url = "https://opencode.ai/zen/go/v1";
          key_env = "OPENCODE_API_KEY";
        }
      ];

      model = {
        provider = "custom:opencode-go";
        default = "glm-5.2";
      };

      toolsets = [ "all" ];

      discord = {
        reply_to_mode = "off";
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
