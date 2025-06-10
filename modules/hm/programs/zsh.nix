{
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
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
      alias n='~/.config/nvchad/kitty.sh' # kitty wrapper for nvim
      alias nl='~/.config/nvim/kitty.sh' # kitty wrapper for nvim
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

      # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
      alias mkdir='mkdir -p'


      export PATH=$HOME/.local/bin:$PATH
      eval "$(zoxide init zsh)"
      eval $(thefuck --alias)

      if [ -n "$TMUX" ]; then                                                                               
        function refresh {                                                                                
          export $(tmux show-environment | grep "^KITTY_PID")
          export $(tmux show-environment | grep "^KITTY_LISTEN_ON")
        }                                                                                                 
      else                                                                                                  
        function refresh { }                                                                              
      fi

    '';
  };
}
