{ lib, pkgs, ... }:

let
  c2ServerSkill = ./c2-server/SKILL.md;
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/c2-server 2770 hermes hermes - -"
  ];

  # Seed this before Hermes starts so it discovers the skill during startup.
  systemd.services.hermes-agent.preStart = lib.mkAfter ''
    ${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 2770 \
      /var/lib/hermes/.hermes/skills/c2-server
    ${pkgs.coreutils}/bin/install -o hermes -g hermes -m 0640 \
      ${c2ServerSkill} \
      /var/lib/hermes/.hermes/skills/c2-server/SKILL.md
  '';

  systemd.services.hermes-c2-server = {
    description = "Hermes C2 static report server";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    path = [ pkgs.docker-client ];

    preStart = ''
      docker rm --force hermes-c2-server 2>/dev/null || true
      ${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 2770 \
        /var/lib/hermes/c2-server
    '';

    script = ''
      exec docker run --rm \
        --name hermes-c2-server \
        --publish 0.0.0.0:8088:80 \
        --volume /var/lib/hermes/c2-server:/usr/share/nginx/html:ro \
        nginx:1.28-alpine
    '';

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
