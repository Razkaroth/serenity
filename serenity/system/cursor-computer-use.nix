{ pkgs, ... }:

let
  # Cursor computer-use looks for Xtigervnc; nixpkgs tigervnc provides Xvnc.
  xtigervnc = pkgs.runCommand "xtigervnc-bin" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.tigervnc}/bin/Xvnc $out/bin/Xtigervnc
  '';
in
{
  # Cursor creates an isolated TigerVNC/Xfce display when started with --computer-use.
  # xfconf exposes the D-Bus service Xfce needs to load its default xfwm4 session.
  environment.systemPackages = with pkgs; [
    xdotool
    ffmpeg-full
    xdpyinfo
    xrdb
    xrandr
    xprop
    tigervnc
    xtigervnc
    xfce4-session
    xfce4-panel
    xfwm4
    xfconf
    dbus
  ];
}
