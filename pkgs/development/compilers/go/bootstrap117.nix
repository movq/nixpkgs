{ callPackage }:
callPackage ./bootstrap-source.nix {
  version = "1.17.13";
  hash = "sha256-oaSLI6+yBvlee7qpuJjZZfkIJvbx0fwMHXhK2gzTAP0=";
  goBootstrap = callPackage ./bootstrap14.nix { };
}
