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
  version,
  rustSrc,
  previous,
  llvmConfig,
  rustcPassthru,
  extraConfigureFlags ? [ ],
}:

assert previous != null;

let
  rustTarget = stdenv.hostPlatform.rust.rustcTargetSpec;
  configureFlags = [
    "--build=${rustTarget}"
    "--host=${rustTarget}"
    "--target=${rustTarget}"
    "--enable-local-rust"
    "--disable-docs"
    "--enable-locked-deps"
    "--enable-vendor"
    "--set=build.cargo=${previous.cargo}/bin/cargo"
    "--set=build.rustc=${previous.rustc-unwrapped}/bin/rustc"
    "--set=target.${rustTarget}.llvm-config=${llvmConfig}"
    "--set=rust.lld=false"
    "--tools="
    "--release-channel=stable"
  ] ++ extraConfigureFlags;
in
rec {
  rustc-unwrapped = stdenv.mkDerivation {
    pname = "rustc-bootstrap-source";
    inherit version;
    src = rustSrc;

    dontFixLibtool = true;
    dontUpdateAutotoolsGnuConfigScripts = true;
    dontUseCmakeConfigure = true;
    dontStrip = true;

    strictDeps = true;
    nativeBuildInputs = [
      cmake
      file
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

    configurePhase = ''
      runHook preConfigure
      ./configure ${lib.escapeShellArgs configureFlags}
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      set -euo pipefail
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"

      # Build only stage1 std/proc_macro, then build cargo once from that stage.
      ${python3}/bin/python3 ./x.py build --stage 1 library/std library/proc_macro

      LIBGIT2_SYS_USE_PKG_CONFIG=1 \
      RUSTC="$PWD/build/${rustTarget}/stage1/bin/rustc" \
      ${previous.cargo}/bin/cargo build --release --frozen --offline \
        --manifest-path src/tools/cargo/Cargo.toml \
        --target-dir build/stage1-cargo

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/lib"
      cp build/${rustTarget}/stage1/bin/rustc "$out/bin/"
      cp build/stage1-cargo/release/cargo "$out/bin/"
      cp -r build/${rustTarget}/stage1/lib/. "$out/lib/"
      # Stage outputs may contain source symlinks into /build; drop them in bootstrap artifacts.
      find "$out/lib/rustlib" -type l -lname '/build/*' -delete || true

      if [ -x build/${rustTarget}/stage1/bin/rustdoc ]; then
        cp build/${rustTarget}/stage1/bin/rustdoc "$out/bin/"
      else
        cp ${previous.rustc-unwrapped}/bin/rustdoc "$out/bin/"
      fi

      runHook postInstall
    '';

    setupHooks = ../setup-hook.sh;
    requiredSystemFeatures = [ "big-parallel" ];
    passthru = rustcPassthru;

    meta = {
      homepage = "https://www.rust-lang.org/";
      description = "Rust bootstrap compiler built from source";
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
