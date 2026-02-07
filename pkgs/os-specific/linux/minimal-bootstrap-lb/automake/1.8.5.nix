{
  lib,
  fetchurl,
  bash,
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
  pname = "automake";
  version = "1.8.5";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-hMk6qjw2UannR0tyGw5niDGFklCefeYEuv5OqASdxBA=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
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
      description = "GNU Automake";
      homepage = "https://www.gnu.org/software/automake/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "automake-1.8";
    };
  }
  ''
    # Unpack
    cp ${src} automake.tar.bz2
    ${bzip2}/bin/bzip2 -d -f automake.tar.bz2
    ${gnutar}/bin/tar xf automake.tar
    rm automake.tar
    cd automake-${version}

    # Prepare
    rm -f doc/automake.info*

      rm -f configure
      AUTOMAKE=automake-1.7 \
      ACLOCAL=aclocal-1.7 \
      AUTOCONF=autoconf-2.59 \
      ${autoconf}/bin/autoreconf-2.59 -f

    # Configure
    AUTOCONF=autoconf-2.59 ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    ${gnumake}/bin/make MAKEINFO=true AUTOMAKE=automake-1.7 ACLOCAL=aclocal-1.7

    # Install
    ${gnumake}/bin/make install MAKEINFO=true AUTOMAKE=automake-1.7 ACLOCAL=aclocal-1.7
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
