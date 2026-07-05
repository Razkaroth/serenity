{ config, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      source = ~/.config/hypr/main.conf
    '';

    # Use the NixOS module's Hyprland and portal packages.
    package = null;
    portalPackage = null;
    systemd.variables = [ "--all" ];
  };

  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
}
