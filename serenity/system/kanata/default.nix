{ pkgs, ... }: {
  
  environment.systemPackages = with pkgs; [
    libnotify
    (pkgs.writeShellScriptBin "notify-session" ''
      export XDG_RUNTIME_DIR=/run/user/1000
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
      exec ${pkgs.libnotify}/bin/notify-send -t 200 "$@"
    '')
  ];

systemd.services.kanata-main.serviceConfig.User = "raz";

  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards = {
      main = {
        # config = (builtins.readFile ./kanataZen.lisp);
        config = (builtins.readFile ./plank.lisp);
        extraDefCfg = ''
          process-unmapped-keys yes
          danger-enable-cmd yes
        '';
      };
    };
  };
}
