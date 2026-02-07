{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  tinycc,
  musl,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "findutils";
  version = "4.2.33";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] target;

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/findutils/findutils-${version}.tar.gz";
    hash = "sha256-gTzZQFrO7Fz+y+lkANAekN2te1EtMDRIcXbOUlirD3g=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/8e128e.tar.gz";
    hash = "sha256-/JXsuiv1rcZnNG+mqmJju+eaHhZl3ZUDHAzAY1/DuMU=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      coreutils
      diffutils
      binutils
      gnumake
      gnupatch
      gnutar
      gzip
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "GNU Find Utilities";
      homepage = "https://www.gnu.org/software/findutils/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "find";
    };
  }
  ''
    # Unpack
    cp ${src} findutils.tar.gz
    ${gzip}/bin/gzip -d -f findutils.tar.gz
    ${gnutar}/bin/tar xf findutils.tar
    rm findutils.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-8e128e
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" gnulib-8e128e/gnulib-tool
    chmod +x gnulib-8e128e/gnulib-tool
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-8e128e/build-aux/po/Makefile.in.in

    cd findutils-${version}

    # Prepare
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" mkinstalldirs
    chmod +x mkinstalldirs
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    ${bash}/bin/sh ${./import-gnulib.sh}
    ${gnupatch}/bin/patch -Np1 -i ${./patches/force-getcwd-fallback.patch}

      rm -f configure
      AUTOMAKE=automake-1.10 \
      ACLOCAL=aclocal-1.10 \
      AUTOM4TE=autom4te-2.61 \
      AUTOCONF=autoconf-2.61 \
      autoreconf-2.61 -f

    rm doc/find.info
    rm po/*.gmo

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    cat > tcc <<EOF
    #!${bash}/bin/bash
    exec ${tinycc.compiler}/bin/tcc -B "''${PWD}/bootstrap-lib" "\$@"
    EOF
    chmod 555 tcc
    export PATH="''${PWD}:$PATH"

    # Configure
    CC=tcc \
      CPPFLAGS="-D__UCLIBC__" \
      ./configure \
        --prefix=''${out} \
        --build=${gnuTarget} \
        --host=${gnuTarget}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
