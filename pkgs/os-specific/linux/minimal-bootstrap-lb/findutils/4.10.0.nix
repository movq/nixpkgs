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
  gnused,
  grep,
  gawk,
  autoconf,
  automake,
  libtool,
}:
let
  pname = "findutils";
  version = "4.10.0";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuBuildTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] buildTarget;
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/findutils/findutils-${version}.tar.xz";
    hash = "sha256-E4fgtn/yR9Kr3pmPkN+/cMFJE5Glnd/suK5ph4nwpPU=";
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
      gnused
      grep
      gawk
      autoconf
      automake
      libtool
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
    ${xz}/bin/xz -d -c ${src} > findutils.tar
    ${gnutar}/bin/tar xf findutils.tar
    rm findutils.tar
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

    ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
    while read -r script; do
      [ -n "''${script}" ] || continue
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
      chmod +x "''${script}"
    done < sh-scripts.list
    rm -f sh-scripts.list

    # Regenerate autotools outputs from source templates.
    shopt -s globstar nullglob
    rm -f configure aclocal.m4
    for makefileIn in **/Makefile.in; do
      rm -f "''${makefileIn}"
    done
    shopt -u globstar nullglob

    AUTOPOINT=true \
      ACLOCAL_PATH="${libtool}/share/aclocal" \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fiv

    ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
    while read -r script; do
      [ -n "''${script}" ] || continue
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
      chmod +x "''${script}"
    done < sh-scripts.list
    rm -f sh-scripts.list

    # Configure
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      SORT=${coreutils}/bin/sort \
      ./configure \
        --prefix=''${out} \
        --build=${gnuBuildTarget} \
        --host=${target}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
