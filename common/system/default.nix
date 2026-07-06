{ ... }:
{
  imports = [
    ./tailscale.nix
    ./mpd.nix
    ./actual.nix
    ./audio.nix
    ./via.nix
    ./vm.nix
    ./docker.nix
    ./gaming.nix
    ./hermes.nix
    ./kb_layouts
    ./kanata
    ./hamachi.nix
  ];
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
