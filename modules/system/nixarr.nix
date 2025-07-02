{ lib, config, ... }:
let
force = lib.mkForce;
in {
  nixarr = {
    enable = true;
# These two values are also the default, but you can set them to whatever
# else you want
# WARNING: Do _not_ set them to `/home/user/whatever`, it will not work!
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    vpn = {
      enable = false;
# WARNING: This file must _not_ be in the config git directory
# You can usually get this wireguard file from your VPN provider
      wgConf = "/data/.secret/wg.conf";
    };

    jellyfin = {
      enable = true;
# These options set up a nginx HTTPS reverse proxy, so you can access
# Jellyfin on your domain with HTTPS
      expose.https = {
        enable = true;
        domainName = "raz.com";
        acmeMail = "mail@razkaroth.com"; # Required for ACME-bot
      };
    };

    transmission = {
      enable = true;
      vpn.enable = false;
    };

# It is possible for this module to run the *Arrs through a VPN, but it
# is generally not recommended, as it can cause rate-limiting issues.
    bazarr.enable = false;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;
  };

  users = {
    users = {
      bazarr = {
        uid = force 901;
        group = force "bazarr";
        extraGroups = [ "media" ];
      };
      lidarr = {
        uid = force 902;
        group = force "lidarr";
        extraGroups = [ "media" ];
      };
      prowlarr = {
        uid = force 903;
        group = force "prowlarr";
        extraGroups = [ "media" ];
      };
      radarr = {
        uid = force 904;
        group = force "radarr";
        extraGroups = [ "media" ];
      };
      readarr = {
        uid = force 905;
        group =force  "readarr";
        extraGroups = [ "media" ];
      };
      sonarr = {
        uid = force 906;
        group = force "sonarr";
        extraGroups = [ "media" ];
      };
      transmission = {
        uid = force 907;
        group = force "transmission";
        extraGroups = [ "media" ];
      };
      nixarr = {
        uid = force 908;
        group = force "nixarr";
        extraGroups = [ "media" ];
      };
      cross-seed = {
        uid = force 909;
        group = force "cross-seed";
        extraGroups = [ "media" ];
      };
      jellyfin = {  # if you use Jellyfin user
        uid = force 995;
        group = force "jellyfin";
        extraGroups = [ "media" ];
      };
      media = {
        uid = force 910;
        group = force "media";
        extraGroups = [ "media" ];
      };
    };
    groups = {
      nixarr ={
        gid = force 908;
      };
      media = {
        gid = force 910;
      };
      transmission = {
        gid = force 907;
      };
      cross-seed = {
        gid = force 909;
      };
      jellyfin = {
        gid = force 995;
      };
      bazarr = {
        gid = force 901;
      };
      lidarr = {
        gid = force 902;
      };
      prowlarr = {
        gid = force 903;
      };
      radarr = {
        gid = force 904;
      };
      readarr = {
        gid = force 905;
      };
      sonarr = {
        gid = force 906;
      };
    };
  };
}
