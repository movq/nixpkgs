{
  lib,
  stdenv,
  makeWrapper,
  mrustc,
}:

stdenv.mkDerivation rec {
  pname = "mrustc-minicargo";
  inherit (mrustc) src version;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];

  enableParallelBuilding = true;
  makefile = "minicargo.mk";
  makeFlags = [ "bin/minicargo" ];

  postPatch = ''
    # gcc15 requires this include for uint64_t in tools/minicargo/build.cpp.
    sed -i '/^#include <fstream>$/a #include <cstdint>' tools/minicargo/build.cpp
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/minicargo $out/bin

    # Keep a default, but allow callers (e.g. run_rustc) to override MRUSTC_PATH.
    wrapProgram "$out/bin/minicargo" --set-default MRUSTC_PATH ${mrustc}/bin/mrustc
    runHook postInstall
  '';

  meta = {
    description = "Minimalist builder for Rust";
    mainProgram = "minicargo";
    longDescription = ''
      A minimalist builder for Rust, similar to Cargo but written in C++.
      Designed to work with mrustc to build Rust projects
      (like the Rust compiler itself).
    '';
    inherit (src.meta) homepage;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      progval
      r-burns
    ];
    platforms = [ "x86_64-linux" ];
  };
}
