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
  bzip2,
  gnused,
  grep,
  gawk,
}:
let
  pname = "patchelf";
  version = "0.15.2";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://github.com/NixOS/patchelf/releases/download/${version}/patchelf-${version}.tar.bz2";
    hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
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
      bzip2
      gnused
      grep
      gawk
    ];

    meta = {
      description = "Utility to modify the dynamic linker and RPATH of ELF executables (x86_64)";
      homepage = "https://github.com/NixOS/patchelf";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "patchelf";
    };
  }
  ''
    # Unpack
    cp ${src} patchelf.tar.bz2
    ${bzip2}/bin/bzip2 -d patchelf.tar.bz2
    ${gnutar}/bin/tar xf patchelf.tar
    rm patchelf.tar
    cd patchelf-${version}

    # Build CC wrapper (for host programs)
    mkdir -p /build/wrappers
    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -std=gnu17 \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 /build/wrappers/build-cc

    cat > /build/wrappers/build-cxx <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/g++ \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 /build/wrappers/build-cxx

    # Cross CC/CXX wrappers
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

    cat > ${target}-g++ <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-g++ \
      --sysroot=${crossMusl} \
      -Wl,--dynamic-linker=${crossMusl}/lib/ld-musl-x86_64.so.1 \
      -Wl,-rpath,${crossMusl}/lib \
      "\$@"
    EOF
    chmod 555 ${target}-g++

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 cc

    cat > c++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-g++" "\$@"
    EOF
    chmod 555 c++

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Configure - patchelf ships a pre-generated configure script
    CC_FOR_BUILD=/build/wrappers/build-cc \
      CXX_FOR_BUILD=/build/wrappers/build-cxx \
      CC=cc \
      CXX=c++ \
      CONFIG_SHELL=${bash}/bin/bash \
      SHELL=${bash}/bin/bash \
      ${bash}/bin/bash ./configure \
        --prefix=''${out} \
        --build=${buildTarget} \
        --host=${target}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash

    # Install
    ${gnumake}/bin/make SHELL=${bash}/bin/bash install
  ''
