{
  lib,
  fetchurl,
  bash,
  coreutils,
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
  automake,
}:
let
  pname = "which";
  version = "2.21";

  src = fetchurl {
    url = "https://carlowood.github.io/which/which-${version}.tar.gz";
    hash = "sha256-9KJFuUEks3fYtJZGv0IfkVXTaqdhS26/g3BdP/x26q0=";
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
      description = "Show the full path of shell commands";
      homepage = "https://www.gnu.org/software/which/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "which";
    };
  }
  ''
    # Unpack
    cp ${src} which.tar.gz
    ${gzip}/bin/gzip -d -f which.tar.gz
    ${gnutar}/bin/tar xf which.tar
    rm which.tar
    cd which-${version}

    export PATH="${binutils}/bin:$PATH"

    # Prepare
    rm configure Makefile.in aclocal.m4 which.1
    touch ChangeLog which.1
    ${gnused}/bin/sed -i '/@ACLOCAL_CWFLAGS@/d' Makefile.am
    ACLOCAL=aclocal-1.16 \
      AUTOMAKE=automake-1.16 \
      ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    CC=cc ./configure --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install MAKEINFO=true
    rm ''${out}/share/man/man1/which.1
  ''
