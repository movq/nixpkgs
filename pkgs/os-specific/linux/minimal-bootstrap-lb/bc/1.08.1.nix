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
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  flex,
  bison,
  ed,
}:
let
  pname = "bc";
  version = "1.08.1";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/bc/bc-${version}.tar.xz";
    hash = "sha256-UVQwEVszNMY2MXUDRgoJUN/3mUCqMlnOLBqmfCiB0CM=";
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
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      flex
      bison
      ed
    ];

    meta = {
      description = "GNU arbitrary precision calculator language";
      homepage = "https://www.gnu.org/software/bc/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bc";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -
    cd bc-${version}

    # Prepare
    rm bc/bc.c bc/bc.h bc/scan.c
    ${gnused}/bin/sed -i 's/ doc//' Makefile.am
    rm doc/*.info
    rm bc/libmath.h

      rm -f configure
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOCONF=autoconf-2.69 \
      AUTOHEADER=autoheader-2.69 \
      AUTOM4TE=autom4te-2.69 \
      autoreconf-2.69 -fi

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${target}

    # Build
    ${gnumake}/bin/make -j1 PREFIX=''${out}

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
  ''
