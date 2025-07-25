{
  description = "template for hydenix";

  inputs = {
    # User's nixpkgs - for user packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hydenix and its nixpkgs - kept separate to avoid conflicts
    hydenix = {
      # Available inputs:
      # Main: github:richen604/hydenix
      # Dev: github:richen604/hydenix/dev
      # Commit: github:richen604/hydenix/<commit-hash>
      # Version: github:richen604/hydenix/v1.0.0
      url = "github:richen604/hydenix";
    };

   nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    { 
      nixos-hardware,
      nixarr,
      zen-browser,
      ...
    }@inputs:
    let
      HOSTNAME = "serenity";

      hydenixConfig = inputs.hydenix.inputs.hydenix-nixpkgs.lib.nixosSystem {
        inherit (inputs.hydenix.lib) system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
        inputs.nixarr.nixosModules.default

          # inputs.nixos-hardware.nixosModules.omen."15-en0010ca"
          ./configuration.nix
        ];
      };

    in
    {
      nixosConfigurations.nixos = hydenixConfig;
      nixosConfigurations.${HOSTNAME} = hydenixConfig;
    };
}
