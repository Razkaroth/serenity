{ pkgs, ... }:

let
  image = "ghcr.io/heuwels/lector:latest";
  containerName = "lector";
  uiPort = 3400;
  apiPort = 3457;
  envFile = "/home/raz/.config/lector.env";
in
{
  systemd.services.lector = {
    description = "Lector language learning reader";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "lector";
      EnvironmentFile = envFile;
    };

    preStart = ''
      docker pull ${image}
      docker rm --force ${containerName} 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name ${containerName} \
        --publish 127.0.0.1:${toString uiPort}:3000 \
        --publish 127.0.0.1:${toString apiPort}:${toString apiPort} \
        --volume /var/lib/lector:/app/data \
        --env NODE_ENV=production \
        --env DATA_DIR=/app/data \
        --env LLM_PROVIDER=openai \
        --env OPENAI_COMPAT_URL=https://api.deepseek.com \
        --env OPENAI_COMPAT_MODEL=deepseek-v4-pro \
        --env OPENAI_COMPAT_API_KEY \
        --env API_URL \
        --env CLASSIFY_WORKER=1 \
        ${image}
    '';
  };

  systemd.services.lector-tailscale-serve = {
    description = "Tailscale Serve HTTPS for Lector UI and API";
    after = [
      "tailscaled.service"
      "lector.service"
    ];
    wants = [
      "tailscaled.service"
      "lector.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      tailscale serve --bg --yes --https=${toString uiPort} http://127.0.0.1:${toString uiPort}
      tailscale serve --bg --yes --https=${toString apiPort} http://127.0.0.1:${toString apiPort}
    '';
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "30 4 * * 0 root /run/current-system/sw/bin/docker pull ${image} && /run/current-system/sw/bin/systemctl restart lector.service"
    ];
  };
}
