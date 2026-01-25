{ pkgs,  ... }:
{

   # ===== Virtualization Configuration =====
  
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    gnome-boxes
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };
}
