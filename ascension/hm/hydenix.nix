{ pkgs, config, lib, modulesPath, ... }:
{

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
    git = {
      enable = false; # enable git module
      name = "razkaroth"; # git user name eg "John Doe"
      email = "rocker.ikaros@gmail.com"; # git user email eg "john.doe@example.com"
     };
    hyde.enable = false; # enable hyde module
    hyprland.enable = false; # enable hyprland module
    lockscreen = {
      enable = false; # enable lockscreen module
      hyprlock = false; # enable hyprlock lockscreen
      swaylock = false; # enable swaylock lockscreen
    };
    screenshots = {
      enable = true; # enable screenshots module
      grim.enable = true; # enable grim screenshot tool
      slurp.enable = true; # enable slurp region selection tool
    };
    spotify.enable = true; # enable spotify module
  };
}
