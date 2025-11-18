
{ pkgs,  ... }:
{

   # ===== Virtualization Configuration =====

  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

}
