{ callPackage }:
callPackage ./bootstrap-source.nix {
  version = "1.22.12";
  hash = "sha256-ASp+HzfzYsCRjB36MzRFisLaFijEuc9NnKAtuYbhfXE=";
  goBootstrap = callPackage ./bootstrap120.nix { };
}
