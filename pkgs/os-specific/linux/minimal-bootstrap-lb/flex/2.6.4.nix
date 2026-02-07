{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  gzip,
  gnused,
  oyacc,
  m4,
  oldFlex,
}:
let
  pname = "flex";
  version = "2.6.4";

  src = fetchurl {
    url = "https://github.com/westes/flex/releases/download/v${version}/flex-${version}.tar.gz";
    hash = "sha256-6HquAyvwfCb4WsDtMlCZjDdiHZX4vXSLMfFbM8Re6ZU=";
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
      gnused
      oyacc
      m4
      oldFlex
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/flex --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        cat > scanner.l <<'EOF'
        %%
        [0-9]+  ;
        %%
        EOF
        PATH="${m4}/bin:$PATH" ${result}/bin/flex scanner.l
        test -s lex.yy.c
        mkdir ''${out}
      '';

    meta = {
      description = "Fast lexical analyzer generator";
      homepage = "https://github.com/westes/flex";
      license = lib.licenses.bsd2;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "flex";
    };
  }
  ''
    # Unpack
    cp ${src} flex.tar.gz
    ${gzip}/bin/gzip -d -f flex.tar.gz
    ${gnutar}/bin/tar xf flex.tar
    rm flex.tar
    cd flex-${version}

    # Prepare
    cp ${./main-2.6.4.mk} Makefile
    mv Makefile src/
    touch src/config.h
    rm src/parse.c src/parse.h src/scan.c src/skel.c

    cd src

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    PATH="${oldFlex}/bin:${oyacc}/bin:${m4}/bin:$PATH" \
      CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j1 \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib"

    PATH="${oldFlex}/bin:${oyacc}/bin:${m4}/bin:$PATH" \
      ${gnumake}/bin/make -f Makefile install PREFIX=''${out}
  ''
