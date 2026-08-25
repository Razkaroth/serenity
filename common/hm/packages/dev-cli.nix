{
  inputs,
  pkgs,
  pkgs-edge,
  ...
}:
{
  home.packages = with pkgs; [
    git-lfs
    kubectl
    kubernetes-helm
    doctl
    ngrok
    bootdev-cli
    n8n
    inputs.beads.packages.${pkgs.stdenv.hostPlatform.system}.default
    (inputs.bead-me-up-scotty.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        npmDeps = pkgs.fetchNpmDeps {
          inherit (oldAttrs) src;
          hash = "sha256-cSl80FcI6+8dp5r6jr8mTbCtBqGXqS6+i7aW/AHaMSo=";
        };
        npmFlags = [ "--ignore-scripts" ];
      })
    )
    websocat
    tinymist
    docker-compose
    process-compose
    sqlite
    mongodb-tools
    inputs.spacetimedb.packages.${pkgs.stdenv.hostPlatform.system}.default
    nodejs
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
    pkgs-edge.github-cli
    pkgs-edge.neovim
  ];
}
