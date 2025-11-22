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
  
  # Edge packages for latest unstable - use for selective updates
  # Example usage: pkgs-edge.firefox, pkgs-edge.vscode
  pkgs-edge = import inputs.nixpkgs-edge {
    inherit system;
    config.allowUnfree = true;
  };
in
{

  # Set pkgs for hydenix globally, any file that imports pkgs will use this
  nixpkgs.pkgs = pkgs;

  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./ascension-hardware.nix
    inputs.hydenix.nixosModules.default
    ./system

    # === GPU-specific configurations ===

    /*
      For drivers, we are leveraging nixos-hardware
      Most common drivers are below, but you can see more options here: https://github.com/NixOS/nixos-hardware
    */
    inputs.hydenix.inputs.nixos-hardware.nixosModules.omen-14-fb0798ng
  ];
  
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      adi1090x-plymouth-themes
    ];
  };
    services.power-profiles-daemon.enable = true;
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "nixbak";
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs pkgs-edge;
    };

    #! EDIT THIS USER (must match users defined below)
    users."raz" =
      { ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ./hm
        ];
      };
  };

  # IMPORTANT: Customize the following values to match your preferences
  hydenix = {
    enable = true; # Enable the Hydenix module

    #! EDIT THESE VALUES
    hostname = "ascension"; # Change to your preferred hostname
    timezone = "America/Mexico_City"; # Change to your timezone
    locale = "en_US.UTF-8"; # Change to your preferred locale

      boot = {
        enable = true; # enable boot module
        useSystemdBoot = false; # disable for GRUB
        grubExtraConfig = ""; # additional GRUB configuration
        kernelPackages = pkgs.linuxPackages_zen; # default zen kernel
      };

      network.enable = true; # enable network module

      gaming.enable = false;
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
      "libvirtd" # For virtualization access
      "gamemode"
      # Add other groups as needed
    ];
    shell = pkgs.zsh; # Change if you prefer a different shell
  };
}
