{
  description = "template for hydenix";

  inputs = {
    # User's nixpkgs - locked to working revision for stability (especially NVIDIA drivers)
    nixpkgs-locked.url = "github:nixos/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
    # nixpkgs.url = "github:nixos/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # Not needed, but useful

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-rocksmith = {
      url = "github:re1n0/nixos-rocksmith";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #playwright.url = "github:pietdevries94/playwright-web-flake";
    
  spacetimedb = {
      url = "github:clockworklabs/SpacetimeDB/31fd1c8c3346dfec38dfcc2e89c2ecf457cf26ff";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anifetch = {
      url = "github:Notenlish/anifetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      spacetimedb,
    #playwright,
      nixpkgs-edge,
      nixpkgs-locked,
      ...
    }@inputs:
    let
      SERENITY = "serenity";
      ASCENSION = "ascension";

      system = "x86_64-linux";
      hydenixSerenityConfig = inputs.nixpkgs.lib.nixosSystem {
         specialArgs = {
           inherit inputs;
         };
        modules = [
        { nixpkgs.hostPlatform = system; }
        inputs.nixarr.nixosModules.default
        chaotic.nixosModules.default
          ./serenity/configuration.nix
        ];
      };
      hydenixAscenceConfig = inputs.nixpkgs.lib.nixosSystem {
         specialArgs = {
           inherit inputs;
         };
        modules = [
          { nixpkgs.hostPlatform = system; }
          # inputs.nixos-hardware.nixosModules.omen."15-en0010ca"
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
