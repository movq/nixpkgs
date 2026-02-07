{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  gzip,
  bison,
  gnused,
  m4,
  oldPerl,
}:
let
  pname = "perl";
  version = "5.6.2";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl-${version}.tar.gz";
    hash = "sha256-peZvbr9wGwVn9Wn1fK6Cq/XOV69worRa5xMjth9JE04=";
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
      gnused
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
        test "$(${result}/bin/perl -e 'use strict; use warnings; print 6 * 7')" = 42
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
    cd perl-${version}

    # Configure
    cp ${./files/config-5.6.2.h} config.h
    ${gnused}/bin/sed -i 's|/bin/sh|${bash}/bin/bash|' config.h
    cp ${./files/config-5.6.2.sh} config.sh
    cp ${./mk/main-5.6.2.mk} Makefile
    ${gnused}/bin/sed -i "s|spitshell=cat eunicefix=true ./|spitshell=cat eunicefix=true ${bash}/bin/bash ./|" Makefile

    # Regenerate bison files
    ${gnused}/bin/sed -i '/yydestruct/d' perly.y
    rm -f perly.c perly.h
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      M4="${m4}/bin/m4" \
      ${bison}/bin/bison -d perly.y
    mv perly.tab.c perly.c
    mv perly.tab.h perly.h

    # Regenerate generated headers and perl sources
    rm -f proto.h pp.sym pp_proto.h perlapi.c perlapi.h opnames.h opcode.h \
      objXSUB.h embedvar.h global.sym
    for file in opcode embed keywords; do
      rm -f ''${file}.h
      ${oldPerl}/bin/perl ''${file}.pl
    done
    rm -f regnodes.h
    ${oldPerl}/bin/perl regcomp.pl
    rm -f ext/ByteLoader/byterun.h ext/ByteLoader/byterun.c ext/B/B/Asmdata.pm
    ${oldPerl}/bin/perl bytecode.pl
    rm -f warnings.h lib/warnings.pm
    ${oldPerl}/bin/perl warnings.pl

    # Regenerate unicode tables and drop pregenerated manpage output
    rm -rf lib/unicode/Is lib/unicode/In lib/unicode/To lib/unicode/*.pl
    rm -f lib/Pod/Man.pm

    ${gnused}/bin/sed -i 's/perl_call_method/Perl_call_method/' ext/Data/Dumper/Dumper.xs
    ${gnused}/bin/sed -i 's/perl_call_sv/Perl_call_sv/' ext/Data/Dumper/Dumper.xs
    ${gnused}/bin/sed -i 's/sv_setptrobj/Perl_sv_setref_iv/' ext/POSIX/POSIX.xs
    ${gnused}/bin/sed -i "s#/usr/include/errno.h#${musl}/include/bits/errno.h#" ext/Errno/Errno_pm.PL

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j1 \
        SHELL="${bash}/bin/bash" \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
        AR="${tinycc.compiler}/bin/tcc -ar" \
        PREFIX=''${out}

    cd lib/unicode
    ../../miniperl -I../../lib mktables.PL
    cd ../..

    # Install
    ${gnumake}/bin/make -f Makefile \
      SHELL="${bash}/bin/bash" \
      install \
      PREFIX=''${out}
  ''
