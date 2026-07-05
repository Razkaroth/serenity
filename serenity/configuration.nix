{ inputs, ... }:
{
  imports = [
    (import ../common/host-base.nix {
      inherit inputs;
      hostName = "serenity";
      homeModule = ./hm;
      hydenixConfig.gaming.enable = false;
      userConfig.linger = true;
    })
    ./serenity-hardware.nix
    ./system
    ./server.nix
  ];
}
