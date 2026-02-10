{
  lib,
  callPackage,
  fetchurl,
  llvm_17,
  llvm_18,
  llvm_19,
  llvm_20,
  sourceHashes ? { },
}:

let
  bootstrapVersions = [
    "1.90.0"
    "1.91.1"
    "1.92.0"
  ];

  llvmPackageForVersion =
    version:
    let
      minor = lib.toInt (builtins.elemAt (lib.splitVersion version) 1);
    in
    if minor >= 92 then llvm_20 else if minor >= 88 then llvm_19 else if minor >= 81 then llvm_18 else llvm_17;

  rustcSources = lib.genAttrs bootstrapVersions (
    version:
    fetchurl {
      url = "https://static.rust-lang.org/dist/rustc-${version}-src.tar.xz";
      hash = sourceHashes.${version} or (throw "missing source hash for rustc ${version}");
    }
  );

  rustcPassthru = rec {
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
      # Rust is currently unable to target the n32 ABI.
      lib.systems.inspect.patterns.isMips64n32
    ];
  };

  # Per-version changes can be modeled here.
  stageOverrides = {
    "1.90.0" = {
      builder = "mrustc";
    };
  };

  mkStage =
    previous: version:
    let
      stageConfig = stageOverrides.${version} or { };
      stageBuilder = stageConfig.builder or "source";
      stageArgs =
        {
          inherit version rustcPassthru;
          rustSrc = rustcSources.${version};
          llvmConfig = "${lib.getDev (llvmPackageForVersion version)}/bin/llvm-config";
        }
        // builtins.removeAttrs stageConfig [ "builder" ];
    in
    if stageBuilder == "mrustc" then
      callPackage ./bootstrap/1_90.nix stageArgs
    else
      callPackage ./bootstrap/source-stage.nix (stageArgs // { inherit previous; });

  stageFolded =
    lib.foldl'
      (
        acc: version:
        let
          previous = if acc.lastVersion == null then null else acc.stages.${acc.lastVersion};
        in
        {
          lastVersion = version;
          stages = acc.stages // { "${version}" = mkStage previous version; };
        }
      )
      {
        lastVersion = null;
        stages = { };
      }
      bootstrapVersions;

  finalStage = stageFolded.stages.${lib.last bootstrapVersions};
in
finalStage
// {
  bootstrapStages = stageFolded.stages;
}
