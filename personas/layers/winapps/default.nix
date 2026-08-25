{
  config,
  inputs,
  pkgs,
  ...
}:
let
  winapps = import ../../../common/packages/winapps.nix {
    inherit inputs pkgs;
    launcherPath = "${config.home.profileDirectory}/bin/winapps";
  };
in
{
  home.packages = [
    winapps
    pkgs.freerdp
  ];
}
