{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    ./modules/gh-repos.nix
    ./programs
    ./services
    ./packages
    ./caelestia.nix
  ];
}
