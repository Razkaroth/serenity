# Agent Guidelines for NixOS Multi-Host Configuration

## Hosts Overview
- **serenity**: Standard Hydenix desktop (generic hardware)
- **ascence**: HP Omen laptop with Caelestia shell theme integration

## Build Commands
- **Serenity rebuild**: `sudo nixos-rebuild switch --flake ./#serenity`
- **Ascence rebuild**: `sudo nixos-rebuild switch --flake ./#ascence`
- **Test without switching**: `sudo nixos-rebuild test --flake ./#<host>`
- **Update flake inputs**: `nix flake update` or `nix flake update <input-name>`
- **Check flake**: `nix flake check`

## Code Style
- **Language**: Nix (declarative), Fish shell for scripts, TypeScript for Caelestia extensions
- **Formatting**: 2-space indentation, no tabs
- **Imports**: Use relative paths (`./module`), group system/home-manager imports separately
- **Naming**: camelCase for Nix variables, kebab-case for hostnames/filenames
- **Comments**: Mark user-editable sections with `#! EDIT`, use `/* */` for multi-line docs
- **Structure**: Separate system (`./system/`) and home-manager (`./hm/`) per host
- **Paths**: Absolute paths in Nix expressions, relative in imports
- **Overlays**: Define in configuration.nix, apply via nixpkgs.overlays

## Host-Specific Notes
- **Ascence only**: Caelestia configs in `./ascence/hm/confs/caelestia/` (browser extensions, themes, etc.)
- **Ascence only**: Uses `caelestia-shell` flake input, configured in `./ascence/hm/caelestia.nix`
- **Serenity**: Minimal config structure, standard Hydenix theming

## Error Handling
- Test changes with `nixos-rebuild test` before `switch`
- Git commit changes before rebuilding (flakes require git tracking)
- Clean backup files: `find ~/ -name "*.nixbak" -type f -delete`
