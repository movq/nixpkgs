{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  buildGcc,
  buildMusl,
  crossGcc,
  crossBinutils,
  crossMusl,
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
  help2man,
  bison,
}:
let
  pname = "coreutils";
  version = "9.4";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://github.com/coreutils/coreutils/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-2zf33TqJYS1J4hnFFayiuFMdpalE5JyyYpwlXVngmbk=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/bb5bb43.tar.gz";
    hash = "sha256-fyHd6QYywhk31+q4649668jDS4gjc34ZBPBF/CbJQ/o=";
  };

  unicodeSources = [
    {
      name = "UnicodeData-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/UnicodeData.txt";
        hash = "sha256-gG6a7WUDcZfx7IXhK+bozYcPxWCLTeD//ZkPaJ83anM=";
      };
    }
    {
      name = "PropList-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/PropList.txt";
        hash = "sha256-4FwKKBHRE9rkq9gyiEGZo+qNGH7huHLYJAp4ipZUC/0=";
      };
    }
    {
      name = "DerivedCoreProperties-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/DerivedCoreProperties.txt";
        hash = "sha256-02cpC8CGfmtITGg3BTC90aCLazJARgG4x6zK+D4FYo0=";
      };
    }
    {
      name = "emoji-data-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/emoji/emoji-data.txt";
        hash = "sha256-KQcduiLHLCd4OnMBavuP+usCWGZ0B5H5wtC1XMRaNHA=";
      };
    }
    {
      name = "ArabicShaping-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/ArabicShaping.txt";
        hash = "sha256-64QPNuCnRGKTV4xoSlTG2D0kmr3nvdTfqJeUrx1/6ek=";
      };
    }
    {
      name = "Scripts-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/Scripts.txt";
        hash = "sha256-zKhdgw9Grs4ufBRZ7xJJmT3Kjy5G1R6GklW+FA1+pLA=";
      };
    }
    {
      name = "Blocks-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/Blocks.txt";
        hash = "sha256-Up3F0PY4bVLy9W4AS7+rSM4tWH7qnTi6VGxAUkkb2CA=";
      };
    }
    {
      name = "PropList-3.0.1.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/3.0-Update1/PropList-3.0.1.txt";
        hash = "sha256-kJ7vStvt293c2Uh8hW/ozbuJEqqOsxXteIW272X03Ew=";
      };
    }
    {
      name = "EastAsianWidth-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/EastAsianWidth.txt";
        hash = "sha256-dD57xDXASrGoRZcQscPK1W7tztW4BrRlm25puF0K3yo=";
      };
    }
    {
      name = "LineBreak-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/LineBreak.txt";
        hash = "sha256-ASvKho4sTlmloQp1RrrwxvsbLvRYwnfwVJFciknSkr8=";
      };
    }
    {
      name = "WordBreakProperty-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/auxiliary/WordBreakProperty.txt";
        hash = "sha256-UYilbpFZNGfC6RJgHrx4dQ5q3JsEVBuMW+y1RB44jOI=";
      };
    }
    {
      name = "GraphemeBreakProperty-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/auxiliary/GraphemeBreakProperty.txt";
        hash = "sha256-Wg+HSFdUMvj/leHdW/qie9oahEgJ4X1pOe6RK7plaKE=";
      };
    }
    {
      name = "CompositionExclusions-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/CompositionExclusions.txt";
        hash = "sha256-OwGcCjPDFAy8kgwHj0+a8mgLpPcYacjU3lGQZnxwtqM=";
      };
    }
    {
      name = "SpecialCasing-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/SpecialCasing.txt";
        hash = "sha256-eLKcZLWEDSXBGp8xtmXuVRuKSZ7KbHDXcPytfdcQ9JQ=";
      };
    }
    {
      name = "CaseFolding-15.0.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/15.0.0/ucd/CaseFolding.txt";
        hash = "sha256-zdSeVerju/Hwo/ZYDJdKAmPLhqagjaoQ+/cFtICKVvc=";
      };
    }
  ];
