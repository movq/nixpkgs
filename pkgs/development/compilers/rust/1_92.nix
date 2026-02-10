# New rust versions should first go to staging.
# Things to check after updating:
# 1. Rustc should produce rust binaries on x86_64-linux, aarch64-linux and x86_64-darwin:
#    i.e. nix-shell -p fd or @GrahamcOfBorg build fd on github
#    This testing can be also done by other volunteers as part of the pull
#    request review, in case platforms cannot be covered.
# 2. The LLVM version used for building should match with rust upstream.
#    Check the version number in the src/llvm-project git submodule in:
#    https://github.com/rust-lang/rust/blob/<version-tag>/.gitmodules

# Note: The way this is structured is:
# 1. Import default.nix, and apply arguments as needed for the file-defined function
# 2. Implicitly, all arguments to this file are applied to the function that is imported.
#    if you want to add an argument to default.nix's top-level function, but not the function
#    it instantiates, add it to the `removeAttrs` call below.
{
  stdenv,
  lib,
  newScope,
  callPackage,
  pkgsBuildTarget,
  pkgsBuildBuild,
  pkgsBuildHost,
  pkgsHostTarget,
  pkgsTargetTarget,
  makeRustPlatform,
  wrapRustcWith,
  llvmPackages,
  llvm,
  cargo-auditable,
  wrapCCWith,
  overrideCC,
  fetchpatch,
}@args:
let
  llvmSharedFor =
    pkgSet:
    pkgSet.llvmPackages.libllvm.override (
      {
        enableSharedLibraries = true;
      }
      // lib.optionalAttrs (stdenv.targetPlatform.useLLVM or false) {
        # Force LLVM to compile using clang + LLVM libs when targeting pkgsLLVM
        stdenv = pkgSet.stdenv.override {
          allowedRequisites = null;
          cc = pkgSet.pkgsBuildHost.llvmPackages.clangUseLLVM;
        };
      }
    );
in
import ./default.nix
  {
    rustcVersion = "1.92.0";
    rustcSha256 = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
    rustcPatches = [ ./ignore-missing-docs.patch ];

    llvmSharedForBuild = llvmSharedFor pkgsBuildBuild;
    llvmSharedForHost = llvmSharedFor pkgsBuildHost;
    llvmSharedForTarget = llvmSharedFor pkgsBuildTarget;

    inherit llvmPackages cargo-auditable;

    # For use at runtime
    llvmShared = llvmSharedFor pkgsHostTarget;

    bootstrapSourceHashes = {
      "1.74.0" = "sha256-I3BeOMGjes/X+7khxd2HcmGUdugNCzs5rI60W8DDMYc=";
      "1.75.0" = "sha256-RSb3htZz5IWf8q+gurK6E8kYt5ZRmiXBrM4G26lUI0A=";
      "1.76.0" = "sha256-gFSCtDZEKmeG0nDKy6uPAFKeBhQbJ7f7AZCbl85PNGQ=";
      "1.77.2" = "sha256-TSFMQYnk3ZNNR+hp+lchssM9u73qIfL8f6bfPzjB3qI=";
      "1.78.0" = "sha256-gGWCTwJV+qOQHbggbm+UI/b4wHzsKLxvJ5fGyUgxDs4=";
      "1.79.0" = "sha256-q4JuhLjUjsbtozcAZQNN6owAb2qUbXipuhK8tQ5tPHo=";
      "1.80.1" = "sha256-arebcNxXc3od43jyEvz4hS1n/mzyctEioVs+oTvneUc=";
      "1.81.0" = "sha256-NiF+9+MvQKGA49eb1ma039rtSd04ECOl+3Zf0S0Aks4=";
      "1.82.0" = "sha256-Enagu4+hIoi6b6lll9KLQOdMRCV8BR07wCwrBJuzghA=";
      "1.83.0" = "sha256-exHUJC2rCSGn1UdYrT/oBRU8l5wURiX+zeEXNXYPl98=";
      "1.84.1" = "sha256-4j7HR6Bv/T6UFVBG9AtmZKwVLJ7jwq39kDU6fM/yQiY=";
      "1.85.1" = "sha256-sfv4Ce/p8DaTlAHhQmMcIBpTvPQ+wWlr2fUpC6I2omY=";
      "1.86.0" = "sha256-2Tnq2gZdyCep1Nu1W9SFM60UwW5/CkLnAUcCnIKncHs=";
      "1.87.0" = "sha256-hiO4ZRiT6Mauv6RbapBkWk9lL3sYGJoJkqkNEawmMfQ=";
      "1.88.0" = "sha256-DB3LtPdiUT0CHhooLArFjApCNkKzpr9YHK+1QU30GT4=";
      "1.89.0" = "sha256-C51VYQ2CcOBsRPRZ0eK3kYpeZzgJxZKr7ZucYA4z2Vo=";
      "1.90.0" = "sha256-a/6t3ZD/2i8GNJKwkr/tklxLjHAVebr0sTFuAhRw2qw=";
      "1.91.1" = "sha256-ZkAbuBXiNsxrKqy74jthsobB/iemeQLnwCIs/nez26s=";
      "1.92.0" = "sha256-6+4XC/5MTfxZUhoQHeZR5VNPTa6Il1alyXyp6kDQwwc=";
    };

    selectRustPackage = pkgs: pkgs.rust_1_92;
  }

  (
    removeAttrs args [
      "llvmPackages"
      "llvm"
      "wrapCCWith"
      "overrideCC"
      "pkgsHostTarget"
      "fetchpatch"
      "cargo-auditable"
    ]
  )
