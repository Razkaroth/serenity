{ pkgs, lib, inputs, ... }:
{
  home.file = {
    ".config/hypr" = {
      source = ./caelestia/hypr;
      # recursive = true; # Recursive is needed to allow host-specific overrides
      recursive = true;
    };

    ".config/zen" = {
      source = ./caelestia/zen;
      recursive = true;
    };

    ".config/btop" = {
      source = ./caelestia/btop;
      recursive = true;
    };
    
    # Link other common configs if needed
    ".config/fastfetch" = {
        source = ./caelestia/fastfetch;
        recursive = true;
    };
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
  };
}
