{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [
    git-lfs
  ];
  edgePkgs = with pkgs-edge; [
    # --------------------------------------------------- // Software Development

    antigravity-fhs

    # k8s
    kubectl
    lens
    kubernetes-helm

    #Cloud
    doctl
    ngrok

    # Boot.dev
    bootdev-cli

    # AI
    lmstudio
    n8n

    # Tools
    aria2
    bat
    btop
    curl
    anydesk
    fd
    ripgrep
    lsof
    fzf
    socat
    ffmpeg
    docker-compose
    process-compose
    jq
    lazygit
    github-cli
    jetbrains-toolbox
    code-cursor
    postman
    insomnia
    pandoc
    speedtest-cli
    stripe-cli
    sshfs
    tree-sitter
    tree
    zoxide
    uutils-coreutils-noprefix

    #DB
    sqlite
    sqlitebrowser
    mongodb-compass
    mongodb-tools


    # langs
    nodejs
    # corepack
    gjs
    bun
    cargo
    uv
    go
    gcc
    gnumake
    cmakeMinimal
    typescript
    eslint
    # very important stuff
    neovim
    neofetch
    
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
