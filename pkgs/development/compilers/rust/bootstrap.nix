{
  lib,
  stdenv,
  fetchurl,
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
  libffi,
  libgit2,
  mrustc,
  mrustc-minicargo,
  llvm_17,
  llvm_18,
  llvm_19,
  sourceHashes ? { },
}:

let
  initialVersion = "1.74.0";
  mrustcTargetVersion = "1.74";
  chainVersions = [
    "1.75.0"
    "1.76.0"
    "1.77.2"
    "1.78.0"
    "1.79.0"
    "1.80.1"
    "1.81.0"
    "1.82.0"
    "1.83.0"
    "1.84.1"
    "1.85.1"
    "1.86.0"
    "1.87.0"
    "1.88.0"
    "1.89.0"
    "1.90.0"
    "1.91.1"
    "1.92.0"
  ];
  allVersions = [ initialVersion ] ++ chainVersions;
  finalVersion = lib.last chainVersions;

  rustcSource =
    version:
    fetchurl {
      url = "https://static.rust-lang.org/dist/rustc-${version}-src.tar.xz";
      hash = sourceHashes.${version} or (throw "missing source hash for rustc ${version}");
    };

  rustcSources = builtins.listToAttrs (
    map (version: {
      name = version;
      value = rustcSource version;
    }) allVersions
  );

  llvm17Config = "${lib.getDev llvm_17}/bin/llvm-config";
  llvm18Config = "${lib.getDev llvm_18}/bin/llvm-config";
  llvm19Config = "${lib.getDev llvm_19}/bin/llvm-config";

  rustTarget = stdenv.hostPlatform.rust.rustcTargetSpec;

  rustSourceSymlinks = lib.concatMapStrings (version: ''
    ln -s ${rustcSources.${version}} "$workdir/sources/rustc-${version}-src.tar.xz"
  '') allVersions;

  rustChain = lib.concatStringsSep " " chainVersions;
