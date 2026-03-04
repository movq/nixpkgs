{
  lib,
  config,
  buildPlatform,
  hostPlatform,
  fetchurl,
  checkMeta,
}:
let
  minimal-bootstrap-lb = import ./default.nix {
    inherit
      lib
      config
      buildPlatform
      hostPlatform
      fetchurl
      checkMeta
      ;
  };

  glibc-stage0 = derivation {
    name = "glibc-2.42-stage0";
    system = buildPlatform.system;
    builder = "${minimal-bootstrap-lb.bash-5_2_15}/bin/bash";
    args = [
      "-e"
      "-c"
      ''
        cp -a ${minimal-bootstrap-lb.glibc-2_42} "$out"
        chmod -R u+w "$out"

        for script in "$out"/lib/*.so; do
          if [ -f "$script" ] && head -n 1 "$script" | ${minimal-bootstrap-lb.grep-3_7}/bin/grep -q '^/\* GNU ld script'; then
            ${minimal-bootstrap-lb.gnused-4_8}/bin/sed -i \
              -e "s# //lib/# $out/lib/#g" \
              -e "s# =/lib/# $out/lib/#g" \
              -e "s# /lib/# $out/lib/#g" \
              -e "s# //usr/lib/# $out/lib/#g" \
              -e "s# =/usr/lib/# $out/lib/#g" \
              -e "s# /usr/lib/# $out/lib/#g" \
              "$script"
          fi
        done

        chmod -R a-w "$out"
      ''
    ];
    PATH = lib.makeBinPath [ minimal-bootstrap-lb.coreutils-9_4 ];
  };

  markFromMinBootstrap =
    drv:
    lib.extendDerivation true {
      passthru = (drv.passthru or { }) // {
        isFromMinBootstrap = true;
      };
    } drv;

  binutils-final =
    if hostPlatform.libc == "glibc" then
      minimal-bootstrap-lb.binutils-2_41-gnu
    else
      minimal-bootstrap-lb.binutils-2_41;
in
{
  supportedSystems = [ "x86_64-linux" ];

  # Expose a stage0-compatible interface so stdenv can consume lb bootstrap
  # the same way it consumes upstream minimal-bootstrap.
  bash = markFromMinBootstrap minimal-bootstrap-lb.bash-5_2_15;
  bash-static = markFromMinBootstrap minimal-bootstrap-lb.bash-5_2_15;
  binutils-static = markFromMinBootstrap binutils-final;
  bzip2-static = markFromMinBootstrap minimal-bootstrap-lb.bzip2-1_0_8;
  coreutils-static = markFromMinBootstrap minimal-bootstrap-lb.coreutils-9_4;
  diffutils-static = markFromMinBootstrap minimal-bootstrap-lb.diffutils-3_10;
  findutils-static = markFromMinBootstrap minimal-bootstrap-lb.findutils-4_10_0;
  gawk-static = markFromMinBootstrap minimal-bootstrap-lb.gawk-5_3_0;
  gnugrep-static = markFromMinBootstrap minimal-bootstrap-lb.grep-3_7;
  gnumake-static = markFromMinBootstrap minimal-bootstrap-lb.gnumake-4_2_1;
  gnupatch-static = markFromMinBootstrap minimal-bootstrap-lb.gnupatch-2_7_6;
  gnused-static = markFromMinBootstrap minimal-bootstrap-lb.gnused-4_8;
  gnutar-static = markFromMinBootstrap minimal-bootstrap-lb.gnutar-1_34;
  gzip-static = markFromMinBootstrap minimal-bootstrap-lb.gzip-1_13;
  patchelf-static = markFromMinBootstrap minimal-bootstrap-lb.patchelf-0_15_2;
  # `bootstrap-tools-assembled` provides `/bin/xz` via busybox wrapper.
  xz-static = markFromMinBootstrap minimal-bootstrap-lb.bootstrap-tools-assembled;

  gcc-latest = markFromMinBootstrap minimal-bootstrap-lb.gcc-15_2_0;
  gcc-glibc = markFromMinBootstrap minimal-bootstrap-lb.gcc-15_2_0-gnu;
  musl-static = markFromMinBootstrap minimal-bootstrap-lb.musl-1_2_5;
  glibc = markFromMinBootstrap glibc-stage0;
}
