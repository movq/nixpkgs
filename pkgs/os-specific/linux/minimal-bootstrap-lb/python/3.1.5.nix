{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cxx,
  musl,
  binutils,
  bzip2,
  gnumake,
  gnupatch,
  gnutar,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libffi,
  zlib,
  oldPython,
  pythonPass1,
}:
let
  pname = "python";
  version = "3.1.5";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.bz2";
    hash = "sha256-OnKiFSjwdR6JFRdENQ3RIAQTHTEtR7k1zoBBsHDJA2E=";
  };

  unicodeData32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/UnicodeData-3.2.0.txt";
    hash = "sha256-XkRAKLbnbZb53FCWCcXjIiv2CQVvNeX83n5vuKWM1EY=";
  };

  compositionExclusions32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/CompositionExclusions-3.2.0.txt";
    hash = "sha256-HTpFDQ85kCcQ30lyrEpg7DH7y1T/1NU82BL8EgDHMss=";
  };

  eastAsianWidth32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/EastAsianWidth-3.2.0.txt";
    hash = "sha256-zhnzX/ypEb9JKqtsDT9q89GTLzXSBkzy/hThC+KVNMs=";
  };

  derivedCoreProperties32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/DerivedCoreProperties-3.2.0.txt";
    hash = "sha256-eHQZ3ekXAQGNetT0dDLqpVrxTj/j/hQKEeS789sYu0w=";
  };

  derivedNormalizationProps32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/DerivedNormalizationProps-3.2.0.txt";
    hash = "sha256-urSSleX5BkITdiRHIkzNg86gzO0Ntdz8lvnIqTXvZ+4=";
  };

  unicodeData51Src = fetchurl {
    url = "http://ftp.unicode.org/Public/5.1.0/ucd/UnicodeData.txt";
    hash = "sha256-i9g+nE4zlyjs1TLFsXTeW+uctLq12xTkT80DzLLiwbU=";
    name = "UnicodeData-5.1.0.txt";
  };

  compositionExclusions51Src = fetchurl {
    url = "http://ftp.unicode.org/Public/5.1.0/ucd/CompositionExclusions.txt";
    hash = "sha256-aDsJTyvdCrEywLrCk6VARibdhYpTtTZLO2tSUyPFpeQ=";
    name = "CompositionExclusions-5.1.0.txt";
  };

  eastAsianWidth51Src = fetchurl {
    url = "http://ftp.unicode.org/Public/5.1.0/ucd/EastAsianWidth.txt";
    hash = "sha256-oNir8I0I8+YYda7WARy3DGHdjqYQieatm2z1JNj7oPI=";
    name = "EastAsianWidth-5.1.0.txt";
  };

  derivedCoreProperties51Src = fetchurl {
    url = "http://ftp.unicode.org/Public/5.1.0/ucd/DerivedCoreProperties.txt";
    hash = "sha256-j1THdYf+6Z+swvKLlOdI392l2kT0KtqzGmX4i2NYeuA=";
    name = "DerivedCoreProperties-5.1.0.txt";
  };

  derivedNormalizationProps51Src = fetchurl {
    url = "http://ftp.unicode.org/Public/5.1.0/ucd/DerivedNormalizationProps.txt";
    hash = "sha256-T8jL+h7tV4zdoHaPtKSs5UQ/gHwfZS42pr12joHCwqM=";
    name = "DerivedNormalizationProps-5.1.0.txt";
  };

  cp437Src = fetchurl {
    url = "http://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/PC/CP437.TXT";
    hash = "sha256-a61Nq831lAInx9gfqxMNyxineFC1153ii13E4Eewqqw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cxx
      binutils
      bzip2
      gnumake
      gnupatch
      gnutar
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libffi
      zlib
      oldPython
      pythonPass1
    ];

    meta = {
      description = "Python 3.1.5 rebuilt with regenerated parser, unicode, and encoding files";
      homepage = "https://www.python.org/";
      license = lib.licenses.psfl;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "python";
    };
  }
  ''
    # Unpack
    cp ${src} python.tar.bz2
    ${bzip2}/bin/bzip2 -d -f python.tar.bz2
    ${gnutar}/bin/tar xf python.tar
    rm python.tar
    cp ${unicodeData32Src} UnicodeData-3.2.0.txt
    cp ${compositionExclusions32Src} CompositionExclusions-3.2.0.txt
    cp ${eastAsianWidth32Src} EastAsianWidth-3.2.0.txt
    cp ${derivedCoreProperties32Src} DerivedCoreProperties-3.2.0.txt
    cp ${derivedNormalizationProps32Src} DerivedNormalizationProps-3.2.0.txt
    cp ${unicodeData51Src} UnicodeData-5.1.0.txt
    cp ${compositionExclusions51Src} CompositionExclusions-5.1.0.txt
    cp ${eastAsianWidth51Src} EastAsianWidth-5.1.0.txt
    cp ${derivedCoreProperties51Src} DerivedCoreProperties-5.1.0.txt
    cp ${derivedNormalizationProps51Src} DerivedNormalizationProps-5.1.0.txt
    cp ${cp437Src} CP437.TXT
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./3.1.5/patches/install-perms.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.1.5/patches/openssl.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.1.5/patches/posixmodule.patch}
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

    rm Include/Python-ast.h Python/Python-ast.c
    rm Lib/stringprep.py
    rm Lib/pydoc_data/topics.py
    rm Misc/Vim/python.vim
    rm -r Modules/_ctypes/libffi
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${gnused}/bin/sed -i "1s@^#!.*python.*@#!${pythonPass1}/bin/python@" Parser/asdl_c.py
    chmod 555 Parser/asdl_c.py
    ${grep}/bin/grep generated -r . -l | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    mkdir Tools/unicode/in Tools/unicode/out
    mv ../CP437.TXT Tools/unicode/in/
    (
      cd Tools/unicode
      ${pythonPass1}/bin/python -B gencodec.py in/ ../../Lib/encodings/
    )

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    for f in UnicodeData CompositionExclusions EastAsianWidth DerivedCoreProperties DerivedNormalizationProps; do
      mv "../$f-3.2.0.txt" .
      mv "../$f-5.1.0.txt" "$f.txt"
    done
    ${pythonPass1}/bin/python -B Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    ${oldPython}/bin/python Lib/sre_constants.py

    aclocal-1.16
    autoheader-2.71
    rm -f configure
    autoconf-2.71

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc CFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include" \
      CPPFLAGS="-I${libffi}/include -I${zlib}/include" \
      LDFLAGS="-L${libffi}/lib -L${zlib}/lib -L${musl}/lib" \
      ./configure \
      --build=${target} \
      --host=${target} \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --with-pydebug \
      --with-system-ffi \
      --enable-ipv6

    # Build
    ${gnupatch}/bin/patch -Np1 -i ${./3.1.5/files/graminit-regen.patch}
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Parser/pgen
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Include/graminit.h

    cp Lib/symbol.py Lib/keyword.py Lib/token.py .
    ${pythonPass1}/bin/python -B symbol.py
    ${pythonPass1}/bin/python -B keyword.py
    ${pythonPass1}/bin/python -B token.py

    ${gnupatch}/bin/patch -Np1 -R -i ${./3.1.5/files/graminit-regen.patch}
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install
    ln --symbolic --relative ''${out}/bin/python3.1 ''${out}/bin/python

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
    rm ''${out}/lib/python3.1/lib2to3/{Pattern,}Grammar3.1.5.final.0.pickle
  ''
