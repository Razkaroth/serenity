{...}:
{
  services.xserver.xkb.extraLayouts.dh = {
    description = "Colemak-DH ergo";
    languages = [ "eng" ];
    symbolsFile = ./colemak_dh;
  };

  services.xserver.xkb ={
    layout = "us,dh";
  };
  
}
