#!/run/current-system/sw/bin/sh

sudo echo "rebuilding system"

if [ "$1" != "-s" ]; then
    sudo echo "removing *.nixbak files"

    sudo find ~/ -name "*.nixbak" -type f -delete
fi

sudo nixos-rebuild switch -p solitude --flake ./#serenity --log-format internal-json -v |& nom --json
