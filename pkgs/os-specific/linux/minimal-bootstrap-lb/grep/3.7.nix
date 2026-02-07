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
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/grep/grep-${version}.tar.xz";
    hash = "sha256-XBDaMSRgrschmE1dgyRtJFIOxDjdSNerWgXbwNbWgjw=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/8f4538a5.tar.gz";
    hash = "sha256-rxTcOb9aMzLaEeVRvJfQLeFYZMnoaI8tcSD/yHxBSvI=";
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
      description = "GNU implementation of grep (x86_64)";
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
    ln -s ${automake}/bin/aclocal-1.16 aclocal
    ln -s ${automake}/bin/automake-1.16 automake
    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Prepare
    rm configure
    ${findutils}/bin/find . -name 'Makefile.in' -delete

    ${bash}/bin/bash ./import-gnulib.sh

    AUTOPOINT=true \
      AUTOMAKE=automake-1.16 \
      ACLOCAL="aclocal-1.16 -I m4" \
      ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi

    # Configure
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      CONFIG_SHELL=${bash}/bin/bash \
      SHELL=${bash}/bin/bash \
      ${bash}/bin/bash ./configure \
        --prefix=''${out} \
        --build=${buildTarget} \
        --host=${target}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
