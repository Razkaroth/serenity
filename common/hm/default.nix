{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./programs
    ./services
    ./packages
    ./modules/gh-repos.nix
    ./caelestia.nix
  ];
}
