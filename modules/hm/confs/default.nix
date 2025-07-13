{ pkgs, lib, ...}:{
  home.file = {
    ".config/hypr/userprefs.conf" = pkgs.lib.mkForce {
    source = ./hypr.conf;
      force = true;
      mutable = true;
    };
  };

  home.file = {
    ".config/hypr/scripts/rofiBeats.sh" = {
      source = ./rofiBeats.sh;
      force = true;
      mutable = true;
    };
  };
  home.activation = {
    rofiBeats = lib.hm.dag.entryAfter [ "setTheme" ] ''
    $DRY_RUN_CMD chmod u+rxw  $HOME/.config/hypr/scripts/rofiBeats.sh
    # gsettings set org.gnome.desktop.interface cursor-theme 'Gruvbox-Retro'
    # gsettings set org.gnome.desktop.interface cursor-size 30
    # hyprctl setcursor Gruvbox-Retro 30
    '';
  };

    home.sessionVariables = {
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
      XCURSOR_SIZE = "24";
      # Gaming
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        "\${HOME}/.steam/root/compatibilitytools.d";
      STEAMLIBRARY = "\${HOME}/.steam/steam";
      PROTON_EXPERIMENTAL =
        "\${HOME}/.local/share/Steam/steamapps/common/Proton - Experimental";
      PROTON_GE = "\${STEAM_EXTRA_COMPAT_TOOLS_PATHS}/Proton-GE";
      PROTON = "\${PROTON_EXPERIMENTAL}";
      # Other variables
      # NIX_BUILD_SHELL = "fish";
    };
  

}
