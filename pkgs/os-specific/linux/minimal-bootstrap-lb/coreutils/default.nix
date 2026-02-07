{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
  gnupatch,
  gnused,
  gnutar,
  bzip2,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "bootstrap-coreutils";
  version = "5.0";

  src = fetchurl {
    url = "mirror://gnu/coreutils/coreutils-${version}.tar.bz2";
    hash = "sha256-wls2uK9uCtKoddr01hlr0N8opivn3SUuX5mk1dcojZU=";
  };

  patches = [
    ./modechange.patch
    ./mbstate.patch
    ./ls-strcmp.patch
    ./touch-getdate.patch
    ./touch-dereference.patch
    ./tac-uint64.patch
    ./expr-strcmp.patch
    ./sort-locale.patch
    ./uniq-fopen.patch
  ];
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnused
      gnutar
      bzip2
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/cat --version
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    cp ${src} coreutils-${version}.tar.bz2
    ${bzip2}/bin/bunzip2 -f coreutils-${version}.tar.bz2
    ${gnutar}/bin/tar xf coreutils-${version}.tar
    rm coreutils-${version}.tar
    cd coreutils-${version}
    cp ${./main.mk} Makefile

    # Patch and prepare
    catm config.h
    cp lib/fnmatch_.h lib/fnmatch.h
    cp lib/ftw_.h lib/ftw.h
    cp lib/search_.h lib/search.h
    rm src/false.c
    rm src/dircolors.h
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

    # Build and install
    ${gnumake}/bin/make -f Makefile \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      PREFIX=''${out}

    mkdir -p ''${out}/bin

    ${gnumake}/bin/make -f Makefile \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      PREFIX=''${out} \
      install
  ''
