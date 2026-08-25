{ pkgs, config, ... }:
let
  storePath = "${config.home.homeDirectory}/.password-store";
in
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (
      exts: with exts; [
        pass-otp
        pass-import
        pass-audit
        pass-file
      ]
    );
    settings.PASSWORD_STORE_DIR = storePath;
  };

  home.sessionVariables.PASSWORD_STORE_DIR = storePath;
}
