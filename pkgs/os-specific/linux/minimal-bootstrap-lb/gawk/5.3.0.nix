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
  gnutar,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  bison,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
}:
let
  pname = "gawk";
  version = "5.3.0";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuBuildTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] buildTarget;
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gawk/gawk-${version}.tar.xz";
    hash = "sha256-ypwW09EdD/jGnXncC0cmfhMppps5t5mJVgTtRH08qQs=";
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
      gnutar
      xz
      findutils
      gnused
      grep
      gawk
      bison
      m4
      perl
      autoconf
      automake
      libtool
    ];

    meta = {
      description = "GNU implementation of the AWK programming language (x86_64)";
      homepage = "https://www.gnu.org/software/gawk/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gawk";
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > gawk.tar
    ${gnutar}/bin/tar xf gawk.tar
    rm gawk.tar
    cd gawk-${version}

    # Build CC wrapper (for host programs)
    mkdir -p /build/wrappers
    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      --sysroot=${buildMusl} \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -std=gnu11 \
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
      -std=gnu11 \
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
    export AUTOCONF=autoconf-2.71
    export AUTOHEADER=autoheader-2.71
    export AUTOM4TE=autom4te-2.71
    export AUTORECONF=autoreconf-2.71
    export AUTOUPDATE=autoupdate-2.71
    export AUTOMAKE=automake-1.16
    export ACLOCAL=aclocal-1.16

    ${findutils}/bin/find . -type f -exec ${grep}/bin/grep -l '^#! */bin/sh' {} + | while IFS= read -r script; do
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
      chmod +x "$script"
    done

    rm -f doc/*.info
    rm -f awkgram.c command.c
    ${gnused}/bin/sed -i '/rm -fr eg &&/d' awklib/Makefile.am

    shopt -s globstar nullglob
    rm -f configure aclocal.m4
    for makefileIn in **/Makefile.in; do
      rm -f "''${makefileIn}"
    done
    shopt -u globstar nullglob

    AUTOPOINT=true \
      ACLOCAL_PATH="${libtool}/share/aclocal" \
      autoreconf-2.71 -fiv

    ${findutils}/bin/find . -type f -exec ${grep}/bin/grep -l '^#! */bin/sh' {} + | while IFS= read -r script; do
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
      chmod +x "$script"
    done

    # Configure
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      AUTOCONF=autoconf-2.71 \
      AUTOHEADER=autoheader-2.71 \
      AUTOM4TE=autom4te-2.71 \
      AUTORECONF=autoreconf-2.71 \
      AUTOUPDATE=autoupdate-2.71 \
      AUTOMAKE=automake-1.16 \
      ACLOCAL=aclocal-1.16 \
      CFLAGS="-std=gnu11" \
      AWK=${gawk}/bin/gawk \
      ./configure \
        --prefix=''${out} \
        --build=${gnuBuildTarget} \
        --host=${target} \
        --disable-maintainer-mode

    # Build
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      AWK=${gawk}/bin/gawk \
      ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true \
        AUTOCONF=autoconf-2.71 \
        AUTOHEADER=autoheader-2.71 \
        AUTOM4TE=autom4te-2.71 \
        AUTORECONF=autoreconf-2.71 \
        AUTOUPDATE=autoupdate-2.71 \
        AUTOMAKE=automake-1.16 \
        ACLOCAL=aclocal-1.16

    # Install
    ${gnumake}/bin/make SHELL=${bash}/bin/bash install MAKEINFO=true \
      AUTOCONF=autoconf-2.71 \
      AUTOHEADER=autoheader-2.71 \
      AUTOM4TE=autom4te-2.71 \
      AUTORECONF=autoreconf-2.71 \
      AUTOUPDATE=autoupdate-2.71 \
      AUTOMAKE=automake-1.16 \
      ACLOCAL=aclocal-1.16
  ''
