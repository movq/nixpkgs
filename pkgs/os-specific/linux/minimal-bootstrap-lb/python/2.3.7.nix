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
  pythonPass1,
}:
let
  pname = "python";
  version = "2.3.7";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tgz";
    hash = "sha256-lpqYkdzp9QsT5U+YkKyvK+ZnFaWJW/mxERHzIMIFuQ4=";
  };

  unicodeDataSrc = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/UnicodeData-3.2.0.txt";
    hash = "sha256-XkRAKLbnbZb53FCWCcXjIiv2CQVvNeX83n5vuKWM1EY=";
  };

  compositionExclusionsSrc = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/CompositionExclusions-3.2.0.txt";
    hash = "sha256-HTpFDQ85kCcQ30lyrEpg7DH7y1T/1NU82BL8EgDHMss=";
  };
in
bash.runCommand "${pname}-${version}"
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
      pythonPass1
    ];

    meta = {
      description = "Python 2.3.7 rebuilt with regenerated unicode, regex, and AST files";
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
    rm Lib/stringprep.py
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${grep}/bin/grep -r -l generated . | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    cp ${unicodeDataSrc} UnicodeData.txt
    cp ${compositionExclusionsSrc} CompositionExclusions.txt
    ${pythonPass1}/bin/python Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    ${pythonPass1}/bin/python Lib/sre_constants.py

    rm Lib/compiler/ast.py
    (
      cd Tools/compiler
      ${pythonPass1}/bin/python astgen.py > ../../Lib/compiler/ast.py
    )

    rm -f configure
    ACLOCAL=aclocal-1.15 AUTOMAKE=automake-1.15 autoreconf-2.69 -fi

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc CFLAGS="-U__DATE__ -U__TIME__" \
      ./configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --enable-ipv6

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Parser/pgen
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Include/graminit.h

    cp Lib/symbol.py Lib/keyword.py Lib/token.py .
    ${pythonPass1}/bin/python symbol.py
    ${pythonPass1}/bin/python keyword.py
    ${pythonPass1}/bin/python token.py

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CFLAGS="-U__DATE__ -U__TIME__"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
