{ pkgs,inputs, ... }:
let
  system = "x86_64-linux";
in
{
  home.packages = with pkgs; [
    # --------------------------------------------------- // Applications
    firefox # browser
    bottles # wine manager
    inputs.zen-browser.packages."${system}".default
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
    libsForQt5.networkmanager-qt
    kdePackages.kalarm
    gcalcli # google calendar
    signal-desktop # messaging client
    zoom-us # video conferencing
  ];

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
