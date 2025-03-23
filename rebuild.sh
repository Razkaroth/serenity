#!/run/current-system/sw/bin/sh

sudo echo "rebuilding system"

sudo nixos-rebuild switch -p solitude --flake ./#solitude --log-format internal-json -v |& nom --json
