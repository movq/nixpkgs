{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  cxx,
  binutils,
  gnumake,
  gnutar,
  gzip,
  findutils,
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
  pname = "libffi";
  version = "3.3";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://github.com/libffi/libffi/releases/download/v${version}/libffi-${version}.tar.gz";
    hash = "sha256-cvunkicD3fp6Ao1ROsFahcjVTI1n9V+lpIAohdxlIFY=";
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
      gzip
      findutils
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
      description = "Portable foreign-function interface library";
      homepage = "https://sourceware.org/libffi/";
      license = lib.licenses.mit;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} libffi.tar.gz
    ${gzip}/bin/gzip -d -f libffi.tar.gz
    ${gnutar}/bin/tar xf libffi.tar
    rm libffi.tar
    cd libffi-${version}

    # Prepare
    ${findutils}/bin/find . -name '*.info*' -delete
    rm configure

    ACLOCAL_PATH="${libtool}/share/aclocal" \
      ACLOCAL=aclocal-1.16 \
      AUTOMAKE=automake-1.16 \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi

    # Configure
    MAKEINFO=true CC=cc CXX=c++ CPP="cc -E" CXXCPP="c++ -E" ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --build=${target} \
      --disable-shared \
      --with-gcc-arch=generic \
      --enable-pax_emutramp

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install MAKEINFO=true
  ''
