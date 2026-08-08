{ pkgs, lib, config, ... }:
{
  # Hydenix enables services.blueman, but the NixOS module ships a user unit
  # that re-sets ExecStart on top of blueman's package unit. systemd rejects
  # that for non-oneshot services (bad-setting), so the tray never starts.
  systemd.user.services.blueman-applet = lib.mkIf config.services.blueman.enable {
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.blueman}/bin/blueman-applet"
    ];
  };

  environment.systemPackages = [ pkgs.overskride ];
}
