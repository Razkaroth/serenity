{ pkgs, pkgs-edge, pkgs-locked, inputs, ... }:
let
  system = "x86_64-linux";

  lockedPkgs = with pkgs-locked; [
  ];
  stablePkgs = with pkgs; [
    bagels
    yazi
    eza
    kitty
    firefox # browser
    bottles # wine manager
    brave # browser
    chromium # browser
    google-chrome # browser
    satty
    gnome-disk-utility
    # vesktop # discord client
    pomodoro
    kdePackages.konsole
    sunvox
    obsidian
    obs-studio
    rofi
    typora
    transmission_4-gtk
    libreoffice
    kdePackages.kalarm
    gcalcli # google calendar
    todoist
    todoist-electron
    signal-desktop # messaging client
    zoom-us # video conferencing
    zk
    gthumb
    capitaine-cursors-themed
  ];
  edgePkgs = with pkgs-edge; [

    vesktop
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs ++ lockedPkgs ++ [
    inputs.zen-browser.packages."${system}".beta # zen-beta
  ];

  # Configure zen-beta as default browser
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/ftp" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";
      "x-scheme-handler/webcal" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";

      # all images to satty, except SVG which opens in Zen
      "image/avif" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/bmp" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/gif" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/heic" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/heif" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/jpeg" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/jxl" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/png" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/tiff" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/webp" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-bmp" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-ico" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-png" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-tga" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-tiff" = [ "satty.desktop" "com.gabm.satty.desktop" ];
      "image/x-webp" = [ "satty.desktop" "com.gabm.satty.desktop" ];

      # SVG/PDF in browser (Zen)
      "image/svg+xml" = "zen-beta.desktop";
      "application/pdf" = "zen-beta.desktop";
      "application/x-pdf" = "zen-beta.desktop";

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
      "x-scheme-handler/file" = "org.kde.dolphin.desktop";
    };
  };

  home.sessionVariables = {
    BROWSER = "zen-beta";
    DEFAULT_BROWSER = "zen-beta";
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
      ExecStart = "${pkgs-edge.gcalcli}/bin/gcalcli remind";
      Restart = "on-failure";
      RestartSec = "30";
      # Set working directory to user's home directory for OAuth2 config access
      WorkingDirectory = "%h";
      # Ensure proper environment for gcalcli and OAuth2
      Environment = [
        "PATH=${pkgs-edge.gcalcli}/bin:${pkgs-edge.coreutils}/bin:/run/current-system/sw/bin"
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
