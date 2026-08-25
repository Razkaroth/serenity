{ ... }:
{
  imports = [
    ../common/hm/modules/mutable-files.nix
    ../common/hm/programs/git.nix
    ../common/hm/programs/zsh.nix
    ../common/hm/programs/starship.nix
    ../common/hm/programs/direnv.nix
    ../common/hm/programs/pass.nix
    ../common/hm/programs/vscode.nix
    ../common/hm/programs/herdr.nix
    ../common/hm/packages/cli.nix
    ../common/hm/packages/dev-cli.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.file.".config/herdr/config.toml" = {
    mutable = false;
    mutablePersist = true;
  };
}
