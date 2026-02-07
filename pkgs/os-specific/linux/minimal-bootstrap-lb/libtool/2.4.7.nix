{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  coreutils5,
  diffutils,
  findutils,
  cc,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  help2man,
}:
let
  pname = "libtool";
  version = "2.4.7";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/libtool/libtool-${version}.tar.xz";
    hash = "sha256-T38hfwV85lX/IlWa0iGg/Y74StH8X8tpkM7MMzqhY10=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/a521820.tar.gz";
    hash = "sha256-2eXDjZ0ldjsFjEWLz81oHU0y6olI0iBNPL+db22XpV4=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      coreutils5
      diffutils
      findutils
      cc
      binutils
      gnumake
      gnupatch
      gnutar
      gzip
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      help2man
    ];

    meta = {
      description = "GNU Libtool";
      homepage = "https://www.gnu.org/software/libtool/";
      license = [ lib.licenses.gpl2Plus lib.licenses.lgpl21Plus ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "libtool";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-a521820
    for script in gnulib-a521820/* gnulib-a521820/build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-a521820/build-aux/po/Makefile.in.in

    ${gnupatch}/bin/patch -Np0 -i ${./2.4.7/hostname.patch}
    cd libtool-${version}

    # Replace /bin/sh with store path to bash
    ${gnused}/bin/sed -i "1s|.*/bin/sh|#!${bash}/bin/bash|" \
      build-aux/inline-source build-aux/options-parser build-aux/extract-trace
    chmod +x build-aux/inline-source build-aux/options-parser build-aux/extract-trace

    # Prepare
    cp ${./2.4.7/import-gnulib.sh} import-gnulib.sh
    cp ${./2.4.7/bootstrap-helper.sh} bootstrap-helper.sh
    chmod 555 import-gnulib.sh bootstrap-helper.sh
    ${gnused}/bin/sed -i "s|SED='/usr/bin/sed'|SED='sed'|" bootstrap-helper.sh

    rm -f build-aux/ltmain.sh
    rm -f doc/*.info doc/*.1
    rm -f bootstrap
    rm -f tests/testsuite tests/package.m4
    ${gnused}/bin/sed -i "1 s|^#! /usr/bin/env sh$|#!${bash}/bin/bash|" libtoolize.in

    ${bash}/bin/sh ./import-gnulib.sh
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    LIBTOOLIZE=true \
      AUTOPOINT=true \
      ${bash}/bin/sh ./bootstrap-helper.sh

      rm -f configure
      LIBTOOLIZE=true \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOCONF=autoconf-2.69 \
      AUTOHEADER=autoheader-2.69 \
      autoreconf-2.69 -fi

    LIBTOOLIZE=true \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOCONF=autoconf-2.69 \
      AUTOHEADER=autoheader-2.69 \
      autoreconf-2.69 -fi libltdl

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --disable-shared \
        --host=${target} \
        --target=${target} \
        --build=${target} \
        ac_path_EGREP=egrep \
        ac_path_FGREP=fgrep \
        ac_path_GREP=grep \
        ac_path_SED=sed

    # Build
    ${gnumake}/bin/make -j1 AUTOM4TE=autom4te-2.69 MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j1 install MAKEINFO=true

    ${gnused}/bin/sed -i \
      -e "s/{EGREP=.*/{EGREP='egrep'}/" \
      -e "s/{FGREP=.*/{FREGP='fgrep'}/" \
      -e "s/{GREP=.*/{GREP='grep'}/" \
      -e "s/{SED=.*/{SED='sed'}/" \
      ''${out}/bin/libtool
  ''
