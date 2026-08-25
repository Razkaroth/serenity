# Home Manager Extensions

## Mutable Files

`mutable-files.nix` extends `home.file`, `xdg.configFile`, and `xdg.dataFile`
with two mutually exclusive modes. Both require `force = true`.

```nix
home.file.".config/example" = {
  source = ./example;
  recursive = true;
  force = true;
  mutable = true;
};
```

- `mutable = true` installs a writable copy and resets it to declared content
  on every activation.
- `mutablePersist = true` preserves existing files and edits, then copies only
  newly declared missing paths. Removing target manually reseeds current source
  on next activation.

Copied targets remain when declaration is removed. This prevents accidental
loss of edited data; cleanup is manual. Files removed from persistent source
also remain in target.

Layers consume these options without importing provider. Standalone persona or
host adapter must import `mutable-files.nix`. Existing Hydenix-backed hosts keep
using Hydenix provider until later host migration, avoiding duplicate option
declarations.
