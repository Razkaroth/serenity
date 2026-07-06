{
  inputs,
  hostName,
  homeModule,
  extraOverlays ? [ ],
  extraGroups ? [ ],
  userConfig ? { },
  hydenixConfig ? { },
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.hydenix.overlays.default
      inputs.nixos-rocksmith.overlays.default
    ] ++ extraOverlays;

    userPkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
  pkgs-edge = import inputs.nixpkgs-edge {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs-locked = import inputs.nixpkgs-locked {
    inherit system;
    config.allowUnfree = true;
  };
in
{ lib, ... }:
let
  baseGroups = [
    "wheel"
    "networkmanager"
    "video"
    "docker"
    "gamemode"
    "media"
    "libvirtd"
  ];
in
{
  nixpkgs.pkgs = pkgs;

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hermes-agent.nixosModules.default
    inputs.hydenix.nixosModules.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs pkgs-edge pkgs-locked;
    };

    users."raz" = { ... }: {
      imports = [
        inputs.hydenix.homeModules.default
        homeModule
      ];
    };
  };

  hydenix = lib.recursiveUpdate {
    enable = true;
    hostname = hostName;
    timezone = "America/Mexico_City";
    locale = "en_US.UTF-8";

    boot = {
      enable = true;
      useSystemdBoot = false;
      grubExtraConfig = "";
      kernelPackages = pkgs.linuxPackages_zen;
    };
  } hydenixConfig;

  users.users.raz = lib.recursiveUpdate {
    isNormalUser = true;
    initialPassword = "hydenix";
    extraGroups = baseGroups ++ extraGroups;
    shell = pkgs.zsh;
  } userConfig;
}
