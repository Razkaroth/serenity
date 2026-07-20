{ inputs, pkgs, ... }:
let
  upstreamWinapps = inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps;
  winapps = upstreamWinapps.overrideAttrs (oldAttrs: {
    # Keep generated launchers valid after input updates and garbage collection.
    postPatch = ''
      substituteInPlace setup.sh \
        --replace-fail "@out@/bin/winapps" \
        "/run/current-system/sw/bin/winapps"
    ''
    + (oldAttrs.postPatch or "");
  });
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
