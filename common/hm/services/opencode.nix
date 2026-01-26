{ pkgs, ... }:

{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      # Run via nix run inside zsh to ensure environment is set
      # Add beads-mcp path explicitly as requested, and ensure local bin is there too
      ExecStart = "${pkgs.zsh}/bin/zsh -l -c 'export PATH=$HOME/.local/share/uv/tools/beads-mcp/bin:$HOME/.local/bin:$PATH; nix run github:anomalyco/opencode -- web --hostname 0.0.0.0 --port 4242'";
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
