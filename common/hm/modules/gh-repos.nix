{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gh-repos;

  repoOption = types.submodule {
    options = {
  repo = mkOption {
    type = types.str;
    description = "Repository to clone (e.g. 'git@github.com:owner/repo.git')";
  };
      path = mkOption {
        type = types.str;
        description = "Target path (relative to $HOME if not absolute)";
      };
    };
  };

in {
  options.programs.gh-repos = {
    enable = mkEnableOption "GitHub repository cloning command";

    repositories = mkOption {
      type = types.listOf repoOption;
      default = [];
      description = "List of repositories to clone";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "repoSync" ''
        export PATH="${lib.makeBinPath [ pkgs.git pkgs.openssh ]}:$PATH"

        ${concatMapStringsSep "\n" (repo: ''
          REPO="${repo.repo}"
          TARGET="${repo.path}"

          if [[ "$REPO" != *"@"* ]]; then
            echo "Skipping $REPO: not a git@ SSH URL."
            continue
          fi

          if [[ "$TARGET" != /* ]]; then
            TARGET="$HOME/$TARGET"
          fi

          if [ ! -d "$TARGET" ]; then
            echo "Cloning $REPO into $TARGET..."
            mkdir -p "$(dirname "$TARGET")"
            git clone "$REPO" "$TARGET"
          else
            echo "Repository $REPO already exists at $TARGET. Skipping."
          fi
        '') cfg.repositories}
      '')
    ];
  };
}
