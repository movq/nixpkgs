{
  lib,
  fetchurl,
  bash,
  coreutils,
  gnupatch,
  gnutar,
  gzip,
  findutils,
  gnused,
  grep,
  perl,
}:
let
  pname = "dist";
  version = "3.5";

  src = fetchurl {
    url = "https://github.com/rmanfredi/dist/archive/99eb95e214b87a84b0a7752adba30e9b0fec977f.tar.gz";
    hash = "sha256-IM/NE9WIq9y1AsHEaC+x8z/+/TB2JbO4d9Ia2TintwU=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      gnupatch
      gnutar
      gzip
      findutils
      gnused
      grep
      perl
    ];

    meta = {
      description = "Metaconfig tooling used to generate Perl Configure";
      homepage = "https://github.com/rmanfredi/dist";
      license = lib.licenses.artistic1;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "metaconfig";
    };
  }
  ''
    # Unpack
    cp ${src} dist.tar.gz
    ${gzip}/bin/gzip -d -f dist.tar.gz
    ${gnutar}/bin/tar xf dist.tar
    rm dist.tar

    ${gnupatch}/bin/patch -Np0 -i ${./3.5/patches/env.patch}

    cd dist-99eb95e214b87a84b0a7752adba30e9b0fec977f
    cp ${./3.5/files/config.sh.in} config.sh.in
    cp ${./3.5/files/revision.h} revision.h

    # Prepare
    ${gnused}/bin/sed 's/@PERLVER@/5.6.2/' config.sh.in > config.sh
    ${findutils}/bin/find . -name Makefile.SH -delete
    rm -f Configure

    # Build
    cd mcon
    ./mconfig.SH
    ${perl}/bin/perl ../bin/perload -o mconfig > metaconfig
    ./makegloss.SH
    cd ..

    cd kit
    ./manifake.SH
    cd ..

    # Install
    mkdir -p ''${out}/bin ''${out}/lib/perl5/5.6.2
    install mcon/metaconfig ''${out}/bin/
    install mcon/makegloss ''${out}/bin/
    install kit/manifake ''${out}/bin/
    cp -r mcon/U ''${out}/lib/perl5/5.6.2/
  ''
