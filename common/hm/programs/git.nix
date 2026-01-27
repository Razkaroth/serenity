{  lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "razkaroth";
        email = "rocker.ikaros@gmail.com";
      };
      push = { autoSetupRemote = true; };
      pull = { rebase = false; };
    };
    lfs.enable = true;
  };
}
