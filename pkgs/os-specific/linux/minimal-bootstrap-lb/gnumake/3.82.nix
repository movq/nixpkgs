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
  bzip2,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "make";
  version = "3.82";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] target;

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/make/make-${version}.tar.bz2";
    hash = "sha256-4sGnPxecQMceL+ir+KigaIuEmVOFEphNpKdpWNBAKWY=";
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
      bzip2
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "GNU Make";
      homepage = "https://www.gnu.org/software/make/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "make";
    };
  }
  ''
    # Unpack
    cp ${src} make.tar.bz2
    ${bzip2}/bin/bzip2 -d -f make.tar.bz2
    ${gnutar}/bin/tar xf make.tar
    rm make.tar
    cd make-${version}

    # Patch default shell
    ${gnused}/bin/sed -i 's|"/bin/sh"|"${bash}/bin/bash"|' job.c

    # Prepare
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" config/mkinstalldirs
    chmod +x config/mkinstalldirs
    rm doc/make.info*
    touch doc/make.info
    rm po/*.gmo

      rm -f configure
      AUTOPOINT=true \
      AUTOMAKE=automake-1.10 \
      ACLOCAL=aclocal-1.10 \
      AUTOM4TE=autom4te-2.64 \
      autoreconf-2.64 -fi
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${gnuTarget} \
        --disable-nls

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
