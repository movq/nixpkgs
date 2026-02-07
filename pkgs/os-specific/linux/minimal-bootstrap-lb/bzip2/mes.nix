{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
}:
let
  pname = "bzip2-mes";
  version = "1.0.8";

  src = fetchurl {
    url = "https://sourceware.org/pub/bzip2/bzip2-${version}.tar.gz";
    sha256 = "0s92986cv0p692icqlw1j42y9nld8zd83qwhzbqd61p1dqbh6nmb";
  };

  patches = [
    ./mes-libc.patch
    ./coreutils.patch
  ];
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnutar
      gzip
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/bzip2 --help
        mkdir ''${out}
      '';

    meta = {
      description = "High-quality data compression program";
      homepage = "https://www.sourceware.org/bzip2";
      license = lib.licenses.bsdOriginal;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} bzip2-${version}.tar.gz
    ${gzip}/bin/gzip -d -f bzip2-${version}.tar.gz
    ${gnutar}/bin/tar xf bzip2-${version}.tar
    rm bzip2-${version}.tar
    cd bzip2-${version}

    # Patch
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

    # Build
    ${gnumake}/bin/make \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      AR="${tinycc.compiler}/bin/tcc -ar" \
      LDFLAGS="-static" \
      bzip2

    # Install
    mkdir -p ''${out}/bin
    cp bzip2 ''${out}/bin/bzip2
    cp bzip2 ''${out}/bin/bunzip2
    chmod 555 ''${out}/bin/bzip2
    chmod 555 ''${out}/bin/bunzip2
  ''
