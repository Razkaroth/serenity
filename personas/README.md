# Personas

Personas are portable Home Manager compositions. They select reusable layers
and ordinary Home Manager modules, but never own host hardware, privileged
services, account paths, GPU drivers, or operating-system configuration.

Host and standalone-output adapters provide username, home directory, state
version, platform settings, and any host-specific Home Manager additions.

## Layers

Layers live in `personas/layers/`. A layer is a cohesive subsystem with several
configuration surfaces, dependencies, services, or assets. Large single apps
and package categories remain ordinary modules.

Available layers:

- `caelestia`: Caelestia shell, settings, and active themed application assets.
- `hyprland`: Hyprland Home Manager configuration and writable config tree.
- `mpd`: user MPD service, rmpc, and MPRIS integration.
- `winapps`: WinApps and FreeRDP user packages.

Personas activate layers through explicit imports. Persona or host modules own
integration between layers and override layer defaults through normal Nix
module merging.

```nix
{
  imports = [
    ./layers/caelestia
    ./layers/hyprland
  ];

  persona.layers.caelestia.gpuType = "NVIDIA";
}
```

Flake consumers can also import exported modules from
`homeManagerModules.personas` and `homeManagerModules.layers`.

## Nomad

`nomad.nix` is a development identity for preconfigured Linux desktops. It
provides shell tools, development toolchains, editors, Pass, and Herdr without
owning a desktop shell, compositor, terminal emulator, keyring, or user daemon
layer.

Activate standalone Home Manager with:

```sh
home-manager switch --flake .#raz@nomad
```
