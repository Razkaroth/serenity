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
    allowedTCPPorts = [ 8088 ]; # Hermes C2 static report server
    allowedUDPPorts = [ 9993 ]; # Needed for ZeroTier to function
    trustedInterfaces = [ "zt0" ]; # Allows all traffic from ZeroTier network
  };

}
