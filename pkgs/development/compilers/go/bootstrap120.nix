{ callPackage }:
callPackage ./bootstrap-source.nix {
  version = "1.20.14";
  hash = "sha256-Gu8yGg4+OLfpHS1+tkBAZmyr3Md9OD3jyVItDWm2f04=";
  goBootstrap = callPackage ./bootstrap117.nix { };
}
