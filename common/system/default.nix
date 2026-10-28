{ ... }:
{
  imports = [
    ./tailscale.nix
    ./mpd.nix
    ./audio.nix
    ./bluetooth.nix
    ./via.nix
    ./vm.nix
    ./docker.nix
    ./gaming.nix
    ./kb_layouts
    ./kanata
    ./hamachi.nix
  ];
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
