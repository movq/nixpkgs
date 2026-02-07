{
  lib,
  fetchurl,
  bash,
  gnumake,
  gnutar,
  bzip2,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "autoconf";
  version = "2.55";

  src = fetchurl {
    url = "mirror://gnu/autoconf/autoconf-${version}.tar.bz2";
    hash = "sha256-91cVigSImyZSA+7NjKklaOKmfDuQYvpr/3oKbv0iRKw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gnumake
      gnutar
      bzip2
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "GNU Autoconf";
      homepage = "https://www.gnu.org/software/autoconf/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "autoconf";
    };
  }
  ''
    # Unpack
    cp ${src} autoconf.tar.bz2
    ${bzip2}/bin/bzip2 -d -f autoconf.tar.bz2
    ${gnutar}/bin/tar xf autoconf.tar
    rm autoconf.tar
    cd autoconf-${version}

    # Replace /bin/sh with store path to bash
    ${gnused}/bin/sed -i \
      -e "s|@%:@! /bin/sh|@%:@! ${bash}/bin/bash|" \
      -e "s|/bin/sh}|${bash}/bin/bash}|" \
      lib/m4sugar/m4sh.m4 lib/autoconf/general.m4 lib/autotest/general.m4
    for wrapper in tests/wrappl.in tests/wrapsh.in tests/wrapper.in; do
      if [ -f "$wrapper" ]; then
        ${gnused}/bin/sed -i -e "s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$wrapper"
      fi
    done

    # GNUmakefile hardcodes SHELL=/bin/sh and takes precedence over Makefile
    rm -f GNUmakefile

    # Prepare
    rm -f bin/autoconf.in
    rm -f -- Makefile.in */Makefile.in */*/Makefile.in aclocal.m4 configure
    rm -f doc/*.info
    rm -f man/*.1
    rm -f tests/*.at

    ${gnused}/bin/sed -i '/SUBDIRS/s/ man//' Makefile.am

    AUTOMAKE=automake-1.7 \
      ACLOCAL=aclocal-1.7 \
      AUTOCONF=autoconf-2.54 \
      ${autoconf}/bin/autoreconf-2.54

    shopt -s nullglob
    for file in */*/Makefile.in */Makefile.in Makefile.in; do
      ${gnused}/bin/sed -i '/^pkgdatadir/s:$:-@VERSION@:' "$file"
    done
    shopt -u nullglob

    # Configure
    ./configure --prefix=''${out} --program-suffix=-${version}

    # Build
    ${gnumake}/bin/make -C bin autom4te
    ${gnumake}/bin/make -C lib
    ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    ln -s autoconf-${version} ''${out}/bin/autoconf
    ln -s autoheader-${version} ''${out}/bin/autoheader
    ln -s autom4te-${version} ''${out}/bin/autom4te
    ln -s autoreconf-${version} ''${out}/bin/autoreconf
  ''
