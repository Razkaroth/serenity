{ lib, ... }:
{
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    # Add app classes here only after observing a WinApps RemoteApp class.
    $winapps_office = ^(Microsoft (Word|Excel|PowerPoint|Publisher|Powershell|Visual Studio))$

    windowrule {
        name = suppress-winapps-office-maximize
        match:class = $winapps_office
        suppress_event = maximize
    }
  '';
}