in
rec {
  rustc-unwrapped = stdenv.mkDerivation {
    pname = "rustc-bootstrap-source";
    version = finalVersion;
    src = rustcSources.${finalVersion};

    dontUnpack = true;
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
      openssl
      zlib
    ];

    buildPhase = ''
      runHook preBuild

      set -euo pipefail

      export MAKEFLAGS="-j$NIX_BUILD_CORES"
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"

      workdir="$PWD/work"
      mkdir -p "$workdir/sources"
      ${rustSourceSymlinks}

      cp -r ${mrustc.src} "$workdir/mrustc"
      chmod -R u+w "$workdir/mrustc"
      ln -s "$workdir/sources/rustc-${initialVersion}-src.tar.xz" "$workdir/mrustc/rustc-${initialVersion}-src.tar.xz"

      cd "$workdir/mrustc"

      substituteInPlace minicargo.mk \
        --replace-fail "tar.gz" "tar.xz" \
        --replace-fail "xzf" "xf"

      sed -i '/^LLVM_CONFIG/s|=.*|= ${llvm17Config}|' minicargo.mk
      sed -i '/^LLVM_CONFIG/s|=.*|= ${llvm17Config}|' run_rustc/Makefile

      export RUSTC_VERSION=${initialVersion}
      export MRUSTC_TARGET_VER=${mrustcTargetVersion}
      export OUTDIR_SUF=-${initialVersion}
      export RUSTC_TARGET=${rustTarget}
      export MRUSTC_PATH=${mrustc}/bin/mrustc
      export LLVM_CONFIG=${llvm17Config}

      make PARLEVEL="$NIX_BUILD_CORES"
      make -C tools/minicargo PARLEVEL="$NIX_BUILD_CORES"
      make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" RUSTCSRC
      make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" LIBS
      RUSTC_INSTALL_BINDIR=bin make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" output-${initialVersion}/rustc
      LIBGIT2_SYS_USE_PKG_CONFIG=1 make -f minicargo.mk PARLEVEL="$NIX_BUILD_CORES" output-${initialVersion}/cargo
      make -C run_rustc PARLEVEL="$NIX_BUILD_CORES"

      RUSTC="$PWD/run_rustc/output-${initialVersion}/prefix/bin/rustc"
      CARGO="$PWD/run_rustc/output-${initialVersion}/prefix/bin/cargo"

      cd "$workdir"
      last=""
      for ver in ${rustChain}; do
        minor="''${ver#1.}"
        minor="''${minor%%.*}"

        if [ "$minor" -ge 88 ]; then
          llvmConfig=${llvm19Config}
        elif [ "$minor" -ge 81 ]; then
          llvmConfig=${llvm18Config}
        else
          llvmConfig=${llvm17Config}
        fi

        tar -xf "$workdir/sources/rustc-''${ver}-src.tar.xz"
        srcdir="$workdir/rustc-''${ver}-src"
        cd "$srcdir"

        ./configure \
          --build=${rustTarget} \
          --host=${rustTarget} \
          --target=${rustTarget} \
          --enable-local-rust \
          --disable-docs \
          --enable-locked-deps \
          --enable-vendor \
          --set="build.cargo=$CARGO" \
          --set="build.rustc=$RUSTC" \
          --set="target.${rustTarget}.llvm-config=$llvmConfig" \
          --set="rust.lld=false" \
          --tools= \
          --release-channel=stable

        # Build just stage1 std/proc_macro, then build cargo manually from that stage.
        ./x.py build --stage 1 library/std library/proc_macro

        RUSTC="$srcdir/build/${rustTarget}/stage1/bin/rustc"
        "$CARGO" build --release --frozen --offline \
          --manifest-path src/tools/cargo/Cargo.toml \
          --target-dir build/stage1-cargo
        CARGO="$srcdir/build/stage1-cargo/release/cargo"

        cd "$workdir"
        if [ -n "$last" ]; then
          rm -rf "$last"
        fi
        last="$srcdir"
      done

      finalPrefix="$PWD/bootstrap-prefix"
      mkdir -p "$finalPrefix/bin" "$finalPrefix/lib"
      cp "$last/build/${rustTarget}/stage1/bin/rustc" "$finalPrefix/bin/"
      cp "$last/build/${rustTarget}/stage1/bin/rustdoc" "$finalPrefix/bin/"
      cp "$last/build/stage1-cargo/release/cargo" "$finalPrefix/bin/"
      cp -r "$last/build/${rustTarget}/stage1/lib/." "$finalPrefix/lib/"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r "$PWD/bootstrap-prefix/." "$out/"
      runHook postInstall
    '';

    setupHooks = ./setup-hook.sh;
    requiredSystemFeatures = [ "big-parallel" ];

    passthru = rec {
      targetPlatformsWithHostTools = [
        "x86_64-darwin"
        "aarch64-darwin"
        "i686-freebsd"
        "x86_64-freebsd"
        "x86_64-solaris"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
        "i686-linux"
        "loongarch64-linux"
        "powerpc-linux"
        "powerpc64-linux"
        "powerpc64le-linux"
        "riscv64-linux"
        "s390x-linux"
        "x86_64-linux"
        "aarch64-netbsd"
        "armv7l-netbsd"
        "i686-netbsd"
        "powerpc-netbsd"
        "x86_64-netbsd"
        "i686-openbsd"
        "x86_64-openbsd"
        "i686-windows"
        "x86_64-windows"
      ];
      targetPlatforms = targetPlatformsWithHostTools ++ [
        "armv5tel-linux"
        "armv7a-linux"
        "m68k-linux"
        "mips-linux"
        "mips64-linux"
        "mipsel-linux"
        "mips64el-linux"
        "riscv32-linux"
        "armv6l-netbsd"
        "mipsel-netbsd"
        "riscv64-netbsd"
        "x86_64-redox"
        "wasm32-wasi"
      ];
      badTargetPlatforms = [
        lib.systems.inspect.patterns.isMips64n32
      ];
    };

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
