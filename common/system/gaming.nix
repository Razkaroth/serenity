{ inputs, ... }:
{
  imports = [
    inputs.nixos-rocksmith.nixosModules.default
  ];

  programs.steam = {
    enable = true;
    rocksmithPatch.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };
}
