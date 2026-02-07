{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  buildGcc,
  buildMusl,
  crossGcc,
  crossBinutils,
  crossMusl,
  gnumake,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  bison,
}:
let
  pname = "bash";
  version = "5.2.15";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/bash/bash-${version}.tar.gz";
    hash = "sha256-E3IJZbX0/DoNS2HdN+dWXHQdqaW+JO3CrgAYL8GzWIw=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      buildGcc
      buildMusl
      crossGcc
      crossBinutils
      crossMusl
      gnumake
      gnutar
      gzip
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      bison
    ];

    meta = {
      description = "GNU Bourne-Again Shell (x86_64)";
      homepage = "https://www.gnu.org/software/bash/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bash";
    };
  }
  ''
    # Unpack
    cp ${src} bash.tar.gz
    ${gzip}/bin/gzip -d -f bash.tar.gz
    ${gnutar}/bin/tar xf bash.tar
    rm bash.tar
    cd bash-${version}

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
    rm y.tab.c y.tab.h
    rm po/*.gmo

    mv doc/Makefile.in Makefile.in.doc
    rm doc/*
    mv Makefile.in.doc doc/Makefile.in

    rm lib/sh/strtoimax.c
    touch lib/sh/strtoimax.c

    ${gnused}/bin/sed -i \
      -e "s|MAKE_SHELL=/bin/sh|MAKE_SHELL=${bash}/bin/bash|" \
      -e "s|/bin/sh}|${bash}/bin/bash}|" \
      configure.ac

    rm configure
    ${autoconf}/bin/autoconf-2.69

    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" \
      lib/intl/Makefile.in po/Makefile.in.in

    cat > builtins/psize.sh <<EOF
    #!${bash}/bin/bash
    echo "#define PIPESIZE 65536"
    EOF
    chmod 555 builtins/psize.sh

    # Configure
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --without-bash-malloc \
        --enable-static-link \
        --disable-nls \
        --build=${buildTarget} \
        --host=${target} \
        bash_cv_dev_stdin=absent \
        bash_cv_dev_fd=whacky

    # Build
    ${gnumake}/bin/make -j1 PREFIX=''${out}

    # Install
    install -m 555 -D bash ''${out}/bin/bash
    install -m 555 bash ''${out}/bin/sh
  ''
