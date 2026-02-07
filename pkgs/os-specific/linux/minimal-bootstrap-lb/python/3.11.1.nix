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
  gzip,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  pkgConfig,
  autoconfArchive,
  libffi,
  zlib,
  oldPython,
}:
let
  pname = "python";
  version = "3.11.1";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz";
    hash = "sha256-hYeRkvLP/VbLFsCSkFlJ6/Pl45S392RyNSljeQHftY8=";
  };

  opensslVersion = "3.6.0";
  opensslSrc = fetchurl {
    url = "https://github.com/openssl/openssl/releases/download/openssl-${opensslVersion}/openssl-${opensslVersion}.tar.gz";
    hash = "sha256-tqX0S362nj+jXb8VUkQFtEg3pIHUPYHa3d4/8h/LuOk=";
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

  unicodeData140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/UnicodeData.txt";
    hash = "sha256-NgGOaGV/3LNIX2NmMP/oyFMuAcl3cD0oA/W4nWxf6vs=";
    name = "UnicodeData-14.0.0.txt";
  };

  compositionExclusions140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/CompositionExclusions.txt";
    hash = "sha256-M2B2L8MpXOpUqyUcMd9iHQW6S5TUbGDqrCmqFtcK0eA=";
    name = "CompositionExclusions-14.0.0.txt";
  };

  eastAsianWidth140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/EastAsianWidth.txt";
    hash = "sha256-+QGsARqjKgkiTWVV2nHiUyxZwdM4EyKCneDjuIBQclA=";
    name = "EastAsianWidth-14.0.0.txt";
  };

  derivedCoreProperties140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/DerivedCoreProperties.txt";
    hash = "sha256-4+3dfUac0bD+7XUo3vrRocx8apzrCuREam0Qkh7S57w=";
    name = "DerivedCoreProperties-14.0.0.txt";
  };

  derivedNormalizationProps140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/DerivedNormalizationProps.txt";
    hash = "sha256-ssREwgcwsJd4f99QvX1t0/xSVquAhPWzWxHId27KZ0w=";
    name = "DerivedNormalizationProps-14.0.0.txt";
  };

  lineBreak140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/LineBreak.txt";
    hash = "sha256-ngbp81xpWfuR3MeZP5DVhSPDB5vGLGsl+Ci0zevF1ww=";
    name = "LineBreak-14.0.0.txt";
  };

  nameAliases140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/NameAliases.txt";
    hash = "sha256-FLO2d9M/lcUUI9zm7vSmootLFgRR7O3uS5HttnRc9KM=";
    name = "NameAliases-14.0.0.txt";
  };

  namedSequences140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/NamedSequences.txt";
    hash = "sha256-21dFaIr/zcDDknoe4GZwGKlqeyRRP4ZtUjXpj+9sJDY=";
    name = "NamedSequences-14.0.0.txt";
  };

  specialCasing140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/SpecialCasing.txt";
    hash = "sha256-xme0WQj9JpryX9VdL8W7wVf7G3dnWTbiXFE84y4IAzQ=";
    name = "SpecialCasing-14.0.0.txt";
  };

  caseFolding140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/CaseFolding.txt";
    hash = "sha256-pWbNSGh7LNiX4CUBEYskE8FK6G0xj5q7u6l/64QYnw8=";
    name = "CaseFolding-14.0.0.txt";
  };

  unihan140Src = fetchurl {
    url = "http://ftp.unicode.org/Public/14.0.0/ucd/Unihan.zip";
    hash = "sha256-KuRRmyuCzU0VN5wX5Xv7EsM8D1TaSXfeA7KwS88RhS0=";
    name = "Unihan-14.0.0.zip";
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
      gzip
      xz
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      pkgConfig
      autoconfArchive
      libffi
      zlib
      oldPython
    ];

    meta = {
      description = "Python 3.11.1 rebuilt with regenerated parser, unicode, and frozen module assets";
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
    cp ${opensslSrc} openssl.tar.gz
    ${gzip}/bin/gzip -d -f openssl.tar.gz
    ${gnutar}/bin/tar xf openssl.tar
    rm openssl.tar
    cp ${unicodeData32Src} UnicodeData-3.2.0.txt
    cp ${compositionExclusions32Src} CompositionExclusions-3.2.0.txt
    cp ${eastAsianWidth32Src} EastAsianWidth-3.2.0.txt
    cp ${derivedCoreProperties32Src} DerivedCoreProperties-3.2.0.txt
    cp ${derivedNormalizationProps32Src} DerivedNormalizationProps-3.2.0.txt
    cp ${lineBreak32Src} LineBreak-3.2.0.txt
    cp ${specialCasing32Src} SpecialCasing-3.2.0.txt
    cp ${caseFolding32Src} CaseFolding-3.2.0.txt
    cp ${unihan32Src} Unihan-3.2.0.zip
    cp ${unicodeData140Src} UnicodeData-14.0.0.txt
    cp ${compositionExclusions140Src} CompositionExclusions-14.0.0.txt
    cp ${eastAsianWidth140Src} EastAsianWidth-14.0.0.txt
    cp ${derivedCoreProperties140Src} DerivedCoreProperties-14.0.0.txt
    cp ${derivedNormalizationProps140Src} DerivedNormalizationProps-14.0.0.txt
    cp ${lineBreak140Src} LineBreak-14.0.0.txt
    cp ${nameAliases140Src} NameAliases-14.0.0.txt
    cp ${namedSequences140Src} NamedSequences-14.0.0.txt
    cp ${specialCasing140Src} SpecialCasing-14.0.0.txt
    cp ${caseFolding140Src} CaseFolding-14.0.0.txt
    cp ${unihan140Src} Unihan-14.0.0.zip
    cp ${cp437Src} CP437.TXT
    cp ${rfc3454Src} rfc3454.txt
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    export ACLOCAL_PATH="${pkgConfig}/share/aclocal:${autoconfArchive}/share/aclocal"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./3.11.1/patches/empty-date.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.11.1/patches/multiarch.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.11.1/patches/multiarch-os-system-no-sh.patch}
    ${gnused}/bin/sed -i "s|'/bin/sh'|'${bash}/bin/bash'|g" Lib/subprocess.py
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
    rm Misc/stable_abi.toml

    rm Modules/_ssl_data_111.h Modules/_ssl_data.h
    ${oldPython}/bin/python -B Tools/ssl/make_ssl_data.py ../openssl-${opensslVersion} Modules/_ssl_data_300.h
    ${gnused}/bin/sed -i 's#$(srcdir)/Modules/_ssl_data.h ##' Makefile.pre.in
    ${gnused}/bin/sed -i 's#$(srcdir)/Modules/_ssl_data_111.h ##' Makefile.pre.in

    ${grep}/bin/grep generated -r . -l | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm
    mkdir Tools/unicode/in Tools/unicode/out
    mv ../CP437.TXT Tools/unicode/in/
    (
      cd Tools/unicode
      ${oldPython}/bin/python -B gencodec.py in/ ../../Lib/encodings/
    )

    rm Lib/stringprep.py
    mv ../rfc3454.txt .
    ${oldPython}/bin/python -B Tools/unicode/mkstringprep.py > Lib/stringprep.py

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    mkdir -p Tools/unicode/data
    mv ../*.txt ../*.zip Tools/unicode/data/
    ${oldPython}/bin/python -B Tools/unicode/makeunicodedata.py

    rm Lib/re/_casefix.py
    ${oldPython}/bin/python -B Tools/scripts/generate_re_casefix.py Lib/re/_casefix.py

    rm Programs/test_frozenmain.h
    ${oldPython}/bin/python -B Programs/freeze_test_frozenmain.py Programs/test_frozenmain.h

    cat > Python/stdlib_module_names.h <<EOF2
    static const char* _Py_stdlib_module_names[] = {};
    EOF2

    rm configure aclocal.m4
    ACLOCAL=aclocal-1.16 \
      AUTOMAKE=automake-1.16 \
      autoreconf-2.71 -fi

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
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      regen-opcode \
      regen-opcode-targets \
      regen-typeslots \
      regen-token \
      regen-ast \
      regen-keyword \
      regen-sre \
      clinic \
      regen-pegen-metaparser \
      regen-pegen \
      regen-global-objects
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" regen-frozen
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" regen-deepfreeze
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" regen-global-objects

    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CPPFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include"
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" regen-stdlib-module-names
    PYTHONDONTWRITEBYTECODE=1 ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      CPPFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include -I${zlib}/include"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install
    ln --symbolic --relative ''${out}/bin/python3.11 ''${out}/bin/python

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
