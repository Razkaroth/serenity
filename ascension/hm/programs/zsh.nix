{
  ...
}:
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
      # Helpful aliases
      alias c='clear' # clear terminal
      alias l='eza -lh --icons=auto' # long list
      alias ls='eza -1 --icons=auto' # short list
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

      # Google calendar
      alias gcal='gcalcli'
      alias gcq='gcalcli --calendar rocker.ikaros@gmail.com quick'
      

      # Directory navigation shortcuts
      alias ..='cd ..'
      alias ...='cd ../..'
      alias .3='cd ../../..'
      alias .4='cd ../../../..'
      alias .5='cd ../../../../..'

      # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
      alias mkdir='mkdir -p'

      # Google calendar
      alias gcal='gcalcli'
      alias gcq='gcalcli --calendar rocker.ikaros@gmail.com quick'

      alias ascension='cd /home/raz/ascension && n'
      alias ascend='~/ascension/rebuild-ascension.sh'

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


      # a super touch command
      touch() {
        for f in "$@"; do
          if [[ "$f" == */ ]]; then
            # Ends with a slash → make directory
            mkdir -p "$f"
          else
            # Otherwise → make file (with parent dirs)
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

    '';
  };
}
