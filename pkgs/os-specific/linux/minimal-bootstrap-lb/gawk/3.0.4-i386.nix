{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  gzip,
  bison,
  m4,
}:
let
  pname = "gawk";
  version = "3.0.4";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gawk/gawk-${version}.tar.gz";
    hash = "sha256-XMNd7x/0N1qLmpjC/3npXoCYfSTw1C/bt7cDmz3bP7A=";
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
      bison
      m4
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/gawk --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        test "$(${result}/bin/gawk 'BEGIN { print 42 }')" = 42
        test "$(${result}/bin/awk 'BEGIN { print 6 * 7 }')" = 42
        cat > prog.awk <<'EOF'
        BEGIN { print ord("A") }
        EOF
        test "$(${result}/bin/gawk -f ord.awk -f prog.awk)" = 65
        test -s ${result}/share/awk/ord.awk
        mkdir ''${out}
      '';

    meta = {
      description = "GNU implementation of the AWK programming language";
      homepage = "https://www.gnu.org/software/gawk/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gawk";
    };
  }
  ''
    # Unpack
    cp ${src} gawk.tar.gz
    ${gzip}/bin/gzip -d -f gawk.tar.gz
    ${gnutar}/bin/tar xf gawk.tar
    rm gawk.tar
    cd gawk-${version}

    # Configure
    rm awktab.c
    rm pc/config.h
    cp ${./main.mk} Makefile

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      M4="${m4}/bin/m4" \
      CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j1 \
        PREFIX=''${out} \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib"

    # Install
    ${gnumake}/bin/make -f Makefile \
      PREFIX=''${out} \
      install

    install -d ''${out}/share/awk
    for file in awklib/eg/lib/*.awk; do
      install -m 644 "''${file}" ''${out}/share/awk/
    done
  ''
