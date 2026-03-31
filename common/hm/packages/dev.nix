{ pkgs, pkgs-edge, inputs, ... }:
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

    # Docmunents
    websocat
    tinymist

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
    typst
    zoxide
    uutils-coreutils-noprefix

    #DB
    sqlite
    sqlitebrowser
    mongodb-compass
    mongodb-tools

    inputs.spacetimedb.packages.${pkgs.system}.default

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
