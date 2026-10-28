{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  vmName = "coolify";
  vmMac = "52:54:00:c0:01:f7";
  vmUuid = "c001f700-5e1e-4117-a777-525400c001f7";
  diskPath = "/var/lib/libvirt/images/coolify.qcow2";
  diskGiB = 50;
  sutrIp = "93.188.166.75";
  sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/UwzECsaGLKWKPKzXS+PrPdI3m2HBUOUX1D7vFQuQT"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPei9Lvs+bmmrlWpQf7Na+Pe+yNn9egSU5YBcqfcFHoq"
  ];

  # Ubuntu 24.04 LTS cloud image (noble release 20260814).
  ubuntuCloudImage = pkgs.fetchurl {
    url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img";
    hash = "sha256-bkDAeucV90T4SvC+x2QVzBmH3RFbS43kN4GFYfAaNzM=";
  };

  userData = pkgs.writeText "user-data" ''
    #cloud-config
    hostname: ${vmName}
    fqdn: ${vmName}
    manage_etc_hosts: false
    users:
      - name: raz
        groups: [sudo, docker]
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
    ${lib.concatMapStringsSep "\n" (key: "          - ${key}") sshPubKeys}
    ssh_pwauth: false
    package_update: true
    packages:
      - qemu-guest-agent
      - curl
      - docker.io
      - docker-compose-v2
    runcmd:
      - grep -q '^${sutrIp}[[:space:]]\+sutr$' /etc/hosts || printf '${sutrIp} sutr\n' >> /etc/hosts
      - systemctl enable --now qemu-guest-agent
      - systemctl enable --now docker
      - curl -fsSL https://tailscale.com/install.sh | sh
  '';

  metaData = pkgs.writeText "meta-data" ''
    instance-id: ${vmName}-2
    local-hostname: ${vmName}
  '';

  cidataIso = pkgs.runCommand "coolify-cidata.iso" {
    nativeBuildInputs = [ pkgs.xorriso ];
  } ''
    xorriso -as mkisofs -V CIDATA -r -J -o "$out" \
      -graft-points \
      user-data=${userData} \
      meta-data=${metaData}
  '';

  domain = lib.recursiveUpdate
    (inputs.NixVirt.lib.domain.templates.linux {
      name = vmName;
      uuid = vmUuid;
      vcpu = { count = 2; };
      memory = {
        count = 2560;
        unit = "MiB";
      };
      storage_vol = diskPath;
      install_vol = "${cidataIso}";
      bridge_name = "br0";
      net_iface_mac = vmMac;
      virtio_video = false;
    })
    {
      os.boot = [
        { dev = "hd"; }
        { dev = "cdrom"; }
      ];
      devices = {
        serial = [
          {
            type = "pty";
            target.port = 0;
          }
        ];
        console = [
          {
            type = "pty";
            target = {
              type = "serial";
              port = 0;
            };
          }
        ];
      };
    };
in
{
  # LAN bridge via NetworkManager so DHCP stays on br0. wlo1 is left alone
  # as a fallback if the first ethernet cutover drops briefly.
  networking.networkmanager.ensureProfiles.profiles = {
    br0 = {
      connection = {
        id = "br0";
        type = "bridge";
        "interface-name" = "br0";
        autoconnect = true;
        "autoconnect-priority" = "100";
      };
      bridge = {
        stp = "false";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        method = "auto";
      };
    };
    eno1-br = {
      connection = {
        id = "eno1-br";
        type = "ethernet";
        "interface-name" = "eno1";
        master = "br0";
        "slave-type" = "bridge";
        autoconnect = true;
        "autoconnect-priority" = "100";
      };
    };
  };

  virtualisation.libvirtd = {
    allowedBridges = [
      "br0"
      "virbr0"
    ];
    nss.enableGuest = true;
  };

  systemd.services.nixvirt = {
    after = [ "NetworkManager-wait-online.service" ];
    wants = [ "NetworkManager-wait-online.service" ];
  };

  # Copy the cloud image once into a persistent qcow2. Never use the nix
  # store path as a backing file — store GC would break the guest disk.
  system.activationScripts.coolify-disk = {
    deps = [ ];
    text = ''
      disk="${diskPath}"
      if [ ! -e "$disk" ]; then
        mkdir -p "$(dirname "$disk")"
        ${pkgs.qemu-utils}/bin/qemu-img convert -f qcow2 -O qcow2 ${ubuntuCloudImage} "$disk"
        ${pkgs.qemu-utils}/bin/qemu-img resize "$disk" ${toString diskGiB}G
        chmod 644 "$disk"
      fi
    '';
  };

  # NixVirt: only declare this domain. Leave networks/pools unset so the
  # default NAT network and storage pool are not deleted.
  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///system".domains = [
      {
        definition = inputs.NixVirt.lib.domain.writeXML domain;
        active = true;
        restart = false;
      }
    ];
  };

  # Discover the guest LAN IP via qemu-guest-agent (MAC-filtered so Docker
  # bridges are ignored) and proxy Coolify ports to it.
  systemd.services.coolify-proxy = {
    description = "Proxy Tailscale serenity:7777 to Coolify VM";
    after = [
      "libvirtd.service"
      "nixvirt.service"
      "tailscaled.service"
    ];
    wants = [
      "libvirtd.service"
      "nixvirt.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.libvirt
      pkgs.gawk
      pkgs.coreutils
      pkgs.socat
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      get_ip() {
        virsh -c qemu:///system domifaddr ${vmName} --source agent 2>/dev/null \
          | awk -v mac="${vmMac}" '
              $2 == mac && $3 == "ipv4" {
                split($4, a, "/")
                ip = a[1]
                if (ip !~ /^127\./) {
                  print ip
                  exit
                }
              }
            '
      }

      ip=""
      while [ -z "$ip" ]; do
        ip="$(get_ip || true)"
        if [ -z "$ip" ]; then
          sleep 5
        fi
      done

      socat TCP-LISTEN:7777,reuseaddr,fork TCP:"$ip":8000 &
      socat TCP-LISTEN:6001,reuseaddr,fork TCP:"$ip":6001 &
      socat TCP-LISTEN:6002,reuseaddr,fork TCP:"$ip":6002 &
      wait
    '';
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    7777
    6001
    6002
  ];
}
