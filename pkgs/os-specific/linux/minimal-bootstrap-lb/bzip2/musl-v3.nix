{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  gzip,
}:
let
  pname = "bzip2";
  version = "1.0.8";

  src = fetchurl {
    url = "https://sourceware.org/pub/bzip2/bzip2-${version}.tar.gz";
    hash = "sha256-q1oDF27hBtPw+pDjgdpHjdrkBZGBU8yiSOaCzQxKImk=";
  };
in
bash.runCommand "${pname}-${version}-musl-v3"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnutar
      gzip
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-help-${version}" { } ''
        ${result}/bin/bzip2 --help
        mkdir ''${out}
      '';

    meta = {
      description = "High-quality data compression program";
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

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
      AR="${tinycc.compiler}/bin/tcc -ar" \
      CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -I ${musl}/include" \
      SHELL="${bash}/bin/sh" \
      bzip2

    # Install
    mkdir -p ''${out}/bin
    cp bzip2 ''${out}/bin/bzip2
    chmod 555 ''${out}/bin/bzip2
    ln -s bzip2 ''${out}/bin/bunzip2
    ln -s bzip2 ''${out}/bin/bzcat
  ''
