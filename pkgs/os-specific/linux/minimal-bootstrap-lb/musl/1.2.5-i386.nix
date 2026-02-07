{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  gcc,
  binutils,
  gnumake,
  gnused,
  gnutar,
  gzip,
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
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gcc
      binutils
      gnumake
      gnused
      gnutar
      gzip
    ];

    meta = {
      description = "Musl libc 1.2.5 rebuilt with GCC 4.0.4";
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

    # Configure
    CC=${gcc}/bin/gcc ./configure \
      --host=${target} \
      --disable-shared \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --includedir=''${out}/include/

    if test -f /dev/null; then
      rm /dev/null
      mknod -m 666 /dev/null c 1 3
    fi

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE=

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CROSS_COMPILE= install
  ''
