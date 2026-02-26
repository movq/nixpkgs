{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "go";
  version = "1.4-bootstrap-20171003";

  src = fetchurl {
    url = "https://dl.google.com/go/go${finalAttrs.version}.tar.gz";
    hash = "sha256-9P9bXrOjyuHJk3I/PqtRnFuuGIZrXl+W/hEC8MtcPlI=";
  };

  strictDeps = true;
  hardeningDisable = [ "all" ];
  NIX_CFLAGS_COMPILE = "-std=gnu89";

  postPatch = ''
    patchShebangs .
  '';

  env = {
    GOOS = "linux";
    GOARCH = "amd64";
    GOHOSTOS = "linux";
    GOHOSTARCH = "amd64";
    GO386 = "softfloat";
    GOARM = "";
    CGO_ENABLED = 0;
  };

  buildPhase = ''
    runHook preBuild
    export GOCACHE=$TMPDIR/go-cache
    export GOROOT_FINAL=$out/share/go

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

  __structuredAttrs = true;

  meta = {
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    changelog = "https://go.dev/doc/devel/release#go1.4";
    description = "Go Programming language bootstrap compiler";
    homepage = "https://go.dev/";
    license = lib.licenses.bsd3;
    teams = [ lib.teams.golang ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "go";
  };
})
