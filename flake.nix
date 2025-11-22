{
  description = "template for hydenix";

  inputs = {
    # User's nixpkgs - locked to working revision for stability (especially NVIDIA drivers)
    nixpkgs.url = "github:nixos/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
    
    # Edge nixpkgs - latest unstable for selective package updates
    nixpkgs-edge.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hydenix and its nixpkgs - kept separate to avoid conflicts
    hydenix = {
      # Available inputs:
      # Main: github:richen604/hydenix
      # Dev: github:richen604/hydenix/dev
      # Commit: github:richen604/hydenix/<commit-hash>
      # Version: github:richen604/hydenix/v1.0.0
      url = "github:richen604/hydenix";
    };
    caelestia-shell = {
      url = "github:razkaroth/caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # Not needed, but useful

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    play-nix.url = "github:TophC7/play.nix";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    { 
      chaotic,
      nixos-hardware,
      nixarr,
      zen-browser,
      play-nix,
      nixpkgs-edge,
      ...
    }@inputs:
    let
      SERENITY = "serenity";
      ASCENSION = "ascension";

    system = "x86_64-linux";
      hydenixSerenityConfig = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
         specialArgs = {
           inherit inputs;
         };
        modules = [
        inputs.nixarr.nixosModules.default
        chaotic.nixosModules.default
          ./serenity/configuration.nix
        ];
      };
      hydenixAscenceConfig = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
         specialArgs = {
           inherit inputs;
         };
        modules = [

          # inputs.nixos-hardware.nixosModules.omen."15-en0010ca"
          play-nix.nixosModules.play
          ./ascension/configuration.nix
        ];
      };

    in
    {
      nixosConfigurations.nixos = hydenixSerenityConfig;
      nixosConfigurations.${SERENITY} = hydenixSerenityConfig;
      nixosConfigurations.${ASCENSION} = hydenixAscenceConfig;
    };
}
