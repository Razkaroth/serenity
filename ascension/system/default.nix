{ pkgs,... }:

{
  imports = [
    # ./example.nix - add your modules here
    # ./kanata
    # ./nixarr.nix # - only on serenity
    ./docker.nix
    ./tailscale.nix
    ./actual.nix
    ./via.nix
    ./vm.nix
    ./hyprland.nix
    ./hamachi.nix
    ./audio.nix
  ];

  environment.systemPackages = [
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
