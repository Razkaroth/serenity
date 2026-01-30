{ ... }:
{
  programs.gh-repos = {
    enable = true;
    repositories = [
      {
        repo = "git@github.com:Razkaroth/opencode-config.git";
        path = ".config/opencode";
      }
      {
        repo = "git@github.com:Razkaroth/lazychad.git";
        path = ".config/nvim";
      }
      # Work repos
      {
        repo = "git@github.com:nordic-rune/rune-forge.git";
        path = "k/n/fg/dev";
      }
      {
        repo = "git@github.com:nordic-rune/reportes-silenciados.git";         
        path = "k/n/rs/dev/";
      }
      {
        repo = "git@github.com:nordic-rune/pinnataparty.git";
        path = "k/n/pp/dev";
      }
    ];
  };
}
