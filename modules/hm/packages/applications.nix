{ pkgs,inputs, ... }:
let
  system = "x86_64-linux";
in
{
  home.packages = with pkgs; [
    # --------------------------------------------------- // Applications
    firefox # browser
    bottles # wine manager
    inputs.zen-browser.packages."${system}".beta # zen-beta
    brave # browser
    chromium # browser
    google-chrome # browser
    vesktop # discord client
    pomodoro
    sunvox
    obsidian
    obs-studio
    typora
    transmission_4-gtk
    libreoffice
    kdePackages.kalarm
    gcalcli # google calendar
    signal-desktop # messaging client
    zoom-us # video conferencing
    zk
  ];

  # Configure zen-beta as default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      
      # Keep other existing defaults
      "application/javascript" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "inode/directory" = "org.kde.dolphin.desktop";
      "text/css" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "text/plain" = "nvim.desktop";
      "text/x-c++src" = "nvim.desktop";
      "text/x-csrc" = "nvim.desktop";
      "text/x-go" = "nvim.desktop";
      "text/x-java-source" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-typescript" = "nvim.desktop";
      "x-scheme-handler/about" = "org.kde.dolphin.desktop";
      "x-scheme-handler/file" = "org.kde.dolphin.desktop";
    };
  };

  # Systemd user service for gcalcli reminders
  systemd.user.timers.gcalcli-reminders = {
    Unit = {
      Description = "gcalcli reminders timer";
    };
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.gcalcli-reminders = {
    Unit = {
      Description = "gcalcli reminders";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.gcalcli}/bin/gcalcli remind";
      Restart = "on-failure";
      RestartSec = "30";
      # Set working directory to user's home directory for OAuth2 config access
      WorkingDirectory = "%h";
      # Ensure proper environment for gcalcli and OAuth2
      Environment = [
        "PATH=${pkgs.gcalcli}/bin:${pkgs.coreutils}/bin:/run/current-system/sw/bin"
        "HOME=%h"
        "XDG_CONFIG_HOME=%h/.config"
        "XDG_DATA_HOME=%h/.local/share"
        "XDG_CACHE_HOME=%h/.cache"
      ];
      # Timeout to prevent hanging
      TimeoutStartSec = "60";
    };
  };
}
