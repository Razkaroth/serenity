# Using Edge Packages

Your configuration now supports two nixpkgs channels:
- **nixpkgs**: Locked to revision `9da7f1cf` (Jan 16, 2025) for stability, especially NVIDIA drivers
- **nixpkgs-edge**: Always latest unstable for selective package updates

## Using Edge Packages

### System-level packages
In any system configuration file (e.g., `ascension/system/default.nix`):

```nix
{ pkgs, pkgs-edge, ... }:
{
  environment.systemPackages = [
    pkgs.neovim           # Uses stable locked version
    pkgs-edge.firefox     # Uses latest unstable
    pkgs-edge.vscode      # Uses latest unstable
  ];
}
```

### Home-Manager packages
In your home configuration files (e.g., `ascension/hm/packages/applications.nix`):

```nix
{ pkgs, pkgs-edge, ... }:
{
  home.packages = [
    pkgs.htop             # Uses stable locked version
    pkgs-edge.discord     # Uses latest unstable
  ];
}
```

## Updating Channels

### Update only edge packages (keep base stable):
```bash
nix flake update nixpkgs-edge
```

### Update base nixpkgs to new working revision:
```bash
# Test a specific commit first
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/<commit-hash>

# Once verified working, edit flake.nix to lock permanently:
nixpkgs.url = "github:nixos/nixpkgs/<commit-hash>";
```

### Update both:
```bash
nix flake update
```

## Checking Package Versions

```bash
# Check version in stable
nix eval .#nixosConfigurations.ascension.pkgs.firefox.version

# Check version in edge
nix eval .#nixosConfigurations.ascension.config.home-manager.users.raz.pkgs-edge.firefox.version
```
