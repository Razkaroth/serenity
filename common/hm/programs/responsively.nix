{ lib, pkgs, ... }:

let
  pname = "responsively";
  version = "1.18.0";

  src = pkgs.fetchurl {
    url = "https://github.com/responsively-org/responsively-app-releases/releases/download/v${version}/ResponsivelyApp-${version}.AppImage";
    hash = "sha256-FxGlt9Ame63pwEp+6x2WLOlRVITb/QVKhr/34mKCO6c=";
  };

  icon = pkgs.fetchurl {
    url = "https://github.com/responsively-org/responsively-app/raw/refs/heads/main/desktop-app/assets/icon.svg";
    hash = "sha256-Qhmdd5gEfkrGepYf2QtvvHsirNCwoJ9WIEHC9SWTWU4=";
  };

  responsively = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      if [ -e "$out/bin/${pname}-${version}" ]; then
        mv "$out/bin/${pname}-${version}" "$out/bin/${pname}"
      fi

      install -Dm644 ${icon} "$out/share/icons/hicolor/scalable/apps/${pname}.svg"
    '';

    meta = with lib; {
      description = "Responsively AppImage wrapper";
      homepage = "https://responsively.app/";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in
{
  home.packages = [ responsively ];

  xdg.desktopEntries.responsively = {
    name = "Responsively";
    comment = "Browser for responsive web development";
    exec = "${lib.getExe responsively}";
    icon = "responsively";
    terminal = false;
    type = "Application";
    categories = [
      "Development"
      "WebDevelopment"
      "Utility"
    ];
    startupNotify = true;
  };
}
