{ config, lib, pkgs, ... }:
{
    services.udev = {
      enable = true;
      extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '';
      packages = with pkgs; [ hidapi via ];
    };
}
