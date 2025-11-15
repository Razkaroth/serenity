#!/run/current-system/sw/bin/sh

sudo echo "Ascending..."
sleep 1
echo "Rebuilding..."

if [ "$1" != "-s" ]; then
  sudo echo "removing *.nixbak files"

  sudo find ~/ -name "*.nixbak" -type f -delete
fi

sudo nixos-rebuild switch -p ascension --flake ./#ascension --log-format internal-json -v |& nom --json
