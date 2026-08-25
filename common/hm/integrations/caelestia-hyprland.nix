{ ... }:
{
  persona.layers.caelestia.extraActions = [
    {
      name = "Logout";
      icon = "exit_to_app";
      description = "Log out of current Hyprland session";
      command = [
        "hyprctl"
        "exit"
        ""
      ];
      enabled = true;
      dangerous = true;
    }
    {
      name = "Reload Hyprland";
      icon = "cached";
      description = "Reload Hyprland";
      command = [
        "hyprctl"
        "reload"
      ];
      enabled = true;
      dangerous = false;
    }
  ];
}
