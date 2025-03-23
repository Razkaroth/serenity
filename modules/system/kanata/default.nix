{ ... }: {

  services.kanata = {
    enable = true;
    keyboards = {
      main = {
        config = (builtins.readFile ./kanataZen.lisp);
        # config = (builtins.readFile ./kanataMain.lisp);
        extraDefCfg = ''
          process-unmapped-keys yes
        '';
      };
    };
  };
}
