{
  lib,
  stdenv,
  fetchurl,
  version,
  hash,
  goBootstrap ? null,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "go";
  inherit version;

  src = fetchurl {
    url = "https://go.dev/dl/go${finalAttrs.version}.src.tar.gz";
    inherit hash;
  };

  strictDeps = true;

  postPatch = ''
    patchShebangs .
  '';

  env =
    {
      inherit (stdenv.hostPlatform.go) GOOS GOARCH GOARM;
      GOHOSTOS = stdenv.buildPlatform.go.GOOS;
      GOHOSTARCH = stdenv.buildPlatform.go.GOARCH;
      GO386 = "softfloat";
      CGO_ENABLED = 0;
    }
    // lib.optionalAttrs (goBootstrap != null) {
      GOROOT_BOOTSTRAP = "${goBootstrap}/share/go";
    };

  buildPhase = ''
    runHook preBuild
    export GOCACHE=$TMPDIR/go-cache
    export GOROOT_FINAL=$out/share/go
    export PATH=$(pwd)/bin:$PATH

    pushd src
    ./make.bash
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/go $out/bin
    cp -a . $out/share/go
    ln -s $out/share/go/bin/go $out/bin/go
    runHook postInstall
  '';

  disallowedReferences = lib.optional (goBootstrap != null) goBootstrap;

  __structuredAttrs = true;

  meta = {
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    changelog = "https://go.dev/doc/devel/release#go${lib.versions.majorMinor finalAttrs.version}";
    description = "Go Programming language bootstrap compiler";
    homepage = "https://go.dev/";
    license = lib.licenses.bsd3;
    teams = [ lib.teams.golang ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "go";
  };
})
