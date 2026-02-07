{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnupatch,
  gnused,
  gnutar,
  bzip2,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "coreutils";
  version = "5.0";

  src = fetchurl {
    url = "mirror://gnu/coreutils/coreutils-${version}.tar.bz2";
    hash = "sha256-wls2uK9uCtKoddr01hlr0N8opivn3SUuX5mk1dcojZU=";
  };

  patches = [
    ./touch-getdate.patch
    ./touch-dereference.patch
  ];
in
bash.runCommand "${pname}-${version}"
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
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/cat --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        cat > left <<'EOF'
        alpha
        beta
        EOF
        cat > right <<'EOF'
        beta
        gamma
        EOF
        ${result}/bin/comm -12 left right > common
        test "$(${result}/bin/cat common)" = beta

        cat > numbers <<'EOF'
        2
        1
        1
        EOF
        ${result}/bin/sort numbers > sorted
        ${result}/bin/uniq sorted > dedup
        test "$(${result}/bin/wc -l < dedup)" -eq 2

        ${result}/bin/dd if=numbers of=copy bs=1 count=6 >/dev/null 2>&1
        ${result}/bin/cksum < numbers > numbers.ck
        ${result}/bin/cksum < copy > copy.ck
        test "$(${result}/bin/cat numbers.ck)" = "$(${result}/bin/cat copy.ck)"
        ${result}/bin/uname -s >/dev/null
        ${result}/bin/sync
        mkdir ''${out}
      '';
  }
  ''
    # Unpack
    cp ${src} coreutils.tar.bz2
    ${bzip2}/bin/bunzip2 -f coreutils.tar.bz2
    ${gnutar}/bin/tar xf coreutils.tar
    rm coreutils.tar
    cd coreutils-${version}

    # Configure
    cp ${./pass2.mk} Makefile
    touch config.h
    cp lib/fnmatch_.h lib/fnmatch.h
    cp lib/ftw_.h lib/ftw.h
    cp lib/search_.h lib/search.h
    rm -f src/false.c
    rm src/dircolors.h
    rm src/wheel.h
    rm lib/getdate.c
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

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
