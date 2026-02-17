{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [
    # --------------------------------------------------- // Music
    cava # audio visualizer
    # spicetify-cli # cli to customize spotify client
    # spotify # spotify client
    (mpv.override { scripts = [ mpvScripts.mpris ]; })
    # Audio
    helvum
    easyeffects
    qjackctl
    rtaudio
    # --------------------------------------------------- // Books
    calibre
  ];
  edgePkgs = with pkgs-edge; [
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
