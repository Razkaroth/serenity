{  pkgs, ... }:
{
  fonts.packages = with pkgs; [
    corefonts
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];
}
