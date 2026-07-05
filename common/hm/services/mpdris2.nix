{ ... }:
{
  services.mpdris2 = {
    enable = true;
    mpd = {
      host = "127.0.0.1";
      port = 6600;
      musicDirectory = "/home/raz/Music/ripper";
    };
  };
}
