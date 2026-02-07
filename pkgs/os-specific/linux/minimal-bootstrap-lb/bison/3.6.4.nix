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
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  flex,
  bison,
}:
let
  pname = "bison";
  version = "3.6.4";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/bison/bison-${version}.tar.xz";
    hash = "sha256-ixNHOzHKf89l5einQiQ2j/1d8ZJ1YCqclWe6OT8YV30=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/ffbb0ce.tar.gz";
    hash = "sha256-IHiUmtQS6VgvI/bJlC6OTUsjauh0iVeYjB0NhVZPkB4=";
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
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      flex
      bison
    ];

    meta = {
      description = "Yacc-compatible parser generator";
      homepage = "https://www.gnu.org/software/bison/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bison";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-ffbb0ce

    for script in gnulib-ffbb0ce/gnulib-tool gnulib-ffbb0ce/build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    if [ -f gnulib-ffbb0ce/build-aux/po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" \
        gnulib-ffbb0ce/build-aux/po/Makefile.in.in
    fi

    for patch in ${./3.6.4/patches}/*.patch; do
      ${gnupatch}/bin/patch -Np0 -i "$patch"
    done

    cd bison-${version}
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    cp ${./3.6.4/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh

        # Prepare
    ${gnused}/bin/sed -i '/GRAM_error/d' src/scan-gram.l
    ${gnused}/bin/sed -i "s|^BISON = /usr/bin/bison$|BISON = ${bison}/bin/bison|" Makefile.am

    rm -f src/parse-gram.c src/parse-gram.h
    rm -f src/scan-code.c src/scan-gram.c src/scan-skel.c
    rm -f doc/bison.info*
    rm -f runtime-po/*.gmo

    ${bash}/bin/bash ./import-gnulib.sh

    for template in po/Makefile.in.in runtime-po/Makefile.in.in gnulib-po/Makefile.in.in; do
      if [ -f "$template" ]; then
        ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" "$template"
      fi
    done

    shopt -s nullglob
    for file in lib/iconv_open-*.gperf; do
      touch "$(${coreutils}/bin/basename "$file" .gperf).h"
    done
    shopt -u nullglob

      rm -f configure
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    LEX=flex-2.5.33 CC=cc CXX=c++ \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --disable-nls \
        --program-suffix=-3.6 \
        --datarootdir=''${out}/share/bison-3.6

    # Build
    ${gnumake}/bin/make -j1 MAKEINFO=true BISON=${bison}/bin/bison

    # Install
    ${gnumake}/bin/make install MAKEINFO=true BISON=${bison}/bin/bison
    ln -s bison-3.6 ''${out}/bin/bison
  ''
