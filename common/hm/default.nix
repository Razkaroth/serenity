{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./programs
    ./packages
    ./caelestia.nix
  ];
}
