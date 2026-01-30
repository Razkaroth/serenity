{ ... }:
{
  imports = [
    ./tailscale.nix
    ./actual.nix
    ./via.nix
    ./vm.nix
    ./docker.nix
    ./kb_layouts
    ./kanata
    ./hamachi.nix
    # nixarr.nix is common but not imported by default
  ];
}
