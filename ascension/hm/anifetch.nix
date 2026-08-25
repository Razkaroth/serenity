{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.anifetch.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.zsh.initContent = lib.mkAfter ''
    if [[ -n "$KITTY_WINDOW_ID" && "$SHLVL" -eq 1 ]]; then
      anifetch_video="example.mp4"
      if [[ -f "$HOME/Pictures/anifetch" ]]; then
        anifetch_video="$HOME/Pictures/anifetch"
      else
        anifetch_matches=("$HOME"/Pictures/anifetch.*(N.))
        if (( ''${#anifetch_matches[@]} )); then
          anifetch_video="''${anifetch_matches[1]}"
        fi
      fi

      anifetch "$anifetch_video" -W 80 --center --cleanup -ca "--symbols wide --fg-only"
    fi
  '';
}
