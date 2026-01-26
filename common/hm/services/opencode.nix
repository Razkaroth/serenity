{ pkgs, ... }:

{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      # Run via nix run inside zsh to ensure environment is set
      ExecStart = "${pkgs.zsh}/bin/zsh -l -c 'nix run github:anomalyco/opencode -- web --hostname 0.0.0.0 --port 4242'";
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
