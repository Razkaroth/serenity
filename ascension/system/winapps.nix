{ inputs, pkgs, ... }:
let
  winapps = import ../../common/packages/winapps.nix {
    inherit inputs pkgs;
    launcherPath = "/run/current-system/sw/bin/winapps";
  };
in
{
  environment.systemPackages = [
    winapps
    pkgs.freerdp
  ];

  nix.settings = {
    substituters = [ "https://winapps.cachix.org/" ];
    trusted-public-keys = [
      "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
    ];
  };
}
