{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cxx,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "gperf";
  version = "3.3";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gperf/gperf-${version}.tar.gz";
    hash = "sha256-/Yfgq6fkOuBUg3r9bNTbA6PyaT3rNhkIXm7Z2NlgStg=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/b08ee1d.tar.gz";
    hash = "sha256-1qn8DbNOu6AcN/oyUMQSfoF1rz2/MsQ14kqRhfD0Kpk=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cxx
      binutils
      gnumake
      gnupatch
      gnutar
      gzip
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "GNU perfect hash function generator";
      homepage = "https://www.gnu.org/software/gperf/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gperf";
    };
  }
  ''
    # Unpack
    cp ${src} gperf.tar.gz
    ${gzip}/bin/gzip -d -f gperf.tar.gz
    ${gnutar}/bin/tar xf gperf.tar
    rm gperf.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-b08ee1d

    for script in gnulib-b08ee1d/gnulib-tool gnulib-b08ee1d/gnulib-tool.sh gnulib-b08ee1d/gnulib-tool.py; do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod 755 "$script"
      fi
    done

    if [ -f gnulib-b08ee1d/build-aux/po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-b08ee1d/build-aux/po/Makefile.in.in
    fi

    cd gperf-${version}

    export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./patches/reproducible-docs.patch}

    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" Makefile.devel
    ${findutils}/bin/find . -type f -name Makefile.in -exec \
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" {} +
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" autogen.sh
    chmod 755 autogen.sh

    rm doc/gperf.{1,dvi,info,pdf,ps} doc/*.html
    touch doc/gperf.info doc/gperf.pdf
    rm tests/*.exp tests/{languages,charsets}.gperf tests/lang-ucs2.in
    GNULIB_TOOL="$(${coreutils}/bin/realpath ../gnulib-b08ee1d/gnulib-tool)"
    GNULIB_MODULES="
      filename
      getopt-gnu
      map-c++ hash-map
      read-file
      package-version
    "
    "$GNULIB_TOOL" \
      --lib=libgp \
      --source-base=lib \
      --m4-base=lib/gnulib-m4 \
      --makefile-name=Makefile.gnulib \
      --local-dir=gnulib-local \
      --import \
      $GNULIB_MODULES
    "$GNULIB_TOOL" --copy-file build-aux/config.guess
    chmod 755 build-aux/config.guess
    "$GNULIB_TOOL" --copy-file build-aux/config.sub
    chmod 755 build-aux/config.sub
    "$GNULIB_TOOL" --copy-file build-aux/install-sh
    chmod 755 build-aux/install-sh
    "$GNULIB_TOOL" --copy-file build-aux/mkinstalldirs
    chmod 755 build-aux/mkinstalldirs
    "$GNULIB_TOOL" --copy-file build-aux/compile
    chmod 755 build-aux/compile
    "$GNULIB_TOOL" --copy-file build-aux/ar-lib
    chmod 755 build-aux/ar-lib

    sed -i -e 's/aclocal -I/aclocal-1.15 -I/' \
      -e 's/automake --add-missing/automake-1.15 --add-missing/' \
      Makefile.devel

    ${findutils}/bin/find . -name configure.ac -exec ${gnused}/bin/sed -i 's/2\.70/2.69/g' {} +
    ${gnumake}/bin/make -f Makefile.devel totally-clean all
    ${gnused}/bin/sed -i "1s@^#!/usr/bin/env perl\$@#!${perl}/bin/perl@" doc/help2man
    chmod 755 doc/help2man

    # Configure
    CC=cc CXX=c++ \
      ./configure \
      --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true PREFIX=''${out}

    # Install
    ${gnumake}/bin/make MAKEINFO=true PREFIX=''${out} install
  ''
