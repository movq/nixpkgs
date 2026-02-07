{
  lib,
  fetchurl,
  bash,
  coreutils,
  findutils,
  gnumake,
  gnutar,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  help2man,
}:
let
  pname = "automake";
  version = "1.16.3";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.xz";
    hash = "sha256-/yv3ZWxNHG/do7i+uyHwkVOnNry6FpqvZeqyX6ETvzo=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      findutils
      gnumake
      gnutar
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      help2man
    ];

    meta = {
      description = "GNU Automake";
      homepage = "https://www.gnu.org/software/automake/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "automake-1.16";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -
    cd automake-${version}

    # Prepare
    rm -f doc/amhello-1.0.tar.gz
    ${gnused}/bin/sed -i "/^dist_doc_DATA =/d" doc/local.mk

    rm -f configure

    ${findutils}/bin/find . -type f -print0 | while IFS= read -r -d $'\0' script; do
      if ${coreutils}/bin/head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|BOOTSTRAP_SHELL=/bin/sh|BOOTSTRAP_SHELL=${bash}/bin/bash|" bootstrap
    chmod +x bootstrap

    AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOCONF=autoconf-2.69 \
      AUTOM4TE=autom4te-2.69 \
      ./bootstrap

    rm -f doc/automake-history.info doc/automake.info*
    ${grep}/bin/grep "DO NOT EDIT BY HAND" -r t -l | while read -r file; do
      rm -f "''${file}"
    done

    cp ${help2man}/bin/help2man doc/
    perl ./gen-testsuite-part --srcdir . > t/testsuite-part.am
    touch Makefile.in

    # Configure
    AUTOCONF=autoconf-2.69 \
      ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    ${gnumake}/bin/make -j1 MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
