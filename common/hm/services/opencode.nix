{ pkgs, ... }:

{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      # Run via nix run inside zsh to ensure environment is set
      # Source .zshrc to get all user environment variables (PATHs, etc.) defined in home-manager zsh config
      # Add beads-mcp path explicitly as requested just in case
      ExecStart = "${pkgs.zsh}/bin/zsh -c 'source $HOME/.zshrc; export PATH=$HOME/.local/share/uv/tools/beads-mcp/bin:$PATH; nix run github:anomalyco/opencode -- web --hostname 0.0.0.0 --port 4242'";
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
