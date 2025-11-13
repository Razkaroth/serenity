{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "CaskaydiaCove NF:size=12";
        term = "xterm-256color";
      };
      scrollback = {
        lines = 3000;
      };
    };
  };
}
