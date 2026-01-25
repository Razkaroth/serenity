{ pkgs, config, lib, osConfig, ... }:
let
  hostname = osConfig.networking.hostName;
  isAscension = hostname == "ascension";
  isSerenity = hostname == "serenity";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = false;
    };
    initContent = ''
      # Load Caelestia terminal colors if available
      cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

      # Helpful aliases
      alias c='clear' # clear terminal
      alias l='eza -lh --icons=auto' # long list
      alias ls='eza -1 --icons=auto' # short list
      alias la='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
      alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
      alias ld='eza -lhD --icons=auto' # long list dirs
      alias lt='eza --icons=auto --tree' # list folder as tree
      alias vc='code' # gui code editor
      alias nc='~/.config/nvchad/kitty.sh' # kitty wrapper for nvim
      alias n='~/.config/nvim/kitty.sh' # kitty wrapper for nvim
      alias ta='tmux attach'
      alias t='tmux new-session -A -s scratch'
      alias lz='lazygit'
      alias dcu='docker compose up'
      alias dcd='docker compose down'
      alias dcr='docker compose restart'

      # Directory navigation shortcuts
      alias ..='cd ..'
      alias ...='cd ../..'
      alias .3='cd ../../..'
      alias .4='cd ../../../..'
      alias .5='cd ../../../../..'

      # Always mkdir a path
      alias mkdir='mkdir -p'

      # Google calendar
      alias gcal='gcalcli'
      alias gcq='gcalcli --calendar rocker.ikaros@gmail.com quick'

      # Super touch command
      touch() {
        for f in "$@"; do
          if [[ "$f" == */ ]]; then
            mkdir -p "$f"
          else
            install -D /dev/null "$f"
          fi
        done
      }

      export PATH=$HOME/.local/bin:$PATH
      export PATH="/home/raz/.cache/.bun/bin:$PATH"
      export ZK_NOTEBOOK_DIR="$HOME/vaults/codex-astartes/"
      
      eval "$(zoxide init zsh)"
      eval "$(direnv hook zsh)"

      if [ -n "$TMUX" ]; then                                                                               
        function refresh {                                                                                
          export $(tmux show-environment | grep "^KITTY_PID")
          export $(tmux show-environment | grep "^KITTY_LISTEN_ON")
          clear
        }                                                                                                 
      else                                                                                                  
        function refresh { }                                                                              
      fi

      # --- Host Specific Configuration ---

      ${lib.optionalString isAscension ''
      alias ascension='cd /home/raz/ascension && n'
      alias ascend='~/ascension/rebuild-ascension.sh'
      alias codex='cd /home/raz/vaults/codex-astartes/ && n'

      alias sshS='ssh raz@serenity'
      
      enterSerenity() {
        echo "Entering serenity..."
        echo "Mounting serenity root..."
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@serenity:/ /serenity/root
        echo "Mounting serenity home..."
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@serenity:/home/raz /serenity/home
      }

      exitSerenity() {
        echo "Unmounting serenity root..."
        fusermount -u /serenity/root
        echo "Unmounting serenity home..."
        fusermount -u /serenity/home
        echo "Exiting serenity..."
      }
      ''}

      ${lib.optionalString isSerenity ''
      alias ascend='~/ascension/rebuild.sh'
      
      alias sshA='ssh raz@ascension'

      enterAscension() {
        echo "Entering ascension..."
        echo "Mounting ascension root..."
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@ascension:/ /ascension/root
        echo "Mounting ascension home..."
        sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 raz@ascension:/home/raz /ascension/home
      }

      exitAscension() {
        echo "Unmounting ascension root..."
        fusermount -u /ascension/root
        echo "Unmounting ascension home..."
        fusermount -u /ascension/home
        echo "Exiting ascension..."
      }
      ''}
    '';
  };
}
