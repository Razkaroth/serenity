{
  inputs,
  ...
}:
let
  # Package declaration
  # ---------------------

  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.hydenix.overlays.default
    ];

    # Include your own package set to be used eg. pkgs.userPkgs.bash
    userPkgs = inputs.nixpkgs {
      config.allowUnfree = true;
    };
  };
in
{

  # Set pkgs for hydenix globally, any file that imports pkgs will use this
  nixpkgs.pkgs = pkgs;

  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    inputs.hydenix.nixosModules.default
    ./modules/system

    # === GPU-specific configurations ===

    /*
      For drivers, we are leveraging nixos-hardware
      Most common drivers are below, but you can see more options here: https://github.com/NixOS/nixos-hardware
    */

    #! EDIT THIS SECTION
    # For NVIDIA setups
    # inputs.hydenix.inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    # inputs.hydenix.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonmodeset

    # For AMD setups
    # inputs.hydenix.inputs.nixos-hardware.nixosModules.common-gpu-amd

    # === CPU-specific configurations ===
    # For AMD CPUs
    # inputs.hydenix.inputs.nixos-hardware.nixosModules.common-cpu-amd
    # inputs.hydenix.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate

    # For Intel CPUs
    #inputs.hydenix.inputs.nixos-hardware.nixosModules.common-cpu-intel

    # === Other common modules ===
    #inputs.hydenix.inputs.nixos-hardware.nixosModules.common-pc
    #inputs.hydenix.inputs.nixos-hardware.nixosModules.common-pc-ssd

  ];

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "nixbak";
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };

    #! EDIT THIS USER (must match users defined below)
    users."raz" =
      { ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ./modules/hm
        ];
      };
  };

  # IMPORTANT: Customize the following values to match your preferences
  hydenix = {
    enable = true; # Enable the Hydenix module

    #! EDIT THESE VALUES
    hostname = "serenity"; # Change to your preferred hostname
    timezone = "America/Mexico_City"; # Change to your timezone
    locale = "en_US.UTF-8"; # Change to your preferred locale

    /*
      Optionally edit the below values, or leave to use hydenix defaults
      visit ./modules/hm/default.nix for more options

      audio.enable = true; # enable audio module
*/
      boot = {
        enable = true; # enable boot module
        useSystemdBoot = false; # disable for GRUB
        grubExtraConfig = ""; # additional GRUB configuration
        kernelPackages = pkgs.linuxPackages_zen; # default zen kernel
      };
    /*
      hardware.enable = true; # enable hardware module
      network.enable = true; # enable network module
      nix.enable = true; # enable nix module
      sddm = {
        enable = true; # enable sddm module
        theme = pkgs.hydenix.sddm-candy; # or pkgs.hydenix.sddm-corners
      };
      system.enable = true; # enable system module
    */
  };

  #! EDIT THESE VALUES (must match users defined above)
  users.users.raz = {
    isNormalUser = true; # Regular user account
    initialPassword = "hydenix"; # Default password (CHANGE THIS after first login with passwd)
    extraGroups = [
      "wheel" # For sudo access
      "networkmanager" # For network management
      "video" # For display/graphics access
      "docker" # For docker access
      "media" # For media access
      # Add other groups as needed
    ];
    shell = pkgs.zsh; # Change if you prefer a different shell
  };
}
