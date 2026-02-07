{
  lib,
  fetchurl,
  bash,
  coreutils,
  cc,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  bzip2,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  autoconfArchive,
  libtool,
  flex,
  bison,
}:
let
  pname = "bison";
  version = "2.3";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/bison/bison-${version}.tar.bz2";
    hash = "sha256-sQ1+njVL5yruTkkRzxndJ7XFJ9TnIAhXNltfze6g3/s=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/b28236b.tar.gz";
    hash = "sha256-WHaShej03sSjCvEgMvMMBiHSGqYaAb1Iojaurp97AnY=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cc
      binutils
      gnumake
      gnupatch
      gnutar
      gzip
      bzip2
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      autoconfArchive
      libtool
      flex
      bison
    ];

    meta = {
      description = "Yacc-compatible parser generator";
      homepage = "https://www.gnu.org/software/bison/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bison-2.3";
    };
  }
  ''
    # Unpack
    cp ${src} bison.tar.bz2
    ${bzip2}/bin/bzip2 -d -f bison.tar.bz2
    ${gnutar}/bin/tar xf bison.tar
    rm bison.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-b28236b

    ${gnupatch}/bin/patch -Np0 -i ${./2.3/patches/autover-mismatch.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./2.3/patches/fopen-safer.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./2.3/patches/gnulib-fix.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./2.3/patches/our-bison.patch}

    cd bison-${version}
    cp ${./2.3/import-gnulib.sh} import-gnulib.sh
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" import-gnulib.sh
    chmod 555 import-gnulib.sh

    for script in ../gnulib-b28236b/gnulib-tool ../gnulib-b28236b/build-aux/*; do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

    if [ -f ../gnulib-b28236b/build-aux/po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" ../gnulib-b28236b/build-aux/po/Makefile.in.in
    fi

    # Prepare
    for script in build-aux/* examples/calc++/test tests/testsuite; do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

    for makefile in GNUmakefile po/Makefile.in.in runtime-po/Makefile.in.in; do
      if [ -f "$makefile" ]; then
        ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" "$makefile"
        ${gnused}/bin/sed -i "s|^SHELL = sh$|SHELL = ${bash}/bin/bash|" "$makefile"
      fi
    done

    ${gnused}/bin/sed -i "s|echo '#! /bin/sh' >\$@|echo '#! ${bash}/bin/bash' >\$@|" src/Makefile.am

    ./import-gnulib.sh

      rm -f configure
      ACLOCAL_PATH="${autoconfArchive}/share/aclocal:${libtool}/share/aclocal" \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    for makefile in po/Makefile.in.in runtime-po/Makefile.in.in; do
      if [ -f "$makefile" ]; then
        ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" "$makefile"
      fi
    done

    rm src/parse-gram.c src/parse-gram.h src/scan-skel.c src/scan-gram.c
    rm doc/bison.info

    # Configure
    LEX=flex-2.5.33 \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --program-suffix=-2.3 \
        --datarootdir=''${out}/share/bison-2.3

    # Build
    ${gnumake}/bin/make -j1 MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
