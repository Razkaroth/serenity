{ pkgs, ... }:

let
  image = "actualbudget/actual-server:26.7.0";
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

  systemd.services.actual-budget-tailscale-funnel = {
    description = "Tailscale Funnel HTTPS for Actual Budget";
    after = [
      "tailscaled.service"
      "actual-budget.service"
    ];
    wants = [
      "actual-budget.service"
    ];
    requires = [
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.coreutils
      pkgs.jq
      pkgs.tailscale
    ];

    unitConfig = {
      BindsTo = "tailscaled.service";
      StartLimitIntervalSec = "0";
    };

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 10;
      ExecStop = "${pkgs.tailscale}/bin/tailscale funnel reset";
    };

    # RemainAfterExit oneshot stays "active" after tailscale drops serve
    # config, so public Funnel dies while systemd still reports success.
    # Jellyfin's nginx owns 80/443. Actual is exposed only through Funnel 8443.
    script = ''
      desiredProxy="http://127.0.0.1:${toString hostPort}"

      apply() {
        tailscale funnel --bg --yes --https=8443 "$desiredProxy"
      }

      isHealthy() {
        tailscale funnel status --json | jq -e --arg proxy "$desiredProxy" '
          (.TCP["8443"].HTTPS == true)
          and (.AllowFunnel | to_entries | any(.value == true and (.key | endswith(":8443"))))
          and (.Web | to_entries | any(.value.Handlers["/"].Proxy == $proxy))
        ' >/dev/null
      }

      apply
      while true; do
        sleep 30
        if ! isHealthy; then
          apply
        fi
      done
    '';
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 4 * * 0 root /run/current-system/sw/bin/docker pull ${image} && /run/current-system/sw/bin/systemctl restart actual-budget.service"
    ];
  };
}
