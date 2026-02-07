{
  lib,
  fetchurl,
  bash,
  tinycc,
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
    ./sigsetjmp.patch
    ./set_thread_area.patch
    ./makefile.patch
    ./madvise_preserve_errno.patch
    ./fenv.patch
    ./avoid_sys_clone.patch
    ./avoid_set_thread_area.patch
  ];
in
bash.runCommand "${pname}-${version}-tcc-musl"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnused
    ];

    meta = {
      description = "Musl libc 1.1.24 rebuilt with TinyCC linked against musl";
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
      AR="${tinycc.compiler}/bin/tcc -ar" \
      RANLIB=true \
      CFLAGS="-DSYSCALL_NO_TLS"

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CROSS_COMPILE= \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      AR="${tinycc.compiler}/bin/tcc -ar" \
      RANLIB=true \
      CFLAGS="-DSYSCALL_NO_TLS" \
      install
  ''
