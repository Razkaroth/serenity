{ config, lib, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = lib.mkForce false;
    };
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime.offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };

  boot.kernelParams = lib.mkAfter [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

  boot.initrd.kernelModules = lib.mkAfter [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
}
