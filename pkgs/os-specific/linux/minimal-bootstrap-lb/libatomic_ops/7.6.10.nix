{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cc,
  binutils,
  gnumake,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  autoconf269,
  automake,
  libtool,
}:
let
  pname = "libatomic_ops";
  version = "7.6.10";

  src = fetchurl {
    url = "https://www.hboehm.info/gc/gc_source/libatomic_ops-${version}.tar.gz";
    hash = "sha256-OAFEzwIlq53oQT/188gkSaATNVOF/Yc3K2DXrAv98E4=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cc
      binutils
      gnumake
      gnutar
      gzip
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      autoconf269
      automake
      libtool
    ];

    meta = {
      description = "Semi-portable atomic memory operation library";
      homepage = "https://www.hboehm.info/gc/";
      license = lib.licenses.mit;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} libatomic_ops.tar
    ${gnutar}/bin/tar xf libatomic_ops.tar
    rm libatomic_ops.tar
    cd libatomic_ops-${version}

    # Prepare
    rm -f configure
    ACLOCAL_PATH="${libtool}/share/aclocal" \
      ACLOCAL=aclocal-1.16 \
      AUTOMAKE=automake-1.16 \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi

    # Configure
    CC=cc ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --disable-shared

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install MAKEINFO=true
  ''
