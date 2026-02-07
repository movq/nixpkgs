{
  lib,
  fetchurl,
  bash,
  coreutils,
  crossGcc,
  crossBinutils,
  gnumake,
  gnused,
  gnutar,
  gzip,
}:
let
  pname = "musl";
  version = "1.2.5";
  target = "x86_64-unknown-musl";

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    hash = "sha256-qaEYu+hNh2TaDqDSizqz+uhHf8fkCF2QECuFlvx8deQ=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      crossGcc
      crossBinutils
      gnumake
      gnused
      gnutar
      gzip
    ];

    meta = {
      description = "Musl libc 1.2.5 built for x86_64 with cross GCC 15.2.0 and binutils 2.41";
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

    export PATH="${crossGcc}/bin:${crossBinutils}/bin:$PATH"

    # Configure
    CC=${crossGcc}/bin/gcc ./configure \
      --host=${target} \
      --prefix=/ \
      --libdir=/lib \
      --includedir=/include

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE=

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE= install DESTDIR=''${out}

    rm ''${out}/lib/ld-musl-x86_64.so.1
    ln -sr ''${out}/lib/libc.so ''${out}/lib/ld-musl-x86_64.so.1

    mkdir -p ''${out}/usr/lib
    for i in crt1.o crti.o crtn.o Scrt1.o rcrt1.o; do
      ln -sr ''${out}/lib/"$i" ''${out}/usr/lib/"$i"
    done

    mkdir -p ''${out}/bin
    ln -s ../lib/ld-musl-x86_64.so.1 ''${out}/bin/ldd

    mkdir -p ''${out}/etc
    cp ${./1.2.5-x86_64/files/ld-musl-x86_64.path} ''${out}/etc/ld-musl-x86_64.path
  ''
