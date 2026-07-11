{ pkgs, ... }:

let
  camofoxDockerImage = "hermes-camofox:1.11.2";
in
{
  systemd.services.hermes-camofox-image = {
    description = "Build Hermes Camofox Docker image";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      docker build -t ${camofoxDockerImage} ${./camofox-docker}
    '';
  };

  systemd.services.hermes-camofox = {
    description = "Camofox loopback browser service";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "hermes-camofox-image.service"
    ];
    requires = [
      "docker.service"
      "hermes-camofox-image.service"
    ];
    path = [ pkgs.docker-client ];

    preStart = ''
      docker rm --force hermes-camofox 2>/dev/null || true
    '';

    script = ''
      exec docker run --rm \
        --name hermes-camofox \
        --publish 127.0.0.1:9377:9377 \
        --add-host host.docker.internal:host-gateway \
        --volume /var/lib/hermes-camofox:/root/.camofox:rw \
        --env CAMOFOX_PORT=9377 \
        --env CAMOFOX_CRASH_REPORT_ENABLED=false \
        --env MAX_OLD_SPACE_SIZE=2048 \
        ${camofoxDockerImage}
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "hermes-camofox";
    };
  };
}
