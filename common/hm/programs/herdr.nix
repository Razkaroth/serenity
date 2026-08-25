{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];

  home.file.".config/herdr/config.toml" = {
    source = ../confs/herdr/config.toml;
    mutable = lib.mkDefault true;
    force = true;
  };
}
