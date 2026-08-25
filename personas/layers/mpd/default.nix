{ config, pkgs, ... }:
{
  imports = [
    ../../../common/hm/programs/rmpc.nix
    ../../../common/hm/services/mpdris2.nix
  ];

  home.packages = with pkgs; [
    mpd
    mpc
    rmpc
  ];

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music/ripper";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PipeWire Pulse"
        mixer_type "software"
      }
      auto_update "yes"
    '';
  };
}
