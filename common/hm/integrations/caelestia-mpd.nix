{ ... }:
{
  persona.layers.caelestia = {
    extraActions = [
      {
        name = "Music";
        icon = "music_note";
        description = "Open rmpc MPD client";
        command = [
          "kitty"
          "-e"
          "rmpc"
        ];
        enabled = true;
        dangerous = false;
      }
    ];

    defaultPlayer = "MPD";
    playerAliases = [
      {
        from = "mpd";
        to = "MPD";
      }
      {
        from = "Music Player Daemon";
        to = "MPD";
      }
    ];
  };
}
