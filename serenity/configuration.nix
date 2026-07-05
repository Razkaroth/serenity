{ inputs, ... }:
{
  imports = [
    (import ../common/host-base.nix {
      inherit inputs;
      hostName = "serenity";
      homeModule = ./hm;
      userConfig.linger = true;
    })
    ./serenity-hardware.nix
    ./system
    ./server.nix
  ];
}
