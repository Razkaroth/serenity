{ lib, ... }:
{
  programs.zsh.initContent = lib.mkBefore ''
    cat ~/.local/state/caelestia/sequences.txt 2>/dev/null
  '';
}
