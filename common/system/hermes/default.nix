{ pkgs, ... }:

let
  pythonPackages = pkgs.python312Packages;

  replacePythonPackage = pname: replacement: packages:
    builtins.map (package:
      if (package.pname or null) == pname then replacement else package
    ) packages;

  pythonDependencies = old: old.propagatedBuildInputs or old.dependencies or [ ];

  einopsNoCheck = pythonPackages.einops.overridePythonAttrs (_old: {
    doCheck = false;
    doInstallCheck = false;
    nativeCheckInputs = [ ];
  });

  hyperConnectionsNoCheck = pythonPackages.hyper-connections.overridePythonAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
    nativeCheckInputs = [ ];
    dependencies = replacePythonPackage "einops" einopsNoCheck (pythonDependencies old);
    propagatedBuildInputs = replacePythonPackage "einops" einopsNoCheck (pythonDependencies old);
  });

  localAttentionNoCheck = pythonPackages.local-attention.overridePythonAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
    nativeCheckInputs = [ ];
    dependencies = replacePythonPackage "hyper-connections" hyperConnectionsNoCheck (
      replacePythonPackage "einops" einopsNoCheck (pythonDependencies old)
    );
    propagatedBuildInputs = replacePythonPackage "hyper-connections" hyperConnectionsNoCheck (
      replacePythonPackage "einops" einopsNoCheck (pythonDependencies old)
    );
  });

  cartesiaTtsPlugin = pkgs.runCommand "cartesia-tts" { } ''
    mkdir -p "$out"
    cp ${./plugins/cartesia-tts/plugin.yaml} "$out/plugin.yaml"
    cp ${./plugins/cartesia-tts/__init__.py} "$out/__init__.py"
  '';

  vectorQuantizePytorch = pythonPackages.buildPythonPackage rec {
    pname = "vector-quantize-pytorch";
    version = "1.17.8";
    format = "wheel";
    dontBuild = true;

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/fb/2e/58e1dae68baea6e55caf78be53b0d6fb3ff800f70df950a3a1462242cbbd/vector_quantize_pytorch-${version}-py3-none-any.whl";
      hash = "sha256-Y/2GtdlRqOfctwtJmormhKUewFpP/o8sCRLBr0hIrng=";
    };

    propagatedBuildInputs = with pythonPackages; [
      einopsNoCheck
      einx
      torch
    ];

    doCheck = false;
  };

  resemblePerth = pythonPackages.buildPythonPackage rec {
    pname = "resemble-perth";
    version = "1.0.1";
    format = "wheel";
    dontBuild = true;

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/77/cc/73226dd776f8e9c2975f64f4efc22988fb37e5b185ba5cccd6f2e7196954/resemble_perth-${version}-py3-none-any.whl";
      hash = "sha256-ZenDdTGxoSikpWImt13s5FIWg882EbCypf/iNPAMk0I=";
    };

    propagatedBuildInputs = with pythonPackages; [
      librosa
      numpy
      soundfile
      torch
    ];

    doCheck = false;
  };

  neucodec = pythonPackages.buildPythonPackage rec {
    pname = "neucodec";
    version = "0.0.4";
    format = "wheel";
    dontBuild = true;
    pythonRemoveDeps = [ "torchtune" ];
    nativeBuildInputs = [ pythonPackages.pythonRelaxDepsHook ];

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/54/3e/af493b15fd54da38cc32e9b8f0979b73c11290ef4674c180427232b509d6/neucodec-${version}-py3-none-any.whl";
      hash = "sha256-nHydN02eqSsgaZU5BlcMdIvrlelp5ALGxqR/iO1sF/Q=";
    };

    propagatedBuildInputs = with pythonPackages; [
      librosa
      localAttentionNoCheck
      numpy
      torch
      torchaudio
      torchao
      transformers
      vectorQuantizePytorch
    ];

    doCheck = false;
  };

  neutts = pythonPackages.buildPythonPackage rec {
    pname = "neutts";
    version = "1.2.1";
    format = "wheel";
    dontBuild = true;

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/eb/a5/c029b77ad4d35b61df0541dda418a10e201fb7667a9c8d7d1842e0f14799/neutts-${version}-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-+XyrmoUTbw9AOoJC6DL6NXmxDYQKiqxRS4pFBcUKzg8=";
    };

    propagatedBuildInputs = with pythonPackages; [
      librosa
      llama-cpp-python
      neucodec
      numpy
      onnxruntime
      phonemizer
      resemblePerth
      soundfile
      torch
      transformers
    ];

    doCheck = false;
  };

  neuttsRefText = pkgs.writeText "neutts-reference-text.txt" ''
    Morning. Four tasks: finish the landing page by end of day, review the Márquez contract, fix nexus permissions, renew the SSL cert. Meeting at 2 PM with design. Saturday is Emilio's thing — bring food. And no, the contract review can't move to tomorrow. It's been sitting since Monday and Márquez is waiting.
  '';
in
{
  security.sudo.extraRules = [
    {
      users = [ "raz" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/docker";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    container = {
      enable = true;
      backend = "docker";
      hostUsers = [ "raz" ];
      extraVolumes = [
        "/home/raz/.agents:/home/raz/.agents:rw"
        "/home/raz/nexus:/home/raz/nexus:rw"
      ];
    };

    extraPlugins = [
      cartesiaTtsPlugin
    ];

    environmentFiles = [
      "/home/raz/.config/hermes/hermes.env"
    ];

    settings = {
      plugins.enabled = [
        "cartesia-tts"
      ];

      custom_providers = [
        {
          name = "opencode-go";
          base_url = "https://opencode.ai/zen/go/v1";
          key_env = "OPENCODE_API_KEY";
        }
      ];

      model = {
        provider = "custom:opencode-go";
        default = "deepseek-v4-pro";
      };

      toolsets = [ "all" ];

      discord = {
        reply_to_mode = "off";
      };

      tts = {
        provider = "neutts";
        neutts = {
          ref_audio = "/data/.hermes/tts/voice-message.wav";
          ref_text = "${neuttsRefText}";
          model = "neuphonic/neutts-air-q4-gguf";
          device = "cpu";
        };
      };

      terminal = {
        backend = "local";
        timeout = 180;
      };

      compression = {
        enabled = true;
        threshold = 0.85;
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    extraPackages = with pkgs; [
      bashInteractive
      coreutils
      curl
      espeak-ng
      ffmpeg
      git
      nodejs_22
      ripgrep
      uv
    ];

    extraPythonPackages = [
      neutts
    ];
  };

  # Hermes hardens its env/auth parent with chmod 0700 at startup, but the NixOS
  # module exposes that state to hostUsers via ~/.hermes -> /var/lib/hermes/.hermes.
  # Restore group traversal after service start so raz can run the host CLI.
  systemd.services.hermes-agent.postStart = ''
    sleep 2
    chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes
    chown hermes:hermes /var/lib/hermes /var/lib/hermes/.hermes
  '';

}
