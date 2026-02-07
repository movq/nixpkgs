{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
}:
let
  pname = "patch";
  version = "2.5.9";

  src = fetchurl {
    url = "mirror://gnu/patch/patch-${version}.tar.gz";
    sha256 = "ecb5c6469d732bcf01d6ec1afe9e64f1668caba5bfdb103c28d7f537ba3cdb8a";
  };

  makefile = builtins.toFile "main.mk" ''
    CC      = tcc
    CFLAGS  = -I .
    CPPFLAGS = -DHAVE_DECL_GETENV -DHAVE_DECL_MALLOC -DHAVE_DIRENT_H -DHAVE_LIMITS_H -DHAVE_GETEUID -DHAVE_MKTEMP -DPACKAGE_BUGREPORT= -Ded_PROGRAM=\"/nullop\" -Dmbstate_t=void\* -DRETSIGTYPE=int -DHAVE_MKDIR -DHAVE_RMDIR -DHAVE_FCNTL_H -DPACKAGE_NAME=\"patch\" -DPACKAGE_VERSION=\"2.5.9\" -DHAVE_MALLOC -DHAVE_REALLOC -DSTDC_HEADERS -DHAVE_STRING_H -DHAVE_STDLIB_H
    LDFLAGS = -static

    .PHONY: all
    all: patch

    patch: error.o getopt.o getopt1.o addext.o argmatch.o backupfile.o basename.o dirname.o inp.o maketime.o partime.o patch.o pch.o quote.o quotearg.o quotesys.o util.o version.o xmalloc.o
    	$(CC) $^ $(LDFLAGS) -o $@
  '';
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
    ];

    meta = {
      description = "GNU Patch 2.5.9";
      homepage = "https://www.gnu.org/software/patch";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      mainProgram = "patch";
      platforms = lib.platforms.unix;
    };
  }
  ''
    ungz --file ${src} --output patch.tar
    untar --file patch.tar
    rm patch.tar
    cd ${pname}-${version}

    catm config.h
    catm patchlevel.h

    cp ${makefile} Makefile

    ${gnumake}/bin/make CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib"

    mkdir -p ''${out}/bin
    cp patch ''${out}/bin/patch
    chmod 555 ''${out}/bin/patch

    ''${out}/bin/patch --version
  ''
