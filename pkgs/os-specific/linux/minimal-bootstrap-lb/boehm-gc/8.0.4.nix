{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cxx,
  binutils,
  gnumake,
  gnutar,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  autoconf269,
  automake,
  libtool,
  libatomic_ops,
}:
let
  pname = "boehm-gc";
  version = "8.0.4";

  src = fetchurl {
    url = "https://www.hboehm.info/gc/gc_source/gc-${version}.tar.gz";
    hash = "sha256-dbXLLVyVBsuW4KMeAYWudJN/jkByP5MrU2CweFiBNFM=";
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
      gnutar
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      autoconf269
      automake
      libtool
      libatomic_ops
    ];

    meta = {
      description = "Conservative garbage collector for C and C++";
      homepage = "https://www.hboehm.info/gc/";
      license = lib.licenses.boehmGC;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} boehm-gc.tar
    ${gnutar}/bin/tar xf boehm-gc.tar
    rm boehm-gc.tar
    cd gc-${version}

    # Prepare
    rm configure Makefile.in aclocal.m4
    ACLOCAL_PATH="${libtool}/share/aclocal" \
      ACLOCAL=aclocal-1.16 \
      AUTOMAKE=automake-1.16 \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi

    # Configure
    MAKEINFO=true CC=cc CXX=c++ CPP="cc -E" CXXCPP="c++ -E" \
      CPPFLAGS="-I${libatomic_ops}/include" \
      LDFLAGS="-L${libatomic_ops}/lib" \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --disable-shared \
        CFLAGS='-D_GNU_SOURCE -DNO_GETCONTEXT -DSEARCH_FOR_DATA_START -DUSE_MMAP -DHAVE_DL_ITERATE_PHDR'

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install MAKEINFO=true
  ''
