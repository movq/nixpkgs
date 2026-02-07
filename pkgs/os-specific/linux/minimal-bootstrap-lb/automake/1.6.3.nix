{
  lib,
  fetchurl,
  bash,
  gnutar,
  bzip2,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
}:
let
  pname = "automake";
  version = "1.6.3";
  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-Dbr6yvIeE1yrNdNXoUvc2YHS8tAOE4eAG+gJGjG3u4E=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gnutar
      bzip2
      gnused
      grep
      gawk
      m4
      perl
      autoconf
    ];

    meta = {
      description = "GNU Automake";
      homepage = "https://www.gnu.org/software/automake/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "automake-1.6";
    };
  }
  ''
    # Unpack source twice for the two bootstrap passes
    cp ${src} automake.tar.bz2
    ${bzip2}/bin/bzip2 -d -f automake.tar.bz2
    ${gnutar}/bin/tar xf automake.tar || true
    mv automake-${version} automake-pass1
    ${gnutar}/bin/tar xf automake.tar || true
    mv automake-${version} automake-pass2
    rm automake.tar

    stage1="$PWD/stage1"
    mkdir -p "$stage1"

    # Pass 1
    cd automake-pass1
    rm -f -- configure Makefile.in */Makefile.in */*/Makefile.in aclocal.m4 automake.info*
    cp aclocal.in aclocal
    cp m4/amversion.in m4/amversion.m4

    ${gnused}/bin/sed -i -e 's/@VERSION@/1.6.3/' -e 's/@APIVERSION@/1.6/' m4/amversion.m4
    ${gnused}/bin/sed -i \
      -e "s#@PERL@#${perl}/bin/perl#" \
      -e 's/@PACKAGE@/automake/' \
      -e 's/@APIVERSION@/1.6/' \
      -e 's/@VERSION@/1.6.3/' \
      -e "s#@prefix@#''${stage1}#" \
      -e "s#@datadir@#''${stage1}/share#" \
      aclocal

    mkdir -p "''${stage1}/share/automake-1.6/Automake"
    cp lib/Automake/*.pm "''${stage1}/share/automake-1.6/Automake/"
    install -D aclocal "''${stage1}/bin/aclocal-1.6"
    mkdir -p "''${stage1}/share/aclocal-1.6"
    cp -r m4/*.m4 "''${stage1}/share/aclocal-1.6/"

    # Pass 2
    cd ../automake-pass2
    PATH="''${stage1}/bin:$PATH"
    sed -i '/Makefile/d' configure.in
    rm -f -- configure Makefile.in */Makefile.in */*/Makefile.in aclocal.m4 automake.info*
    aclocal-1.6
    autoconf-2.52

    ./configure --prefix=''${out}

    cp m4/amversion.in m4/amversion.m4
    ${gnused}/bin/sed -i -e 's/@VERSION@/1.6.3/' -e 's/@APIVERSION@/1.6/' m4/amversion.m4

    install -D automake ''${out}/bin/automake-1.6
    mkdir -p ''${out}/share/automake-1.6/am
    mkdir -p ''${out}/share/automake-1.6/Automake
    cp lib/Automake/*.pm ''${out}/share/automake-1.6/Automake/
    cp -r lib/am/*.am ''${out}/share/automake-1.6/am/

    install -D aclocal ''${out}/bin/aclocal-1.6
    mkdir -p ''${out}/share/aclocal-1.6/
    cp -r m4/*.m4 ''${out}/share/aclocal-1.6/
  ''
