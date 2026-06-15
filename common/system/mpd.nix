{ ...}:
{
  services.mpd = {
    enable = true;
    settings = {
      audio_output = [
        {
          type = "pulse";
          name = "PipeWire Pulse";
          server = "/run/user/1000/pulse/native";
          mixer_type = "software";
        }
      ];
      auto_update = "yes";
      music_directory = "/home/raz/Music/ripper";
    };
    startWhenNeeded = true;
    user = "raz";
  };
}
