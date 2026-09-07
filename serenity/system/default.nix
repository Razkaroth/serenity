{ pkgs,... }:

{
  imports = [
    ../../common/system
    ./actual-budget.nix
    ./anki-sync.nix
    ./cursor-computer-use.nix
    ./habitica.nix
    ./hermes
    ./lector.nix
    ./nixarr.nix
    ./zero-tier.nix
    ./coolify-vm.nix
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
