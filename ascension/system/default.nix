{ pkgs,... }:

{
  imports = [
    ../../common/system
    ./kanata # - only targets laptop keyboard
    ./hyprland.nix
    ./hamachi.nix
    ./audio.nix
    ./gaming.nix
    ./kb_layouts
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
