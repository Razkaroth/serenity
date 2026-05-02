{ lib, pkgs, ... }:

let
  pname = "pencil";
  version = "1.1.55";

  src = pkgs.fetchurl {
    url = "https://www.pencil.dev/download/Pencil-linux-x86_64.AppImage";
    hash = "sha256-pu7KAEUQh3k/tcvy58P3u6L3wUf/wY2PxV6VhKS+AC0=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  pencil = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      if [ -e "$out/bin/${pname}-${version}" ]; then
        mv "$out/bin/${pname}-${version}" "$out/bin/${pname}"
      fi

      install -Dm644 ${appimageContents}/pencil.png "$out/share/icons/hicolor/512x512/apps/${pname}.png"
    '';

    meta = with lib; {
      description = "Desktop app for Pencil";
      homepage = "https://www.pencil.dev/";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in
{
  home.packages = [ pencil ];

  xdg.desktopEntries.pencil = {
    name = "Pencil";
    comment = "Desktop app for Pencil";
    exec = "${lib.getExe pencil} --no-sandbox %U";
    icon = "pencil";
    terminal = false;
    type = "Application";
    categories = [
      "Graphics"
    ];
    mimeType = [
      "x-scheme-handler/pencil"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "Pencil";
    };
  };
}
