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
    beads = {
      url = "github:gastownhall/beads";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bead-me-up-scotty = {
      url = "github:Razkaroth/bead-me-up-scotty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

      nomadPkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      nomadPkgsEdge = import inputs.nixpkgs-edge {
        inherit system;
        config.allowUnfree = true;
      };
      nomadPkgsLocked = import inputs.nixpkgs-locked {
        inherit system;
        config.allowUnfree = true;
      };
      nomadConfig = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nomadPkgs;
        extraSpecialArgs = {
          inherit inputs;
          pkgs-edge = nomadPkgsEdge;
          pkgs-locked = nomadPkgsLocked;
        };
        modules = [
          ./personas/nomad.nix
          {
            home = {
              username = "raz";
              homeDirectory = "/home/raz";
              stateVersion = "26.05";
            };
            targets.genericLinux.enable = true;
          }
        ];
      };
      mkHomeCheck =
        modules:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = nomadPkgs;
          extraSpecialArgs = {
            inherit inputs;
            pkgs-edge = nomadPkgsEdge;
            pkgs-locked = nomadPkgsLocked;
          };
          modules = modules ++ [
            {
              home = {
                username = "raz";
                homeDirectory = "/home/raz";
                stateVersion = "26.05";
              };
              targets.genericLinux.enable = true;
            }
          ];
        };
      layerChecks = {
        caelestia = mkHomeCheck [ ./personas/layers/caelestia ];
        hyprland = mkHomeCheck [
          ./common/hm/modules/mutable-files.nix
          ./personas/layers/hyprland
        ];
        mpd = mkHomeCheck [ ./personas/layers/mpd ];
        winapps = mkHomeCheck [ ./personas/layers/winapps ];
      };
      mutableCopy = import ./common/hm/modules/mutable-copy.nix { pkgs = nomadPkgs; };
      invalidMutableConfig = mkHomeCheck [
        ./common/hm/modules/mutable-files.nix
        {
          home.file.".invalid-mutable" = {
            source = nomadPkgs.writeText "invalid-mutable" "invalid";
            force = true;
            mutable = true;
            mutablePersist = true;
          };
        }
      ];
      mutableConflictRejected =
        !(builtins.tryEval (builtins.deepSeq invalidMutableConfig.activationPackage true)).success;
      mutableCopyCheck =
        assert mutableConflictRejected;
        nomadPkgs.runCommand "mutable-copy-check"
          {
            nativeBuildInputs = [ mutableCopy ];
          }
          ''
            mkdir -p source target
            printf baseline > source/existing
            printf stale > target/existing

            hm-mutable-copy reset source target
            test "$(cat target/existing)" = baseline
            test -w target/existing

            printf edited > target/existing
            printf added > source/missing
            hm-mutable-copy merge source target
            test "$(cat target/existing)" = edited
            test "$(cat target/missing)" = added

            rm source/missing
            hm-mutable-copy merge source target
            test "$(cat target/missing)" = added

            touch "$out"
          '';

    in
    {
      nixosConfigurations.nixos = hydenixSerenityConfig;
      nixosConfigurations.${SERENITY} = hydenixSerenityConfig;
      nixosConfigurations.${ASCENSION} = hydenixAscenceConfig;
      homeConfigurations."raz@nomad" = nomadConfig;

      homeManagerModules = {
        personas.nomad = import ./personas/nomad.nix;
        layers = {
          caelestia = import ./personas/layers/caelestia;
          hyprland = import ./personas/layers/hyprland;
          mpd = import ./personas/layers/mpd;
          winapps = import ./personas/layers/winapps;
        };
        mutableFiles = import ./common/hm/modules/mutable-files.nix;
      };

      checks.${system} = {
        nomad = nomadConfig.activationPackage;
        layer-caelestia = layerChecks.caelestia.activationPackage;
        layer-hyprland = layerChecks.hyprland.activationPackage;
        layer-mpd = layerChecks.mpd.activationPackage;
        layer-winapps = layerChecks.winapps.activationPackage;
        mutable-copy = mutableCopyCheck;
      };
    };
}
