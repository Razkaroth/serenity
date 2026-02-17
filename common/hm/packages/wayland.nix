{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [
    wlsunset
    kde-gruvbox
  ];
  edgePkgs = with pkgs-edge; [
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
