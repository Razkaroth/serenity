{ lib, ... }:
{
  programs.zsh.initContent = lib.mkAfter ''
    alias nc='~/.config/nvchad/kitty.sh'
    alias n='~/.config/nvim/kitty.sh'
    alias gcal='gcalcli'
    alias gcq='gcalcli --calendar rocker.ikaros@gmail.com quick'
  '';
}
