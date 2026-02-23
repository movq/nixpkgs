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
    substituteInPlace tools/minicargo/build.cpp \
      --replace-fail "#include <fstream>" "#include <fstream>\n#include <cstdint>"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/minicargo $out/bin

    # without it, minicargo defaults to "<minicargo_path>/../bin/mrustc"
    wrapProgram "$out/bin/minicargo" --set MRUSTC_PATH ${mrustc}/bin/mrustc
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
