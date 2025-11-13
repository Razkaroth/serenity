{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "CaskaydiaCove NF:size=12";
        term = "xterm-256color";
        font-feature-settings = "liga,calt"; # Enable ligatures
      };
      scrollback = {
        lines = 3000;
      };
    };
  };
}
