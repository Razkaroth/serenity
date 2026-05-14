{ pkgs, ... }:
let
  nvidiaOffloadEnv = ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export GAMESCOPE_VULKAN_DISPLAY_INDEX=1
  '';

  gs-sdr-internal = pkgs.writeShellScriptBin "gs-sdr-internal" ''
    ${nvidiaOffloadEnv}

    exec gamescope \
      -w 2880 -h 1800 \
      -W 2880 -H 1800 \
      -r 120 \
      --adaptive-sync \
      --mangoapp \
      -f \
      -- "$@"
  '';

  gs-sdr-external = pkgs.writeShellScriptBin "gs-sdr-external" ''
    ${nvidiaOffloadEnv}

    exec gamescope \
      -w 2560 -h 1080 \
      -W 2560 -H 1080 \
      -r 60 \
      --mangoapp \
      -f \
      -- "$@"
  '';

  gs-hdr-internal = pkgs.writeShellScriptBin "gs-hdr-internal" ''
    ${nvidiaOffloadEnv}
    export ENABLE_HDR_WSI=1
    export DXVK_HDR=1
    export PROTON_ENABLE_HDR=1

    exec gamescope \
      -w 2880 -h 1800 \
      -W 2880 -H 1800 \
      -r 120 \
      --adaptive-sync \
      --hdr-enabled \
      --mangoapp \
      -f \
      -- "$@"
  '';
in
{
  environment.systemPackages = [
    gs-sdr-internal
    gs-sdr-external
    gs-hdr-internal
  ];
}
