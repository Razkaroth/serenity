{
  config,
  lib,
  pkgs,
  ...
}:
let
  mutableCopy = import ./mutable-copy.nix { inherit pkgs; };
  fileOptionAttrPaths = [
    [
      "home"
      "file"
    ]
    [
      "xdg"
      "configFile"
    ]
    [
      "xdg"
      "dataFile"
    ]
  ];

  mergeAttrsList = builtins.foldl' lib.mergeAttrs { };
  fileAttrsType = lib.types.attrsOf (
    lib.types.submodule {
      options = {
        mutable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Copy the declared source to a writable target after every activation.
            Local changes are reset by the next activation.
          '';
        };

        mutablePersist = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Keep existing writable content and merge newly declared missing paths
            after each activation.
          '';
        };
      };
    }
  );

  allFiles = builtins.concatLists (
    map (attrPath: builtins.attrValues (lib.getAttrFromPath attrPath config)) fileOptionAttrPaths
  );
  mutableFiles = lib.sortOn (file: builtins.stringLength file.target) (
    builtins.filter (file: (file.mutable or false) || (file.mutablePersist or false)) allFiles
  );
  persistentFiles = builtins.filter (file: file.mutablePersist or false) mutableFiles;
  resetFiles = builtins.filter (file: file.mutable or false) mutableFiles;

  targetPath =
    file:
    if lib.hasPrefix "/" file.target then
      file.target
    else
      "${config.home.homeDirectory}/${file.target}";

in
{
  options = mergeAttrsList (
    map (
      attrPath: lib.setAttrByPath attrPath (lib.mkOption { type = fileAttrsType; })
    ) fileOptionAttrPaths
  );

  config = {
    assertions = map (file: {
      assertion = file.force && !((file.mutable or false) && (file.mutablePersist or false));
      message = "Mutable file '${file.target}' must set force = true and choose only one mutable mode.";
    }) mutableFiles;

    home.activation.mutablePersistCapture = lib.mkIf (persistentFiles != [ ]) (
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] (
        ''
          mutablePersistBackup="$(mktemp -d)"
        ''
        + lib.concatImapStrings (
          index: file:
          let
            target = targetPath file;
            backup = "$mutablePersistBackup/${toString index}";
          in
          ''
            if [ -e ${lib.escapeShellArg target} ] && [ ! -L ${lib.escapeShellArg target} ]; then
              cp -a ${lib.escapeShellArg target} "${backup}"
              touch "${backup}.exists"
            fi
          ''
        ) persistentFiles
      )
    );

    home.activation.mutableFileGeneration = lib.mkIf (mutableFiles != [ ]) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] (
        ''
          if [ -v DRY_RUN ]; then
            echo "Would copy mutable Home Manager files"
          else
        ''
        + lib.concatMapStrings (
          file:
          let
            target = targetPath file;
          in
          ''
            verboseEcho "Resetting mutable file: ${target}"
            ${mutableCopy}/bin/hm-mutable-copy reset \
              ${lib.escapeShellArg (toString file.source)} ${lib.escapeShellArg target}
          ''
        ) resetFiles
        + lib.concatImapStrings (
          index: file:
          let
            target = targetPath file;
            backup = "$mutablePersistBackup/${toString index}";
          in
          ''
            verboseEcho "Merging persistent mutable file: ${target}"
            rm -rf ${lib.escapeShellArg target}
            if [ -e "${backup}.exists" ]; then
              mv "${backup}" ${lib.escapeShellArg target}
              ${mutableCopy}/bin/hm-mutable-copy merge \
                ${lib.escapeShellArg (toString file.source)} ${lib.escapeShellArg target}
            else
              ${mutableCopy}/bin/hm-mutable-copy reset \
                ${lib.escapeShellArg (toString file.source)} ${lib.escapeShellArg target}
            fi
          ''
        ) persistentFiles
        + lib.optionalString (persistentFiles != [ ]) ''
          rm -rf "$mutablePersistBackup"
        ''
        + ''
          fi
        ''
      )
    );
  };
}
