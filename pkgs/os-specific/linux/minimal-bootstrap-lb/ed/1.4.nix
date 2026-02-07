{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cc,
  binutils,
  gnumake,
  gnutar,
  gzip,
  gnused,
}:
let
  pname = "ed";
  version = "1.4";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/ed/ed-${version}.tar.gz";
    hash = "sha256-2zbahe4anYuvtLBBvUyMEb7LoMQ+xEY1O2cEXeFjT9o=";
  };
in
bash.runCommand "${pname}-${version}"
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
    ];

    meta = {
      description = "GNU line-oriented text editor";
      homepage = "https://www.gnu.org/software/ed/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "ed";
    };
  }
  ''
    # Unpack
    cp ${src} ed.tar.gz
    ${gzip}/bin/gzip -d -f ed.tar.gz
    ${gnutar}/bin/tar xf ed.tar
    rm ed.tar
    cd ed-${version}

    # Prepare
    rm doc/ed.info

    # Configure
    ./configure \
      --prefix=''${out} \
      --build=${target}

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES"

    # Install
    install -m 555 -D ed ''${out}/bin/ed
  ''
