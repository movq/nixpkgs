{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cc,
  binutils,
  gnumake,
  gnupatch,
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
  pname = "libunistring";
  version = "0.9.10";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/libunistring/libunistring-${version}.tar.xz";
    hash = "sha256-64+yw+S24tM2YIN3BQiStUw8mDtkbFYYNlUIYwA8Bdc=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/52a06cb3.tar.gz";
    hash = "sha256-H7kWk+7KS4Fvc/uPvKrb8DZvXB4Y490fISjaUxDeN00=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cc
      binutils
      gnumake
      gnupatch
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
      description = "Unicode string library";
      homepage = "https://www.gnu.org/software/libunistring/";
      license = lib.licenses.lgpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} libunistring.tar.xz
    ${xz}/bin/xz -d -f libunistring.tar.xz
    ${gnutar}/bin/tar xf libunistring.tar
    rm libunistring.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-52a06cb3

    (
      cd gnulib-52a06cb3
      ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
      while read -r script; do
        [ -n "''${script}" ] || continue
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
        chmod 755 "''${script}"
      done < sh-scripts.list
      rm -f sh-scripts.list
    )

    cd libunistring-${version}

    # Prepare
    ${findutils}/bin/find . -name '*.info*' -delete
    ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
    while read -r script; do
      [ -n "''${script}" ] || continue
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
      chmod 755 "''${script}"
    done < sh-scripts.list
    rm -f sh-scripts.list
    GNULIB_TOOL=../gnulib-52a06cb3/gnulib-tool ${bash}/bin/bash ./autogen.sh
    rm -f configure
    ACLOCAL=aclocal-1.15 \
      AUTOMAKE=automake-1.15 \
      ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    CONFIG_SHELL=${bash}/bin/bash SHELL=${bash}/bin/bash CC=cc \
      ${bash}/bin/bash ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --disable-shared

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
