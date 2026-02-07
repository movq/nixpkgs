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
  pname = "diffutils";
  version = "2.7";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/diffutils/diffutils-${version}.tar.gz";
    hash = "sha256-1fJInEBWoxUo462krazCPUmFMrCvGpgPL3YVgWKxOdY=";
  };
in
bash.runCommand "${pname}-${version}"
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
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/diff --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        cat > left <<'EOF'
        one
        EOF
        cat > right <<'EOF'
        two
        EOF
        diffStatus=0
        ${result}/bin/diff left right > changes || diffStatus=$?
        test "''${diffStatus}" -eq 1
        test -s changes
        ${result}/bin/cmp left left
        cmpStatus=0
        ${result}/bin/cmp left right >/dev/null 2>&1 || cmpStatus=$?
        test "''${cmpStatus}" -eq 1
        mkdir ''${out}
      '';

    meta = {
      description = "GNU diffutils";
      homepage = "https://www.gnu.org/software/diffutils/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "diff";
    };
  }
  ''
    # Unpack
    cp ${src} diffutils.tar.gz
    ${gzip}/bin/gzip -d -f diffutils.tar.gz
    ${gnutar}/bin/tar xf diffutils.tar
    rm diffutils.tar
    cd diffutils-${version}

    # Configure
    touch config.h
    cp ${./main.mk} Makefile

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j "$NIX_BUILD_CORES" \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib"

    # Install
    ${gnumake}/bin/make -f Makefile install PREFIX=''${out}
  ''
