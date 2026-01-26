{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./programs
    ./packages
    ./modules/gh-repos.nix
    ./caelestia.nix
  ];
}
