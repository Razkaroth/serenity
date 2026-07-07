{ ... }:
{
  boot.kernelModules = [ "snd_sof_pci_intel_mtl" ];

  services.pipewire.wireplumber.extraConfig."51-sof-soundwire" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "device.name" = "alsa_card.pci-0000_00_1f.3-platform-sof_sdw"; }
        ];
        actions.update-props = {
          "api.alsa.split-enable" = true;
        };
      }
    ];
  };
}
