{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  bison,
  m4,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "coreutils";
  version = "6.10";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/coreutils/coreutils-${version}.tar.lzma";
    hash = "sha256-iwW7obJyahZOREwxTj81lgS1gha+cEvtjy4ChEnMYgQ=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnutar
      bison
      m4
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/date --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        tmpFile="$(${result}/bin/mktemp tmp.XXXXXX)"
        digest="$(${result}/bin/sha256sum "''${tmpFile}")"
        test "''${digest%% *}" = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        test "$(${result}/bin/date -u -d '1970-01-01 00:00:00 UTC' '+%Y-%m-%d')" = 1970-01-01
        rm -f "''${tmpFile}"
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -
    cd coreutils-${version}

    # Configure
    cp ${./6.10.mk} Makefile
    cp lib/fnmatch.in.h lib/fnmatch.h
    rm lib/iconv_open-hpux.h lib/iconv_open-aix.h lib/iconv_open-irix.h lib/iconv_open-osf.h
    rm lib/getdate.c
    (
      cd lib
      M4="${m4}/bin/m4" ${bison}/bin/bison --update getdate.y
      M4="${m4}/bin/m4" ${bison}/bin/bison getdate.y
      mv getdate.tab.c getdate.c
    )
    touch config.h
    touch lib/configmake.h

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
        AR="${tinycc.compiler}/bin/tcc -ar" \
        PREFIX=''${out}

    # Install
    ${gnumake}/bin/make -f Makefile \
      PREFIX=''${out} \
      install
  ''
