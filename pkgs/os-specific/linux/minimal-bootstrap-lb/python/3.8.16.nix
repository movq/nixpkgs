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
  version = "3.8.16";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz";
    hash = "sha256-2F27N3QTJHPYCB3LFY80oQzK16kLlsflDqS7YfXORWI=";
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

  unicodeData121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/UnicodeData.txt";
    hash = "sha256-k6sazY/Z1FBGO1Cud+qxUafNpI+YsltWuu2AcPgPyTY=";
    name = "UnicodeData-12.1.0.txt";
  };

  compositionExclusions121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/CompositionExclusions.txt";
    hash = "sha256-q8g5TFveYkUxGLAMHFhCFgoE1//7LoKe5UJrhGWW0IE=";
    name = "CompositionExclusions-12.1.0.txt";
  };

  eastAsianWidth121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/EastAsianWidth.txt";
    hash = "sha256-kEUAF4sudSY1vvJ6rtOio3GKEAvONf+Ws4kL56gxXY8=";
    name = "EastAsianWidth-12.1.0.txt";
  };

  derivedCoreProperties121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/DerivedCoreProperties.txt";
    hash = "sha256-put6hnH7Uy+9iMN/17ILWy59v8ixIfdMFKvilH2w2mg=";
    name = "DerivedCoreProperties-12.1.0.txt";
  };

  derivedNormalizationProps121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/DerivedNormalizationProps.txt";
    hash = "sha256-ktzdqEFCGUoVlvIhgPzfjA5/hol/CcySA8fcY2xUn18=";
    name = "DerivedNormalizationProps-12.1.0.txt";
  };

  lineBreak121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/LineBreak.txt";
    hash = "sha256-lh+EL8cLWv0dgsZkXmjBDR9wE4Ku04rjjLL/J/ZxkDw=";
    name = "LineBreak-12.1.0.txt";
  };

  nameAliases121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/NameAliases.txt";
    hash = "sha256-/2GgaH0vMsDdEJQlS4velniDtDwtTVD9F1MdSY5Bqyw=";
    name = "NameAliases-12.1.0.txt";
  };

  namedSequences121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/NamedSequences.txt";
    hash = "sha256-0+uaKI6+r53hI3mJ9JBwXih7b2ELWdJFn7G3wtjjnDk=";
    name = "NamedSequences-12.1.0.txt";
  };

  specialCasing121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/SpecialCasing.txt";
    hash = "sha256-gXzi6e3KjgdaFT9UuPOwIDReN2Us0r2psUlcNmrxfn4=";
    name = "SpecialCasing-12.1.0.txt";
  };

  caseFolding121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/CaseFolding.txt";
    hash = "sha256-nHcmJ8bud+6moXtCknuO4oygXcZdalEQYhBLqvPRIpQ=";
    name = "CaseFolding-12.1.0.txt";
  };

  unihan121Src = fetchurl {
    url = "http://ftp.unicode.org/Public/12.1.0/ucd/Unihan.zip";
    hash = "sha256-bkVT87X//g0xLfMk0CDvEnjZWVkyrgP06KLUJ96Dzc0=";
    name = "Unihan-12.1.0.zip";
  };

  cp437Src = fetchurl {
    url = "http://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/PC/CP437.TXT";
    hash = "sha256-a61Nq831lAInx9gfqxMNyxineFC1153ii13E4Eewqqw=";
  };

  rfc3454Src = fetchurl {
    url = "https://www.ietf.org/rfc/rfc3454.txt";
    hash = "sha256-63Ivppj7fogjuDXZ/SY+TNuPHHsNI07ffw470sy7LHk=";
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
      description = "Python 3.8.16 rebuilt with regenerated parser and unicode assets";
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
    cp ${unicodeData121Src} UnicodeData-12.1.0.txt
    cp ${compositionExclusions121Src} CompositionExclusions-12.1.0.txt
    cp ${eastAsianWidth121Src} EastAsianWidth-12.1.0.txt
    cp ${derivedCoreProperties121Src} DerivedCoreProperties-12.1.0.txt
    cp ${derivedNormalizationProps121Src} DerivedNormalizationProps-12.1.0.txt
    cp ${lineBreak121Src} LineBreak-12.1.0.txt
    cp ${nameAliases121Src} NameAliases-12.1.0.txt
    cp ${namedSequences121Src} NamedSequences-12.1.0.txt
    cp ${specialCasing121Src} SpecialCasing-12.1.0.txt
    cp ${caseFolding121Src} CaseFolding-12.1.0.txt
    cp ${unihan121Src} Unihan-12.1.0.zip
    cp ${cp437Src} CP437.TXT
    cp ${rfc3454Src} rfc3454.txt
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./3.8.16/patches/empty-date.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.8.16/patches/maxgroups.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.8.16/patches/multiarch-os-system-no-sh.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.8.16/patches/refractor.patch}
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

    rm Lib/pydoc_data/topics.py
    rm Modules/_ssl_data*.h

    ${grep}/bin/grep generated -r . -l | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm
    mkdir Tools/unicode/in Tools/unicode/out
    mv ../CP437.TXT Tools/unicode/in/
    (
      cd Tools/unicode
      ${oldPython}/bin/python -B gencodec.py in/ ../../Lib/encodings/
    )

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    mv ../*.txt ../*.zip .
    ${oldPython}/bin/python -B Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    cp Lib/sre_constants.py .
    ${oldPython}/bin/python -B sre_constants.py
    rm sre_constants.py
    mv sre_constants.h Modules/

    rm Lib/stringprep.py
    ${oldPython}/bin/python -B Tools/unicode/mkstringprep.py > Lib/stringprep.py

    aclocal-1.16
    autoheader-2.71
    rm -f configure
    autoconf-2.71

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc \
      CPPFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include" \
      LDFLAGS="-L${libffi}/lib -L${zlib}/lib -L${musl}/lib" \
      PYTHON_FOR_BUILD="python -B" \
      ./configure \
      --build=${target} \
      --host=${target} \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --with-system-ffi

    # Build
    rm Modules/_blake2/blake2s_impl.c
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" regen-all
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CPPFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install
    ln --symbolic --relative ''${out}/bin/python3.8 ''${out}/bin/python

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
