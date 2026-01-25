{  lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "razkaroth";
        email = "rocker.ikaros@gmail.com";
      };
    };
    lfs.enable = true;
    extraConfig = {
      push = { autoSetupRemote = true; };
      pull = { rebase = false; };
    };
  };
}
