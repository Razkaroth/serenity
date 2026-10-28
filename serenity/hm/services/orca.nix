# Headless Orca runtime server (stablyai/orca) for serenity.
#
# Runs as a systemd *user* service under raz's user manager (linger is enabled
# in serenity/configuration.nix), so Orca and everything it spawns inherits the
# real user environment: XDG_RUNTIME_DIR=/run/user/1000, the user PATH,
# rootless Docker (DOCKER_HOST derives from XDG_RUNTIME_DIR in /etc/profile),
# D-Bus/pipewire, and the user's files/permissions.
#
# The nix package (numtide/llm-agents.nix) ships a wrapper with git/xclip/
# xdg-utils/xdotool/xvfb/xvfb-run on PATH, so `orca serve` has everything the
# computer-use surface shells out to.
#
# Orca's own auto-Xvfb path crashed the Electron GPU process here, so we own
# the virtual display as a second user unit (guide's "Managed Xvfb Service").
{ pkgs, inputs, ... }:

let
  # Advertised to clients only; the listener still binds 0.0.0.0. This is
  # serenity's Tailscale IPv4, which zenith dials over tailscale0.
  tailscaleAddress = "100.104.2.6";

  display = ":99";

  orca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
in
{
  systemd.user.services.orca-xvfb = {
    Unit = {
      Description = "Virtual X display for Orca";
    };
    Service = {
      ExecStart = "${pkgs.xvfb}/bin/Xvfb ${display} -screen 0 1920x1080x24 -nolisten tcp -ac";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.orca-serve = {
    Unit = {
      Description = "Orca runtime server";
      After = [ "orca-xvfb.service" ];
      Wants = [ "orca-xvfb.service" ];
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      WorkingDirectory = "%h";
      # XDG_RUNTIME_DIR/HOME/PATH come from the user manager; do not override.
      Environment = [
        "DISPLAY=${display}"
        # No GPU under Xvfb; force software GL so Chromium does not try the
        # NVIDIA driver and abort.
        "LIBGL_ALWAYS_SOFTWARE=1"
      ];
      ExecStart = "${orca}/bin/orca serve --port 6768 --pairing-address ${tailscaleAddress} --json";
      # Graceful stop hits only the main process, keeping Orca's children
      # alive long enough to disconnect cleanly before systemd SIGKILLs the cgroup.
      KillMode = "mixed";
      Restart = "on-failure";
      # Exit 3 = another process owns this userData profile; do not retry.
      RestartPreventExitStatus = 3;
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # tailscale0 is already a trusted interface (common/system/tailscale.nix),
  # so 6768 is reachable from zenith without opening it to the LAN.
}
