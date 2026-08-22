{ inputs, ... }:
{
  imports = [
    (import ../common/host-base.nix {
      inherit inputs;
      hostName = "serenity";
      homeModule = ./hm;
      extraGroups = [ "kvm" ];
      hydenixConfig.gaming.enable = false;
      userConfig.linger = true;
    })
    inputs.NixVirt.nixosModules.default
    inputs.hermes-agent.nixosModules.default
    ./serenity-hardware.nix
    ./system
    ./server.nix
  ];
}
