{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cxx,
  binutils,
  gnumake,
  gnutar,
  gzip,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
}:
let
  pname = "texinfo";
  version = "6.7";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/texinfo/texinfo-${version}.tar.xz";
    hash = "sha256-mIQDwVQtFa0ERgC5CZl7owebEOAyJMYRiBF/NnawLKo=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/b81ec69.tar.gz";
    hash = "sha256-TDiKKA3gY6i4jMiCU4+hSLdTtm2sE2lhONvHfh1Gtyg=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cxx
      binutils
      gnumake
      gnutar
      gzip
      xz
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libtool
    ];

    meta = {
      description = "GNU documentation system";
      homepage = "https://www.gnu.org/software/texinfo/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "texi2any";
    };
  }
  ''
    # Unpack
    cp ${src} texinfo.tar.xz
    unxz texinfo.tar.xz
    ${gnutar}/bin/tar xf texinfo.tar
    rm texinfo.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-b81ec69

    cd texinfo-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${findutils}/bin/find . -name '*.mo' -delete
    ${findutils}/bin/find . -name '*.gmo' -delete

    (
      cd ../gnulib-b81ec69
      ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
      while read -r script; do
        [ -n "''${script}" ] || continue
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
        chmod 755 "''${script}"
      done < sh-scripts.list
      rm -f sh-scripts.list
    )

    cp ${./6.7/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" import-gnulib.sh
    ${bash}/bin/bash ./import-gnulib.sh

    sed -i '65,66c\  SUBDIRS += util' Makefile.am
    rm configure Makefile.in
    AUTOMAKE=automake-1.15 \
    ACLOCAL=aclocal-1.15 \
    AUTOCONF=autoconf \
    AUTOPOINT=true \
    ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    CONFIG_SHELL=${bash}/bin/bash SHELL=${bash}/bin/bash CC=cc CXX=c++ \
      ./configure \
      --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make SHELL=${bash}/bin/bash MAKEINFO=true install
  ''
