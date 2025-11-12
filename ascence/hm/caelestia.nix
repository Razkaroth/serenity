{ pkgs, inputs, ... }: 
{ 
  programs.caelestia = {
  enable = true;
  systemd = {
    enable = true; # if you prefer starting from your compositor
    target = "graphical-session.target";
    environment = [];
  };
  # settings = {
  #   bar.status = {
  #     showBattery = true;
  #   };
  #   paths.wallpaperDir = "~/Pictures/wallpaper";
  # };
  cli = {
    enable = true; # Also add caelestia-cli to path
    settings = {
      theme.enableGtk = true;
    };
  };
};

}
