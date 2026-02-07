{
  lib,
  fetchurl,
  autoconf,
  bash,
  buildPlatform,
  coreutils,
  buildGcc,
  buildMusl,
  buildBinutils,
  crossGcc,
  crossBinutils,
  linuxHeaders,
  gnumake,
  gnused,
  grep,
  gawk,
  diffutils,
  findutils,
  python,
  bison,
  gnutar,
  xz,
  gzip,
  buildZlib,
}:
let
  pname = "glibc";
  version = "2.42";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-gnu";

  src = fetchurl {
    url = "mirror://gnu/libc/glibc-${version}.tar.xz";
    hash = "sha256-0XdeMuRijmTvkw9DW2e7Y691may2viszW58Z8WUJ8X8=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      autoconf
      coreutils
      buildGcc
      buildMusl
      buildBinutils
      crossGcc
      crossBinutils
      gnumake
      gnused
      grep
      gawk
      diffutils
      findutils
      python
      bison
      gnutar
      xz
      gzip
      buildZlib
    ];

    meta = {
      description = "The GNU C Library for x86_64-unknown-linux-gnu";
      homepage = "https://www.gnu.org/software/libc/";
      license = lib.licenses.lgpl2Plus;
      platforms = lib.platforms.linux;
      teams = [ lib.teams.minimal-bootstrap ];
    };
  }
  ''
    # Unpack
    ${xz}/bin/unxz -c ${src} | ${gnutar}/bin/tar xf -
    cd glibc-${version}
    chmod -R u+w .

    mkdir -p /build/wrappers

    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      --sysroot=${buildMusl} \
      -isystem ${buildZlib}/include \
      -B ${buildMusl}/lib \
      -L ${buildZlib}/lib \
      -L ${buildBinutils}/lib \
      -L ${buildMusl}/lib \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildZlib}/lib \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 /build/wrappers/build-cc

    cat > /build/wrappers/cc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      -isystem ${linuxHeaders}/include \
      "\$@"
    EOF
    chmod 555 /build/wrappers/cc

    export PATH="/build/wrappers:${crossBinutils}/bin:$PATH"

    find . -type f -exec grep -l '^#! */bin/sh' {} + | while IFS= read -r script; do
      sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
      chmod 755 "$script"
    done

    rm configure
    autoconf -f

    # Configure
    mkdir build
    cd build

    CC=cc \
      BUILD_CC=/build/wrappers/build-cc \
      CXX=false \
      AR=${crossBinutils}/bin/${target}-ar \
      AS=${crossBinutils}/bin/${target}-as \
      LD=${crossBinutils}/bin/${target}-ld \
      NM=${crossBinutils}/bin/${target}-nm \
      OBJCOPY=${crossBinutils}/bin/${target}-objcopy \
      OBJDUMP=${crossBinutils}/bin/${target}-objdump \
      RANLIB=${crossBinutils}/bin/${target}-ranlib \
      READELF=${crossBinutils}/bin/${target}-readelf \
      STRIP=${crossBinutils}/bin/${target}-strip \
      ../configure \
      --prefix=/ \
      --libdir=/lib \
      --build=${buildTarget} \
      --host=${target} \
      --with-headers=${linuxHeaders}/include \
      --disable-werror

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES"

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install install_root=''${out}

    for script in ''${out}/lib/*.so; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^/\* GNU ld script'; then
        ${gnused}/bin/sed -i \
          -e "s# //lib/# =/lib/#g" \
          -e "s# /lib/# =/lib/#g" \
          -e "s# //usr/lib/# =/usr/lib/#g" \
          -e "s# /usr/lib/# =/usr/lib/#g" \
          "$script"
      fi
    done

    for h in ${linuxHeaders}/include/*; do
      base="$(${coreutils}/bin/basename "$h")"
      [ -e "''${out}/include/''${base}" ] || ln -s "$h" "''${out}/include/''${base}"
    done

    for d in bin sbin lib libexec; do
      if [ -d "''${out}/$d" ]; then
        ${findutils}/bin/find "''${out}/$d" -type f -exec ${crossBinutils}/bin/${target}-strip --strip-unneeded {} + || true
      fi
    done
  ''
