{ inputs, config, pkgs, ... }:

{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./packages
    ./programs
    ./confs
    ./caelestia.nix
    ./hydenix.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland
    settings = {
      "$mod" = "Super";
      bind = [
       "$mod, T, exec, $TERMINAL"
    ];
    };

    # use os module packages
    package = null;
    portalPackage = null;
    systemd.variables = [ "--all" ];
  };

  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"; 

  # home-manager options go here
  home.packages = [
    # pkgs.vscode - hydenix's vscode version
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Gruvbox-Retro";
    package = pkgs.capitaine-cursors-themed;
    size = 30;
  };
  
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
    VISUAL = "nvim";
    # XDG_CONFIG_HOME = "$USER_HOME/.config";
    # XDG_DATA_HOME = "$USER_HOME/.local/share";
    # XDG_CACHE_HOME = "$USER_HOME/.cache";
  };


}
