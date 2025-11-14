# Project Overview

This repository contains the NixOS configurations for two systems: "serenity" and "ascence". Both systems are based on the Hydenix template, but with some key differences.

*   **serenity**: This system seems to be a desktop environment with a more "out-of-the-box" Hydenix configuration. It includes a wide range of desktop applications and themes.
*   **ascence**: This system is a desktop environment that is in the process of transitioning from Hydenix to a more customized setup based on [caelestia](https://github.com/caelestia-dots/caelestia). While it still uses some Hydenix modules for system-level configuration, the desktop environment is being replaced with caelestia.

The project uses Nix Flakes to manage dependencies and build the system configurations.

## Building and Running

To build and apply the configuration for a specific system, you can use the following commands:

*   **serenity**: `sudo nixos-rebuild switch --flake .#serenity`
*   **ascence**: `sudo nixos-rebuild switch --flake .#ascence`

## Development Conventions

*   **NixOS Modules**: The configurations are organized into NixOS modules, which are imported into the main `configuration.nix` files for each system.
*   **Home-Manager**: Home-Manager is used to manage user-specific configurations and packages.
*   **Hydenix**: The Hydenix framework is used to provide a set of pre-configured modules and themes.
*   **caelestia**: The `ascence` system is transitioning to use `caelestia` for its desktop environment.
*   **Secrets**: There is no clear secrets management strategy in this repository. It is recommended to use a tool like `agenix` or `sops-nix` to manage secrets.