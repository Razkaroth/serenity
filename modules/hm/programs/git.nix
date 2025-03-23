{ userConfig, ... }:

let
  cfg = userConfig;
in
{
programs.git = {
    enable = true;
    userName = cfg.gitUser;
    userEmail = cfg.gitEmail;
    lfs.enable = true;
    extraConfig = {
    push = { autoSetupRemote = true; };
    pull = { rebase = false; };
    };
  };
}
