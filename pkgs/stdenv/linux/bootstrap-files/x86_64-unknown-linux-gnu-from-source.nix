{ lib, config }:

let
  i386Platform = lib.systems.elaborate "i686-linux";

  fetchurl = import ../../../build-support/fetchurl/boot.nix {
    system = "i686-linux";
    inherit (config) rewriteURL;
  };

  checkMeta = import ../../generic/check-meta.nix {
    inherit lib config;
    hostPlatform = i386Platform;
  };

  bootstrap = import ../../../os-specific/linux/minimal-bootstrap-lb {
    inherit lib config fetchurl checkMeta;
    buildPlatform = i386Platform;
    hostPlatform = i386Platform;
  };
in
{
  busybox = bootstrap.busybox;
  bootstrapTools = bootstrap.bootstrap-tools-assembled-gnu;
}
