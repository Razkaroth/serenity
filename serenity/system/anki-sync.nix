{ pkgs, ... }:

{
  services.anki-sync-server = {
    enable = true;
    address = "127.0.0.1";
    port = 27701;
    openFirewall = false;
    users = [
      {
        username = "raz";
        passwordFile = "/home/raz/.config/anki-sync.password";
      }
    ];
  };

  systemd.services.anki-sync-tailscale-serve = {
    description = "Tailscale Serve HTTPS for Anki sync server";
    after = [
      "tailscaled.service"
      "anki-sync-server.service"
    ];
    wants = [
      "tailscaled.service"
      "anki-sync-server.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      tailscale serve --bg --yes --https=27701 http://127.0.0.1:27701
    '';
  };
}
