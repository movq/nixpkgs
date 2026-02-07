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
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  gperf,
  m4,
  perl,
  autoconf,
  automake,
  help2man,
}:
let
  pname = "diffutils";
  version = "3.10";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuBuildTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] buildTarget;
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/diffutils/diffutils-${version}.tar.xz";
    hash = "sha256-kOXpPMck5OvhLt6A3xY0Bjx6hVaSaFkZv+YLVWyb0J4=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/5d2fe24.tar.gz";
    hash = "sha256-gnTBqqZ5YX8RKJOEjkk1be6a14ztBybBfELpXZKt+s8=";
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
      gzip
      findutils
      gnused
      grep
      gawk
      gperf
      m4
      perl
      autoconf
      automake
      help2man
    ];

    meta = {
      description = "GNU diffutils (x86_64)";
      homepage = "https://www.gnu.org/software/diffutils/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "diff";
    };
  }
  ''
    # Unpack
    ${xz}/bin/xz -d -c ${src} > diffutils.tar
    ${gnutar}/bin/tar xf diffutils.tar
    rm diffutils.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-5d2fe24

    cd diffutils-${version}

    cp ${./3.10/import-gnulib.sh} import-gnulib.sh
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" import-gnulib.sh
    chmod 555 import-gnulib.sh

    patch_shebangs() {
      local targetDir="$1"
      if [ -d "$targetDir" ]; then
        ${findutils}/bin/find "$targetDir" -type f -exec ${grep}/bin/grep -l '^#! */bin/sh' {} + | while IFS= read -r script; do
          ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
          chmod +x "$script"
        done
      fi
    }

    patch_shebangs ../gnulib-5d2fe24

    # Build CC wrapper (for host programs that run on the build machine)
    mkdir -p /build/wrappers
    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      --sysroot=${buildMusl} \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
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

    rm -f man/*.1
    rm -f doc/*.info
    rm -f lib/iconv_open*.h
    rm -f man/help2man
    ln -s ${help2man}/bin/help2man man/help2man

    ${bash}/bin/bash ./import-gnulib.sh

    patch_shebangs build-aux
    if [ -f po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in
    fi

    AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOPOINT=true \
      autoreconf-2.69 -fi

    patch_shebangs .
    if [ -f po/Makefile.in.in ]; then
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in
    fi

    # Configure
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      M4=${m4}/bin/m4 \
      ./configure \
        --prefix=''${out} \
        --build=${gnuBuildTarget} \
        --host=${target}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true

    # Install
    ${gnumake}/bin/make SHELL=${bash}/bin/bash install MAKEINFO=true
  ''
