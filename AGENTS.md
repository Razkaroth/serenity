# Agent Guidelines for NixOS Configuration

## Build Commands
- **Rebuild ascension (laptop)**: `./rebuild-ascension.sh` or `sudo nixos-rebuild switch --flake ./#ascension`
- **Rebuild serenity (desktop)**: `./rebuild.sh` or `sudo nixos-rebuild switch --flake ./#serenity`
- **Update edge packages only**: `nix flake update nixpkgs-edge` (keeps stable base locked)
- **Update all inputs**: `nix flake update` or `nix flake update <input-name>`
- **Check flake**: `nix flake check`
- **Build without switching**: `sudo nixos-rebuild build --flake ./#<hostname>`

## Structure
- **Hosts**: `ascension/` (laptop with Caelestia theme), `serenity/` (desktop server)
- **Host config**: `<host>/configuration.nix` - main host configuration
- **System modules**: `<host>/system/` - system-level NixOS modules
- **Home-Manager**: `<host>/hm/` - user configuration (packages, programs, dotfiles)
- **Common**: `common/` - shared configuration (currently empty)

## Code Style
- **Imports**: Place imports at top in attribute set pattern: `{ inputs, pkgs, ... }:`
- **Indentation**: 2 spaces, no tabs
- **Let-in blocks**: Use for local variables, especially pkgs declarations
- **Comments**: Use `#` for single-line, `/* */` for multi-line, `#!` prefix for required edits
- **Attribute sets**: Use multiline format with proper indentation
- **Lists**: Place each item on new line with proper indentation for readability
- **Naming**: Use camelCase for variables, kebab-case for hostnames/module names

## Conventions
- **AllowUnfree**: Already enabled in pkgs configuration
- **Overlays**: Hydenix overlay applied in configuration.nix
- **Package references**: 
  - `pkgs.package-name` - stable locked nixpkgs (locked for NVIDIA driver compatibility)
  - `pkgs-edge.package-name` - latest unstable nixpkgs (for selective updates)
  - `pkgs.userPkgs.package-name` - alternative user nixpkgs
- **Module options**: Always check if module.enable exists before setting options
- **User config**: User "raz" defined in both hosts, shell is zsh
- **Hardware**: Use nixos-hardware modules for device-specific optimizations
- **Dual nixpkgs**: See EDGE-PACKAGES.md for using stable vs edge packages

## Best Practices
- **Flake changes**: Run `git add .` after modifying files (flakes require git tracking)
- **Backup handling**: Rebuild scripts auto-remove `*.nixbak` files unless `-s` flag used
- **specialArgs**: Use `inputs` for passing flake inputs to modules
- **Module imports**: Prefer directory imports (./system) over explicit file lists
- **Testing changes**: Use `nixos-rebuild build` first to catch errors before switching
