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
  version = "1.9.6";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-jsyqmOGGPRDkpfhh2OLsNJoj6IyxKtEPa295AirSu40=";
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
      mainProgram = "automake-1.9";
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
    ${gnused}/bin/sed -i 's/1.8a/1.8.5/; s/ filename-length-max=99//' configure.ac

      rm -f configure
      AUTOMAKE=automake-1.8 \
      ACLOCAL=aclocal-1.8 \
      AUTOM4TE=autom4te-2.61 \
      AUTOCONF=autoconf-2.61 \
      ${autoconf}/bin/autoreconf-2.61 -f

    # Configure
    AUTOCONF=autoconf-2.61 ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
