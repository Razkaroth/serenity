{ pkgs, ... }:

let
  xclip = pkgs.writeShellScriptBin "xclip" ''
    set -euo pipefail

    mode="copy" # copy|paste
    selection="clipboard" # clipboard|primary
    trimNewline=0
    mimeType=""
    seat=""

    usage() {
      cat <<'EOF'
    xclip (Wayland wrapper)

    This is a small compatibility wrapper that maps common xclip usages to wl-copy/wl-paste.

    Supported flags (subset):
      -i, -in                 Copy (default)
      -o, -out                Paste
      -selection, -sel <name> selection: clipboard|primary
      -rmlastnl, -n           Trim trailing newline when copying
      -t <mime/type>          Override MIME type
      -s <seat-name>          Pick a seat

    Examples:
      printf 'hi' | xclip -selection clipboard
      xclip -o -selection clipboard
    EOF
    }

    while [ "$#" -gt 0 ]; do
      case "$1" in
        -i|-in)
          mode="copy"
          shift
          ;;
        -o|-out)
          mode="paste"
          shift
          ;;
        -selection|-sel)
          selection="''${2:-}"
          shift 2
          ;;
        -rmlastnl|-n)
          trimNewline=1
          shift
          ;;
        -t|-type)
          mimeType="''${2:-}"
          shift 2
          ;;
        -s|-seat)
          seat="''${2:-}"
          shift 2
          ;;
        -quiet|-q)
          shift
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        --)
          shift
          break
          ;;
        -* )
          echo "xclip wrapper: unsupported option: $1" >&2
          echo "Run: xclip --help" >&2
          exit 2
          ;;
        *)
          break
          ;;
      esac
    done

    primaryFlag=()
    case "''${selection,,}" in
      primary)
        primaryFlag=(-p)
        ;;
      clipboard|"" )
        primaryFlag=()
        ;;
      *)
        echo "xclip wrapper: unsupported -selection '$selection' (supported: clipboard|primary)" >&2
        exit 2
        ;;
    esac

    mimeFlag=()
    if [ -n "$mimeType" ]; then
      mimeFlag=(-t "$mimeType")
    fi

    seatFlag=()
    if [ -n "$seat" ]; then
      seatFlag=(-s "$seat")
    fi

    if [ "$mode" = "paste" ]; then
      if [ "$#" -ne 0 ]; then
        echo "xclip wrapper: unexpected arguments for paste: $*" >&2
        exit 2
      fi

      # xclip prints the selection as-is; wl-paste appends a newline by default.
      exec ${pkgs."wl-clipboard"}/bin/wl-paste --no-newline "''${primaryFlag[@]}" "''${mimeFlag[@]}" "''${seatFlag[@]}"
    fi

    trimFlag=()
    if [ "$trimNewline" -eq 1 ]; then
      trimFlag=(-n)
    fi

    exec ${pkgs."wl-clipboard"}/bin/wl-copy "''${primaryFlag[@]}" "''${trimFlag[@]}" "''${mimeFlag[@]}" "''${seatFlag[@]}" "$@"
  '';
in
{
  imports = [
    ../../common/system
    ./hyprland.nix
    ./audio.nix
    ./gaming.nix
  ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.tree-sitter
    pkgs.zip
    pkgs.unzip
    pkgs.nix-output-monitor
    pkgs.vial
    pkgs.nerd-fonts.caskaydia-cove
    pkgs.nerd-fonts.caskaydia-mono
    pkgs.nerd-fonts.iosevka
    pkgs.nerd-fonts.iosevka-term-slab
    pkgs.nerd-fonts.iosevka-term
    pkgs."wl-clipboard"
    xclip
  ];
}
