{ pkgs, ... }:

let
  image = "agigante80/actual-mcp-server:latest";
  containerName = "actual-mcp";
  hostPort = 3600;
  envFile = "/home/raz/.config/actual-mcp.env";
in
{
  systemd.services.actual-mcp = {
    description = "Actual Budget MCP server (personal Hermes)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "actual-budget.service"
    ];
    wants = [
      "docker.service"
      "actual-budget.service"
    ];
    path = [ pkgs.docker-client ];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "actual-mcp";
      EnvironmentFile = envFile;
    };

    preStart = ''
      docker pull ${image}
      docker rm --force ${containerName} 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name ${containerName} \
        --publish 127.0.0.1:${toString hostPort}:${toString hostPort} \
        --add-host host.docker.internal:host-gateway \
        --volume /var/lib/actual-mcp:/app/data \
        --env ACTUAL_SERVER_URL=http://host.docker.internal:9999 \
        --env ACTUAL_PASSWORD \
        --env ACTUAL_BUDGET_SYNC_ID \
        --env MCP_SSE_AUTHORIZATION \
        ${image}
    '';
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "15 4 * * 0 root /run/current-system/sw/bin/docker pull ${image} && /run/current-system/sw/bin/systemctl restart actual-mcp.service"
    ];
  };
}
