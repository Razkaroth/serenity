{ inputs, pkgs, ... }:
{
  imports = [
    (import ../common/host-base.nix {
      inherit inputs;
      hostName = "ascension";
      homeModule = ./hm;
      extraOverlays = [
        inputs.nixos-rocksmith.overlays.default
        inputs.anifetch.overlays.default
      ];
      extraGroups = [ "gamemode" ];
      hydenixConfig = {
        network.enable = true;
        gaming.enable = false;
      };
    })
    ./ascension-hardware.nix
    inputs.nixos-rocksmith.nixosModules.default
    ./system

    # GPU-specific configuration for the OMEN 14 laptop.
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
}
