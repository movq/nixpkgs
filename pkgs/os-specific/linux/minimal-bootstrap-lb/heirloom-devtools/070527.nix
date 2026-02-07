{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnutar,
  bzip2,
  oyacc,
}:
let
  pname = "heirloom-devtools";
  version = "070527";

  src = fetchurl {
    url = "http://downloads.sourceforge.net/project/heirloom/heirloom-devtools/${version}/heirloom-devtools-${version}.tar.bz2";
    hash = "sha256-nyM9i3jkNR/p3S1Q2DlYoOWvNvVOmBhSFFigjgWGkbo=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnutar
      bzip2
      oyacc
    ];

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        cat > scanner.l <<'EOF'
        %%
        %%
        EOF
        ${result}/bin/lex scanner.l
        test -s lex.yy.c
        mkdir ''${out}
      '';

    meta = {
      description = "Heirloom lex implementation";
      homepage = "https://heirloom.sourceforge.net/devtools.html";
      license = with lib.licenses; [
        cddl
        bsdOriginalUC
        caldera
      ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "lex";
    };
  }
  ''
    # Unpack
    cp ${src} heirloom-devtools.tar.bz2
    ${bzip2}/bin/bzip2 -d -f heirloom-devtools.tar.bz2
    ${gnutar}/bin/tar xf heirloom-devtools.tar
    rm heirloom-devtools.tar
    cd heirloom-devtools-${version}

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Build
    cd lex
    ${gnumake}/bin/make -f Makefile.mk \
      CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/../bootstrap-lib" \
      AR="${tinycc.compiler}/bin/tcc -ar" \
      CFLAGS="-I ${musl}/include" \
      YACC="${oyacc}/bin/yacc" \
      LDFLAGS="-static" \
      RANLIB=true \
      LIBDIR=''${out}/lib

    # Install
    mkdir -p ''${out}/bin ''${out}/lib/lex
    install -m 555 lex ''${out}/bin/lex
    install -m 444 libl.a ''${out}/lib/libl.a
    install -m 444 ncform ''${out}/lib/lex/ncform
  ''
