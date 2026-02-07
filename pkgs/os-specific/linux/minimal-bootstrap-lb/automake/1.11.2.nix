{
  lib,
  fetchurl,
  bash,
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
  version = "1.11.2";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.bz2";
    hash = "sha256-T0bR+TgMijUGKAdQ9jDp/JFcsaQ1tyS+VrSZ0BY2hxg=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
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
      mainProgram = "automake-1.11";
    };
  }
  ''
    # Unpack
    cp ${src} automake.tar.bz2
    ${bzip2}/bin/bzip2 -d -f automake.tar.bz2
    ${gnutar}/bin/tar xf automake.tar
    rm automake.tar

    ${gnupatch}/bin/patch -Np0 -i ${./patches/1.11.2/aclocal_glob.patch}

    cd automake-${version}

    # Prepare
    rm -f doc/amhello-1.0.tar.gz doc/automake.info* doc/aclocal-1.11.1 doc/automake-1.11.1
    rm -f tests/parallel-tests.am

    ${gawk}/bin/awk '/SUBDIRS/{sub("doc ", "", $0)} {print}' Makefile.am > Makefile.am.tmp
    mv Makefile.am.tmp Makefile.am

    rm -f configure

    for script in bootstrap lib/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|BOOTSTRAP_SHELL=/bin/sh|BOOTSTRAP_SHELL=${bash}/bin/bash|" bootstrap
    chmod +x bootstrap

    AUTOCONF=autoconf-2.64 \
      AUTOM4TE=autom4te-2.64 \
      ./bootstrap

    # Configure
    AUTORECONF=autoreconf-2.64 \
      AUTOM4TE=autom4te-2.64 \
      AUTOHEADER=autoheader-2.64 \
      AUTOCONF=autoconf-2.64 \
      ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    AUTORECONF=autoreconf-2.64 \
      AUTOM4TE=autom4te-2.64 \
      AUTOHEADER=autoheader-2.64 \
      AUTOCONF=autoconf-2.64 \
      ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake
  ''
