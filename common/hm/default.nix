{ inputs, ... }:
{
  imports = [
    ./modules/gh-repos.nix
    ./programs
    ./services
    ./packages
    ../../personas/layers/caelestia
    ../../personas/layers/hyprland
    ./integrations/hyprland-nixos.nix
    ./integrations/caelestia-hyprland.nix
    ./integrations/caelestia-mpd.nix
    ./integrations/caelestia-zsh.nix
    ./integrations/zsh-desktop.nix
  ];
}
