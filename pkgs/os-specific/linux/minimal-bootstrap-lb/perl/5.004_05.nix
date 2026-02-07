{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  gzip,
  gnused,
  bison,
  m4,
  oldPerl,
}:
let
  pname = "perl";
  version = "5.004_05";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl${version}.tar.gz";
    hash = "sha256-EYRHiymJeLFko4PtVmHjoRfEirl9bQq372FM2+kYues=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnutar
      gzip
      bison
      m4
      oldPerl
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/perl -v
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        test "$(${result}/bin/perl -e 'use strict; print 6 * 7')" = 42
        mkdir ''${out}
      '';

    meta = {
      description = "Practical Extraction and Report Language";
      homepage = "https://www.perl.org/";
      license = lib.licenses.artistic1;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "perl";
    };
  }
  ''
    # Unpack
    cp ${src} perl.tar.gz
    ${gzip}/bin/gzip -d -f perl.tar.gz
    ${gnutar}/bin/tar xf perl.tar
    rm perl.tar
    cd perl${version}

    # Configure
    cp ${./files/config-5.004_05.h} config.h
    ${gnused}/bin/sed -i 's|/bin/sh|${bash}/bin/bash|' config.h
    cp ${./mk/main-5.004_05.mk} Makefile

    rm -f perly.c perly.h
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      M4="${m4}/bin/m4" \
      ${bison}/bin/bison -d perly.y
    mv perly.tab.c perly.c
    mv perly.tab.h perly.h

    for file in embed keywords opcode; do
      rm -f ''${file}.h
      ${oldPerl}/bin/perl ''${file}.pl
    done

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j1 \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
        PREFIX=''${out}

    # Install
    ${gnumake}/bin/make -f Makefile install PREFIX=''${out}
  ''
