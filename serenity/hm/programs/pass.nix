{
  pkgs,
  config,
  ...
}: let
  storePath = "${config.home.homeDirectory}/.password-store";
in {
  programs.password-store = {
    enable = true;
    package = pkgs.pass-wayland.withExtensions (exts:
      with exts; [
        pass-otp
        pass-import
        pass-audit
        pass-file
      ]);
    settings.PASSWORD_STORE_DIR = storePath;
  };

  services.pass-secret-service = {
    inherit storePath;
    enable = true;
  };

  home.packages = with pkgs; [
    keeweb
    tessen
    rofi-pass-wayland
    qrencode
    wtype
  ];
}
