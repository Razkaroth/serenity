{ pkgs, ... }:

let
  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"
    cp ${./plugins/cartesia-tts/plugin.yaml} "$out/plugin.yaml"
    cp ${./plugins/cartesia-tts/__init__.py} "$out/__init__.py"
  '';
in
{
  services.hermes-agent = {
    extraPlugins = [
      cartesiaTtsPlugin
    ];

    settings.plugins.enabled = [
      "cartesia-tts"
    ];
  };
}