in
bash.runCommand "${pname}-${version}-x86_64"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      buildGcc
      buildMusl
      crossGcc
      crossBinutils
      crossMusl
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
      help2man
      bison
    ];

    meta = {
      description = "GNU core utilities (x86_64)";
      homepage = "https://www.gnu.org/software/coreutils/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "ls";
    };
  }
  ''
    # Unpack
    cp ${src} coreutils.tar.gz
    ${gzip}/bin/gzip -d -f coreutils.tar.gz
    ${gnutar}/bin/tar xf coreutils.tar
    rm coreutils.tar

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-bb5bb43
    for script in gnulib-bb5bb43/* gnulib-bb5bb43/build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-bb5bb43/build-aux/po/Makefile.in.in

    ${lib.concatMapStringsSep "\n" (f: "cp ${f.src} ${f.name}") unicodeSources}

    ${gnupatch}/bin/patch -Np0 -i ${./9.4/remove_gettext.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./9.4/force_to_use_nanosleep.patch}

    cd coreutils-${version}

    # Build CC wrapper (for host programs that run during build)
    mkdir -p /build/wrappers
    cat > /build/wrappers/build-cc <<EOF
    #!${bash}/bin/bash
    exec ${buildGcc}/bin/gcc \
      -isystem ${buildMusl}/include \
      -B ${buildMusl}/lib \
      -L ${buildMusl}/lib \
      -std=gnu17 \
      -Wno-error=implicit-function-declaration \
      -Wno-error=implicit-int \
      -Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${buildMusl}/lib \
      "\$@"
    EOF
    chmod 555 /build/wrappers/build-cc
    ln -s /build/wrappers/build-cc /build/wrappers/gcc

    # Cross CC wrapper
    cat > ${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec ${crossGcc}/bin/${target}-gcc \
      --sysroot=${crossMusl} \
      -isystem ${crossMusl}/include \
      -std=gnu17 \
      -Wno-error=implicit-function-declaration \
      -Wno-error=implicit-int \
      -Wl,--dynamic-linker=${crossMusl}/lib/ld-musl-x86_64.so.1 \
      -Wl,-rpath,${crossMusl}/lib \
      "\$@"
    EOF
    chmod 555 ${target}-gcc

    cat > gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 gcc

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/${target}-gcc" "\$@"
    EOF
    chmod 555 cc

    export PATH="''${PWD}:${crossBinutils}/bin:$PATH"

    # Prepare
    cp ${./9.4/import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    # The import-gnulib.sh calls 'gcc' to build gen-uni-tables which must run
    # on the build machine (i386). Override gcc in the gnulib subdir.
    ln -sf /build/wrappers/build-cc ../gnulib-bb5bb43/lib/gcc

    build-aux/gen-lists-of-programs.sh --autoconf > m4/cu-progs.m4
    build-aux/gen-lists-of-programs.sh --automake > src/cu-progs.mk
    build-aux/gen-single-binary.sh src/local.mk > src/single-binary.mk
    touch ChangeLog
    cp ../gnulib-bb5bb43/build-aux/po/Makefile.in.in po/Makefile.in.in
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in

    rm man/help2man
    ln -s ${help2man}/bin/help2man man/help2man

    rm ../gnulib-bb5bb43/lib/uniwidth/width*.h
    rm ../gnulib-bb5bb43/lib/unictype/ctype*.h
    rm ../gnulib-bb5bb43/lib/unicase/tolower.h

    # gen-uni-tables must run on the build machine
    (
      cd ../gnulib-bb5bb43/lib
      /build/wrappers/build-cc -Iunictype -o gen-uni-tables gen-uni-tables.c
    )

    ${bash}/bin/sh ./import-gnulib.sh
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    echo "${version}" > .tarball-version
    rm gl/tests/test-rand-isaac.c

      rm -f configure
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    FORCE_UNSAFE_CONFIGURE=1 \
      CC_FOR_BUILD=/build/wrappers/build-cc \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${buildTarget} \
        --host=${target} \
        gl_cv_func_getcwd_path_max="no, but it is partly working" \
        gl_cv_prog_perl=no

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out} MAKEINFO=true GPERF=true

    # Install
    ${gnumake}/bin/make install PREFIX=''${out} MAKEINFO=true
  ''
