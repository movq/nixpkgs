{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  buildGcc,
  crossGcc,
  crossBinutils,
  crossMusl,
  buildMusl,
  gnumake,
  gnutar,
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  autoconfArchive,
  libtool,
  gmp,
  mpfr,
}:
let
  pname = "mpc";
  version = "1.2.1";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/mpc/mpc-${version}.tar.gz";
    hash = "sha256-F1A9LDld/PEGtiLcFCaDwRmUMdCVNnxqrLpu7DA0BFk=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      buildGcc
      crossGcc
      crossBinutils
      crossMusl
      buildMusl
      gnumake
      gnutar
      gzip
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      autoconfArchive
      libtool
      gmp
      mpfr
    ];

    meta = {
      description = "Library for multiprecision complex arithmetic (x86_64)";
      homepage = "https://www.multiprecision.org/mpc/";
      license = lib.licenses.lgpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} mpc.tar.gz
    ${gzip}/bin/gzip -d -f mpc.tar.gz
    ${gnutar}/bin/tar xf mpc.tar
    rm mpc.tar
    cd mpc-${version}

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

    # Prepare
    find . -name '*.info' -delete

      rm -f configure
      ACLOCAL_PATH="${autoconfArchive}/share/aclocal:${libtool}/share/aclocal" \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    CPPFLAGS="-I${gmp}/include -I${mpfr}/include" \
      LDFLAGS="-L${gmp}/lib -L${mpfr}/lib" \
      CC=cc \
      AR=${crossBinutils}/bin/${target}-ar \
      RANLIB=${crossBinutils}/bin/${target}-ranlib \
      NM=${crossBinutils}/bin/${target}-nm \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --build=${buildTarget} \
        --host=${target} \
        --disable-shared \
        --with-gmp=${gmp} \
        --with-mpfr=${mpfr}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
