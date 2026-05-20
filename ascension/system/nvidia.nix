{ lib, ... }:
{
  hardware.nvidia = {
    modesetting.enable = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      reverseSync.enable = true;
      sync.enable = lib.mkForce false;
    };
  };
}
