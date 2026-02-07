{
  lib,
  fetchurl,
  bash,
  coreutils,
  cxx,
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
  oldPython,
}:
let
  pname = "python";
  version = "2.3.7";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tgz";
    hash = "sha256-lpqYkdzp9QsT5U+YkKyvK+ZnFaWJW/mxERHzIMIFuQ4=";
  };
in
bash.runCommand "${pname}-${version}-pass1"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cxx
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
      oldPython
    ];

    meta = {
      description = "Python 2.3.7 first pass with unicode generation disabled";
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

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./2.3.7/patches/posixmodule.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.3.7/patches/pyc.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.3.7/files/disable-unicode.patch}
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

    rm Lib/test/test_pep263.py
    rm Modules/glmodule.c
    rm Modules/unicodedata_db.h Objects/unicodetype_db.h
    rm Lib/stringprep.py
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${grep}/bin/grep -r -l generated . | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    rm Modules/sre_constants.h
    ${oldPython}/bin/python Lib/sre_constants.py

    rm Lib/compiler/ast.py
    (
      cd Tools/compiler
      ${oldPython}/bin/python astgen.py > ../../Lib/compiler/ast.py
    )

    rm -f configure
    ACLOCAL=aclocal-1.15 AUTOMAKE=automake-1.15 autoreconf-2.69 -fi

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc CFLAGS="-U__DATE__ -U__TIME__" \
      ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --with-wctype-functions \
      --enable-ipv6

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Parser/pgen
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Include/graminit.h

    cp Lib/symbol.py Lib/keyword.py Lib/token.py .
    ${oldPython}/bin/python symbol.py
    ${oldPython}/bin/python keyword.py
    ${oldPython}/bin/python token.py

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CFLAGS="-U__DATE__ -U__TIME__"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
