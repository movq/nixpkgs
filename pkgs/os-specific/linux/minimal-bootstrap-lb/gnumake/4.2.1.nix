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
  pkgConfig,
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
  pname = "make";
  version = "4.2.1";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/make/make-${version}.tar.gz";
    hash = "sha256-5AuPAYwdpk7dHMmm/OX6Y7LnB+QE4gytkfuuM3yYpbc=";
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
      pkgConfig
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
      description = "GNU Make (x86_64)";
      homepage = "https://www.gnu.org/software/make/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "make";
    };
  }
  ''
    # Unpack
    cp ${src} make.tar.gz
    ${gzip}/bin/gzip -d -f make.tar.gz
    ${gnutar}/bin/tar xf make.tar
    rm make.tar
    cd make-${version}

    # Patch default shell
    ${gnused}/bin/sed -i 's|"/bin/sh"|"${bash}/bin/bash"|' job.c

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
      -std=gnu17 \
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
    rm doc/make.info*
    rm po/*.gmo

      rm -f configure
      ACLOCAL_PATH="${pkgConfig}/share/aclocal" \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    # Configure
    CC_FOR_BUILD=./build-cc \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${buildTarget} \
        --host=${target} \
        --disable-nls

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
