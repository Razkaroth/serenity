{ pkgs }:
pkgs.writeShellScriptBin "hm-mutable-copy" ''
  set -euo pipefail

  mode="$1"
  source="$2"
  target="$3"

  copy_all() {
    rm -rf "$target"
    mkdir -p "$(dirname "$target")"

    if [ -d "$source" ]; then
      mkdir -p "$target"
      cp -a "$source/." "$target/"
    else
      cp -a "$source" "$target"
    fi
  }

  merge_missing() {
    if [ ! -e "$target" ]; then
      copy_all
    elif [ -d "$source" ] && [ -d "$target" ]; then
      cp -a --no-clobber "$source/." "$target/"
    fi
  }

  case "$mode" in
    reset)
      copy_all
      ;;
    merge)
      merge_missing
      ;;
    *)
      echo "Unknown mutable copy mode: $mode" >&2
      exit 2
      ;;
  esac

  chmod -R u+w "$target"
''
