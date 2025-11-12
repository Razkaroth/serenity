#!/run/current-system/sw/bin/sh

sudo echo "rebuilding ascence remotely"

# if [ "$1" != "-s" ]; then
#   sudo echo "removing *.nixbak files"
#
#   sudo find ~/ -name "*.nixbak" -type f -delete
# fi

# nixos-rebuild switch -p ascence --flake ./#ascence --target-host raz@ascence --build-host raz@ascence --sudo --ask-sudo-password --log-format internal-json -v |& nom --json
sudo nixos-rebuild switch -p ascence --flake ./#ascence 
