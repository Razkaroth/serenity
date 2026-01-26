{ pkgs, ... }:

{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      # Run under zsh login shell to ensure environment variables (PATH, bun, node, etc.) are loaded correctly
      # This fixes issues where opencode or its dependencies aren't found (error 127)
      ExecStart = "${pkgs.zsh}/bin/zsh -l -c 'if ! command -v opencode &> /dev/null; then echo \"Installing opencode...\"; bun add -g opencode-ai; fi; exec opencode web --hostname 0.0.0.0 --port 4242'";
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
