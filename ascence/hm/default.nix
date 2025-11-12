{ ... }:

{
  imports = [
    ./packages
    ./programs
    ./confs
    ./caelestia.nix
    ./hydenix.nix
  ];

  # home-manager options go here
  home.packages = [
    # pkgs.vscode - hydenix's vscode version
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];

}
