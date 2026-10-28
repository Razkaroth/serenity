{
  services = {
    tailscale = {
      enable = true;
    };
    openssh = {
      enable = true;
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
