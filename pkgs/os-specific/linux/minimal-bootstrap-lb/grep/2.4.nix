{
  lib,
  fetchurl,
  bash,
  tinycc,
  gnumake,
}:
let
  pname = "grep";
  version = "2.4";

  src = fetchurl {
    url = "mirror://gnu/grep/grep-${version}.tar.gz";
    hash = "sha256-oyAyurNiCFCUZmVN8S9QdgDf4DE/7rvNIYwypwv3KhY=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/grep --version
        mkdir ''${out}
      '';

    meta = {
      description = "GNU grep 2.4 built with TinyCC linked against musl";
      homepage = "https://www.gnu.org/software/grep";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      mainProgram = "grep";
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    ungz --file ${src} --output grep.tar
    untar --file grep.tar
    rm grep.tar
    cd grep-${version}

    # Configure
    cp ${./main.mk} Makefile

    # Build
    ${gnumake}/bin/make CC="${tinycc.compiler}/bin/tcc -B ${tinycc.libs}/lib"

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
  ''
