{ pkgs,  ... }:
{

play = {
  amd.enable = false;           # AMD GPU optimization
  steam.enable = true;         # Steam with Proton-CachyOS
  lutris.enable = true;        # Lutris game manager
  gamemode.enable = true;      # Performance optimization
  ananicy.enable = true;       # Process scheduling
  procon2.enable = false;       # Nintendo Switch 2 Pro Controller support
};



}
