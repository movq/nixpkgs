{
  lib,
  fetchurl,
  kaem,
  tinycc,
}:
let
  pname = "gnumake";
  version = "3.82";

  src = fetchurl {
    url = "mirror://gnu/make/make-${version}.tar.bz2";
    sha256 = "e2c1a73f179c40c71e2fe8abf8a8a0688b8499538512984da4a76958d0402966";
  };
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [ tinycc.compiler ];

    meta = {
      description = "GNU Make 3.82 (mes libc)";
      homepage = "https://www.gnu.org/software/make";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      mainProgram = "make";
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    unbz2 --file ${src} --output make.tar
    untar --file make.tar
    rm make.tar
    cd make-${version}

    # Create empty config.h
    catm config.h

    # Alias for tcc with library path (nixpkgs pattern)
    alias tcc="tcc -B ${tinycc.libs}/lib"

    # Compile each source file (exactly as live-bootstrap pass1.kaem)
    tcc -c getopt.c
    tcc -c getopt1.c
    tcc -c -I. -Iglob -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DHAVE_STDINT_H ar.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DHAVE_FCNTL_H arscan.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DFILE_TIMESTAMP_HI_RES=0 commands.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DSCCS_GET=\"/nullop\" default.c
    tcc -c -I. -Iglob -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DHAVE_DIRENT_H dir.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART expand.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DFILE_TIMESTAMP_HI_RES=0 file.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -Dvfork=fork function.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART implicit.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DHAVE_DUP2 -DHAVE_STRCHR -Dvfork=fork job.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DLOCALEDIR=\"/fake-locale\" -DPACKAGE=\"fake-make\" -DHAVE_MKTEMP -DHAVE_GETCWD main.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DHAVE_STRERROR -DHAVE_VPRINTF -DHAVE_ANSI_COMPILER -DHAVE_STDARG_H misc.c
    tcc -c -I. -Iglob -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DINCLUDEDIR=\"''${out}/include\" read.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART -DFILE_TIMESTAMP_HI_RES=0 -DHAVE_FCNTL_H -DLIBDIR=\"''${out}/lib\" remake.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART rule.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART signame.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART strcache.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART variable.c
    tcc -c -I. -DVERSION=\"3.82\" version.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART vpath.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART hash.c
    tcc -c -I. -DHAVE_INTTYPES_H -DHAVE_SA_RESTART remote-stub.c
    tcc -c -DHAVE_FCNTL_H getloadavg.c
    tcc -c -Iglob -DSTDC_HEADERS glob/fnmatch.c
    tcc -c -Iglob -DHAVE_STRDUP -DHAVE_DIRENT_H glob/glob.c

    # Link
    tcc -static -o make getopt.o getopt1.o ar.o arscan.o commands.o default.o dir.o expand.o file.o function.o implicit.o job.o main.o misc.o read.o remake.o rule.o signame.o strcache.o variable.o version.o vpath.o hash.o remote-stub.o getloadavg.o fnmatch.o glob.o

    # Install
    mkdir -p ''${out}/bin
    cp make ''${out}/bin/make
    chmod 555 ''${out}/bin/make

    # Verify
    ''${out}/bin/make --version
  ''
