{ pkgs, ... }:

let
  sourceDir = "/var/lib/habitica/source";
  image = "habitica:develop";
  containerName = "habitica";
  mongoContainerName = "habitica-mongodb";
  networkName = "habitica";
  hostPort = 9001;
in
{
  systemd.services.habitica-network = {
    description = "Habitica Docker network";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      docker network inspect ${networkName} >/dev/null 2>&1 || docker network create ${networkName}
    '';
  };

  systemd.services.habitica-mongodb = {
    description = "Habitica MongoDB";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "habitica-network.service" ];
    requires = [ "docker.service" "habitica-network.service" ];
    path = [ pkgs.docker-client ];

    preStart = ''
      docker pull mongo:7.0
      docker rm --force ${mongoContainerName} 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name ${mongoContainerName} \
        --hostname mongo \
        --network ${networkName} \
        --network-alias mongo \
        --volume /var/lib/habitica-mongodb:/data/db \
        mongo:7.0 mongod --bind_ip_all --replSet rs
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "habitica-mongodb";
    };
  };

  systemd.services.habitica-mongodb-init = {
    description = "Initialize Habitica MongoDB replica set";
    after = [ "habitica-mongodb.service" ];
    requires = [ "habitica-mongodb.service" ];
    path = [ pkgs.docker-client pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      for _ in $(seq 1 30); do
        if docker exec ${mongoContainerName} mongosh --port 27017 --quiet --eval 'try { rs.status() } catch (err) { rs.initiate() }'; then
          exit 0
        fi
        sleep 2
      done
      exit 1
    '';
  };

  systemd.services.habitica-image = {
    description = "Build Habitica from current upstream develop";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client pkgs.git ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "habitica";
    };

    script = ''
      if [ -d ${sourceDir}/.git ]; then
        git -C ${sourceDir} fetch --depth 1 origin develop
        git -C ${sourceDir} reset --hard origin/develop
        git -C ${sourceDir} submodule sync --recursive
        git -C ${sourceDir} submodule update --init --recursive --depth 1
      else
        rm -rf ${sourceDir}
        git clone --depth 1 --branch develop --recurse-submodules https://github.com/HabitRPG/habitica.git ${sourceDir}
      fi
      docker build --pull --file ${./habitica/Dockerfile} --tag ${image} ${sourceDir}
    '';
  };

  systemd.services.habitica = {
    description = "Habitica self-hosted server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "habitica-image.service"
      "habitica-mongodb-init.service"
    ];
    requires = [
      "habitica-image.service"
      "habitica-mongodb-init.service"
    ];
    path = [ pkgs.docker-client pkgs.gnugrep pkgs.openssl ];

    preStart = ''
      if [ ! -s /var/lib/habitica/habitica.env ]; then
        umask 077
        printf 'SESSION_SECRET=%s\n' "$(openssl rand -hex 64)" > /var/lib/habitica/habitica.env
      fi
      if ! grep -q '^SESSION_SECRET_KEY=' /var/lib/habitica/habitica.env; then
        umask 077
        printf 'SESSION_SECRET_KEY=%s\n' "$(openssl rand -hex 32)" >> /var/lib/habitica/habitica.env
      fi
      docker rm --force ${containerName} 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name ${containerName} \
        --network ${networkName} \
        --publish 0.0.0.0:${toString hostPort}:3000 \
        --env-file /var/lib/habitica/habitica.env \
        --env NODE_ENV=production \
        --env NODE_DB_URI=mongodb://mongo:27017/habitrpg?replicaSet=rs \
        --env BASE_URL=http://serenity:${toString hostPort} \
        --env PAYPAL_MODE=sandbox \
        --env TRUSTED_DOMAINS=serenity \
        ${image} node ./website/transpiled-babel/index.js
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "habitica";
    };
  };

  networking.firewall.allowedTCPPorts = [ hostPort ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      "45 4 * * 0 root /run/current-system/sw/bin/systemctl restart habitica-image.service && /run/current-system/sw/bin/systemctl restart habitica.service"
    ];
  };
}
