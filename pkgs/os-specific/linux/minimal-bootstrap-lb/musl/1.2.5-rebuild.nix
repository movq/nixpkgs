{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  gcc,
  musl,
  binutils,
  gnumake,
  gnutar,
  gzip,
  gnused,
}:
let
  pname = "musl";
  version = "1.2.5";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    hash = "sha256-qaEYu+hNh2TaDqDSizqz+uhHf8fkCF2QECuFlvx8deQ=";
  };
in
bash.runCommand "${pname}-${version}-rebuild"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      gcc
      musl
      binutils
      gnumake
      gnutar
      gzip
      gnused
    ];

    meta = {
      description = "Musl libc 1.2.5 rebuilt with GCC 4.7.4 and binutils 2.41";
      homepage = "https://musl.libc.org/";
      license = lib.licenses.mit;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} musl.tar.gz
    ${gzip}/bin/gzip -d -f musl.tar.gz
    ${gnutar}/bin/tar xf musl.tar
    rm musl.tar
    cd musl-${version}
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" configure
    chmod +x configure
    for script in tools/*.sh; do
      if [ -f "$script" ] && head -n 1 "$script" | ${gnused}/bin/sed -n '/^#! *\/bin\/sh$/p' > /dev/null; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|\"/bin/sh\"|\"${bash}/bin/bash\"|g" \
      src/misc/wordexp.c \
      src/stdio/popen.c \
      src/process/system.c

    cat > gcc-for-build <<EOF
    #!${bash}/bin/bash
    exec ${gcc}/bin/gcc \
      -isystem ${musl}/include \
      -B ${musl}/lib \
      -L ${musl}/lib \
      "\$@"
    EOF
    chmod 555 gcc-for-build

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 cc
    export PATH="''${PWD}:${binutils}/bin:$PATH"

    # Configure
    CC=cc CFLAGS="-O2" ./configure \
      --host=${target} \
      --prefix=/ \
      --libdir=/lib \
      --includedir=/include

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE=

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE= install DESTDIR=''${out}

    rm ''${out}/lib/ld-musl-i386.so.1
    ln -sr ''${out}/lib/libc.so ''${out}/lib/ld-musl-i386.so.1

    mkdir -p ''${out}/bin
    ln -s ../lib/ld-musl-i386.so.1 ''${out}/bin/ldd

    mkdir -p ''${out}/etc
    cp ${./1.2.5-rebuild/files/ld-musl-i386.path} ''${out}/etc/
  ''
