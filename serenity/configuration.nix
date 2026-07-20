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
    inputs.hermes-agent.nixosModules.default
    ./serenity-hardware.nix
    ./system
    ./server.nix
  ];
}
