{
  lib,
  fetchurl,
  bash,
  coreutils,
  buildGcc,
  buildMusl,
  crossGcc,
  crossBinutils,
  crossMusl,
  gnumake,
  gnupatch,
  gnutar,
  bzip2,
  gnused,
  grep,
  diffutils,
  findutils,
}:
let
  pname = "busybox";
  version = "1.37.0";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://busybox.net/downloads/busybox-${version}.tar.bz2";
    hash = "sha256-MxHf8y50ZJn03w1d8E1+s5Y4LX4Qi7klDntRm4NwQ6Q=";
  };
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      buildGcc
      buildMusl
      crossGcc
      crossBinutils
      crossMusl
      gnumake
      gnupatch
      gnutar
      bzip2
      gnused
      grep
      diffutils
      findutils
    ];

    meta = {
      description = "Statically-linked x86_64 BusyBox for stdenv bootstrap";
      homepage = "https://busybox.net/";
      license = lib.licenses.gpl2Only;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} busybox.tar.bz2
    ${bzip2}/bin/bzip2 -d busybox.tar.bz2
    ${gnutar}/bin/tar xf busybox.tar
    rm busybox.tar
    cd busybox-${version}

    # Patch
    patch -Np1 -i ${./busybox-in-store.patch}

    ${findutils}/bin/find . -type f -print0 | while IFS= read -r -d $'\0' script; do
      if ${coreutils}/bin/head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod 755 "$script"
      fi
    done

    # Build CC wrapper (for host programs that run during build)
    cat > build-gcc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 build-gcc

    # Cross CC wrapper
    cat > ${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      --sysroot=${crossMusl} \
      -isystem ${crossMusl}/include \
      "\$@"
    EOF
    chmod 555 ${target}-gcc

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Configure - start from allnoconfig (minimal) and enable what we need
    MAKE_ARGS="CROSS_COMPILE=${target}- HOSTCC=$(pwd)/build-gcc KCONFIG_NOTIMESTAMP=y"
    make $MAKE_ARGS allnoconfig

    # Function to set a kconfig option: removes any existing setting, then appends
    set_config() {
      local name="$1"
      local value="$2"
      sed -i "/$name[ =]/d" .config
      if [ "$value" = "n" ]; then
        echo "# $name is not set" >> .config
      else
        echo "$name=$value" >> .config
      fi
    }

    set_config CONFIG_STATIC y
    set_config CONFIG_CROSS_COMPILER_PREFIX '"${target}-"'
    set_config CONFIG_INSTALL_NO_USR y
    set_config CONFIG_FEATURE_COPYBUF_KB 64
    set_config CONFIG_FEATURE_UTMP n
    set_config CONFIG_FEATURE_WTMP n
    set_config CONFIG_LFS y

    # Shell
    set_config CONFIG_ASH y
    set_config CONFIG_ASH_ECHO y
    set_config CONFIG_ASH_TEST y
    set_config CONFIG_ASH_PRINTF y
    set_config CONFIG_ASH_OPTIMIZE_FOR_SIZE y
    set_config CONFIG_ASH_BASH_COMPAT y
    set_config CONFIG_FEATURE_SH_MATH y
    set_config CONFIG_FEATURE_SH_MATH_64 y
    set_config CONFIG_FEATURE_SH_STANDALONE n

    set_config CONFIG_FEATURE_FANCY_ECHO y
    set_config CONFIG_FEATURE_SH_MATH y
    set_config CONFIG_FEATURE_SH_MATH_64 y
    set_config CONFIG_FEATURE_TEST_64 y

    set_config CONFIG_ASH y
    set_config CONFIG_ASH_OPTIMIZE_FOR_SIZE y

    set_config CONFIG_ASH_ALIAS y
    set_config CONFIG_ASH_BASH_COMPAT y
    set_config CONFIG_ASH_CMDCMD y
    set_config CONFIG_ASH_ECHO y
    set_config CONFIG_ASH_GETOPTS y
    set_config CONFIG_ASH_INTERNAL_GLOB y
    set_config CONFIG_ASH_JOB_CONTROL y
    set_config CONFIG_ASH_PRINTF y
    set_config CONFIG_ASH_TEST y

    # Applets needed by unpack-bootstrap-tools.sh
    set_config CONFIG_MKDIR y
    set_config CONFIG_TAR y
    set_config CONFIG_FEATURE_TAR_AUTODETECT y
    set_config CONFIG_FEATURE_TAR_GNU_EXTENSIONS y
    set_config CONFIG_FEATURE_SEAMLESS_XZ y
    set_config CONFIG_UNXZ y
    set_config CONFIG_CP y
    set_config CONFIG_CHMOD y
    set_config CONFIG_CAT y
    set_config CONFIG_LN y
    set_config CONFIG_LS y
    set_config CONFIG_MV y
    set_config CONFIG_RM y
    set_config CONFIG_SED y
    set_config CONFIG_ECHO y
    set_config CONFIG_TEST y
    set_config CONFIG_GREP y

    make $MAKE_ARGS oldconfig

    # Build
    make -j "$NIX_BUILD_CORES" $MAKE_ARGS SKIP_STRIP=y

    # Install - just the binary
    cp busybox $out
  ''
