{ ... }:
{
  services.howdy = {
    enable = true;
    # `sufficient` keeps password authentication available when recognition fails.
    control = "sufficient";
    settings.video.device_path = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:6:1.2-video-index0";
  };

  security.pam.services.sddm = {
    enableGnomeKeyring = true;
  };

  security.sudo.extraRules = [
    {
      users = [ "raz" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/docker";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
