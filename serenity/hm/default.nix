{ pkgs, pkgs-edge, ... }:

{
  imports = [
    ../../common/hm
    ./confs
  ];

  # home-manager options go here
  home.packages = [
    pkgs-edge.gamescope # Removed from common/gaming due to conflict with play-nix on Ascension
    # pkgs.vscode - hydenix's vscode version
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];

  # hydenix home-manager options go here
  hydenix.hm = {
    #! Important options
    enable = false;
    comma.enable = true; # useful nix tool to run software without installing it first
    dolphin.enable = true; # file manager
    editors = {
      enable = false; # enable editors module
      # neovim.enable = true; # enable neovim module
      vscode = {
        enable = false; # enable vscode module
        wallbash = true; # enable wallbash extension for vscode
      };
      # vim.enable = true; # enable vim module
      default = "nvim"; # default text editor
    };
    fastfetch.enable = false; # fastfetch configuration
    
    # Git configured via common module
    git = {
      enable = false; 
      name = "razkaroth"; 
      email = "rocker.ikaros@gmail.com"; 
    };
    
    hyde.enable = false; # enable hyde module
    hyprland.enable = false; # enable hyprland module
    lockscreen = {
      enable = false; # enable lockscreen module
      hyprlock = true; # enable hyprlock lockscreen
      swaylock = false; # enable swaylock lockscreen
    };
    notifications.enable = true; # enable notifications module
    qt.enable = true; # enable qt module
    rofi.enable = true; # enable rofi module
    screenshots = {
      enable = true; # enable screenshots module
      grim.enable = true; # enable grim screenshot tool
      slurp.enable = true; # enable slurp region selection tool
    };
    
    # Shell configured via common module
    shell = {
      enable = false; 
      zsh ={
        enable = false; 
        configText = "";
    }; 
      bash.enable = false; 
      fish.enable = false; 
      pokego.enable = false; 
      starship.enable = false;
    };
      social.enable = false;
      # social = {
      #   enable = true; # enable social module
      #   # discord.enable = true; # enable discord module
      #   # webcord.enable = true; # enable webcord module
      #   vesktop.enable = true; # enable vesktop module
      # };
      spotify.enable = true; # enable spotify module
      swww.enable = true; # enable swww wallpaper daemon
      terminals = {
        enable = true; # enable terminals module
      kitty.enable = true; # enable kitty terminal
      kitty.configText = ''
        allow_remote_control yes
        ''; # kitty config text
    };
    
    theme = {
      enable = true; # enable theme module
      active = "Cosmic Blue";
      themes = [
        "Cosmic Blue"
      ]; 
    };
    waybar.enable = true; # enable waybar module
    wlogout.enable = true; # enable wlogout module
    xdg.enable = true; # enable xdg module
  };
}
