{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  buildGcc,
  buildMusl,
  crossGcc,
  crossBinutils,
  crossMusl,
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
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";
  gnuTarget = "x86_64-unknown-linux-gnu";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/findutils/findutils-${version}.tar.gz";
    hash = "sha256-gTzZQFrO7Fz+y+lkANAekN2te1EtMDRIcXbOUlirD3g=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/8e128e.tar.gz";
    hash = "sha256-/JXsuiv1rcZnNG+mqmJju+eaHhZl3ZUDHAzAY1/DuMU=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      buildGcc
      buildMusl
      crossGcc
      crossBinutils
      crossMusl
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
      description = "GNU Find Utilities (x86_64)";
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

    # Build CC wrapper (for host programs)
    mkdir -p /build/wrappers
    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -std=gnu17 \
      -Wno-error=implicit-function-declaration \
      -Wno-error=implicit-int \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 /build/wrappers/build-cc

    # Cross CC wrapper
    cat > ${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      --sysroot=${crossMusl} \
      -isystem ${crossMusl}/include \
      -std=gnu17 \
      -Wno-error=implicit-function-declaration \
      -Wno-error=implicit-int \
      -Wl,--dynamic-linker=${crossMusl}/lib/ld-musl-x86_64.so.1 \
      -Wl,-rpath,${crossMusl}/lib \
      "\$@"
    EOF
    chmod 555 ${target}-gcc

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 cc

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

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

    # Replace gnulib files that try to access musl's opaque FILE internals
    # with thin wrappers around musl's native implementations.
    cat > gnulib/lib/fseeko.c <<CEOF
    #include <stdio.h>
    int rpl_fseeko(FILE *fp, off_t offset, int whence) {
      return fseeko(fp, offset, whence);
    }
    CEOF
    cat > gnulib/lib/freadahead.c <<CEOF
    #include <stdio.h>
    #include <stddef.h>
    size_t freadahead(FILE *fp) { (void)fp; return 0; }
    CEOF

    # Configure
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      CPPFLAGS="-D__UCLIBC__" \
      ./configure \
        --prefix=''${out} \
        --build=${lib.replaceStrings ["-musl"] ["-gnu"] buildTarget} \
        --host=${gnuTarget}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
