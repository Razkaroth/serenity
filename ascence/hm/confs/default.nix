{ pkgs, lib, inputs, ... }:
let
  caelestia-dots = inputs.caelestia-dots;
in
{
  home.file = {
    ".config/caelestia/hypr-user.conf" = pkgs.lib.mkForce {
    source = ./hypr.conf;
      force = true;
      mutable = true;
    };

    ".config/hypr" = {
      source = "${caelestia-dots}/hypr";
      force = true;
      mutable = true;
      recursive = true;
    };

    ".config/starship.toml" = {
      source = "${caelestia-dots}/starship.toml";
      force = true;
      mutable = true;
    };

    ".config/fish" = {
      source = "${caelestia-dots}/fish";
      force = true;
      recursive = true;
    };

    ".config/foot" = {
      source = "${caelestia-dots}/foot";
      force = true;
      recursive = true;
    };

    ".config/fastfetch" = {
      source = "${caelestia-dots}/fastfetch";
      force = true;
      recursive = true;
    };

    ".config/zen" = {
      source = "${caelestia-dots}/zen";
      force = true;
      mutable = true;
      recursive = true;
    };

    ".config/btop" = {
      source = "${caelestia-dots}/btop";
      force = true;
      mutable = true;
      recursive = true;
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
