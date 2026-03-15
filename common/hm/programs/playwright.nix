{ config, pkgs, ... }:

let
  browsers =
    (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;

  chromiumRev =
    (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;

  pwBrowsers = pkgs.playwright-driver.browsers;
  chromiumExe =
    let
      p64 = "${pwBrowsers}/chromium-${chromiumRev}/chrome-linux64/chrome";
      p32 = "${pwBrowsers}/chromium-${chromiumRev}/chrome-linux/chrome";
    in
      if builtins.pathExists p64 then p64 else p32;

  # Keeps the npm package tied to the Playwright version shipped by nixpkgs.
  pwVersion = pkgs.playwright-driver.version;
in
{
  home.packages = with pkgs; [
    bun
    playwright-driver.browsers

    (writeShellScriptBin "playwright" ''
      set -euo pipefail

      export PLAYWRIGHT_BROWSERS_PATH="${pwBrowsers}"
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
      export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH="${chromiumExe}"

      exec ${pkgs.bun}/bin/bunx playwright@${pwVersion} "$@"
    '')

    (writeShellScriptBin "playwright-mcp" ''
      set -euo pipefail

      export PLAYWRIGHT_BROWSERS_PATH="${pwBrowsers}"
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
      export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH="${chromiumExe}"

      cfg="$(mktemp)"
      trap 'rm -f "$cfg"' EXIT

      cat > "$cfg" <<EOF
{
  "browser": {
    "browserName": "chromium",
    "isolated": true,
    "launchOptions": {
      "headless": true,
      "executablePath": "${chromiumExe}"
    }
  }
}
EOF

      exec ${pkgs.bun}/bin/bunx @playwright/mcp@0.0.68 --config "$cfg" "$@"
    '')
  ];
}
