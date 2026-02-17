{ pkgs, pkgs-edge, ... }:
let
  stablePkgs = with pkgs; [
    git-lfs


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
    just
    bun
    cargo
    uv
    python3
    go
    gcc
    gnumake
    cmakeMinimal
    typescript
    eslint
    # very important stuff
    neofetch
  ];
  edgePkgs = with pkgs-edge; [
    
    github-cli
    jetbrains-toolbox
    neovim
    
  ];
in
{
  home.packages = stablePkgs ++ edgePkgs;
}
