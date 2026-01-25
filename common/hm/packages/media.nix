{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [];
  edgePkgs = with pkgs-edge; [
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
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
