{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      source = ~/.config/hypr/main.conf
    '';

    package = lib.mkDefault pkgs.hyprland;
    portalPackage = lib.mkDefault pkgs.xdg-desktop-portal-hyprland;
    systemd.variables = [ "--all" ];
  };

  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  home.file.".config/hypr" = {
    source = ../../../common/hm/confs/caelestia/hypr;
    mutable = true;
    force = true;
    recursive = true;
  };
}
