{
  lib,
  fetchurl,
  bash,
  cc,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  gnused,
  flex,
  m4,
}:
let
  pname = "bison";
  version = "3.4.1";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/bison/bison-${version}.tar.gz";
    hash = "sha256-cAf8icIW+/r/VSU1mwKn5bYSaU31Fox0Zz9nBV8BUJU=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      cc
      gnumake
      gnupatch
      gnutar
      gzip
      gnused
      flex
      m4
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/bison --version
        mkdir ''${out}
      '';

    passthru.tests.smoke =
      result:
      bash.runCommand "${pname}-smoke-${version}" { } ''
        cat > parser.y <<'EOF'
        %token NUM
        %%
        input:
          NUM
          ;
        %%
        EOF
        M4="${m4}/bin/m4" ${result}/bin/bison -d parser.y
        test -s parser.tab.c
        test -s parser.tab.h
        mkdir ''${out}
      '';

    meta = {
      description = "Yacc-compatible parser generator";
      homepage = "https://www.gnu.org/software/bison/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "bison";
    };
  }
  ''
    # Unpack
    cp ${src} bison.tar.gz
    ${gzip}/bin/gzip -d -f bison.tar.gz

    build_pass() {
      local pass="$1"
      local prefix="$2"
      local prev_prefix="$3"

      rm -rf bison-${version}
      ${gnutar}/bin/tar xf bison.tar

      ${gnupatch}/bin/patch -Np0 -i ${./patches/fseterr.patch}
      ${gnupatch}/bin/patch -Np0 -i ${./patches/missing-includes.patch}

      cd bison-${version}

      cp ${./files/config.h} config.h
      cp ${./files/configmake.h} configmake.h
      cp ${./mk/main.mk} Makefile
      cp ${./mk/lib.mk} lib/Makefile
      cp ${./mk/src.mk} src/Makefile

      ${gnused}/bin/sed -i 's|#define M4 "/usr/bin/m4"|#define M4 "m4"|' config.h
      ${gnused}/bin/sed -i "s|#define PKGDATADIR \"/usr/share/bison-3.4\"|#define PKGDATADIR \"''${prefix}/share/bison-3.4\"|" configmake.h

      mv lib/textstyle.in.h lib/textstyle.h

      rm src/parse-gram.c src/parse-gram.h
      rm src/scan-code.c src/scan-gram.c src/scan-skel.c

      if [ "''${pass}" = pass1 ]; then
        cp ${./files/parse-gram.c} src/parse-gram.c
        cp ${./files/parse-gram.h} src/parse-gram.h
      fi

      if [ "''${pass}" = pass2 ]; then
        cp ${./files/parse-gram.y} src/parse-gram.y
      fi

      if [ -n "''${prev_prefix}" ]; then
        PATH="''${prev_prefix}/bin:${flex}/bin:${gnused}/bin:${m4}/bin:$PATH" \
          M4="${m4}/bin/m4" \
          BISON_PKGDATADIR="''${prev_prefix}/share/bison-3.4" \
          ${gnumake}/bin/make -f Makefile -j1 \
            CC=tcc \
            AR=ar
      else
        PATH="${flex}/bin:${gnused}/bin:${m4}/bin:$PATH" \
          M4="${m4}/bin/m4" \
          ${gnumake}/bin/make -f Makefile -j1 \
            CC=tcc \
            AR=ar
      fi

      PATH="${flex}/bin:${gnused}/bin:${m4}/bin:$PATH" \
        ${gnumake}/bin/make -f Makefile install PREFIX="''${prefix}"

      cd ..
    }

    pass1Prefix="''${PWD}/pass1-out"
    pass2Prefix="''${PWD}/pass2-out"

    build_pass pass1 "''${pass1Prefix}" ""
    build_pass pass2 "''${pass2Prefix}" "''${pass1Prefix}"
    build_pass pass3 ''${out} "''${pass2Prefix}"
  ''
