{
  lib,
  fetchurl,
  kaem,
  tinycc,
  gnumake,
  gnupatch,
  coreutils,
}:
let
  pname = "oyacc-mes";
  version = "6.6";

  src = fetchurl {
    url = "https://github.com/ibara/yacc/releases/download/oyacc-${version}/oyacc-${version}.tar.gz";
    hash = "sha256-6whm50C3m9OiPgykeIXrMUiqsY13pL7bqW6XnYtOv+E=";
  };

  patches = [
    ./mes-libc.patch
    ./tcc.patch
  ];
in
kaem.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      coreutils
    ];

    meta = {
      description = "Portable OpenBSD yacc implementation";
      homepage = "https://github.com/ibara/yacc";
      license = with lib.licenses; [
        bsd3
        isc
        publicDomain
      ];
      teams = [ lib.teams.minimal-bootstrap ];
      mainProgram = "yacc";
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ungz --file ${src} --output oyacc.tar
    untar --file oyacc.tar
    rm oyacc.tar
    cd oyacc-${version}

    # Prepare
    cp ${./main.mk} Makefile
    catm config.h
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

    # Build
    ${gnumake}/bin/make CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install \
      CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib" \
      DESTDIR=''${out} \
      BINDIR=/bin \
      MANDIR=/share/man
  ''
