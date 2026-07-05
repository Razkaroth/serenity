{ pkgs, ... }:
{
  systemd.services.kanata-main.serviceConfig.User = "raz";

  security.sudo.extraRules = [
    {
      users = [ "raz" ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl start kanata-main.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl stop kanata-main.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards = {
      main = {
        # config = (builtins.readFile ./kanataZen.lisp);
        config = (builtins.readFile ./homeRow.lisp);
        extraDefCfg = ''
          process-unmapped-keys yes
          danger-enable-cmd yes
        '';
      };
    };
  };
}
