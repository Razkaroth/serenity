{
  inputs,
  pkgs,
  launcherPath,
}:
let
  upstreamWinapps = inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps;
in
upstreamWinapps.overrideAttrs (oldAttrs: {
  postPatch = ''
    substituteInPlace setup.sh \
      --replace-fail "@out@/bin/winapps" \
      "${launcherPath}"
  ''
  + (oldAttrs.postPatch or "");
})
