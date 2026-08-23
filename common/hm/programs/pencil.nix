{ lib, pkgs, ... }:

let
  pname = "pencil";
  version = "1.2.5";

  src = pkgs.fetchurl {
    url = "https://www.pen.dev/download/Pen-linux-x86_64.AppImage";
    hash = "sha256-3fQHS8kcY8NiGw2HjNc1S1olGj2+x8QOdLBCY36/sXw=";
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

      install -Dm644 ${appimageContents}/pen.png "$out/share/icons/hicolor/512x512/apps/${pname}.png"
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
