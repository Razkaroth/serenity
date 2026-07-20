{ pkgs, ... }:

let
  playwrightRuntime = pkgs.python312Packages.toPythonModule (pkgs.symlinkJoin {
    name = "hermes-playwright-runtime";
    paths = with pkgs.python312Packages; [
      playwright
      pyee
      greenlet
    ];
  });
in
{
  imports = [
    ./alters.nix
    ./camofox-docker.nix
    ./plugins.nix
    ./spawn-hermes.nix
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
    # Hermes already seals typing-extensions. Keep it out of this union to
    # satisfy its extra-package collision guard while retaining Playwright.
    extraPythonPackages = [ playwrightRuntime ];
    # extraPythonPackages triggers a package override. Preserve Hermes's
    # default optional integrations instead of rebuilding its venv without
    # Discord, Slack, Telegram, voice, or other platform dependencies.
    extraDependencyGroups = [
      "anthropic"
      "azure-identity"
      "bedrock"
      "daytona"
      "dingtalk"
      "edge-tts"
      "exa"
      "fal"
      "feishu"
      "firecrawl"
      "hindsight"
      "honcho"
      "messaging"
      "modal"
      "parallel-web"
      "tts-premium"
      "voice"
      "matrix"
    ];

    container = {
      enable = true;
      backend = "docker";
      hostUsers = [ "raz" ];
      extraVolumes = [
        "/home/raz/.agents:/home/raz/.agents:rw"
        "/home/raz/nexus:/home/raz/nexus:rw"
        "/home/raz/serenity/serenity/system/hermes:/home/raz/serenity/serenity/system/hermes:ro"
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
      # Use Nix's browser bundle matching python-playwright, never a mutable
      # browser download under ~/.cache/ms-playwright.
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
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
        # provider = "custom:opencode-go";
        provider = "openai-codex";
        default = "gpt-5.6-sol";
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
      xorg-server
    ];
  };

  services.hermes-alters = {
    enable = true;
    instances.dr-bruce = {
      enable = true;
      envFile = "/home/raz/.config/hermes/.env.dr-bruce";
    };
    instances.morrison = {
      enable = true;
      envFile = "/home/raz/.config/hermes/.env.morrison";
    };

    instances.jarvis = {
      enable = true;
      envFile = "/home/raz/.config/hermes/.env.jarvis";
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

  systemd.services.hermes-agent-periodic-restart = {
    description = "Restart Hermes Agent every three days";

    serviceConfig.Type = "oneshot";

    script = ''
      state=/var/lib/hermes/.periodic-restart-last
      now=$(${pkgs.coreutils}/bin/date +%s)
      last=0

      if [ -r "$state" ]; then
        last=$(${pkgs.coreutils}/bin/cat "$state")
      fi

      # Timer runs daily, but restarts only after 72 hours.
      if [ "$((now - last))" -lt 259200 ]; then
        exit 0
      fi

      ${pkgs.coreutils}/bin/printf '%s\n' "$now" > "$state"
      ${pkgs.systemd}/bin/systemctl restart hermes-agent.service
    '';
  };

  systemd.timers.hermes-agent-periodic-restart = {
    description = "Three-day Hermes Agent restart timer";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      Unit = "hermes-agent-periodic-restart.service";
    };
  };
}
