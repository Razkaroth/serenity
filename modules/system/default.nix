{ pkgs,... }:

{
  imports = [
    # ./example.nix - add your modules here
    ./kanata
    ./nixarr.nix
    ./docker.nix
    ./tailscale.nix
    ./actual.nix
  ];

  environment.systemPackages = [
    # pkgs.vscode # - hydenix's vscode version
    # pkgs.neovim
    # pkgs.userPkgs.vscode - your personal nixpkgs version
    pkgs.zip
    pkgs.unzip
    pkgs.nix-output-monitor
  ];
}
