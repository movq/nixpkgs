{
  lib,
  fetchurl,
  derivationWithMeta,
  writeText,
  bash,
  buildPlatform,
  mescc-tools-extra,
  coreutils,
  coreutils5,
  cc,
  binutils,
  gnumake,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  bison,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "bash";
  version = "5.2.15";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/bash/bash-${version}.tar.gz";
    hash = "sha256-E3IJZbX0/DoNS2HdN+dWXHQdqaW+JO3CrgAYL8GzWIw=";
  };

  bash5_2_15 = bash.runCommand "${pname}-${version}"
    {
      inherit pname version;

      nativeBuildInputs = [
        coreutils
        cc
        binutils
        gnumake
        gnutar
        gzip
        gnused
        grep
        gawk
        m4
        perl
        autoconf
        bison
      ];

      passthru.runCommand =
        name: env: buildCommand:
        derivationWithMeta (
          {
            inherit name buildCommand;
            builder = "${bash5_2_15}/bin/bash";
            args = [
              "-e"
              (writeText "bash-builder.sh" ''
                export CONFIG_SHELL=$SHELL

                NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
                if [ "$NIX_BUILD_CORES" -le 0 ]; then
                  NIX_BUILD_CORES=1
                fi
                export NIX_BUILD_CORES

                # Default to smaller binaries unless a package explicitly sets flags.
                : "''${CFLAGS:=-Os -g0}"
                : "''${CXXFLAGS:=''${CFLAGS}}"
                export CFLAGS CXXFLAGS

                bash -eux "$buildCommandPath"
              '')
            ];
            passAsFile = [ "buildCommand" ];

            SHELL = "${bash5_2_15}/bin/bash";
            PATH = lib.makeBinPath (
              (env.nativeBuildInputs or [ ])
              ++ [
                bash5_2_15
                coreutils5
                coreutils
                mescc-tools-extra
              ]
            );
          }
          // (removeAttrs env [ "nativeBuildInputs" ])
        );

      meta = meta // {
        mainProgram = "bash";
      };
    }
    ''
      # Unpack
      cp ${src} bash.tar.gz
      ${gzip}/bin/gzip -d -f bash.tar.gz
      ${gnutar}/bin/tar xf bash.tar
      rm bash.tar
      cd bash-${version}

      # Prepare
      rm y.tab.c y.tab.h
      rm po/*.gmo

      mv doc/Makefile.in Makefile.in.doc
      rm doc/*
      mv Makefile.in.doc doc/Makefile.in

      rm lib/sh/strtoimax.c
      touch lib/sh/strtoimax.c

      ${gnused}/bin/sed -i \
        -e "s|MAKE_SHELL=/bin/sh|MAKE_SHELL=${bash}/bin/bash|" \
        -e "s|/bin/sh}|${bash}/bin/bash}|" \
        configure.ac

      rm configure
      ${autoconf}/bin/autoconf-2.69

      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" \
        lib/intl/Makefile.in po/Makefile.in.in

      cat > builtins/psize.sh <<EOF
      #!${bash}/bin/bash
      echo "#define PIPESIZE 65536"
      EOF
      chmod 555 builtins/psize.sh

      # Configure
      CC=cc \
        ./configure \
          --prefix=''${out} \
          --without-bash-malloc \
          --disable-nls \
          --build=${target} \
          --enable-static-link \
          bash_cv_dev_stdin=absent \
          bash_cv_dev_fd=whacky

      # Build
      ${gnumake}/bin/make -j1 PREFIX=''${out}

      # Install
      install -m 555 -D bash ''${out}/bin/bash
      install -m 555 bash ''${out}/bin/sh
    ''
  ;
in
bash5_2_15
