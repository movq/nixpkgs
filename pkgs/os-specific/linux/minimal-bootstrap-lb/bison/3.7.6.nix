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
  version = "3.7.6";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/bison/bison-${version}.tar.xz";
    hash = "sha256-Z9aM4eIhkgUFJWQ/wKeiIpdXZoK+9qXFFEaQP1ru888=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/839ed05.tar.gz";
    hash = "sha256-cKXHD+ivn0QbIF+88wmA0MfSb07PsLqz5HhxMm1hALg=";
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
    mv gnulib-* gnulib-839ed05

    for script in gnulib-839ed05/gnulib-tool gnulib-839ed05/build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    if [ -f gnulib-839ed05/build-aux/po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" \
        gnulib-839ed05/build-aux/po/Makefile.in.in
    fi

    for patch in ${./3.7.6/patches}/*.patch; do
      ${gnupatch}/bin/patch -Np0 -i "$patch"
    done

    cd bison-${version}
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    cp ${./3.7.6/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh

        # Prepare
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
    for file in lib/iconv_open-*.h; do
      rm -f "$file"
      touch "$file"
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
        --program-suffix=-3.7 \
        --datarootdir=''${out}/share/bison-3.7

    # Build
    ${gnumake}/bin/make -j1 MAKEINFO=true BISON=${bison}/bin/bison

    # Install
    ${gnumake}/bin/make install MAKEINFO=true BISON=${bison}/bin/bison
    ln -s bison-3.7 ''${out}/bin/bison
  ''
