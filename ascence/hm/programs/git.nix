{  lib, ... }:
{
programs.git = {
    enable = true;
    userName = "razkaroth";
    userEmail = "rocker.ikaros@gmail.com";
    lfs.enable = true;
    extraConfig = {
    push = { autoSetupRemote = true; };
    pull = { rebase = false; };
    };
  };
}
