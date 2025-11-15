{ pkgs, config, lib, modulesPath, ... }:
{

  # hydenix home-manager options go here
  hydenix.hm = {
    #! Important options
    enable = false;
    comma.enable = true; # useful nix tool to run software without installing it first
    dolphin.enable = true; # file manager
    editors = {
      enable = true; # enable editors module
      # neovim.enable = true; # enable neovim module
      vscode = {
        enable = false; # enable vscode module
        wallbash = true; # enable wallbash extension for vscode
      };
      # vim.enable = true; # enable vim module
      default = "nvim"; # default text editor
    };
    fastfetch.enable = false; # fastfetch configuration
    git = {
      enable = true; # enable git module
      name = "razkaroth"; # git user name eg "John Doe"
      email = "rocker.ikaros@gmail.com"; # git user email eg "john.doe@example.com"
    };
    hyde.enable = false; # enable hyde module
    hyprland.enable = false; # enable hyprland module
    lockscreen = {
      enable = false; # enable lockscreen module
      hyprlock = false; # enable hyprlock lockscreen
      swaylock = false; # enable swaylock lockscreen
    };
    screenshots = {
      enable = true; # enable screenshots module
      grim.enable = true; # enable grim screenshot tool
      slurp.enable = true; # enable slurp region selection tool
    };
    #wallpapers.enable = true; # enable wallpapers module
    shell = {
      enable = false; # enable shell module
      zsh ={
        enable = true; # enable zsh shell
        configText = ''
            alias l='eza -lh --icons=auto' # long list
            alias ls='eza -1 --icons=auto' # short list
            alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
            alias ld='eza -lhD --icons=auto' # long list dirs
            alias lt='eza --icons=auto --tree' # list folder as tree
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

            # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
            alias mkdir='mkdir -p'

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

            if [ -n "$TMUX" ]; then                                                                               
              function refresh {                                                                                
                export $(tmux show-environment | grep "^KITTY_PID")
                export $(tmux show-environment | grep "^KITTY_LISTEN_ON")
              }                                                                                                 
            else                                                                                                  
              function refresh { }                                                                              
            fi
        '';
    }; # enable zsh shell
      #  configText = ""; # zsh config text
      bash.enable = false; # enable bash shell
      fish.enable = false; # enable fish shell
      pokego.enable = false; # enable Pokemon ASCII art scripts
    };
    # social = {
    #   enable = true; # enable social module
    #   # discord.enable = true; # enable discord module
    #   # webcord.enable = true; # enable webcord module
    #   vesktop.enable = true; # enable vesktop module
    # };
    spotify.enable = true; # enable spotify module
    theme = {
      enable = false; # enable theme module
      active = "Cat Latte";
      themes = [
        "Cat Latte"
        "Cosmic Blue"
      ]; # default enabled themes, full list in https://github.com/richen604/hydenix/tree/main/hydenix/sources/themes
    };
  };
}
