{
  lib,
  fetchurl,
  bash,
  coreutils,
  diffutils,
  cc,
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
  autoconf269,
  automake,
}:
let
  pname = "grep";
  version = "3.7";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/grep/grep-${version}.tar.xz";
    hash = "sha256-XBDaMSRgrschmE1dgyRtJFIOxDjdSNerWgXbwNbWgjw=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/8f4538a5.tar.gz";
    hash = "sha256-rxTcOb9aMzLaEeVRvJfQLeFYZMnoaI8tcSD/yHxBSvI=";
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
      autoconf269
      automake
    ];

    meta = {
      description = "GNU implementation of grep, egrep, and fgrep";
      homepage = "https://www.gnu.org/software/grep/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "grep";
    };
  }
  ''
    # Unpack
    cp ${src} grep.tar.xz
    ${xz}/bin/xz -d -f grep.tar.xz
    ${gnutar}/bin/tar xf grep.tar
    rm grep.tar

    cp ${gnulibSrc} gnulib-8f4538a5.tar.gz
    ${gzip}/bin/gzip -d -f gnulib-8f4538a5.tar.gz
    mkdir -p gnulib-8f4538a5
    ${gnutar}/bin/tar xf gnulib-8f4538a5.tar --strip-components=1 -C gnulib-8f4538a5
    rm gnulib-8f4538a5.tar

    (
      cd gnulib-8f4538a5
      ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
      while read -r script; do
        [ -n "''${script}" ] || continue
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
        chmod 755 "''${script}"
      done < sh-scripts.list
      rm -f sh-scripts.list
    )

    cd grep-${version}
    cp ${./3.7/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh

    export PATH="${binutils}/bin:$PATH"

    # Prepare
    rm configure
    ${findutils}/bin/find . -name 'Makefile.in' -delete

    ${bash}/bin/bash ./import-gnulib.sh

    AUTOPOINT=true \
      AUTOMAKE=automake-1.16 \
      ACLOCAL="aclocal-1.16 -I m4" \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi

    # Configure
    CONFIG_SHELL=${bash}/bin/bash SHELL=${bash}/bin/bash CC=cc \
      ${bash}/bin/bash ./configure --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
