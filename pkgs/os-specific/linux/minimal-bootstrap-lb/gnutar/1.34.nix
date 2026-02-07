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
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  bison,
}:
let
  pname = "tar";
  version = "1.34";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/tar/tar-${version}.tar.xz";
    hash = "sha256-Y769JoecXh7qQ1Lw0DyZH5Zq6z3es8dEXJAlaNVBHSg=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/30820c.tar.gz";
    hash = "sha256-9VsMRxBhyRdsTzvEhoYfV6Y0jaDvH/yvq0w+bWXYsLw=";
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
      xz
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      bison
    ];

    meta = {
      description = "GNU tar archiving program (x86_64)";
      homepage = "https://www.gnu.org/software/tar/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "tar";
    };
  }
  ''
    # Unpack
    ${xz}/bin/unxz -c ${src} | ${gnutar}/bin/tar xf -

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-30820c
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" gnulib-30820c/gnulib-tool
    chmod +x gnulib-30820c/gnulib-tool
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-30820c/build-aux/po/Makefile.in.in

    cd tar-${version}

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
    cp ${./import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    ${bash}/bin/sh ./import-gnulib.sh
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    rm gnu/parse-datetime.c gnu/parse-datetime-gen.h
    rm po/*.gmo
    rm doc/tar.info*
    rm tests/testsuite

      rm -f configure
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    FORCE_UNSAFE_CONFIGURE=1 \
      CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --disable-nls \
        --build=${buildTarget} \
        --host=${target} \
        gl_cv_func_getcwd_path_max="no, but it is partly working"

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out} MAKEINFO=true

    # Install
    ${gnumake}/bin/make install PREFIX=''${out} MAKEINFO=true
  ''
