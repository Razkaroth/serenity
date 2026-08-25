{ inputs, lib, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./settings.nix
  ];

  options.persona.layers.caelestia = {
    extraActions = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Portable or host-specific launcher actions appended to Caelestia.";
    };

    playerAliases = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Media player aliases appended to Caelestia.";
    };

    defaultPlayer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional Caelestia default media player.";
    };

    gpuType = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional host GPU type for Caelestia.";
    };
  };

  config = {
    home.file = {
      ".config/zen" = {
        source = ../../../common/hm/confs/caelestia/zen;
        recursive = true;
      };

      ".config/btop" = {
        source = ../../../common/hm/confs/caelestia/btop;
        recursive = true;
      };

      ".config/fastfetch" = {
        source = ../../../common/hm/confs/caelestia/fastfetch;
        recursive = true;
      };
    };
  };
}
