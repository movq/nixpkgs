{
  lib,
  fetchurl,
  bash,
  coreutils,
  buildGcc,
  buildMusl,
  crossGcc,
  crossBinutils,
  crossMusl,
  gnumake,
  gnutar,
  gzip,
}:
let
  pname = "bzip2";
  version = "1.0.8";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://sourceware.org/pub/bzip2/bzip2-${version}.tar.gz";
    hash = "sha256-q1oDF27hBtPw+pDjgdpHjdrkBZGBU8yiSOaCzQxKImk=";
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
    ];

    meta = {
      description = "High-quality data compression program (x86_64)";
      homepage = "https://www.sourceware.org/bzip2";
      license = lib.licenses.bsdOriginal;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bzip2";
    };
  }
  ''
    # Unpack
    cp ${src} bzip2.tar.gz
    ${gzip}/bin/gzip -d -f bzip2.tar.gz
    ${gnutar}/bin/tar xf bzip2.tar
    rm bzip2.tar
    cd bzip2-${version}

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

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CC=cc \
      AR="${crossBinutils}/bin/${target}-ar" \
      RANLIB="${crossBinutils}/bin/${target}-ranlib" \
      CFLAGS="-Wall -Winline -O2 -D_FILE_OFFSET_BITS=64" \
      SHELL="${bash}/bin/sh" \
      bzip2

    # Install
    mkdir -p ''${out}/bin
    cp bzip2 ''${out}/bin/bzip2
    chmod 555 ''${out}/bin/bzip2
    ln -s bzip2 ''${out}/bin/bunzip2
    ln -s bzip2 ''${out}/bin/bzcat
  ''
