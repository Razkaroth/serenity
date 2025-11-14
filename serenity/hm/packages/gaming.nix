{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --------------------------------------------------- // Gaming
    gamemode # daemon and library for game optimisations
    mangohud # system performance overlay
    gamescope # micro-compositor for gaming
    lutris # gaming platform
    sidequest # sideload apps and games to Oculus Quest
    android-tools # android platform tools
    protonup-ng # game launcher
  ];

}
