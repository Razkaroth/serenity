{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [];
  edgePkgs = with pkgs-edge; [
    wlsunset
    kde-gruvbox
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
