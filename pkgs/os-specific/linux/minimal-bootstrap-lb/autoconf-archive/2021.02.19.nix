{
  lib,
  fetchurl,
  bash,
  coreutils,
  gnumake,
  gnutar,
  xz,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "autoconf-archive";
  version = "2021.02.19";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/autoconf-archive/autoconf-archive-${version}.tar.xz";
    hash = "sha256-6KbrnSjdy6j/7z+iEWUyOem/I5q6agGmt8/Hzq7GnL0=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      gnumake
      gnutar
      xz
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "Collection of reusable Autoconf macros";
      homepage = "https://www.gnu.org/software/autoconf-archive/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > autoconf-archive.tar
    ${gnutar}/bin/tar xf autoconf-archive.tar
    rm autoconf-archive.tar
    cd autoconf-archive-${version}

    # Prepare
    for script in build-aux/*; do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

      rm -f configure
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    rm doc/*.info*

    # Configure
    ./configure --prefix=''${out}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
