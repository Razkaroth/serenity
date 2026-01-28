{ pkgs, ... }:

let
  env_vars = {
    PATH = "$HOME/.local/share/uv/tools/beads-mcp/bin:$PATH";
    PLANNOTATOR_REMOTE = "1";
  };

  env_script = pkgs.lib.concatStringsSep "; " 
    (pkgs.lib.mapAttrsToList (name: value: "export ${name}=${value}") env_vars);

  command = "nix run github:anomalyco/opencode -- web --hostname 0.0.0.0 --port 4242";

  execStart = "${pkgs.zsh}/bin/zsh -c 'source $HOME/.zshrc; ${env_script}; ${command}'";
in
{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      # Run via nix run inside zsh to ensure environment is set
      # Source .zshrc to get all user environment variables (PATHs, etc.) defined in home-manager zsh config
      ExecStart = execStart;
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
