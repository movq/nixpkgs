{
  lib,
  fetchurl,
  kaem,
  gnumake,
  tinycc,
  gnutar,
  gzip,
}:

let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "gnused-mes";
  # last version that can be compiled with mes-libc
  version = "4.0.9";

  src = fetchurl {
    url = "mirror://gnu/sed/sed-${version}.tar.gz";
    sha256 = "0006gk1dw2582xsvgx6y6rzs9zw8b36rhafjwm288zqqji3qfrf3";
  };
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      gnumake
      tinycc.compiler
      gnutar
      gzip
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/sed --version
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    cp ${src} sed-${version}.tar.gz
    ${gzip}/bin/gzip -d -f sed-${version}.tar.gz
    ${gnutar}/bin/tar xf sed-${version}.tar
    rm sed-${version}.tar
    cd sed-${version}

    cp ${./main.mk} Makefile
    catm config.h

    # Build
    ${gnumake}/bin/make LIBC=mes CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" AR="${tinycc.compiler}/bin/tcc -ar"

    # Install
    mkdir -p ''${out}/bin
    cp sed/sed ''${out}/bin/sed
    chmod 555 ''${out}/bin/sed
  ''
