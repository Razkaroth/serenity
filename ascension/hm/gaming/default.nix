{
  config,
  osConfig, # This config only works with home-manager as a nixos module
  lib,
  pkgs,
  inputs, # Ensure inputs is available to your home-manager configuration
  ...
}:
{
  imports = [
    inputs.play-nix.homeManagerModules.play
  ];

  play = {
    # Configure monitors for automatic gamescope settings
    monitors = [
      {
        name = "eDP-1";
        primary = true;
        width = 2880;
        height = 1800;
        refreshRate = 120;
        hdr = false;
        vrr = true;
      }
    ];

    # Enable gamescope wrapper
    gamescoperun = {
      enable = true;
      
      # Global defaults for all wrappers (can be overridden per-wrapper)
      defaultHDR = false;      # null = auto-detect monitor HDR (default), true/false = force on/off
      defaultWSI = true;      # Global WSI (Wayland Surface Interface) setting
      defaultSystemd = false; # Global systemd-run setting
      
      # Optional: Override base gamescope options
      baseOptions = {
        "fsr-upscaling" = false;
        # "output-width" = 2560;   # Overrides monitor-derived width
      };
      
      # Optional: Override environment variables
      environment = {
        CUSTOM_VAR = "value";
      };
    };

    # Create application wrappers
    wrappers = {
      # If you wish to override the "steam" command/bin, remove "-gamescope"
      # Overriding the executables makes it so already existing .desktop launchers use the new wrapper
      steam-gamescope = {
        enable = true;
        # Note: Special case for steam, this is the pkg you should use
        # Also as of 07/23, steam does not open in normal "desktop mode" with gamescope
        # You can however exit big picture mode once already open to access the normal ui
        command = "${lib.getExe osConfig.programs.steam.package} -bigpicture -tenfoot";
        
        # Per-wrapper overrides (null = use global defaults)
        useHDR = true;        # Override: force HDR for Steam
        useWSI = null;        # Use global defaultWSI setting
        useSystemd = true;    # Override: use systemd-run for Steam
        
        extraOptions = {
          "steam" = true; # equivalent to --steam flag
        };
        environment = {
          STEAM_FORCE_DESKTOPUI_SCALING = 1;
          STEAM_GAMEPADUI = 1;
        };
      };

      lutris-gamescope = {
        enable = true;
        package = osConfig.play.lutris.package; # play.nix provides readonly packages
        
        # Per-wrapper configuration
        useHDR = false;       # Override: disable HDR for Lutris
        useWSI = true;        # Override: ensure WSI is enabled
        useSystemd = null;    # Use global defaultSystemd setting
        
        extraOptions = {
          "force-windows-fullscreen" = true;
        };
        environment = {
          LUTRIS_SKIP_INIT = 1;
        };
      };

      heroic-gamescope = {
        enable = true;
        package = pkgs.heroic;
        
        # Use all global defaults by omitting override options
        extraOptions."fsr-upscaling" = true;
      };
    };
  };

  # Recommendation: Override desktop entries to use gamescope wrappers
  xdg.desktopEntries = {
    steamGamescope = lib.mkDefault {
      name = "Steam Gamescope";
      comment = "Steam Big Picture (Gamescope Session)";
      exec = "${lib.getExe config.play.wrappers.steam-gamescope.wrappedPackage}";
      icon = "steam";
      type = "Application";
      terminal = false;
      categories = [ "Game" ];
      mimeType = [
        "x-scheme-handler/steam"
        "x-scheme-handler/steamlink"
      ];
      settings = {
        StartupNotify = "true";
        StartupWMClass = "Steam";
        PrefersNonDefaultGPU = "true";
        X-KDE-RunOnDiscreteGpu = "true";
        Keywords = "gaming;";
      };
      actions = {
        client = {
          name = "Steam Client (No Gamescope)";
          exec = "${lib.getExe osConfig.programs.steam.package}";
        };
        steamdeck = {
          name = "Steam Deck (Gamescope)";
          exec = "${lib.getExe config.play.wrappers.steam-gamescope.wrappedPackage} -steamdeck -steamos3";
        };
      };
    };

    heroic = {
      name = "Heroic (Gamescope)";
      exec = "${lib.getExe config.play.wrappers.heroic-gamescope.wrappedPackage}";
      icon = "com.heroicgameslauncher.hgl";
      type = "Application";
      categories = [ "Game" ];
    };
  };
  programs.mangohud = {
    enable = true;
    settings = {
      position = "top-right";
      cpu_stats = true;
      gpu_stats = true;
      fps = true;
      font_size = 12;
      cellpadding_y = -0.070;
      background_alpha = lib.mkForce 0.5;
      alpha = lib.mkForce 0.75;
    };
  };
}
