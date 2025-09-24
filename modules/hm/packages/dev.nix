{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --------------------------------------------------- // Software Development

    # k8s
    kubectl
    lens
    kubernetes-helm

    #Cloud
    doctl

    # Boot.dev
    bootdev-cli
    # Tools

    aria2
    bat
    btop
    anydesk
    fd
    ripgrep
    fzf
    socat
    ffmpeg
    docker-compose
    jq
    git-lfs
    lazygit
    github-cli
    jetbrains-toolbox
    code-cursor
    postman
    insomnia
    pandoc
    speedtest-cli
    stripe-cli
    tree-sitter
    zoxide
    uutils-coreutils-noprefix

    #DB
    sqlite
    sqlitebrowser
    mongodb-compass
    mongodb-tools


    # langs
    nodejs
    corepack
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
    neofetch
    
  ];
}
