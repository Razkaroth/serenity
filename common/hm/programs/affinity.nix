{ lib, pkgs, ... }:

let
  pname = "affinity";
  version = "3";

  src = pkgs.fetchurl {
    url = "https://github.com/ryzendew/Linux-Affinity-Installer/releases/download/Affinity-wine-10.10-Appimage/Affinity-3-x86_64.AppImage";
    hash = "sha256-h+XgxKy7n9oBL+6rmsf36DAc4ok+EwJE3KN/6jUMVbY=";
  };

  runtimeLibs = with pkgs; [
    SDL2
    alsa-lib
    cups
    dbus
    fontconfig
    freetype
    glib
    gnutls
    libGL
    libpulseaudio
    libudev0-shim
    libunwind
    libusb1
    libx11
    libxcomposite
    libxcursor
    libxext
    libxfixes
    libxi
    libxinerama
    libxrandr
    libxrender
    libxscrnsaver
    libxtst
    mesa
    nspr
    nss
    ocl-icd
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
    zlib
  ];

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  launcher = pkgs.writeShellApplication {
    name = "affinity-launcher";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      rsync
      which
    ];
    text = ''
      set -euo pipefail

      HERE="${appimageContents}"
      USER_WINEPREFIX="''${AFFINITY_WINEPREFIX:-$HOME/.AffinityLinux-Appimage}"
      APPIMAGE_WINEPREFIX="$HERE/usr/wineprefix"
      CURRENT_USER="''${USER:-$(whoami)}"
      OLD_USER="matt"
      EXE_PATH="$USER_WINEPREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe"
      APPIMAGE_ROAMING_BASE="$APPIMAGE_WINEPREFIX/drive_c/users/$OLD_USER/AppData/Roaming/Affinity"
      USER_ROAMING_BASE="$USER_WINEPREFIX/drive_c/users/$CURRENT_USER/AppData/Roaming/Affinity"

      export PATH="$HERE/usr/wine/bin:$PATH"
      export WINELOADER="$HERE/usr/wine/bin/wine"
      export WINEPREFIX="$USER_WINEPREFIX"
      export WINEDLLPATH="$HERE/usr/wine/lib/wine/x86_64-unix"
      export LD_LIBRARY_PATH="$HERE/usr/wine/lib:${lib.makeLibraryPath runtimeLibs}:''${LD_LIBRARY_PATH:-}"

      export DXVK_ASYNC=0
      export DXVK_CONFIG="d3d9.deferSurfaceCreation = True; d3d9.shaderModel = 1"

      firstRun=0
      needCopy=0

      if [ ! -d "$USER_WINEPREFIX" ]; then
        needCopy=1
        firstRun=1
      elif [ ! -f "$USER_WINEPREFIX/.appimage-version" ]; then
        needCopy=1
      elif [ -f "$APPIMAGE_WINEPREFIX/.appimage-version" ] && [ "$APPIMAGE_WINEPREFIX/.appimage-version" -nt "$USER_WINEPREFIX/.appimage-version" ] 2>/dev/null; then
        needCopy=1
      fi

      if [ "$needCopy" -eq 1 ]; then
        if [ "$firstRun" -eq 1 ]; then
          echo "Setting up Affinity wineprefix..."
          mkdir -p "$(dirname "$USER_WINEPREFIX")"
        else
          echo "Updating Affinity wineprefix..."
        fi

        mkdir -p "$USER_WINEPREFIX"
        rsync -a "$APPIMAGE_WINEPREFIX/" "$USER_WINEPREFIX/"

        if [ "$CURRENT_USER" != "$OLD_USER" ]; then
          for regfile in "$USER_WINEPREFIX/user.reg" "$USER_WINEPREFIX/userdef.reg"; do
            if [ -f "$regfile" ]; then
              sed -i "s|\\\\users\\\\$OLD_USER|\\\\users\\\\$CURRENT_USER|g" "$regfile"
              sed -i "s|users\\\\$OLD_USER|users\\\\$CURRENT_USER|g" "$regfile"
              sed -i "s|\"USERNAME\"=\"$OLD_USER\"|\"USERNAME\"=\"$CURRENT_USER\"|g" "$regfile"
            fi
          done

          if [ -d "$USER_WINEPREFIX/drive_c/users/$OLD_USER" ] && [ ! -d "$USER_WINEPREFIX/drive_c/users/$CURRENT_USER" ]; then
            mv "$USER_WINEPREFIX/drive_c/users/$OLD_USER" "$USER_WINEPREFIX/drive_c/users/$CURRENT_USER"
          fi
        fi
      fi

      USER_TEMP_DIR="$USER_WINEPREFIX/drive_c/users/$CURRENT_USER/Temp"
      mkdir -p "$USER_TEMP_DIR"
      export TMP="$USER_TEMP_DIR"
      export TEMP="$USER_TEMP_DIR"

      if [ ! -f "$USER_ROAMING_BASE/Affinity/3.0/lessons.json" ] && [ -f "$APPIMAGE_ROAMING_BASE/Affinity/3.0/lessons.json" ]; then
        mkdir -p "$USER_ROAMING_BASE/Affinity/3.0"
        cp "$APPIMAGE_ROAMING_BASE/Affinity/3.0/lessons.json" "$USER_ROAMING_BASE/Affinity/3.0/lessons.json"
      fi

      case "''${1:-}" in
        --dpi)
          exec "$HERE/usr/bin/affinity-dpi-config"
          ;;
        --winecfg)
          exec "$WINELOADER" winecfg
          ;;
      esac

      if [ "$firstRun" -eq 1 ]; then
        "$HERE/usr/bin/affinity-dpi-config"
      fi

      exec "$WINELOADER" "$EXE_PATH" "$@"
    '';
  };

  affinityFhs = pkgs.buildFHSEnv {
    name = "${pname}-fhs";
    targetPkgs = pkgs':
      runtimeLibs
      ++ (with pkgs'; [
        bash
        coreutils
        gnused
        rsync
        which
      ]);
    runScript = "${launcher}/bin/affinity-launcher";
  };

  affinity = pkgs.writeShellApplication {
    name = pname;
    text = ''
      set -euo pipefail

      if command -v nvidia-offload >/dev/null 2>&1; then
        exec nvidia-offload "${affinityFhs}/bin/${affinityFhs.name}" "$@"
      fi

      exec "${affinityFhs}/bin/${affinityFhs.name}" "$@"
    '';

    meta = with lib; {
      description = "Affinity AppImage wrapper for NixOS";
      homepage = "https://github.com/ryzendew/Linux-Affinity-Installer";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in
{
  home.packages = [ affinity ];

  xdg.desktopEntries.affinity = {
    name = "Affinity";
    comment = "Affinity AppImage wrapper";
    exec = "${lib.getExe affinity} %U";
    icon = "${appimageContents}/usr/share/icons/hicolor/scalable/apps/Affinity.svg";
    terminal = false;
    type = "Application";
    categories = [
      "Graphics"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "affinity.exe";
    };
  };
}
