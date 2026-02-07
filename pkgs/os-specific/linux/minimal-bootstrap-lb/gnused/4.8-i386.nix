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
  automake,
}:
let
  pname = "sed";
  version = "4.8";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/sed/sed-${version}.tar.xz";
    hash = "sha256-95sM/qcbN6ju7ISQ22xfeudxnDVYfyHtsGF/Nw7v9jM=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/d279bc.tar.gz";
    hash = "sha256-wvSmGL3L+tnp5xD+e4vAQGfk/ENGDpW6ySL4suAQyVc=";
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
      automake
    ];

    meta = {
      description = "GNU stream editor";
      homepage = "https://www.gnu.org/software/sed/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "sed";
    };
  }
  ''
    # Unpack
    cp ${src} sed.tar.xz
    ${xz}/bin/xz -d -f sed.tar.xz
    ${gnutar}/bin/tar xf sed.tar
    rm sed.tar

    cp ${gnulibSrc} gnulib-d279bc.tar.gz
    ${gzip}/bin/gzip -d -f gnulib-d279bc.tar.gz
    mkdir -p gnulib-d279bc
    ${gnutar}/bin/tar xf gnulib-d279bc.tar --strip-components=1 -C gnulib-d279bc
    rm gnulib-d279bc.tar

    (
      cd gnulib-d279bc
      ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
      while read -r script; do
        [ -n "''${script}" ] || continue
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
        chmod 755 "''${script}"
      done < sh-scripts.list
      rm -f sh-scripts.list
    )

    cd sed-${version}
    cp ${./4.8/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh

    export PATH="${binutils}/bin:$PATH"

    # Prepare
    rm configure
    ${findutils}/bin/find . -name 'Makefile.in' -delete

    ${bash}/bin/bash ./import-gnulib.sh

    AUTOPOINT=true \
      AUTOMAKE=automake-1.16 \
      ACLOCAL="aclocal-1.16 -I m4" \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    GL_GENERATE_ALLOCA_H_TRUE=0 \
      LDFLAGS="-static" \
      CONFIG_SHELL=${bash}/bin/bash \
      SHELL=${bash}/bin/bash \
      CC=cc \
      ${bash}/bin/bash ./configure \
        --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
