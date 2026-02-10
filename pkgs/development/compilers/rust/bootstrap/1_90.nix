{
  lib,
  stdenv,
  makeWrapper,
  wrapRustc,
  cmake,
  python3,
  pkg-config,
  perl,
  which,
  file,
  xz,
  curl,
  openssl,
  zlib,
  ncurses,
  libxml2,
  libffi,
  libgit2,
  mrustc,
  mrustc-minicargo,
  version,
  rustSrc,
  llvmConfig,
  rustcPassthru,
}:

let
  rustTarget = stdenv.hostPlatform.rust.rustcTargetSpec;
  mrustcTargetVersion = lib.concatStringsSep "." (lib.take 2 (lib.splitVersion version));
in
rec {
  rustc-unwrapped = stdenv.mkDerivation {
    pname = "rustc-bootstrap";
    inherit version;
    src = mrustc.src;

    dontConfigure = true;
    dontFixLibtool = true;
    dontUpdateAutotoolsGnuConfigScripts = true;
    dontUseCmakeConfigure = true;
    dontStrip = true;

    strictDeps = true;
    nativeBuildInputs = [
      cmake
      file
      mrustc
      mrustc-minicargo
      perl
      pkg-config
      python3
      which
      xz
    ];
    buildInputs = [
      curl
      libffi
      libgit2
      libxml2
      ncurses
      openssl
      zlib
    ];

    postPatch = ''
      # GCC 15 no longer pulls these transitively.
      if ! grep -q '^#include <cstdint>$' src/common.hpp; then
        sed -i '1i#include <cstdint>' src/common.hpp
      fi
      if ! grep -q '^#include <limits>$' src/trans/codegen_c.cpp; then
        sed -i '1i#include <limits>' src/trans/codegen_c.cpp
      fi

      # Reuse externally-built mrustc instead of rebuilding bin/mrustc in-tree.
      sed -i 's|^MRUSTC ?=.*$|MRUSTC ?= ${mrustc}/bin/mrustc|' minicargo.mk
      # Reuse externally-built minicargo instead of rebuilding tools/minicargo in-tree.
      sed -i 's|^MINICARGO ?=.*$|MINICARGO ?= ${mrustc-minicargo}/bin/minicargo|' minicargo.mk
      sed -i 's|^MINICARGO ?=.*$|MINICARGO ?= ${mrustc-minicargo}/bin/minicargo|' run_rustc/Makefile
      # Avoid assembler/CFI breakage in compiler_builtins by forcing the no-asm feature.
      if ! grep -q 'feature="no-asm"' script-overrides/stable-${version}-linux/build_compiler_builtins.txt; then
        echo 'cargo:rustc-cfg=feature="no-asm"' >> script-overrides/stable-${version}-linux/build_compiler_builtins.txt
      fi

      substituteInPlace minicargo.mk \
        --replace-quiet "tar.gz" "tar.xz" \
        --replace-quiet "xzf" "xf"

      sed -i '/^LLVM_CONFIG/s|=.*|= ${llvmConfig}|' minicargo.mk
      sed -i '/^LLVM_CONFIG/s|=.*|= ${llvmConfig}|' run_rustc/Makefile
    '';

    buildPhase = ''
      runHook preBuild

      set -euo pipefail
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      export MAKEFLAGS="-j$NIX_BUILD_CORES"

      ln -s ${rustSrc} rustc-${version}-src.tar.xz

      export RUSTC_VERSION=${version}
      export MRUSTC_TARGET_VER=${mrustcTargetVersion}
      export OUTDIR_SUF=-${version}
      export RUSTC_TARGET=${rustTarget}
      export MRUSTC_PATH=${mrustc}/bin/mrustc
      export LLVM_CONFIG=${llvmConfig}

      make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" RUSTCSRC
      make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" LIBS
      RUSTC_INSTALL_BINDIR=bin make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" output-${version}/rustc
      LIBGIT2_SYS_USE_PKG_CONFIG=1 make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" output-${version}/cargo
      # Keep make serial to avoid run_rustc races, but let cargo use all cores.
      MAKEFLAGS= make -C run_rustc -j1 PARLEVEL="$NIX_BUILD_CORES"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -r run_rustc/output-${version}/prefix/. "$out/"

      # run_rustc emits a rustc launcher with build-dir absolute paths.
      # Rewrite it to use runtime-relative paths inside the Nix output.
      cat > "$out/bin/rustc" <<'EOF'
#!/bin/sh
set -eu
d="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export LD_LIBRARY_PATH="$d/../lib:$d/../lib/rustlib/${rustTarget}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$d/rustc_binary" "$@"
EOF
      chmod +x "$out/bin/rustc"

      # wrapRustc expects a rustdoc binary in rustc-unwrapped.
      if [ ! -x "$out/bin/rustdoc" ]; then
        cp "$out/bin/rustc" "$out/bin/rustdoc"
      fi

      runHook postInstall
    '';

    setupHooks = ../setup-hook.sh;
    requiredSystemFeatures = [ "big-parallel" ];
    passthru = rustcPassthru;

    meta = {
      homepage = "https://www.rust-lang.org/";
      description = "Rust bootstrap compiler built from source via mrustc";
      mainProgram = "rustc";
      teams = [ lib.teams.rust ];
      license = [
        lib.licenses.mit
        lib.licenses.asl20
      ];
    };
  };

  rustc = wrapRustc rustc-unwrapped;

  cargo = stdenv.mkDerivation {
    pname = "cargo-bootstrap-source";
    inherit (rustc-unwrapped) version;

    dontUnpack = true;
    strictDeps = true;
    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      cp ${rustc-unwrapped}/bin/cargo "$out/bin/"
      wrapProgram "$out/bin/cargo" --suffix PATH : "${rustc}/bin"
      runHook postInstall
    '';

    meta = {
      homepage = "https://doc.rust-lang.org/cargo/";
      description = "Rust package manager (source-bootstrap toolchain variant)";
      mainProgram = "cargo";
      teams = [ lib.teams.rust ];
      license = [
        lib.licenses.mit
        lib.licenses.asl20
      ];
    };
  };
}
