{ ... }:
{
  programs.gh-repos = {
    enable = true;
    repositories = [
      {
        repo = "Razkaroth/opencode-config";
        path = ".config/opencode";
      }
      {
        repo = "Razkaroth/lazychad";
        path = ".config/nvim";
      }
      # Work repos
      {
        repo = "nordic-rune/starter";
        path = "jale/nordic-rune/starter";
      }
    ];
  };
}
