{...}:
{
services.zerotierone = {
  enable = true;
  joinNetworks = [
    "166359304e9dc048"
  ];
};

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 9993 ]; # Needed for ZeroTier to function
    trustedInterfaces = [ "zt0" ]; # Allows all traffic from ZeroTier network
  };

}
