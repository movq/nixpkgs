{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
  gnupatch,
}:
let
  pname = "gzip";
  version = "1.2.4";

  src = fetchurl {
    url = "mirror://gnu/gzip/gzip-${version}.tar.gz";
    sha256 = "0ryr5b00qz3xcdcv03qwjdfji8pasp0007ay3ppmk71wl8c1i90w";
  };
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/gzip --version
        mkdir ''${out}
      '';

    meta = {
      description = "GNU zip compression program";
      homepage = "https://www.gnu.org/software/gzip";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ungz --file ${src} --output gzip.tar
    untar --file gzip.tar
    rm gzip.tar
    cd gzip-${version}

    cp ${./main.mk} Makefile
    catm gzip.c.new ${./stat_override.c} gzip.c
    cp gzip.c.new gzip.c

    # Regen CRC table
    ${gnupatch}/bin/patch -Np1 -i ${./removecrc.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./makecrc-write-to-file.patch}

    ${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib -static -o makecrc sample/makecrc.c
    ./makecrc
    catm util.c.new util.c crc.c
    cp util.c.new util.c

    # Build
    ${gnumake}/bin/make CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" AR="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib -ar"

    # Install
    mkdir -p ''${out}/bin
    cp gzip ''${out}/bin/gzip
    cp gzip ''${out}/bin/gunzip
    chmod 555 ''${out}/bin/gzip
    chmod 555 ''${out}/bin/gunzip
  ''
