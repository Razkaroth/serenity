{ lib, pkgs, ... }:

let
  pname = "spotiflac";
  version = "7.1.1";

  src = pkgs.fetchurl {
    url = "https://github.com/afkarxyz/SpotiFLAC/releases/download/v${version}/SpotiFLAC.AppImage";
    hash = "sha256-X28bE3JEBvKpsDQ1uHKCFTxAa3IK2l/pK2WCq+3oMPY=";
  };

  spotiflac = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = p: [
      p.webkitgtk_4_1
    ];

    extraInstallCommands = ''
      if [ -e "$out/bin/${pname}-${version}" ]; then
        mv "$out/bin/${pname}-${version}" "$out/bin/${pname}"
      fi
    '';

    meta = with lib; {
      description = "SpotiFLAC AppImage wrapper";
      homepage = "https://github.com/afkarxyz/SpotiFLAC";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in
{
  home.packages = [ spotiflac ];

  xdg.desktopEntries.spotiflac = {
    name = "SpotiFLAC";
    comment = "Spotify downloader and converter";
    exec = "${lib.getExe spotiflac}";
    icon = "spotiflac";
    terminal = false;
    type = "Application";
    categories = [
      "Audio"
      "Music"
      "Utility"
    ];
    startupNotify = true;
  };
}
