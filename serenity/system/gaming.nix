{ pkgs, ... }:
let
  gs-sdr-serenity-internal = pkgs.writeShellScriptBin "gs-sdr-serenity-internal" ''
    exec gamescope \
      -w 1920 -h 1080 \
      -W 1920 -H 1080 \
      -r 60 \
      --mangoapp \
      -f \
      -- "$@"
  '';

  gs-sdr-serenity-external = pkgs.writeShellScriptBin "gs-sdr-serenity-external" ''
    exec gamescope \
      -w 2560 -h 1080 \
      -W 2560 -H 1080 \
      -r 60 \
      --mangoapp \
      -f \
      -- "$@"
  '';

in
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    lutris
    gamemode
    vulkan-tools
    nvtopPackages.full
    gs-sdr-serenity-internal
    gs-sdr-serenity-external
  ];
}
