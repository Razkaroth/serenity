{ pkgs,... }:

{
  imports = [
    ../../common/system
    ./hyprland.nix
    ./audio.nix
    ./gaming.nix
  ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.tree-sitter
    pkgs.zip
    pkgs.unzip
    pkgs.nix-output-monitor
    pkgs.vial
    pkgs.nerd-fonts.caskaydia-cove
    pkgs.nerd-fonts.caskaydia-mono
    pkgs.nerd-fonts.iosevka
    pkgs.nerd-fonts.iosevka-term-slab
    pkgs.nerd-fonts.iosevka-term
  ];
}
