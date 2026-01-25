#!/run/current-system/sw/bin/sh

sudo echo "Initializing Ascension"

if [ "$1" != "-s" ]; then
  sudo echo "removing *.nixbak files"

  sudo find ~/ -name "*.nixbak" -type f -delete
fi

sudo nixos-rebuild switch -p ascension --flake ./#ascension --log-format internal-json -v |& nom --json

notify-send "Ascension" "System has ascended to new heights"
