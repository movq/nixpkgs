{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cc,
  binutils,
  gnumake,
  gnutar,
  xz,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
  flex,
  bison,
}:
let
  pname = "gmp";
  version = "6.2.1";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/gmp/gmp-${version}.tar.xz";
    hash = "sha256-/UgpkSzd0S+EGBw0Ucx1K+IkZD6H+sSXtp7d2txJtPI=";
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
      gnutar
      xz
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libtool
      flex
      bison
    ];

    meta = {
      description = "GNU multiple precision arithmetic library";
      homepage = "https://gmplib.org/";
      license = with lib.licenses; [
        lgpl3Plus
        gpl2Plus
      ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > gmp.tar
    ${gnutar}/bin/tar xf gmp.tar
    rm gmp.tar
    cd gmp-${version}

    # Prepare
    rm demos/calc/calc.c demos/calc/calc.h demos/calc/calclex.c demos/primes.h
    rm mpn/cray/cfp/mulwwc90.s mpn/cray/cfp/mulwwj90.s tests/rand/t-rand.c
    rm doc/*.info*
    for script in \
      compile config.guess config.sub configfsf.guess configfsf.sub \
      install-sh missing test-driver ylwrap \
      doc/mdate-sh mini-gmp/tests/run-tests \
      mpn/m4-ccas mpn/cpp-ccas mpn/x86/t-zdisp.sh
    do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

      rm -f configure
      ACLOCAL_PATH="${libtool}/share/aclocal" \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --build=${target} \
        --disable-shared

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
