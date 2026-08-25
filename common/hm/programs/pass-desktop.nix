{ config, pkgs, ... }:
let
  storePath = "${config.home.homeDirectory}/.password-store";
in
{
  services.pass-secret-service = {
    inherit storePath;
    enable = false;
  };

  services.gnome-keyring = {
    enable = true;
    components = [
      "secrets"
      "ssh"
    ];
  };

  home.packages = with pkgs; [
    keeweb
    tessen
    rofi-pass-wayland
    qrencode
    wtype
  ];
}
