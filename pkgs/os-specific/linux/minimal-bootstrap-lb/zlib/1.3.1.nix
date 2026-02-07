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
  gnused,
}:
let
  pname = "zlib";
  version = "1.3.1";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://zlib.net/fossils/zlib-${version}.tar.gz";
    hash = "sha256-mpOyt9/ax3zrpaVYpYDnRmfdb+3kWFuR7vtg8Dty3yM=";
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
    ];

    meta = {
      description = "Compression library implementing the DEFLATE algorithm (x86_64)";
      homepage = "https://zlib.net/";
      license = lib.licenses.zlib;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} zlib.tar.gz
    ${gzip}/bin/gzip -d -f zlib.tar.gz
    ${gnutar}/bin/tar xf zlib.tar
    rm zlib.tar
    cd zlib-${version}
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" configure
    chmod +x configure
    ${gnused}/bin/sed -i "s|^SHELL=/bin/sh$|SHELL=${bash}/bin/bash|" Makefile.in

    # Build CC wrapper (for host programs that need to run during build)
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

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 cc

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Prepare - build generators with build CC
    rm zlib.3.pdf \
      doc/crc-doc.1.0.pdf \
      contrib/puff/zeros.raw \
      contrib/blast/test.pk \
      contrib/dotzlib/DotZLib.chm

    rm crc32.h
    ./build-cc -DMAKECRCH crc32.c -o gen_crc32h
    ./gen_crc32h

    cat > makefixed_main.c <<EOF
    void makefixed(void);
    int main() { makefixed(); }
    EOF
    ./build-cc -DMAKEFIXED inflate.c crc32.c zutil.c inftrees.c \
      adler32.c inffast.c makefixed_main.c -o gen_inffixedh
    ./gen_inffixedh > inffixed.h

    cat > makefixed9_main.c <<EOF
    void makefixed9(void);
    int main() { makefixed9(); }
    EOF
    ./build-cc -DMAKEFIXED -I. contrib/infback9/infback9.c zutil.c \
      contrib/infback9/inftree9.c makefixed9_main.c -o gen_inffix9h
    ./gen_inffix9h > contrib/infback9/inffix9.h

    # Configure
    CHOST=${target} CC=cc AR="${crossBinutils}/bin/${target}-ar" \
      RANLIB="${crossBinutils}/bin/${target}-ranlib" \
      ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --shared

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES"

    # Install
    ${gnumake}/bin/make install
  ''
