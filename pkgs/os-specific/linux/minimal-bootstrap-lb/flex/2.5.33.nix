{
  lib,
  fetchurl,
  bash,
  coreutils,
  cc,
  binutils,
  diffutils,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  autoconfArchive,
  libtool,
  oldFlex,
  bison,
  help2man,
}:
let
  pname = "flex";
  version = "2.5.33";
  srcRev = "e6f147b7a5f2ec2dc862dc9d30b3734b9555a1ea";

  src = fetchurl {
    url = "https://github.com/westes/flex/archive/${srcRev}.tar.gz";
    hash = "sha256-uuxpBp/1i3zb4BA//BbynUhXQowp7832hcV02DAP2Dg=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cc
      binutils
      diffutils
      gnumake
      gnupatch
      gnutar
      gzip
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      autoconfArchive
      libtool
      oldFlex
      bison
      help2man
    ];

    meta = {
      description = "Fast lexical analyzer generator";
      homepage = "https://github.com/westes/flex";
      license = lib.licenses.bsd2;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "flex-2.5.33";
    };
  }
  ''
    # Unpack
    cp ${src} flex.tar.gz
    ${gzip}/bin/gzip -d -f flex.tar.gz
    ${gnutar}/bin/tar xf flex.tar
    rm flex.tar

    ${gnupatch}/bin/patch -Np0 -i ${./2.5.33/disable-unavailables.patch}
    cd flex-${srcRev}

    # Prepare
      rm -f configure
      ACLOCAL_PATH="${autoconfArchive}/share/aclocal:${libtool}/share/aclocal" \
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    cat > rev <<EOF
    #!${bash}/bin/bash
    exec perl -ne 'chomp; print scalar(reverse(\$_)) . "\\n";'
    EOF
    chmod 555 rev
    export PATH="$PWD:$PATH"

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --program-suffix=-2.5.33

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
  ''
