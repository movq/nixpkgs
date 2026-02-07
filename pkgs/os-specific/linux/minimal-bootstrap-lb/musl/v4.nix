{
  lib,
  fetchurl,
  bash,
  tinycc,
  binutils,
  gnumake,
  gnupatch,
  gnused,
}:
let
  pname = "musl";
  version = "1.1.24";

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    hash = "sha256-E3DJqBKyzyp9koAlEMygBYzDfmanvt1wBR8KNAFQIqM=";
  };

  patches = [
    ./va_list.patch
    ./set_thread_area.patch
    ./madvise_preserve_errno.patch
    ./avoid_sys_clone.patch
    ./avoid_set_thread_area.patch
  ];
in
bash.runCommand "${pname}-${version}-v4"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      binutils
      gnumake
      gnupatch
      gnused
    ];

    meta = {
      description = "Musl libc 1.1.24 rebuilt with GNU binutils";
      homepage = "https://musl.libc.org/";
      license = lib.licenses.mit;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ungz --file ${src} --output musl.tar
    untar --file musl.tar
    rm musl.tar
    cd musl-${version}

    # Patch
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

    ${gnused}/bin/sed -i 's|/bin/sh|${bash}/bin/sh|g' \
      configure \
      tools/version.sh \
      tools/musl-clang.in \
      tools/ld.musl-clang.in \
      tools/install.sh \
      Makefile \
      src/legacy/getusershell.c \
      include/paths.h \
      src/misc/wordexp.c \
      src/stdio/popen.c \
      src/process/system.c

    # TinyCC does not support complex types yet
    rm -rf src/complex

    chmod 755 tools/*.sh

    # Configure
    CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      bash ./configure \
        --host=i386 \
        --disable-shared \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --includedir=''${out}/include/

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CROSS_COMPILE= \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      CFLAGS="-DSYSCALL_NO_TLS" \
      AS_CMD='as -o $@ $<'

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CROSS_COMPILE= \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      CFLAGS="-DSYSCALL_NO_TLS" \
      install
  ''
