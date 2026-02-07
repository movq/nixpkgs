{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  buildGcc,
  crossGcc,
  crossBinutils,
  crossMusl,
  buildMusl,
  gnumake,
  gnupatch,
  gnutar,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  autoconfArchive,
  libtool,
  gmp,
  buildGmp,
  buildMpfr,
}:
let
  pname = "mpfr";
  version = "4.1.0";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/mpfr/mpfr-${version}.tar.xz";
    hash = "sha256-DJij8XMv9spOppBVIHnanFl4ctMOluwoQU7iPJVVin8=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      buildGcc
      crossGcc
      crossBinutils
      crossMusl
      buildMusl
      gnumake
      gnupatch
      gnutar
      xz
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      autoconfArchive
      libtool
      gmp
      buildGmp
      buildMpfr
    ];

    meta = {
      description = "GNU multiple-precision floating-point library (x86_64)";
      homepage = "https://www.mpfr.org/";
      license = lib.licenses.lgpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > mpfr.tar
    ${gnutar}/bin/tar xf mpfr.tar
    rm mpfr.tar

    ${gnupatch}/bin/patch -Np0 -i ${./4.1.0/patches/strtofr-gen-fix.patch}
    cd mpfr-${version}

    # Build CC wrapper (for host programs)
    cat > build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 build-cc

    # Cross CC wrapper
    cat > ${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      --sysroot=${crossMusl} \
      -isystem ${crossMusl}/include \
      "\$@"
    EOF
    chmod 555 ${target}-gcc

    cat > gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 gcc

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 cc

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Prepare
    ${gnused}/bin/sed -i '/^  {/,/ };$/d' src/strtofr.c
    cp src/strtofr.c src/strtofr.c.old
    ${gnused}/bin/sed -i '/int RedInvLog2Table/ s/$/};/' src/strtofr.c

    for script in \
      ar-lib compile config.guess config.sub depcomp install-sh missing test-driver \
      doc/check-typography tools/*
    do
      if [ -f "$script" ]; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod +x "$script"
      fi
    done

    rm doc/*.info
    rm tests/tfpif_*.dat tests/tstrtofr.c

    cp ${./4.1.0/files/mparam.h} mparam.h

      rm -f configure
      ACLOCAL_PATH="${autoconfArchive}/share/aclocal:${libtool}/share/aclocal" \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    CC_FOR_BUILD="./build-cc" \
      CPPFLAGS="-I${gmp}/include" \
      LDFLAGS="-L${gmp}/lib" \
      CC=cc \
      AR=${crossBinutils}/bin/${target}-ar \
      RANLIB=${crossBinutils}/bin/${target}-ranlib \
      NM=${crossBinutils}/bin/${target}-nm \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --build=${buildTarget} \
        --host=${target} \
        --disable-shared

    mv mparam.h src

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Regenerate strtofr table using build tools
    pushd src
    cat > strtofr_gen.c <<EOF
    #include <stdio.h>
    #include <gmp.h>
    #include <mpfr.h>
    EOF

    ${gnused}/bin/sed -n '/^#define N 8$/,/^}$/p' strtofr.c >> strtofr_gen.c
    ../build-cc strtofr_gen.c -o strtofr_gen -std=gnu99 -I. -I${buildGmp}/include \
      -I${buildMpfr}/include -L${buildMpfr}/lib -L${buildGmp}/lib -lmpfr -lgmp
    ./strtofr_gen 2>strtofr_table >/dev/null
    echo "};" >> strtofr_table
    ${gnused}/bin/sed "/int RedInvLog2Table/ r strtofr_table" strtofr.c.old > strtofr.c
    popd

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
