{ pkgs, pkgs-edge, ... }:
{
  home.packages = with pkgs; [
    lens
    lmstudio
    anydesk
    postman
    insomnia
    sqlitebrowser
    mongodb-compass
    pkgs-edge.jetbrains-toolbox
    pkgs-edge.code-cursor
  ];
}
