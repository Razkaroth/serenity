#!/run/current-system/sw/bin/sh

sudo echo "Initializing Ascension"

sudo nixos-rebuild switch -p ascension --flake ./#ascension --log-format internal-json -v |& nom --json

hyprctl reload

sleep 3

hyprctl reload

notify-send "Ascension" "System has ascended to new heights"
