{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
  gzip,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "gnutar";
  # >= 1.13 is incompatible with mes-libc
  version = "1.12";

  src = fetchurl {
    url = "mirror://gnu/tar/tar-${version}.tar.gz";
    sha256 = "02m6gajm647n8l9a5bnld6fnbgdpyi4i3i83p7xcwv0kif47xhy6";
  };
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gzip
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/tar --version
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    cp ${src} tar-${version}.tar.gz
    ${gzip}/bin/gzip -d -f tar-${version}.tar.gz
    untar --file tar-${version}.tar
    rm tar-${version}.tar
    cd tar-${version}

    cp ${./main.mk} Makefile
    cp ${./getdate_stub.c} lib/getdate_stub.c
    catm src/create.c.new ${./stat_override.c} src/create.c
    cp src/create.c.new src/create.c

    # Build
    ${gnumake}/bin/make CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" AR="${tinycc.compiler}/bin/tcc -ar"

    # Install
    mkdir -p ''${out}/bin
    cp tar ''${out}/bin/tar
    chmod 555 ''${out}/bin/tar
  ''
