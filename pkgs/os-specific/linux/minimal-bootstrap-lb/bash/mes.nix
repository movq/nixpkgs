{
  lib,
  fetchurl,
  kaem,
  derivationWithMeta,
  writeText,
  tinycc,
  gnumake,
  gnupatch,
  coreutils,
  mescc-tools-extra,
  oyacc,
}:
let
  inherit (import ./common.nix { inherit lib; }) meta;
  pname = "bash-mes";
  version = "2.05b";

  src = fetchurl {
    url = "mirror://gnu/bash/bash-${version}.tar.gz";
    hash = "sha256-ugPUEpmMxUvQsPLWwyEAln0xNwmK/9wtMubnwRsWP+Q=";
  };

  patches = [
    ./mes-libc.patch
    ./tinycc.patch
    ./missing-defines.patch
    ./locale.patch
    ./dev-tty.patch
  ];
  bashMes = kaem.runCommand "${pname}-${version}"
  {
    inherit pname version meta;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      coreutils
      oyacc
    ];

    passthru.tests.get-version =
      result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/bash --version
        mkdir ''${out}
      '';

    passthru.runCommand =
      name: env: buildCommand:
      derivationWithMeta (
        {
          inherit name buildCommand;
          builder = "${bashMes}/bin/bash";
          args = [
            "-e"
            (writeText "bash-builder.sh" ''
              export CONFIG_SHELL=$SHELL

              NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
              if [ "$NIX_BUILD_CORES" -le 0 ]; then
                NIX_BUILD_CORES=1
              fi
              export NIX_BUILD_CORES

              bash -eux "$buildCommandPath"
            '')
          ];
          passAsFile = [ "buildCommand" ];

          SHELL = "${bashMes}/bin/bash";
          PATH = lib.makeBinPath (
            (env.nativeBuildInputs or [ ])
            ++ [
              bashMes
              coreutils
              mescc-tools-extra
            ]
          );
        }
        // (removeAttrs env [ "nativeBuildInputs" ])
      );
  }
  ''
    # Unpack
    ungz --file ${src} --output bash.tar
    untar --file bash.tar
    rm bash.tar
    cd bash-${version}

    # Prepare
    cp ${./main.mk} Makefile
    cp ${./builtins.mk} builtins/Makefile
    cp ${./common.mk} common.mk
    catm config.h
    catm include/version.h
    catm include/pipesize.h
    rm y.tab.c y.tab.h parser-built
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

    # Build
    ${gnumake}/bin/make \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      YACC="${oyacc}/bin/yacc" \
      mkbuiltins
    cd builtins
    ${gnumake}/bin/make \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      YACC="${oyacc}/bin/yacc" \
      libbuiltins.a
    cd ..
    ${gnumake}/bin/make \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      YACC="${oyacc}/bin/yacc"

    # Install
    mkdir -p ''${out}/bin
    ${coreutils}/bin/install -m 555 bash ''${out}/bin/bash
    ${coreutils}/bin/install -m 555 bash ''${out}/bin/sh
  ''
  ;
in
bashMes
