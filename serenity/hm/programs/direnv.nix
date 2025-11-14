{ config, lib, pkgs, ... }:
{
  # ...other config, other config...

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
