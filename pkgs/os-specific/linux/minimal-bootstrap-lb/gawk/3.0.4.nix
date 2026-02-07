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
  bison,
  m4,
}:
let
  pname = "gawk";
  version = "3.0.4";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gawk/gawk-${version}.tar.gz";
    hash = "sha256-XMNd7x/0N1qLmpjC/3npXoCYfSTw1C/bt7cDmz3bP7A=";
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
      bison
      m4
    ];

    meta = {
      description = "GNU implementation of the AWK programming language (x86_64)";
      homepage = "https://www.gnu.org/software/gawk/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gawk";
    };
  }
  ''
    # Unpack
    cp ${src} gawk.tar.gz
    ${gzip}/bin/gzip -d -f gawk.tar.gz
    ${gnutar}/bin/tar xf gawk.tar
    rm gawk.tar
    cd gawk-${version}

    # Cross CC wrapper
    cat > ${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      --sysroot=${crossMusl} \
      -isystem ${crossMusl}/include \
      -std=gnu89 \
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

    # Configure
    rm awktab.c
    rm pc/config.h
    cp ${./main.mk} Makefile

    # Build - override CFLAGS to use GCC builtin alloca instead of C_ALLOCA,
    # and exclude alloca.o from the build
    sed -i 's/-DC_ALLOCA=1/-DHAVE_ALLOCA_H=1/' Makefile
    sed -i 's/alloca //' Makefile
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      M4="${m4}/bin/m4" \
      ${gnumake}/bin/make -f Makefile -j1 \
        PREFIX=''${out} \
        CC=cc

    # Install
    ${gnumake}/bin/make -f Makefile \
      PREFIX=''${out} \
      install

    install -d ''${out}/share/awk
    for file in awklib/eg/lib/*.awk; do
      install -m 644 "''${file}" ''${out}/share/awk/
    done
  ''
