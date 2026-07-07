{ ... }:
{
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
