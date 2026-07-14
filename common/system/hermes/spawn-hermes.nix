{ pkgs, ... }:

let
  spawnHermes = pkgs.writeShellApplication {
    name = "hermes-spawn";
    runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.fzf ];
    text = ''
      set -euo pipefail

      envDir="''${HERMES_ENV_DIR:-$HOME/.config/hermes}"
      declare -a envFiles envKeys envLines additions removedKeys

      loadEnv() {
        local file=$1 line key
        envKeys=()
        envLines=()

        while IFS= read -r line || [ -n "$line" ]; do
          if [[ $line =~ ^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            key="''${BASH_REMATCH[2]}"
            envKeys+=("$key")
            envLines+=("$line")
          fi
        done < "$file"
      }

      selectFile() {
        local prompt=$1 allowNew=$2 choice name file
        envFiles=()
        for file in "$envDir"/.env*; do
          [ -f "$file" ] && envFiles+=("$file")
        done
        if [ "''${#envFiles[@]}" -eq 0 ]; then
          echo "No environment files in $envDir." >&2
          exit 1
        fi

        if [ "$allowNew" = true ]; then
          choice=$(printf '%s\n' "''${envFiles[@]}" "__new__" | fzf --prompt="$prompt")
          if [ "$choice" = "__new__" ]; then
            mapfile -t name < <(printf '\n' | fzf --print-query --phony --prompt="New target filename: ")
            choice="$envDir/''${name[0]:-}"
            if [[ ! $(basename "$choice") =~ ^\.env[.A-Za-z0-9_-]*$ ]]; then
              echo "Target filename must start with .env." >&2
              exit 1
            fi
          fi
        else
          choice=$(printf '%s\n' "''${envFiles[@]}" | fzf --prompt="$prompt")
        fi

        [ -n "$choice" ] || exit 0
        printf '%s\n' "$choice"
      }

      selectEntries() {
        local prompt=$1 selected entry id
        shift
        local -a keys=("$@") choices=()
        for id in "''${!keys[@]}"; do
          choices+=("$id"$'\t'"''${keys[$id]}")
        done
        selected=$(printf '%s\n' "''${choices[@]}" | fzf --multi --delimiter=$'\t' --with-nth=2.. --prompt="$prompt" || true)
        [ -n "$selected" ] || return 1
        while IFS= read -r entry; do
          id="''${entry%%$'\t'*}"
          [[ $id =~ ^[0-9]+$ ]] || continue
          printf '%s\n' "$id"
        done <<< "$selected"
      }

      confirmWrite() {
        local target=$1 action=$2 key
        shift 2
        echo
        echo "Planned $action in $target:"
        for key in "$@"; do
          echo "  $key"
        done
        read -r -p "Type REVIEW to continue: " answer
        [ "$answer" = REVIEW ] || exit 0
        read -r -p "Type $(basename "$target") to write: " answer
        [ "$answer" = "$(basename "$target")" ] || exit 0
      }

      writeTarget() {
        local target=$1 tmp line key skip
        tmp=$(mktemp "$(dirname "$target")/.hermes-spawn.XXXXXX")
        chmod 0600 "$tmp"

        if [ -f "$target" ]; then
          while IFS= read -r line || [ -n "$line" ]; do
            skip=false
            if [[ $line =~ ^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)= ]]; then
              key="''${BASH_REMATCH[2]}"
              for removed in "''${removedKeys[@]}"; do
                if [ "$key" = "$removed" ]; then
                  skip=true
                  break
                fi
              done
            fi
            [ "$skip" = true ] || printf '%s\n' "$line" >> "$tmp"
          done < "$target"
        fi

        for line in "''${additions[@]}"; do
          printf '%s\n' "$line" >> "$tmp"
        done
        mv "$tmp" "$target"
      }

      donor=$(selectFile "Donor env file: " false)
      target=$(selectFile "Target env file: " true)
      [ "$donor" != "$target" ] || {
        echo "Donor and target must differ." >&2
        exit 1
      }

      action=$(printf '%s\n' \
        "Copy selected donor variables" \
        "Append known variable" \
        "Append new variable" \
        "Cleanup selected target variables" \
        "Quit" | fzf --prompt="Action: ")

      additions=()
      removedKeys=()
      case $action in
        "Copy selected donor variables")
          loadEnv "$donor"
          mapfile -t selected < <(selectEntries "Copy variables: " "''${envKeys[@]}" || true)
          [ "''${#selected[@]}" -gt 0 ] || exit 0
          declare -a selectedKeys
          selectedKeys=()
          for id in "''${selected[@]}"; do
            additions+=("''${envLines[$id]}")
            selectedKeys+=("''${envKeys[$id]}")
          done
          confirmWrite "$target" "append" "''${selectedKeys[@]}"
          ;;
        "Append known variable")
          declare -a knownKeys knownLines knownFiles choices
          knownKeys=()
          knownLines=()
          knownFiles=()
          for file in "''${envFiles[@]}"; do
            [ "$file" = "$target" ] && continue
            loadEnv "$file"
            for id in "''${!envKeys[@]}"; do
              knownKeys+=("''${envKeys[$id]}")
              knownLines+=("''${envLines[$id]}")
              knownFiles+=("$(basename "$file")")
            done
          done
          choices=()
          for id in "''${!knownKeys[@]}"; do
            choices+=("$id"$'\t'"''${knownKeys[$id]} from ''${knownFiles[$id]}")
          done
          knownSelection=$(printf '%s\n' "''${choices[@]}" | fzf --delimiter=$'\t' --with-nth=2.. --prompt="Known variable: " || true)
          [ -n "$knownSelection" ] || exit 0
          id="''${knownSelection%%$'\t'*}"
          [[ $id =~ ^[0-9]+$ ]] || {
            echo "Invalid known-variable selection." >&2
            exit 1
          }
          additions=("''${knownLines[$id]}")
          confirmWrite "$target" "append" "''${knownKeys[$id]}"
          ;;
        "Append new variable")
          mapfile -t name < <(printf '\n' | fzf --print-query --phony --prompt="Variable name: ")
          key="''${name[0]:-}"
          [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
            echo "Invalid variable name." >&2
            exit 1
          }
          read -r -s -p "Value for $key: " value
          echo
          additions=("$key=$value")
          confirmWrite "$target" "append" "$key"
          ;;
        "Cleanup selected target variables")
          [ -f "$target" ] || {
            echo "Target does not exist yet." >&2
            exit 1
          }
          loadEnv "$target"
          mapfile -t removedKeys < <(selectEntries "Remove variables: " "''${envKeys[@]}" || true)
          [ "''${#removedKeys[@]}" -gt 0 ] || exit 0
          confirmWrite "$target" "remove" "''${removedKeys[@]}"
          ;;
        *) exit 0 ;;
      esac

      writeTarget "$target"
      echo "Updated $target."
    '';
  };
in
{
  environment.systemPackages = [ spawnHermes ];
}
