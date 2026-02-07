{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cc,
  binutils,
  gnumake,
  pkgConfig,
  gnutar,
  gzip,
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
  version = "4.2.1";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/make/make-${version}.tar.gz";
    hash = "sha256-5AuPAYwdpk7dHMmm/OX6Y7LnB+QE4gytkfuuM3yYpbc=";
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
      pkgConfig
      gnutar
      gzip
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
    cp ${src} make.tar.gz
    ${gzip}/bin/gzip -d -f make.tar.gz
    ${gnutar}/bin/tar xf make.tar
    rm make.tar
    cd make-${version}

    # Patch default shell
    ${gnused}/bin/sed -i 's|"/bin/sh"|"${bash}/bin/bash"|' job.c

    # Prepare
    rm doc/make.info*
    rm po/*.gmo

      rm -f configure
      ACLOCAL_PATH="${pkgConfig}/share/aclocal" \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${target} \
        --disable-nls

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
