{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
}:

let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "gnused";
  version = "4.0.9";

  src = fetchurl {
    url = "mirror://gnu/sed/sed-${version}.tar.gz";
    hash = "sha256-w2WHR5QYf4RE5dIpmM1YiP+kfzbe9Ld1F6gI3sJ8BgA=";
  };
in
bash.runCommand "${pname}-${version}-musl-v3"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/sed --version
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    ungz --file ${src} --output sed.tar
    untar --file sed.tar
    rm sed.tar
    cd sed-${version}

    # Configure
    cp ${./main.mk} Makefile
    touch config.h

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    ${gnumake}/bin/make \
      CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
      CFLAGS="-I . -I lib -I ${musl}/include" \
      AR="${tinycc.compiler}/bin/tcc -ar"

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
  ''
