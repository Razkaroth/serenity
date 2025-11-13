{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "CaskaydiaCove NF";
      size = 12;
    };
    settings = {
      term = "xterm-256color";
      scrollback_lines = 3000;
      background_opacity = "0.8";
      window_padding_width = 10; # Add padding
      font_features = "CaskaydiaCoveNerdFont-Regular +liga +calt"; # Enable ligatures
    };
  };
}
