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
    # nixarr.nix is common but not imported by default
  ];
}
