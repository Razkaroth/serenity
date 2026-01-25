{ pkgs,... }:

{
  imports = [
    ../../common/system
    ../../common/system/nixarr.nix
  ];

  environment.systemPackages = [
    # pkgs.vscode # - hydenix's vscode version
    # pkgs.neovim
    # pkgs.userPkgs.vscode - your personal nixpkgs version
    pkgs.zip
    pkgs.unzip
    pkgs.nix-output-monitor
    pkgs.vial
  ];
}
