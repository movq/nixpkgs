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
  xz,
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
  gmp,
}:
let
  pname = "mpfr";
  version = "4.1.0";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/mpfr/mpfr-${version}.tar.xz";
    hash = "sha256-DJij8XMv9spOppBVIHnanFl4ctMOluwoQU7iPJVVin8=";
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
      xz
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
      gmp
    ];

    meta = {
      description = "GNU multiple-precision floating-point library";
      homepage = "https://www.mpfr.org/";
      license = lib.licenses.lgpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > mpfr.tar
    ${gnutar}/bin/tar xf mpfr.tar
    rm mpfr.tar

    ${gnupatch}/bin/patch -Np0 -i ${./4.1.0/patches/strtofr-gen-fix.patch}
    cd mpfr-${version}

    # Prepare
    ${gnused}/bin/sed -i '/^  {/,/ };$/d' src/strtofr.c
    cp src/strtofr.c src/strtofr.c.old
    ${gnused}/bin/sed -i '/int RedInvLog2Table/ s/$/};/' src/strtofr.c

    for script in \
      ar-lib compile config.guess config.sub depcomp install-sh missing test-driver \
      doc/check-typography tools/*
    do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

    rm doc/*.info
    rm tests/tfpif_*.dat tests/tstrtofr.c

    cp ${./4.1.0/files/mparam.h} mparam.h

      rm -f configure
      ACLOCAL_PATH="${autoconfArchive}/share/aclocal:${libtool}/share/aclocal" \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    CPPFLAGS="-I${gmp}/include" \
      LDFLAGS="-L${gmp}/lib" \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --disable-shared

    mv mparam.h src

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    pushd src
    cat > strtofr_gen.c <<EOF
    #include <stdio.h>
    #include <gmp.h>
    #include <mpfr.h>
    EOF

    ${gnused}/bin/sed -n '/^#define N 8$/,/^}$/p' strtofr.c >> strtofr_gen.c
    gcc strtofr_gen.c -o strtofr_gen -std=gnu99 -I. -I${gmp}/include -L.libs -L${gmp}/lib -lmpfr -lgmp
    ./strtofr_gen 2>strtofr_table >/dev/null
    echo "};" >> strtofr_table
    ${gnused}/bin/sed "/int RedInvLog2Table/ r strtofr_table" strtofr.c.old > strtofr.c
    popd

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
