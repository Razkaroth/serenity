{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [
    # --------------------------------------------------- // Gaming
    gamemode # daemon and library for game optimisations
    mangohud # system performance overlay
    # gamescope # micro-compositor for gaming (managed at system level per host)
    # lutris # gaming platform
    sidequest # sideload apps and games to Oculus Quest
    android-tools # android platform tools
    protonup-ng # game launcher
  ];
  edgePkgs = with pkgs-edge; [
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
