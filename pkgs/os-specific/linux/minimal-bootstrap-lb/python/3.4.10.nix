{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cxx,
  musl,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  xz,
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
}:
let
  pname = "python";
  version = "3.4.10";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz";
    hash = "sha256-1GqPb+kWeeGZxnGxsKMKrxctKstbyrJb6zXxbD0ZW04=";
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

  lineBreak32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/LineBreak-3.2.0.txt";
    hash = "sha256-1pPvKmA9B+ILdp74uimvyjl2VYigPjGWKU5b6GOMpzU=";
  };

  specialCasing32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/SpecialCasing-3.2.0.txt";
    hash = "sha256-H3kTt03d/1XuVm9iIKqeRluubydwn8IdNTsErbhXKzc=";
  };

  caseFolding32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/CaseFolding-3.2.0.txt";
    hash = "sha256-Nw89HnmlJ5HEIGWUZxH07dttmCByav0OQ2o8UDYEdak=";
  };

  unihan32Src = fetchurl {
    url = "http://ftp.unicode.org/Public/3.2-Update/Unihan-3.2.0.zip";
    hash = "sha256-BYK4iMTrq2486NNAx0eI8aaMpmJxOhBluaAH8ku0/kY=";
    name = "Unihan-3.2.0.zip";
  };

  unicodeData63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/UnicodeData.txt";
    hash = "sha256-P3aSTwQQyorg6bXFm9G6Axlik8MmFiBLOTMA8JH1IBM=";
    name = "UnicodeData-6.3.0.txt";
  };

  compositionExclusions63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/CompositionExclusions.txt";
    hash = "sha256-S6jqB5/7/8ACX8MQCelXJoZP7akNKEXJNjwMQN7YURw=";
    name = "CompositionExclusions-6.3.0.txt";
  };

  eastAsianWidth63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/EastAsianWidth.txt";
    hash = "sha256-u9+SgXZ8pGAa82I7YsJuy4NKn0xG7sYp2CM5sAbaANg=";
    name = "EastAsianWidth-6.3.0.txt";
  };

  derivedCoreProperties63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/DerivedCoreProperties.txt";
    hash = "sha256-eQgm9M+oLFhFq0BAtegR8eZ78exMiM2/cieVwykrAQI=";
    name = "DerivedCoreProperties-6.3.0.txt";
  };

  derivedNormalizationProps63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/DerivedNormalizationProps.txt";
    hash = "sha256-xehnrgQ/5dHPcTFQ2Fk1a/3NuikcOfWErwv7lD8al0M=";
    name = "DerivedNormalizationProps-6.3.0.txt";
  };

  lineBreak63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/LineBreak.txt";
    hash = "sha256-ajgGkCUSemD0qAnniPu9G7a5WsjRvWLmp414cDV/NIY=";
    name = "LineBreak-6.3.0.txt";
  };

  nameAliases63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/NameAliases.txt";
    hash = "sha256-oRvth+xvJk7c+E1YHdLXrI7XrBw7LMtUqDB3/b00Ez4=";
    name = "NameAliases-6.3.0.txt";
  };

  namedSequences63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/NamedSequences.txt";
    hash = "sha256-kfxp/2ixqJ5fcnBUVUfHR2JLyWsObCOnkdQmXS+h+Yg=";
    name = "NamedSequences-6.3.0.txt";
  };

  specialCasing63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/SpecialCasing.txt";
    hash = "sha256-ntr7omHiPnL24h49hdfxXdSGbzgASrO/3G9wV8WJ0DQ=";
    name = "SpecialCasing-6.3.0.txt";
  };

  caseFolding63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/CaseFolding.txt";
    hash = "sha256-ITI+aCorNEAMavSrV7l3W35xYVBCjwkrrFsAWoirj0I=";
    name = "CaseFolding-6.3.0.txt";
  };

  unihan63Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.3.0/ucd/Unihan.zip";
    hash = "sha256-nkCNceOrpP9o9QhVabwcMcl1H5d59Vz4d8IiRncymR8=";
    name = "Unihan-6.3.0.zip";
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
      gnumake
      gnupatch
      gnutar
      xz
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
    ];

    meta = {
      description = "Python 3.4.10 rebuilt with regenerated parser, unicode, and clinic files";
      homepage = "https://www.python.org/";
      license = lib.licenses.psfl;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "python";
    };
  }
  ''
    # Unpack
    cp ${src} python.tar.xz
    ${xz}/bin/xz -d -f python.tar.xz
    ${gnutar}/bin/tar xf python.tar
    rm python.tar
    cp ${unicodeData32Src} UnicodeData-3.2.0.txt
    cp ${compositionExclusions32Src} CompositionExclusions-3.2.0.txt
    cp ${eastAsianWidth32Src} EastAsianWidth-3.2.0.txt
    cp ${derivedCoreProperties32Src} DerivedCoreProperties-3.2.0.txt
    cp ${derivedNormalizationProps32Src} DerivedNormalizationProps-3.2.0.txt
    cp ${lineBreak32Src} LineBreak-3.2.0.txt
    cp ${specialCasing32Src} SpecialCasing-3.2.0.txt
    cp ${caseFolding32Src} CaseFolding-3.2.0.txt
    cp ${unihan32Src} Unihan-3.2.0.zip
    cp ${unicodeData63Src} UnicodeData-6.3.0.txt
    cp ${compositionExclusions63Src} CompositionExclusions-6.3.0.txt
    cp ${eastAsianWidth63Src} EastAsianWidth-6.3.0.txt
    cp ${derivedCoreProperties63Src} DerivedCoreProperties-6.3.0.txt
    cp ${derivedNormalizationProps63Src} DerivedNormalizationProps-6.3.0.txt
    cp ${lineBreak63Src} LineBreak-6.3.0.txt
    cp ${nameAliases63Src} NameAliases-6.3.0.txt
    cp ${namedSequences63Src} NamedSequences-6.3.0.txt
    cp ${specialCasing63Src} SpecialCasing-6.3.0.txt
    cp ${caseFolding63Src} CaseFolding-6.3.0.txt
    cp ${unihan63Src} Unihan-6.3.0.zip
    cp ${cp437Src} CP437.TXT
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./3.4.10/patches/install-perms.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.4.10/patches/symbol.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.4.10/patches/multiarch-os-system-no-sh.patch}
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
    rm -r Modules/_ctypes/libffi
    rm Python/importlib.h
    rm Modules/_ssl_data.h
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${grep}/bin/grep generated -r . -l | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    mkdir Tools/unicode/in Tools/unicode/out
    mv ../CP437.TXT Tools/unicode/in/
    (
      cd Tools/unicode
      ${oldPython}/bin/python -B gencodec.py in/ ../../Lib/encodings/
    )

    ${findutils}/bin/find . -name "*.c" -o -name "*.h" \
      | ${findutils}/bin/xargs -r ${grep}/bin/grep "clinic input" -l \
      | ${findutils}/bin/xargs -r -L 1 ${oldPython}/bin/python -B Tools/clinic/clinic.py

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    mv ../*.txt ../*.zip .
    ${oldPython}/bin/python -B Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    cp Lib/sre_constants.py .
    ${oldPython}/bin/python -B sre_constants.py
    mv sre_constants.h Modules/

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
      --with-system-ffi

    # Build
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Parser/pgen
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Include/graminit.h

    cp Lib/symbol.py Lib/keyword.py Lib/token.py .
    cp token.py _token.py
    ${oldPython}/bin/python -B symbol.py
    ${oldPython}/bin/python -B keyword.py
    ${oldPython}/bin/python -B token.py

    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install
    ln --symbolic --relative ''${out}/bin/python3.4 ''${out}/bin/python

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
    rm ''${out}/lib/python3.4/lib2to3/{Pattern,}Grammar3.4.10.final.0.pickle
  ''
