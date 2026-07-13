{ config, inputs, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.hermes-alters;
  hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  containerEntrypoint = pkgs.writeShellScript "hermes-alter-container-entrypoint" ''
    set -eu

    HERMES_UID="''${HERMES_UID:?HERMES_UID must be set}"
    HERMES_GID="''${HERMES_GID:?HERMES_GID must be set}"

    existing_group=$(getent group "$HERMES_GID" 2>/dev/null | cut -d: -f1 || true)
    if [ -n "$existing_group" ]; then
      group_name="$existing_group"
    else
      group_name=hermes
      groupadd -g "$HERMES_GID" "$group_name"
    fi

    passwd_entry=$(getent passwd "$HERMES_UID" 2>/dev/null || true)
    if [ -n "$passwd_entry" ]; then
      target_user=$(echo "$passwd_entry" | cut -d: -f1)
      target_home=$(echo "$passwd_entry" | cut -d: -f6)
    else
      target_user=hermes
      target_home=/home/hermes
      useradd -u "$HERMES_UID" -g "$HERMES_GID" -m -d "$target_home" -s /bin/bash "$target_user"
    fi
    mkdir -p "$target_home"
    chown "$HERMES_UID:$HERMES_GID" "$target_home"
    chmod 0750 "$target_home"

    if [ -d "$HERMES_HOME" ]; then
      find "$HERMES_HOME" \! -user "$HERMES_UID" -exec chown "$HERMES_UID:$HERMES_GID" {} +
    fi

    if [ ! -f /var/lib/hermes-tools-provisioned ]; then
      apt-get update -qq
      apt-get install -y -qq sudo curl ca-certificates gnupg
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
      echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
      apt-get update -qq
      apt-get install -y -qq nodejs
      touch /var/lib/hermes-tools-provisioned
    fi

    if [ ! -f /etc/sudoers.d/hermes ]; then
      echo "$target_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hermes
      chmod 0440 /etc/sudoers.d/hermes
    fi

    if [ ! -x "$target_home/.local/bin/uv" ]; then
      su -s /bin/sh "$target_user" -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' || true
    fi

    if [ ! -d "$target_home/.venv" ] && [ -x "$target_home/.local/bin/uv" ]; then
      su -s /bin/sh "$target_user" -c '
        export PATH="$HOME/.local/bin:$PATH"
        uv python install 3.12
        uv venv --python 3.12 --seed "$HOME/.venv"
      ' || true
    fi

    if [ -d "$target_home/.venv/bin" ]; then
      export PATH="$target_home/.venv/bin:$PATH"
    fi

    exec setpriv --reuid="$HERMES_UID" --regid="$HERMES_GID" --init-groups "$@"
  '';

  commonSettings = {
    custom_providers = [
      {
        name = "opencode-go";
        base_url = "https://opencode.ai/zen/go/v1";
        key_env = "OPENCODE_API_KEY";
      }
    ];
    model = {
      provider = "custom:opencode-go";
      default = "deepseek-v4-pro";
    };
    toolsets = [ "all" ];
    web.backend = "exa";
    browser.camofox = {
      managed_persistence = true;
      rewrite_loopback_urls = false;
    };
    discord = {
      reactions = false;
      reply_to_mode = "off";
    };
    terminal = {
      backend = "local";
      timeout = 180;
    };
    compression = {
      enabled = true;
      threshold = 0.85;
    };
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
      provider = "holographic";
    };
  };

  mkAlter = name: alter:
    let
      serviceName = "hermes-alter-${name}";
      commandName = "hermes-${name}";
      camofoxServiceName = "hermes-camofox-${name}";
      neuttsServiceName = "hermes-neutts-${name}";
      networkName = serviceName;
      userName = "hermes-${name}";
      stateDir = "/var/lib/hermes-${name}";
      camofoxStateDir = "/var/lib/hermes-camofox-${name}";
      neuttsStateDir = "/var/lib/hermes-neutts-${name}";
      neuttsHttpBridge = pkgs.writeShellApplication {
        name = "${serviceName}-neutts-http";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          NEUTTS_ENDPOINT=http://${neuttsServiceName}:8765/synthesize \
            exec python ${./neutts-http-bridge.py} "$@"
        '';
      };
      settings = lib.recursiveUpdate commonSettings (lib.recursiveUpdate {
        browser.camofox.user_id = userName;
        tts = {
          provider = "neutts-http";
          providers.neutts-http = {
            type = "command";
            command = "${pkgs.lib.getExe neuttsHttpBridge} {input_path} {output_path}";
            output_format = "wav";
            timeout = 300;
            voice_compatible = true;
            max_text_length = 2000;
          };
        };
      } alter.settings);
      configFile = pkgs.writeText "${serviceName}-config.yaml" (builtins.toJSON settings);
      identity = builtins.hashString "sha256" (builtins.toJSON {
        image = alter.image;
        package = hermesPackage.outPath;
        network = networkName;
      });
      alterCommand = pkgs.writeShellScriptBin commandName ''
        docker=/run/current-system/sw/bin/docker
        container=${serviceName}

        if [ -t 0 ] && [ -t 1 ]; then
          exec /run/wrappers/bin/sudo -n "$docker" exec --interactive --tty --user hermes "$container" \
            /data/current-package/bin/hermes "$@"
        fi

        exec /run/wrappers/bin/sudo -n "$docker" exec --user hermes "$container" \
          /data/current-package/bin/hermes "$@"
      '';
    in
    {
      environment.systemPackages = [ alterCommand ];
      users.groups.${userName} = { };
      users.users.${userName} = {
        isSystemUser = true;
        group = userName;
        home = stateDir;
        createHome = true;
      };
      users.users.raz.extraGroups = [ userName ];

      systemd.services."${networkName}-network" = {
        description = "Private Docker network for Hermes alter ${name}";
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

      systemd.services.${camofoxServiceName} = {
        description = "Dedicated Camofox service for Hermes alter ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "hermes-camofox-image.service"
          "${networkName}-network.service"
        ];
        requires = [
          "docker.service"
          "hermes-camofox-image.service"
          "${networkName}-network.service"
        ];
        path = [ pkgs.docker-client ];
        preStart = ''
          docker rm --force ${camofoxServiceName} 2>/dev/null || true
        '';
        script = ''
          exec docker run --rm \
            --name ${camofoxServiceName} \
            --network ${networkName} \
            --volume ${camofoxStateDir}:/root/.camofox:rw \
            --env CAMOFOX_PORT=9377 \
            --env CAMOFOX_CRASH_REPORT_ENABLED=false \
            --env MAX_OLD_SPACE_SIZE=2048 \
            hermes-camofox:1.11.2
        '';
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          StateDirectory = "hermes-camofox-${name}";
        };
      };

      systemd.services."${serviceName}-neutts-sample" = {
        description = "Seed editable NeuTTS sample for Hermes alter ${name}";
        path = [ pkgs.coreutils ];
        serviceConfig.Type = "oneshot";
        script = ''
          install -d -o ${userName} -g ${userName} -m 0750 ${stateDir}/neutts
          if [ ! -e ${stateDir}/neutts/audio.wav ]; then
            install -o ${userName} -g ${userName} -m 0640 ${./neutts/C2-voicea/audio.wav} ${stateDir}/neutts/audio.wav
          fi
          if [ ! -e ${stateDir}/neutts/text.txt ]; then
            install -o ${userName} -g ${userName} -m 0640 ${./neutts/C2-voicea/text.txt} ${stateDir}/neutts/text.txt
          fi
        '';
      };

      systemd.services.${neuttsServiceName} = {
        description = "Dedicated NeuTTS service for Hermes alter ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "hermes-neutts-image.service"
          "${networkName}-network.service"
          "${serviceName}-neutts-sample.service"
        ];
        requires = [
          "docker.service"
          "hermes-neutts-image.service"
          "${networkName}-network.service"
          "${serviceName}-neutts-sample.service"
        ];
        path = [ pkgs.docker-client ];
        preStart = ''
          docker rm --force ${neuttsServiceName} 2>/dev/null || true
        '';
        script = ''
          exec docker run --rm \
            --name ${neuttsServiceName} \
            --network ${networkName} \
            --read-only \
            --tmpfs /tmp:rw,exec,nosuid,nodev \
            --volume ${neuttsStateDir}/cache:/cache:rw \
            --volume ${stateDir}/neutts:/voice:ro \
            --env HF_HOME=/cache \
            --env NUMBA_CACHE_DIR=/tmp/numba-cache \
            --env TORCHINDUCTOR_CACHE_DIR=/tmp/torch-cache \
            hermes-neutts:latest \
            --serve 0.0.0.0:8765 \
            --ref-audio /voice/audio.wav \
            --ref-text /voice/text.txt \
            --model neuphonic/neutts-air-q4-gguf \
            --device cpu
        '';
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          StateDirectory = "hermes-neutts-${name}";
        };
      };

      systemd.services.${serviceName} = {
        description = "Hermes agent alter ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "${networkName}-network.service"
          "${camofoxServiceName}.service"
          "${neuttsServiceName}.service"
        ];
        requires = [
          "docker.service"
          "${networkName}-network.service"
          "${camofoxServiceName}.service"
          "${neuttsServiceName}.service"
        ];
        path = [ pkgs.docker-client pkgs.coreutils pkgs.nix ];
        preStart = ''
          test -f ${lib.escapeShellArg alter.envFile} || {
            echo "Missing Hermes alter environment file: ${alter.envFile}" >&2
            exit 1
          }

          install -d -o ${userName} -g ${userName} -m 0750 ${stateDir}/home ${stateDir}/workspace
          install -d -o ${userName} -g ${userName} -m 0750 \
            ${stateDir}/.hermes \
            ${stateDir}/.hermes/cron \
            ${stateDir}/.hermes/sessions \
            ${stateDir}/.hermes/logs \
            ${stateDir}/.hermes/memories
          install -o ${userName} -g ${userName} -m 0640 ${configFile} ${stateDir}/.hermes/config.yaml
          install -o ${userName} -g ${userName} -m 0640 /dev/null ${stateDir}/.hermes/.env
          cat ${lib.escapeShellArg alter.envFile} >> ${stateDir}/.hermes/.env
          cat >> ${stateDir}/.hermes/.env <<'HERMES_ALTER_ENV_EOF'
          CAMOFOX_URL=http://${camofoxServiceName}:9377
          DISCORD_ALLOW_ALL_USERS=false
          DISCORD_ALLOW_BOTS=none
          HERMES_ALTER_ENV_EOF

          ln -sfn ${hermesPackage} ${stateDir}/current-package
          ln -sfn ${containerEntrypoint} ${stateDir}/current-entrypoint
          ${pkgs.nix}/bin/nix-store --add-root ${stateDir}/.gc-root --indirect -r ${hermesPackage} 2>/dev/null || true
          ${pkgs.nix}/bin/nix-store --add-root ${stateDir}/.gc-root-entrypoint --indirect -r ${containerEntrypoint} 2>/dev/null || true

          if ! docker inspect ${serviceName} >/dev/null 2>&1 || [ ! -f ${stateDir}/.container-identity ] || [ "$(cat ${stateDir}/.container-identity)" != "${identity}" ]; then
            docker rm --force ${serviceName} 2>/dev/null || true
            docker create \
              --name ${serviceName} \
              --network ${networkName} \
              --entrypoint /data/current-entrypoint \
              --volume /nix/store:/nix/store:ro \
              --volume ${stateDir}:/data \
              --volume ${stateDir}/home:/home/hermes \
              --env HERMES_UID="$(id -u ${userName})" \
              --env HERMES_GID="$(id -g ${userName})" \
              --env HERMES_HOME=/data/.hermes \
              --env HERMES_MANAGED=true \
              --env HOME=/home/hermes \
              --env MESSAGING_CWD=/data/workspace \
              ${alter.image} \
              /data/current-package/bin/hermes gateway run --replace
            echo ${identity} > ${stateDir}/.container-identity
          fi
        '';
        script = ''
          exec docker start -a ${serviceName}
        '';
        preStop = ''
          docker stop -t 10 ${serviceName} || true
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = 5;
          StateDirectory = "hermes-${name}";
          UMask = "0007";
        };
      };

      system.activationScripts."hermes-alter-${name}-link".text = ''
        target=${stateDir}/.hermes
        link=/home/raz/.hermes-${name}
        if [ -d "$link" ] && [ ! -L "$link" ]; then
          echo "hermes-alter-${name}: refusing to replace existing directory $link" >&2
          exit 1
        fi
        ln -sfn "$target" "$link"
        chown -h raz:${userName} "$link"
      '';
    };
in
{
  options.services.hermes-alters = {
    enable = mkEnableOption "isolated Hermes alter agents";
    instances = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          enable = mkEnableOption "this Hermes alter";
          envFile = mkOption {
            type = types.str;
            description = "Host path to this alter's secret environment file.";
          };
          image = mkOption {
            type = types.str;
            default = "ubuntu:24.04";
            description = "OCI image used by the Hermes alter container.";
          };
          settings = mkOption {
            type = types.attrs;
            default = { };
            description = "Hermes settings merged over the isolated alter defaults.";
          };
        };
      }));
      default = { };
      description = "Named isolated Hermes agent instances.";
    };
  };

  config = mkIf (cfg.enable && cfg.instances.goku.enable)
    (mkAlter "goku" cfg.instances.goku);
}
