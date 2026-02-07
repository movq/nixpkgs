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
  oldPython,
}:
let
  pname = "python";
  version = "2.5.6";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/${version}/Python-${version}.tar.bz2";
    hash = "sha256-V+BEhN4FHezUdB+0pKP1Q77MmiGa+LgGO1VB4nDybcw=";
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

  unicodeData41Src = fetchurl {
    url = "http://ftp.unicode.org/Public/4.1.0/ucd/UnicodeData.txt";
    hash = "sha256-qfA/agYe4hDFPjN4IoiiCL7UjGXHDTB7KyFJic7f2rA=";
    name = "UnicodeData-4.1.0.txt";
  };

  compositionExclusions41Src = fetchurl {
    url = "http://ftp.unicode.org/Public/4.1.0/ucd/CompositionExclusions.txt";
    hash = "sha256-EAOmiWB453UyoBexNXYlAf8KVAujNpTjK2F38JPr5rI=";
    name = "CompositionExclusions-4.1.0.txt";
  };

  eastAsianWidth41Src = fetchurl {
    url = "http://ftp.unicode.org/Public/4.1.0/ucd/EastAsianWidth.txt";
    hash = "sha256-CJ7Vsr7NMZbmESTTbpaEdNO3FSy1o/tWWUw0qx5pjpI=";
    name = "EastAsianWidth-4.1.0.txt";
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
      oldPython
    ];

    meta = {
      description = "Python 2.5.6 rebuilt with regenerated unicode, parser, and AST files";
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
    cp ${unicodeData41Src} UnicodeData-4.1.0.txt
    cp ${compositionExclusions41Src} CompositionExclusions-4.1.0.txt
    cp ${eastAsianWidth41Src} EastAsianWidth-4.1.0.txt
    cd Python-${version}

        export PATH="${binutils}/bin:$PATH"

    # Prepare
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/keyword.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/pgen-timestamp.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/posixmodule.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/pyc.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/sorted.patch}
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/patches/sre_constants.patch}
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
    rm Include/Python-ast.h Python/Python-ast.c
    rm Lib/stringprep.py
    rm Misc/Vim/python.vim
    mv Lib/plat-generic .
    rm -r Lib/plat-*
    rm -r Modules/_ctypes/libffi
    mv plat-generic Lib/
    ${gnused}/bin/sed -i "s@/usr/include@${musl}/include@g" Lib/plat-generic/regen
    chmod 555 Lib/plat-generic/regen
    ${gnused}/bin/sed -i "1s@^#!.*python.*@#!${oldPython}/bin/python@" Parser/asdl_c.py
    chmod 555 Parser/asdl_c.py
    ${grep}/bin/grep -r -l generated . | ${grep}/bin/grep encodings | ${findutils}/bin/xargs -r rm

    rm Modules/unicodedata_db.h Modules/unicodename_db.h Objects/unicodetype_db.h
    for f in UnicodeData CompositionExclusions EastAsianWidth; do
      mv "../$f-3.2.0.txt" .
      mv "../$f-4.1.0.txt" "$f.txt"
    done
    ${oldPython}/bin/python Tools/unicode/makeunicodedata.py

    rm Modules/sre_constants.h
    ${oldPython}/bin/python Lib/sre_constants.py

    rm Lib/compiler/ast.py
    (
      cd Tools/compiler
      ${oldPython}/bin/python astgen.py > ../../Lib/compiler/ast.py
    )

    aclocal-1.16
    autoheader-2.71
    rm -f configure
    autoconf-2.71

    # Configure
    MACHDEP=linux ac_sys_system=Linux CC=cc CFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include" \
      CPPFLAGS="-I${libffi}/include" \
      LDFLAGS="-L${libffi}/lib -L${musl}/lib" \
      ./configure \
      --build=${target} \
      --host=${target} \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --with-system-ffi \
      --enable-ipv6

    # Build
    ${gnupatch}/bin/patch -Np1 -i ${./2.5.6/files/graminit-regen.patch}
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Parser/pgen
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" Include/graminit.h

    cp Lib/symbol.py Lib/keyword.py Lib/token.py .
    ${oldPython}/bin/python symbol.py
    ${oldPython}/bin/python keyword.py
    ${oldPython}/bin/python token.py

    ${gnupatch}/bin/patch -Np1 -R -i ${./2.5.6/files/graminit-regen.patch}

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" CFLAGS="-U__DATE__ -U__TIME__ -I${libffi}/include"

    # Install
    mkdir -p ''${out}
    ${gnumake}/bin/make install

    # Remove non-reproducible cache files.
    ${findutils}/bin/find ''${out} -name "*.pyc" -delete
    ${findutils}/bin/find ''${out} -name "*.pyo" -delete
  ''
