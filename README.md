# NixOS Multi-Host Configuration

Multi-host NixOS configuration with Hydenix desktop environment.

## Hosts

### serenity
- **Type**: Primary desktop system
- **Hardware**: Generic hardware configuration
- **Theme**: Standard Hydenix configuration
- **Config Path**: `./serenity/`

### ascence
- **Type**: Laptop (HP Omen 14-fb0798ng)
- **Hardware**: HP Omen specific optimizations via nixos-hardware
- **Theme**: Caelestia shell integration (caelestia-dots/shell)
- **Config Path**: `./ascence/`
- **Special Features**: 
  - Extensive Caelestia theming (VSCode, Firefox/Zen, Zed, Spicetify, Hyprland)
  - Custom TypeScript extensions for browser/editor integration
  - Rich configuration files in `./ascence/hm/confs/caelestia/`

## Quick Start

```bash
# Build serenity (standard Hydenix)
sudo nixos-rebuild switch --flake ./#serenity

# Build ascence (Caelestia theme)
sudo nixos-rebuild switch --flake ./#ascence
```

### Initial Setup

1. Edit host-specific `configuration.nix` (sections marked with `#! EDIT`)
2. Generate hardware config: `sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix`
3. Initialize git: `git init && git add .` (required for flakes)
4. Build your host using commands above
5. **IMPORTANT**: Change default password with `passwd`

NOTE: Run `hyde-shell reload` after first boot to generate theme cache.

All module options are documented [here](https://github.com/richen604/hydenix/blob/main/docs/faq.md#What-are-the-module-options).

Other than that, this is your own nixos configuration. You can do whatever you want with it.
Add modules, change packages, add flakes, even disable hydenix and try something else!

If you have any questions, please refer to the [FAQ](https://github.com/richen604/hydenix/blob/main/docs/faq.md) or [Hydenix README](https://github.com/richen604/hydenix/blob/main/README.md).

You can also reach out to me on the [Hyde Discord](https://discord.gg/AYbJ9MJez7) or [Hydenix GitHub Discussions](https://github.com/richen604/hydenix/discussions).

## Upgrading

Hydenix can be upgraded, downgraded, or version locked easy.
in your template flake folder, update hydenix to main using

```bash
nix flake update hydenix
```

or define a specific version in your `flake.nix` template

```nix
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hydenix = {
      # Available inputs:
      # Main: github:richen604/hydenix
      # Dev: github:richen604/hydenix/dev 
      # Commit: github:richen604/hydenix/<commit-hash>
      # Version: github:richen604/hydenix/v1.0.0
      url = "github:richen604/hydenix";
    };
  };
```

run `nix flake update hydenix` again to apply the changes