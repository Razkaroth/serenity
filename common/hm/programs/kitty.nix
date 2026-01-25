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


      # Allow remote control for theme updates
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-raz";
      
      # These settings help with tmux transparency
      background_blur = 0;
      
      # Dynamic background opacity to work with tmux
      dynamic_background_opacity = "yes";
    };
    extraConfig = ''
    '';
  };

 home.sessionVariables = {
    KITTY_LISTEN_ON = "unix:/tmp/kitty-raz";
  };
}
