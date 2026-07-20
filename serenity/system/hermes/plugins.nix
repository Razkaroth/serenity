{ pkgs, ... }:

let
  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"
    cp ${./plugins/cartesia-tts/plugin.yaml} "$out/plugin.yaml"
    cp ${./plugins/cartesia-tts/__init__.py} "$out/__init__.py"
  '';
  googleMeetCustomPlugin = pkgs.runCommand "google-meet-custom" { } ''
    mkdir -p "$out"
    cp -r ${./plugins/google-meet-custom}/. "$out"
  '';
in
{
  services.hermes-agent = {
    extraPlugins = [
      cartesiaTtsPlugin
      googleMeetCustomPlugin
    ];

    settings.plugins.enabled = [
      "cartesia-tts"
      "google_meet"
    ];
  };
}
