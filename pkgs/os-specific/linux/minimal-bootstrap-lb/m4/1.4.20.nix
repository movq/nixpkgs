{
  lib,
  fetchurl,
  autoconf,
  automake,
  bash,
  binutils,
  cc,
  coreutils,
  diffutils,
  gawk,
  gnumake,
  gnutar,
  gnused,
  grep,
}:

let
  pname = "m4";
  version = "1.4.20";

  src = fetchurl {
    url = "mirror://gnu/m4/m4-${version}.tar.xz";
    hash = "sha256-4jbqOhzPX2wnCxxLtgcm83H6SUWajqrryQshazKNrys=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      autoconf
      automake
      cc
      binutils
      coreutils
      diffutils
      gawk
      gnumake
      gnused
      gnutar
      grep
    ];

    meta = {
      description = "GNU M4, a macro processor";
      homepage = "https://www.gnu.org/software/m4/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "m4";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | tar xf -
    cd m4-${version}

    # Prepare
    sed -i 's/SUBDIRS = \. examples lib src doc checks po tests/SUBDIRS = . lib src/' Makefile.am
    rm configure aclocal.m4 Makefile.in
    AUTOMAKE=automake-1.16 \
      ACLOCAL=aclocal-1.16 \
      AUTOCONF=autoconf-2.71 \
      AUTOPOINT=true \
      autoreconf-2.71 -fi

    # Configure
   ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    make -j $NIX_BUILD_CORES

    # Install
    make install
  ''
