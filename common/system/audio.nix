{ pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    easyeffects
    qjackctl
    rtaudio
  ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
  ];

  users.users.raz.extraGroups = [
    "audio"
    "rtkit"
  ];
}
