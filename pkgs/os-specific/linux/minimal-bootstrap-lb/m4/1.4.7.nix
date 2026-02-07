{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  bzip2,
}:

let
  pname = "m4";
  version = "1.4.7";

  src = fetchurl {
    url = "mirror://gnu/m4/m4-${version}.tar.bz2";
    hash = "sha256-qI892qfInPTDQoQ4W+QcqF6RNTacMz/fojLzv0giMhM=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnutar
      bzip2
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/m4 --version
        mkdir ''${out}
      '';

    meta = {
      description = "GNU M4, a macro processor";
      homepage = "https://www.gnu.org/software/m4/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "m4";
    };
  }
  ''
    # Unpack
    cp ${src} m4.tar.bz2
    ${bzip2}/bin/bzip2 -d -f m4.tar.bz2
    ${gnutar}/bin/tar xf m4.tar
    rm m4.tar
    cd m4-${version}

    # Configure
    cp ${./main.mk} Makefile

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j "$NIX_BUILD_CORES" \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
        AR="${tinycc.compiler}/bin/tcc -ar"

    # Install
    ${gnumake}/bin/make -f Makefile install PREFIX=''${out}
  ''
