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
    enable = true;
    comma.enable = true; # useful nix tool to run software without installing it first
    dolphin.enable = true; # file manager
    editors = {
      enable = true; # enable editors module
      # neovim.enable = true; # enable neovim module
      vscode = {
        enable = false; # enable vscode module
        wallbash = true; # enable wallbash extension for vscode
      };
      # vim.enable = true; # enable vim module
      default = "nvim"; # default text editor
    };
    fastfetch.enable = true; # fastfetch configuration
    
    # Git configured via common module
    git = {
      enable = false; 
      name = "razkaroth"; 
      email = "rocker.ikaros@gmail.com"; 
    };
    
    hyde.enable = true; # enable hyde module
    hyprland.enable = true; # enable hyprland module
    lockscreen = {
      enable = true; # enable lockscreen module
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
    
    spotify.enable = true; # enable spotify module
    swww.enable = true; # enable swww wallpaper daemon
    
    # Terminals configured via common module
    terminals = {
      enable = false; 
      kitty.enable = false; 
    };
    
    theme = {
      enable = true; # enable theme module
      active = "Monokai";
      themes = [
        "AncientAliens"
        "Graphite Mono"
        "Catppuccin Mocha"
        "Cat Latte"
        "Rosé Pine"
        "Vanta Black"
        "Cosmic Blue"
        "Scarlet Night"
        "Ever Blushing"
        "Gruvbox Retro"
        "Monokai"
        "Moonlight"
        "Tokyo Night"
        "Sci-fi"
        "Solarized Dark"
        "Green Lush"
        "Grukai"
        "Obisidian-Purple"
        "Decay Green"
        "AbyssGreen"
        "Amethyst-Aura"
        "Peace Of Mind"
        "Synth Wave"
        "Tundra"
      ]; 
    };
    waybar.enable = true; # enable waybar module
    wlogout.enable = true; # enable wlogout module
    xdg.enable = true; # enable xdg module
  };
}
