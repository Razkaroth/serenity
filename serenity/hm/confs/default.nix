{ ... }:
{
  imports = [
    ../../../common/hm/confs/default.nix
  ];

  # Host specific Hyprland config
  home.file.".config/hypr/hyprland/monitors.conf".source = ./caelestia/hypr/hyprland/monitors.conf;
  home.file.".config/hypr/hyprland/input.conf".source = ./caelestia/hypr/hyprland/input.conf;
}
