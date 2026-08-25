{ pkgs, ... }:
{
  persona.layers.caelestia = {
    extraActions = [
      {
        name = "Enable homerow";
        icon = "shift_lock";
        description = "Enable homerow keys";
        command = [
          "sudo"
          "${pkgs.systemd}/bin/systemctl"
          "start"
          "kanata-main.service"
        ];
        enabled = true;
        dangerous = false;
      }
      {
        name = "Disable homerow";
        icon = "shift_lock_off";
        description = "Disable homerow keys";
        command = [
          "sudo"
          "${pkgs.systemd}/bin/systemctl"
          "stop"
          "kanata-main.service"
        ];
        enabled = true;
        dangerous = false;
      }
    ];

    gpuType = "NVIDIA";
  };
}
