{ pkgs, lib, inputs, ... }:
{
  home.file = {
    ".config/hypr" = {
      source = ./caelestia/hypr;
      force = true;
      mutable = true;
      recursive = true;
    };

    # ".config/fastfetch" = {
    #   source = ./caelestia/fastfetch;
    #   force = true;
    #   recursive = true;
    # };

    ".config/zen" = {
      source = ./caelestia/zen;
      force = true;
      mutable = true;
      recursive = true;
    };

    ".config/btop" = {
      source = ./caelestia/btop;
      force = true;
      mutable = true;
      recursive = true;
    };
  };
  home.activation = {
    # rofiBeats = lib.hm.dag.entryAfter [ "setTheme" ] ''
    # $DRY_RUN_CMD chmod u+rxw  $HOME/.config/hypr/scripts/rofiBeats.sh
    # # gsettings set org.gnome.desktop.interface cursor-theme 'Gruvbox-Retro'
    # # gsettings set org.gnome.desktop.interface cursor-size 30
    # # hyprctl setcursor Gruvbox-Retro 30
    # '';
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
