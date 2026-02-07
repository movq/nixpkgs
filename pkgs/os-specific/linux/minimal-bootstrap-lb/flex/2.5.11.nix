{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  gnused,
  oyacc,
  heirloomDevtools,
}:
let
  pname = "flex";
  version = "2.5.11";
  rev = "d160f0247ba1611aa59d28f027d6292ba24abb50";

  src = fetchurl {
    url = "https://github.com/westes/flex/archive/${rev}.tar.gz";
    hash = "sha256-aKoQxHO2AQ/61oDK2gn8TuxrPMbkFcwjOeX8I4XMwUI=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnutar
      gzip
      gnused
      oyacc
      heirloomDevtools
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
        ${result}/bin/flex scanner.l
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

    ${gnupatch}/bin/patch -Np0 -i ${./yyin.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./scan_l.patch}

    cd flex-${rev}

    # Prepare
    rm -r to.do
    touch config.h
    cp ${./main.mk} Makefile
    cp ${./scan.lex.l} scan.lex.l

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a
    cp ${heirloomDevtools}/lib/libl.a bootstrap-lib/libl.a

    # Build
    CPATH="${musl}/include" \
      ${gnumake}/bin/make -f Makefile -j1 \
        CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
        YACC="${oyacc}/bin/yacc" \
        LEX="${heirloomDevtools}/bin/lex"

    # Install
    mkdir -p ''${out}/bin
    install -m 555 flex ''${out}/bin/flex
    ln -s flex ''${out}/bin/lex
  ''
