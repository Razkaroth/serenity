{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gh-repos;

  repoOption = types.submodule {
    options = {
      repo = mkOption {
        type = types.str;
        description = "Repository to clone (e.g. 'owner/repo' or full URL)";
      };
      path = mkOption {
        type = types.str;
        description = "Target path (relative to $HOME if not absolute)";
      };
    };
  };

in {
  options.programs.gh-repos = {
    enable = mkEnableOption "Automatic GitHub repository cloning";

    repositories = mkOption {
      type = types.listOf repoOption;
      default = [];
      description = "List of repositories to clone";
    };
  };

  config = mkIf cfg.enable {
    home.activation.cloneGhRepos = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Ensure gh is available
      GH_BIN="${pkgs.github-cli}/bin/gh"
      
      # Check if we are inside a robust enough environment (PATH included git, ssh, etc)
      export PATH="${lib.makeBinPath [ pkgs.git pkgs.openssh ]}:$PATH"

      echo "Checking GitHub authentication status..."
      if $GH_BIN auth status 2>&1 | grep -q "Razkaroth"; then
        echo "GH Authenticated as Razkaroth."
        
        ${concatMapStringsSep "\n" (repo: ''
          REPO="${repo.repo}"
          TARGET="${repo.path}"
          
          # Resolve absolute path
          if [[ "$TARGET" != /* ]]; then
            TARGET="$HOME/$TARGET"
          fi
          
          if [ ! -d "$TARGET" ]; then
            echo "Cloning $REPO into $TARGET..."
            # Ensure parent directory exists
            mkdir -p "$(dirname "$TARGET")"
            
            # Run clone
            $GH_BIN repo clone "$REPO" "$TARGET"
          else
            echo "Repository $REPO already exists at $TARGET. Skipping."
          fi
        '') cfg.repositories}
        
      else
        echo "WARNING: GitHub CLI (gh) is not authenticated as 'Razkaroth'."
        echo "SKIPPING repository cloning."
        echo "Please run 'gh auth login' and then rebuild (or re-activate) to clone repositories."
      fi
    '';
  };
}
