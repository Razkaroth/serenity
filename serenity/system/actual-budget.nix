{ pkgs, ... }:

let
  image = "actualbudget/actual-server:latest";
  containerName = "actual-budget";
  hostPort = 9999;
  containerPort = 5006;
in
{
  systemd.services.actual-budget = {
    description = "Actual Budget server";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    preStart = ''
      docker pull ${image}
      docker rm --force ${containerName} 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name ${containerName} \
        --publish 127.0.0.1:${toString hostPort}:${toString containerPort} \
        --volume /var/lib/actual-budget:/data \
        ${image}
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "actual-budget";
    };
  };

  systemd.services.actual-budget-tailscale-serve = {
    description = "Tailscale Serve HTTPS for Actual Budget";
    after = [
      "tailscaled.service"
      "actual-budget.service"
    ];
    wants = [
      "tailscaled.service"
      "actual-budget.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      tailscale serve --bg --yes --https=443 http://127.0.0.1:${toString hostPort}
    '';
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 4 * * 0 root /run/current-system/sw/bin/docker pull ${image} && /run/current-system/sw/bin/systemctl restart actual-budget.service"
    ];
  };
}
