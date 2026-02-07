{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cc,
  binutils,
  gnumake,
  gnutar,
  bzip2,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "xz";
  version = "5.6.4";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://github.com/tukaani-project/xz/releases/download/v${version}/xz-${version}.tar.bz2";
    hash = "sha256-F21RDDDYCiO4BQu8BI8uyqy4I65ItoIXJ+1lkfDfkgA=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cc
      binutils
      gnumake
      gnutar
      bzip2
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "General-purpose data compression software";
      homepage = "https://tukaani.org/xz/";
      license = with lib.licenses; [
        gpl2Plus
        lgpl21Plus
      ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "xz";
    };
  }
  ''
    # Unpack
    cp ${src} xz.tar.bz2
    ${bzip2}/bin/bzip2 -d -f xz.tar.bz2
    ${gnutar}/bin/tar xf xz.tar
    rm xz.tar
    cd xz-${version}
    ${gnused}/bin/sed -i \
      -e "s|/bin/sh build-aux/version.sh|${bash}/bin/bash build-aux/version.sh|" \
      configure.ac
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" build-aux/version.sh
    chmod +x build-aux/version.sh

    # Prepare
    rm po/*.gmo
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in
    rm -rf po4a/man
    rm tests/files/*.xz tests/files/*.lz

    rm src/liblzma/rangecoder/price_table.c src/liblzma/lzma/fastpos_table.c \
      src/liblzma/lz/lz_encoder_hash_table.h \
      src/liblzma/check/crc32_table_*.h \
      src/liblzma/check/crc64_table_*.h

    (
      cd src/liblzma/rangecoder
      gcc -std=c99 -o price_tablegen price_tablegen.c
      ./price_tablegen > price_table.c
    )

    (
      cd src/liblzma/lzma
      gcc -std=c99 -o fastpos_tablegen fastpos_tablegen.c
      ./fastpos_tablegen > fastpos_table.c
    )

    (
      cd src/liblzma/check
      gcc -std=c99 -o crc32_tablegen_le crc32_tablegen.c
      ./crc32_tablegen_le > crc32_table_le.h
      gcc -std=c99 -DWORDS_BIGENDIAN -o crc32_tablegen_be crc32_tablegen.c
      ./crc32_tablegen_be > crc32_table_be.h
      gcc -std=c99 -DLZ_HASH_TABLE -o crc32_tablegen_hashtable crc32_tablegen.c
      ./crc32_tablegen_hashtable > ../lz/lz_encoder_hash_table.h

      gcc -std=c99 -o crc64_tablegen_le crc64_tablegen.c
      ./crc64_tablegen_le > crc64_table_le.h
      gcc -std=c99 -DWORDS_BIGENDIAN -o crc64_tablegen_be crc64_tablegen.c
      ./crc64_tablegen_be > crc64_table_be.h
    )

      rm -f configure
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      AUTOCONF=autoconf-2.69 \
      AUTOM4TE=autom4te-2.69 \
      ${autoconf}/bin/autoreconf-2.69 -f
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --disable-shared \
        --disable-nls \
        --build=${target} \
        --libdir=''${out}/lib

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out}

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
  ''
