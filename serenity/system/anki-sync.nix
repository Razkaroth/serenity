{ ... }:

{
  services.anki-sync-server = {
    enable = true;
    address = "0.0.0.0";
    port = 27701;
    openFirewall = false;
    users = [
      {
        username = "raz";
        passwordFile = "/home/raz/.config/anki-sync.password";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 27701 ];
}
