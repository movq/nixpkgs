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
  libffi,
  zlib,
  oldPython,
}:
let
  pname = "python";
  version = "3.3.7";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz";
    hash = "sha256-hfYMMnUBw2vBjDM3DBTUcoAeavL5Adr7ugVvYWhUKf4=";
  };

  opensslVersion = "1.1.1w";
  opensslSrc = fetchurl {
    url = "https://www.openssl.org/source/openssl-${opensslVersion}.tar.gz";
    hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
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

  unicodeData61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/UnicodeData.txt";
    hash = "sha256-MGYmJYWjxPQHsW23h+bTpuAzuQ8nQFtsdtG6vv/8pq0=";
    name = "UnicodeData-6.1.0.txt";
  };

  compositionExclusions61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/CompositionExclusions.txt";
    hash = "sha256-IRJPnTg3LWjgnGe8tkaU/UvKDJyznFdrHwlVVMTqlpM=";
    name = "CompositionExclusions-6.1.0.txt";
  };

  eastAsianWidth61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/EastAsianWidth.txt";
    hash = "sha256-1ZHCS3AsGwJbWMphaHRvcTtlfG4lLCaPUssHdY9CgGc=";
    name = "EastAsianWidth-6.1.0.txt";
  };

  derivedCoreProperties61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/DerivedCoreProperties.txt";
    hash = "sha256-oD5iul+pxvMntubPxdAU9Zr5smK3aN2aaqo50gXdi3o=";
    name = "DerivedCoreProperties-6.1.0.txt";
  };

  derivedNormalizationProps61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/DerivedNormalizationProps.txt";
    hash = "sha256-0Cj37Mq0mY+NemsVcDsIjib/buHy28CTmuhywhPehiA=";
    name = "DerivedNormalizationProps-6.1.0.txt";
  };

  lineBreak61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/LineBreak.txt";
    hash = "sha256-e34s9YLvfyT9J0ek7xpQk0wVoPwKsQznN9Xj5Hvr3g0=";
    name = "LineBreak-6.1.0.txt";
  };

  nameAliases61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/NameAliases.txt";
    hash = "sha256-clO9hOINNEkbKxJKhcqEvSzV0RPklXrrrpLw48IfCkU=";
    name = "NameAliases-6.1.0.txt";
  };

  namedSequences61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/NamedSequences.txt";
    hash = "sha256-YMiLbjzuyHHMa34tVSRT+I7vD0D/IYjZzscCHC3r02o=";
    name = "NamedSequences-6.1.0.txt";
  };

  specialCasing61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/SpecialCasing.txt";
    hash = "sha256-fQR/4aqKaMwSEBQnzwO/vOgyAe4nfpB4IpAXNfC/7jw=";
    name = "SpecialCasing-6.1.0.txt";
  };

  caseFolding61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/CaseFolding.txt";
    hash = "sha256-TAvs4Tghok9Gm7jRbqM/x9pkNrfr5kx4Y1Zz2/qojtw=";
    name = "CaseFolding-6.1.0.txt";
  };

  unihan61Src = fetchurl {
    url = "http://ftp.unicode.org/Public/6.1.0/ucd/Unihan.zip";
    hash = "sha256-jKUI7xvH66jBAnEAFthRD4cfab3MdP+HfDPQG7eZo48=";
    name = "Unihan-6.1.0.zip";
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
      libffi
      zlib
      oldPython
    ];

    meta = {
      description = "Python 3.3.7 rebuilt with regenerated parser, unicode, and ssl data files";
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
    cp ${unicodeData61Src} UnicodeData-6.1.0.txt
    cp ${compositionExclusions61Src} CompositionExclusions-6.1.0.txt
    cp ${eastAsianWidth61Src} EastAsianWidth-6.1.0.txt
    cp ${derivedCoreProperties61Src} DerivedCoreProperties-6.1.0.txt
    cp ${derivedNormalizationProps61Src} DerivedNormalizationProps-6.1.0.txt
    cp ${lineBreak61Src} LineBreak-6.1.0.txt
    cp ${nameAliases61Src} NameAliases-6.1.0.txt
    cp ${namedSequences61Src} NamedSequences-6.1.0.txt
    cp ${specialCasing61Src} SpecialCasing-6.1.0.txt
    cp ${caseFolding61Src} CaseFolding-6.1.0.txt
    cp ${unihan61Src} Unihan-6.1.0.zip
    cp ${cp437Src} CP437.TXT
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./3.3.7/patches/install-perms.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.3.7/patches/symbol.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./3.3.7/patches/multiarch-os-system-no-sh.patch}
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
    rm Python/importlib.h
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

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    mv ../*.txt ../*.zip .
    ${oldPython}/bin/python -B Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    cp Lib/sre_constants.py .
    ${oldPython}/bin/python -B sre_constants.py

    ${oldPython}/bin/python -B Tools/ssl/make_ssl_data.py ../openssl-${opensslVersion}/include/openssl Modules/_ssl_data.h

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
    ln --symbolic --relative ''${out}/bin/python3.3 ''${out}/bin/python

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
    rm ''${out}/lib/python3.3/lib2to3/{Pattern,}Grammar3.3.7.final.0.pickle
  ''
