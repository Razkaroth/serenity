{ pkgs, ... }:

{
  imports = [
    ./alters.nix
    ./camofox-docker.nix
    ./plugins.nix
    ./tts-neutts-docker.nix
  ];

  # The host CLI uses sudo -n docker to enter the root-owned Hermes container.
  # This does not grant the Hermes container Docker socket access.
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
        "/home/raz/serenity/common/system/hermes:/home/raz/serenity/common/system/hermes:ro"
        "${pkgs.gws}/bin/gws:/usr/local/bin/gws:ro"
      ];
    };

    environmentFiles = [
      "/home/raz/.config/hermes/hermes.env"
    ];

    environment = {
      # Keep gws OAuth state in Hermes's persistent state volume rather than
      # the container's ephemeral /home/hermes.
      GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "/data/.hermes/gws";
      GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = "file";
    };

    settings = {
      custom_providers = [
        {
          name = "opencode-go";
          base_url = "https://opencode.ai/zen/go/v1";
          key_env = "OPENCODE_API_KEY";
        }
      ];

      model = {
        provider = "opencode-go";
        default = "deepseek-v4-pro";
      };

      toolsets = [ "all" ];

      mcp_servers.linear = {
        url = "https://mcp.linear.app/mcp";
        auth = "oauth";
      };

      web.backend = "exa";

      browser.camofox = {
        managed_persistence = true;
        rewrite_loopback_urls = true;
        loopback_host_alias = "host.docker.internal";
      };

      discord = {
        reactions = false;
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
        provider = "holographic";
      };
    };

    extraPackages = with pkgs; [
      bashInteractive
      coreutils
      curl
      espeak-ng
      ffmpeg
      git
      gws
      nodejs_22
      ripgrep
      uv
    ];
  };

  services.hermes-alters = {
    enable = true;
    instances.gai-sensei = {
      enable = true;
      envFile = "/home/raz/.config/hermes/.env.gai-sensei";
    };
  };

  # Hermes hardens its env/auth parent with chmod 0700 at startup, but the
  # NixOS module exposes that state to hostUsers via ~/.hermes ->
  # /var/lib/hermes/.hermes. Restore group traversal for host CLI access.
  systemd.services.hermes-agent.postStart = ''
    sleep 2
    chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes
    chown hermes:hermes /var/lib/hermes /var/lib/hermes/.hermes
  '';

}
