{ pkgs, lib, ... }:

let
  opencodeScript = pkgs.writeShellScriptBin "opencode-service" ''
    export PATH="/home/raz/.cache/.bun/bin:$PATH"
    
    if ! command -v opencode &> /dev/null; then
      echo "opencode not found in PATH. Installing via bun..."
      bun add -g opencode-ai
    else
      echo "opencode found: $(which opencode)"
    fi
    
    echo "Starting opencode web service..."
    # Launch in web mode on 0.0.0.0:4242
    exec opencode web --hostname 0.0.0.0 --port 4242
  '';
in
{
  systemd.user.services.opencode = {
    Unit = {
      Description = "Opencode Web Service";
      After = [ "network.target" ];
    };
    
    Service = {
      ExecStart = "${opencodeScript}/bin/opencode-service";
      Restart = "always";
      RestartSec = "10s";
      Environment = "PATH=/home/raz/.cache/.bun/bin:${lib.makeBinPath [ pkgs.bun pkgs.bash pkgs.coreutils ]}:/usr/bin:/bin";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
