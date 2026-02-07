{ lib, ... }:
{
  imports = [
    ../../../common/hm/confs/default.nix
  ];

  # Host specific Hyprland config
  home.file.".config/hypr/hyprland/monitors.conf" = lib.mkForce {
    source = ./caelestia/hypr/hyprland/monitors.conf;
    mutable = true;
    force = true;
  };
   home.file.".config/hypr/hyprland/input.conf" = lib.mkForce {
    source = ./caelestia/hypr/hyprland/input.conf;
    mutable = true;
    force = true;
  };
}
