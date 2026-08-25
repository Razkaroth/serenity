{ ... }:
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
      alias la='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
      alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
      alias ld='eza -lhD --icons=auto' # long list dirs
      alias lt='eza --icons=auto --tree' # list folder as tree
      alias vc='code' # gui code editor
      alias n='nvim'
      alias h='herdr'
      alias hs='herdr --remote raz@serenity'
      alias lz='lazygit'
      alias y='yazi'
      alias dcu='docker compose up'
      alias dcd='docker compose down'
      alias dcr='docker compose restart'

      # Directory navigation shortcuts
      alias ..='cd ..'
      alias .2='cd ../..'
      alias .3='cd ../../..'
      alias .4='cd ../../../..'
      alias .5='cd ../../../../..'

      # Always mkdir a path
      alias mkdir='mkdir -p'

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
      export PATH="$HOME/.cache/.bun/bin:$PATH"
      export PATH="$HOME/.bun/bin:$PATH"
      export PATH="$PATH:$HOME/go/bin"
      export ZK_NOTEBOOK_DIR="$HOME/vaults/codex-astartes/"

      eval "$(zoxide init zsh)"
      eval "$(direnv hook zsh)"

    '';
  };
}
