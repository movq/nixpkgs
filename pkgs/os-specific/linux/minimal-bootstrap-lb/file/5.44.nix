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
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
}:
let
  pname = "file";
  version = "5.44";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "http://ftp.astron.com/pub/file/file-${version}.tar.gz";
    hash = "sha256-N1HH+6jbyDHLjXzIr/IQNUWbjOUVXviwiAon0ChHXzs=";
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
      gzip
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libtool
    ];

    meta = {
      description = "Program that shows the type of files";
      homepage = "https://darwinsys.com/file";
      license = lib.licenses.bsd2;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "file";
    };
  }
  ''
    # Unpack
    cp ${src} file.tar.gz
    ${gzip}/bin/gzip -d -f file.tar.gz
    ${gnutar}/bin/tar xf file.tar
    rm file.tar
    cd file-${version}

    # Prepare
    rm tests/*.testfile

      rm -f configure
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      ${autoconf}/bin/autoreconf-2.69 -fi

    # Configure
    CC=cc \
      CFLAGS="-std=gnu99" \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --build=${target} \
        --disable-shared

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES"

    # Install
    ${gnumake}/bin/make install
  ''
