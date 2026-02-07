{
  lib,
  fetchurl,
  bash,
  coreutils,
  cc,
  musl,
  binutils,
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
}:
let
  pname = "python";
  version = "2.0.1";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tgz";
    hash = "sha256-mFV7gZpC0gk7QdhjcwLRMRuB9ievmtIANjV9frKBOHI=";
  };
in
bash.runCommand "${pname}-${version}-pass1"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cc
      binutils
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
    ];

    meta = {
      description = "Python 2.0.1 first pass with unicode and regex generation disabled";
      homepage = "https://www.python.org/";
      license = lib.licenses.psfl;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "python";
    };
  }
  ''
    # Unpack
    cp ${src} python.tgz
    ${gzip}/bin/gzip -d -f python.tgz
    ${gnutar}/bin/tar xf python.tar
    rm python.tar
    cd Python-${version}

    cp ${./2.0.1/files/keyword.c} keyword.c
    cp ${./2.0.1/files/token.c} token.c

    export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./2.0.1/patches/posixmodule.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.0.1/patches/destdir.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.0.1/patches/pyc.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.0.1/patches/undefs.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.0.1/files/disable-unicode.patch}
    ${findutils}/bin/find . -type f -name Makefile.in -exec \
      ${gnused}/bin/sed -i "s|^SHELL[[:space:]]*=[[:space:]]*/bin/sh$|SHELL = ${bash}/bin/bash|" {} +
    ${findutils}/bin/find . -type f -name Makefile.pre.in -exec \
      ${gnused}/bin/sed -i "s|^SHELL[[:space:]]*=[[:space:]]*/bin/sh$|SHELL = ${bash}/bin/bash|" {} +
    ${findutils}/bin/find . -type f -print0 | while IFS= read -r -d $'\0' script; do
      if ${coreutils}/bin/head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
        chmod 755 "$script"
      fi
    done

    rm Modules/glmodule.c
    rm Modules/unicodedata_db.h Objects/unicodetype_db.h
    rm Modules/sre_constants.h
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${grep}/bin/grep -r -l generated . | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    ${gnused}/bin/sed -i '/^_sre/d' Modules/Setup.in
    ${gnused}/bin/sed -i '/^unicodedata/d' Modules/Setup.in

    rm -f configure
    ACLOCAL=aclocal-1.15 AUTOMAKE=automake-1.15 autoreconf-2.69 -fi

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc \
      ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --with-wctype-functions

    # Build pgen
    (
      cd Parser
      ${gnumake}/bin/make -j1 pgen
    )
    # Regenerate graminit.c and graminit.h
    (
      cd Grammar
      ${gnumake}/bin/make -j1 graminit.c
    )

    # Regenerate token/keyword/symbol scripts with the C helpers.
    cc -o keyword keyword.c
    cc -o token token.c
    ${grep}/bin/grep -E '\{1, "[^"]+"' Python/graminit.c | ./keyword > Lib/keyword.py.new
    mv Lib/keyword.py.new Lib/keyword.py
    ./token Lib/symbol.py < Include/graminit.h > Lib/symbol.py.new
    mv Lib/symbol.py.new Lib/symbol.py
    ${grep}/bin/grep '#define[[:space:]][A-Z]*[[:space:]][[:space:]]*[0-9][0-9]*' Include/token.h | ./token Lib/token.py > Lib/token.py.new
    mv Lib/token.py.new Lib/token.py

    # Build
    ${gnumake}/bin/make -j1

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
