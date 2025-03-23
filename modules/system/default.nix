{ pkgs,... }:

{
  imports = [
    # ./example.nix - add your modules here
    ./kanata
    ./nixarr.nix
    ./tailscale.nix
  ];

  environment.systemPackages = [
    # pkgs.vscode # - hydenix's vscode version
    # pkgs.neovim
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];
}
