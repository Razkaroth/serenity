#!/run/current-system/sw/bin/sh

sudo echo "rebuilding system"

sudo echo "removing *.nixbak files"

sudo find ~/ -name "*.nixbak" -type f -delete

sudo nixos-rebuild boot --install-bootloader -p solitude --flake ./#serenity --log-format internal-json -v |& nom --json
