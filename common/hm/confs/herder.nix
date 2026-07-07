{ ... }:
{
  home.file.".config/herdr/config.toml" = {
    source = ./herdr/config.toml;
    mutable = true;
    force = true;
  };
}
