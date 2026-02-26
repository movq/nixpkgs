{ callPackage }:
callPackage ./bootstrap-source.nix {
  version = "1.24.11";
  hash = "sha256-/9+XdmpMSxNc1TgJcTl46e4alDssjiitIhpUKd4w4hA=";
  goBootstrap = callPackage ./bootstrap122.nix { };
}
