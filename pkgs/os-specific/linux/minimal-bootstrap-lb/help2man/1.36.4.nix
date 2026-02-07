{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnupatch,
  gnutar,
  gzip,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "help2man";
  version = "1.36.4";

  src = fetchurl {
    url = "mirror://gnu/help2man/help2man-${version}.tar.gz";
    hash = "sha256-pK2t92tJamvFB5VwIlPs/Lbw0Vm2gDjzGlNiAJNAvKI=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnutar
      gzip
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "Generate simple man pages from --help and --version output";
      homepage = "https://www.gnu.org/software/help2man/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "help2man";
    };
  }
  ''
    # Unpack
    cp ${src} help2man.tar.gz
    ${gzip}/bin/gzip -d -f help2man.tar.gz
    ${gnutar}/bin/tar xf help2man.tar
    rm help2man.tar

    ${gnupatch}/bin/patch -Np0 -i ${./patches/date.patch}

    cd help2man-${version}

    # Prepare
    rm -f configure
    AUTOMAKE=automake-1.8 \
      ACLOCAL=aclocal-1.8 \
      AUTOCONF=autoconf-2.59 \
      ${autoconf}/bin/autoreconf-2.59 -f
    ${autoconf}/bin/autoconf-2.59 --force
    ${gnused}/bin/sed -i \
      -e "s|^#! */bin/sh$|#! ${bash}/bin/bash|" \
      mkinstalldirs install-sh
    chmod +x configure mkinstalldirs install-sh

    rm -f help2man.info
    touch help2man.info
    rm -f help2man*.1
    rm -f po/*.gmo

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    # Configure
    PERL=${perl}/bin/perl \
      CONFIG_SHELL=${bash}/bin/bash \
      SHELL=${bash}/bin/bash \
      CC="${tinycc.compiler}/bin/tcc -B ''${PWD}/bootstrap-lib" \
      ${bash}/bin/bash ./configure --prefix=''${out} --disable-nls

    # Build
    ${gnumake}/bin/make help2man PERL=${perl}/bin/perl
    ${gnused}/bin/sed -i "s|/usr/bin/perl|${perl}/bin/perl|g" help2man
    chmod 555 help2man
    ${gnumake}/bin/make MAKEINFO=true PERL=${perl}/bin/perl

    # Install
    ${gnumake}/bin/make install MAKEINFO=true PERL=${perl}/bin/perl
  ''
