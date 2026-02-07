{
  lib,
  fetchurl,
  bash,
  cc,
  gnumake,
  gnupatch,
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
  version = "1.10.3";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-6Yq0O7g5wxaWpCAuW2/ziLORZZ7yOHz5NlAZ+tF+Gtw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      cc
      gnumake
      gnupatch
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
      mainProgram = "automake-1.10";
    };
  }
  ''
    # Unpack
    cp ${src} automake.tar.bz2
    ${bzip2}/bin/bzip2 -d -f automake.tar.bz2
    ${gnutar}/bin/tar xf automake.tar
    rm automake.tar

    ${gnupatch}/bin/patch -Np0 -i ${./patches/1.10.3/aclocal_glob.patch}

    cd automake-${version}

    # Prepare
    rm -f doc/amhello-1.0.tar.gz doc/automake.info*

    ${gawk}/bin/awk '/SUBDIRS/{sub("doc ", "", $0)} {print}' Makefile.am > Makefile.am.tmp
    mv Makefile.am.tmp Makefile.am

    rm -f configure

    for script in bootstrap lib/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    AUTOM4TE=autom4te-2.61 \
      AUTOCONF=autoconf-2.61 \
      AUTOHEADER=autoheader-2.61 \
      AUTORECONF=autoreconf-2.61 \
      ./bootstrap

    # Configure
    AUTORECONF=autoreconf-2.61 \
      AUTOHEADER=autoheader-2.61 \
      AUTOCONF=autoconf-2.61 \
      AUTOM4TE=autom4te-2.61 \
      ./configure CC=tcc --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    AUTOM4TE=autom4te-2.61 \
      ${gnumake}/bin/make MAKEINFO=true CC=tcc

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
