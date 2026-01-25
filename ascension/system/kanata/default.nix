{ pkgs, ... }: {

  systemd.services.kanata-main = {
    serviceConfig.User = "raz";
    wantedBy = pkgs.lib.mkForce [ ];  # Disable auto-start
  };

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
