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
  version = "1.7";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-ZjPuEgI3XjyHmKkuG39GiU941UGu6n9JZUUD/cCyiDU=";
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
      mainProgram = "automake-1.7";
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
    rm -f -- configure Makefile.in */Makefile.in */*/Makefile.in aclocal.m4 automake.info*
    ${gnused}/bin/sed -i -e 's/2.54/2.53/' -e '/AC_PROG_EGREP/d' -e '/AC_PROG_FGREP/d' configure.in
    ${automake}/bin/aclocal-1.6
    ${autoconf}/bin/autoconf-2.53
    ${automake}/bin/automake-1.6

    # Configure
    ./configure --prefix=''${out}

    # Build
    ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
