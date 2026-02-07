{
  lib,
  fetchurl,
  bash,
  gcc,
  musl,
  binutils,
  gnupatch,
  gnutar,
  gnused,
  grep,
  findutils,
}:
let
  pname = "linux-headers";
  version = "4.14.341-openela";
  sourceVersion = "4.14.336";

  src = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${sourceVersion}.tar.xz";
    hash = "sha256-CCD9t5ccaXQzgIHBH78tyGmHBQHnvcrE0O1Yuh9Xthw=";
  };

  patches = [
    ./patches/4.14.341-openela.patch
    ./patches/winsize.patch
  ];
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gcc
      musl
      binutils
      gnupatch
      gnutar
      gnused
      grep
      findutils
    ];

    meta = {
      description = "Linux kernel userspace headers";
      license = lib.licenses.gpl2Only;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.linux;
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf - \
      linux-${sourceVersion}/scripts \
      linux-${sourceVersion}/include \
      linux-${sourceVersion}/arch/x86/include \
      linux-${sourceVersion}/arch/x86/entry

    # Patch
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np0 -i ${f}") patches}

    cd linux-${sourceVersion}

    # Prepare
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" scripts/headers_install.sh
    chmod +x scripts/headers_install.sh

    rm \
      include/uapi/linux/pktcdvd.h \
      include/uapi/linux/hw_breakpoint.h \
      include/uapi/linux/eventpoll.h \
      include/uapi/linux/atmdev.h

    # Build
    ${gcc}/bin/gcc -static \
      -I${musl}/include \
      -B ${musl}/lib \
      -L ${musl}/lib \
      -o scripts/unifdef \
      scripts/unifdef.c

    # Install
    base_dir="''${PWD}"
    for d in include/uapi arch/x86/include/uapi; do
      cd "''${d}"
      ${findutils}/bin/find . -type d -exec mkdir -p "''${out}/include/{}" ';'
      headers="$(${findutils}/bin/find . -type f -name '*.h')"
      cd "''${base_dir}"
      for h in ''${headers}; do
        path="$(dirname "''${h}")"
        scripts/headers_install.sh "''${out}/include/''${path}" "''${d}/''${path}" "$(basename "''${h}")"
      done
    done

    for i in types ioctl termios termbits ioctls sockios socket param; do
      cp "''${out}/include/asm-generic/''${i}.h" "''${out}/include/asm/''${i}.h"
    done

    ${bash}/bin/bash arch/x86/entry/syscalls/syscallhdr.sh \
      arch/x86/entry/syscalls/syscall_32.tbl \
      "''${out}/include/asm/unistd_32.h" \
      i386

    ${bash}/bin/bash arch/x86/entry/syscalls/syscallhdr.sh \
      arch/x86/entry/syscalls/syscall_64.tbl \
      "''${out}/include/asm/unistd_64.h" \
      common,64

    VERSION=4
    PATCHLEVEL=14
    SUBLEVEL=336
    VERSION_CODE="$((VERSION * 65536 + PATCHLEVEL * 256 + SUBLEVEL))"

    echo "#define LINUX_VERSION_CODE ''${VERSION_CODE}" > "''${out}/include/linux/version.h"
    echo "#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + ((c) > 255 ? 255 : (c)))" >> "''${out}/include/linux/version.h"
  ''
