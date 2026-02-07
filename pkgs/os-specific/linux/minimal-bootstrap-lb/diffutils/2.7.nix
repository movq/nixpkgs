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
  pname = "diffutils";
  version = "2.7";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/diffutils/diffutils-${version}.tar.gz";
    hash = "sha256-1fJInEBWoxUo462krazCPUmFMrCvGpgPL3YVgWKxOdY=";
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
    cp ${src} diffutils.tar.gz
    ${gzip}/bin/gzip -d -f diffutils.tar.gz
    ${gnutar}/bin/tar xf diffutils.tar
    rm diffutils.tar
    cd diffutils-${version}

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
    touch config.h
    cp ${./main.mk} Makefile

    # Build
    ${gnumake}/bin/make -f Makefile -j "$NIX_BUILD_CORES" CC=cc

    # Install
    ${gnumake}/bin/make -f Makefile install PREFIX=''${out}
  ''
