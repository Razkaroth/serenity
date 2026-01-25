{ pkgs, ... }:
let

  # tmux-which-key = pkgs.tmuxPlugins.mkTmuxPlugin
  #   {
  #     pluginName = "tmux-which-key";
  #     version = "main-2024-05-09";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "alexwforsythe";
  #       repo = "tmux-which-key/";
  #       rev = "57220071739c723c3a318e9d529d3e5045f503b8";
  #       sha256 = "sha256-zpg7XJky7PRa5sC7sPRsU2ZOjj0wcepITLAelPjEkSI=";
  #     };
  #   };
  #
  tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-super-fingers";
    version = "unstable-2023-01-06";
    src = pkgs.fetchFromGitHub {
      owner = "artemave";
      repo = "tmux_super_fingers";
      rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
      sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
    };
  };
  usr = "raz";
  resurrectDirPath = "/home/${usr}/.tmux/resurrect";
in {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "kitty";
    sensibleOnTop = true;

    baseIndex = 1;
    prefix = "M-s";

    extraConfig = ''

 # Fix for terminal transparency with Kitty
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ',xterm*:Tc:sitm=\E[3m'
      set -as terminal-features ",xterm-256color:RGB"
      
      # CRITICAL: These settings fix the transparency issue
      set -g status-style "bg=default,fg=default"
      set -g window-style "bg=default"
      set -g window-active-style "bg=default"
      
      # Allow passthrough for kitty
      set -gq allow-passthrough on
      
      # Update environment variables for Kitty integration
      set -g update-environment "DISPLAY KITTY_PID KITTY_LISTEN_ON"

      # exec-once = tmux setenv -g HYPRLAND_INSTANCE_SIGNATURE "$HYPRLAND_INSTANCE_SIGNATURE"
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"
      # tmux-sensible
      set -g mouse on
      # open panes in current directory
      bind '"' split-window -c '#{pane_current_path}'
      bind % split-window -h -c '#{pane_current_path}'

      set -g update-environment "DISPLAY KITTY_PID KITTY_LISTEN_ON"

      # window rezise with arrow keys
      bind -n M-Up resize-pane -U 5
      bind -n M-Down resize-pane -D 5
      bind -n M-Left resize-pane -L 5
      bind -n M-Right resize-pane -R 5

      # bind a to create a new window and A to create a new session
      bind a new-window
      bind A new-session
    '';

    plugins = with pkgs; [
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.better-mouse-mode
      {
        plugin = tmux-super-fingers;
        extraConfig = "set -g @super-fingers-key f";
      }
      {
        plugin = tmuxPlugins.power-theme;
        extraConfig = ''
          # Theme
          set -g @tmux_power_theme 'snow'
          # 'L' for left only, 'R' for right only and 'LR' for both
          set -g @tmux_power_prefix_highlight_pos 'LR'
          # set -g status-right '𒀪: #{continuum_status}'
            # set -g status-style "bg=terminal,fg=terminal" 
        '';
      }
      tmuxPlugins.prefix-highlight
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-vim 'session'
             set -g @resurrect-strategy-nvim 'session'

             set -g @resurrect-capture-pane-contents 'on'

             set -g @resurrect-dir ${resurrectDirPath}
             set -g @resurrect-hook-post-save-all 'sed "s| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/${usr}/bin/||g; s|/home/${usr}/.nix-profile/bin/||g" ${resurrectDirPath}/last | sponge ${resurrectDirPath}/last'        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '1'
        '';
      }
    ];

  };
}
