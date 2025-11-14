{ pkgs, ... }:

let 

  insiders = (pkgs.vscode.override { 
    isInsiders = true;
    commandLineArgs = "--password-store='kwalletd6'";
  }).overrideAttrs (oldAttrs: rec {
  src = (builtins.fetchTarball {
    url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
    sha256 = "01ln0dv9f3dpvh9q2jplmjv8ldidpxgycl0k5nnrdkkzn28r60y2";
  });
  version = "latest";
  dontStrip = true;

  buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];
});

 in
{
  programs.vscode = {
    enable = true;
    # package = insiders.fhs;
  };
}
