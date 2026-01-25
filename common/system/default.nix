{ ... }:
{
  imports = [
    ./tailscale.nix
    ./actual.nix
    ./via.nix
    ./vm.nix
    ./docker.nix
    # nixarr.nix is common but not imported by default
  ];
}
