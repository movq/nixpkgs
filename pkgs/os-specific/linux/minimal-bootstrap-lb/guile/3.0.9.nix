{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  cxx,
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
  gperf,
  perl,
  autoconf,
  autoconf269,
  automake,
  libtool,
  pkgConfig,
  gmp,
  libunistring,
  libffi,
  boehm-gc,
}:
let
  pname = "guile";
  version = "3.0.9";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src307 = fetchurl {
    url = "https://mirrors.kernel.org/gnu/guile/guile-3.0.7.tar.xz";
    hash = "sha256-9X2GxwYgJxv863qb4MgXRKAz8IrcfOuoMsmRerPmkbc=";
  };

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/guile/guile-${version}.tar.xz";
    hash = "sha256-GiYlrHKyNm6VeS8/51j9Lfd1tARKkKSpeHMm5mwNdQ0=";
  };

  gnulibSrc307 = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/901694b9.tar.gz";
    hash = "sha256-xpvJ6YbWvGIiXriGNtxzyk4+To+iIlxUpe9Wm+ishEk=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/356a414e.tar.gz";
    hash = "sha256-H/D0GRGI4Y0SHtPKCe+zyX/fBUJiO1OfsMbHGuvP2/I=";
  };

  psyntaxBootstrapSrc = fetchurl {
    url = "https://github.com/schierlm/guile-psyntax-bootstrapping/archive/refs/tags/guile-3.0.7.tar.gz";
    hash = "sha256-FM2pxBZQbfrfYMFPxiP/Ae+ZuHVkp40KKcXRcUPJdgk=";
  };

  pkgConfigPath = lib.concatStringsSep ":" [
    "${libunistring}/lib/pkgconfig"
    "${libffi}/lib/pkgconfig"
    "${boehm-gc}/lib/pkgconfig"
  ];
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
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
      gperf
      perl
      autoconf
      autoconf269
      automake
      libtool
      pkgConfig
      gmp
      libunistring
      libffi
      boehm-gc
    ];

    meta = {
      description = "Ubiquitous, intelligent, extensible programming language";
      homepage = "https://www.gnu.org/software/guile/";
      license = lib.licenses.lgpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "guile";
    };
  }
  ''
    rewrite_sh_shebangs() {
      ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
      while read -r script; do
        [ -n "''${script}" ] || continue
        ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
        chmod 755 "''${script}"
      done < sh-scripts.list
      rm -f sh-scripts.list
    }

    common_prepare() {
      ${findutils}/bin/find . -name '*.info*' -delete
      rm -r prebuilt/*/ice-9

      ${gnused}/bin/sed -i "s/\`date -u +'%Y-%m-%d %T'.*\`/1970-01-01 00:00:00/" libguile/Makefile.am
      ${gnused}/bin/sed -i \
        's@(system (format #f "mv -f ~s.tmp ~s" target target))@(rename-file (string-append target ".tmp") target)@' \
        module/ice-9/compile-psyntax.scm

      rewrite_sh_shebangs
      rm configure Makefile.in aclocal.m4
      AUTOPOINT=true \
        ACLOCAL_PATH="${libtool}/share/aclocal:${pkgConfig}/share/aclocal" \
        ACLOCAL=aclocal-1.16 \
        AUTOMAKE=automake-1.16 \
        ${perl}/bin/perl ${autoconf}/bin/autoreconf-2.71 -fi
    }

    # Unpack
    cp ${src307} guile-3.0.7.tar.xz
    ${xz}/bin/xz -d -f guile-3.0.7.tar.xz
    ${gnutar}/bin/tar xf guile-3.0.7.tar
    rm guile-3.0.7.tar

    cp ${src} guile-3.0.9.tar.xz
    ${xz}/bin/xz -d -f guile-3.0.9.tar.xz
    ${gnutar}/bin/tar xf guile-3.0.9.tar
    rm guile-3.0.9.tar

    cp ${gnulibSrc307} gnulib-901694b9.tar.gz
    ${gzip}/bin/gzip -d -f gnulib-901694b9.tar.gz
    mkdir -p gnulib-901694b9
    ${gnutar}/bin/tar xf gnulib-901694b9.tar --strip-components=1 -C gnulib-901694b9
    rm gnulib-901694b9.tar
    (
      cd gnulib-901694b9
      rewrite_sh_shebangs
    )

    cp ${gnulibSrc} gnulib-356a414e.tar.gz
    ${gzip}/bin/gzip -d -f gnulib-356a414e.tar.gz
    mkdir -p gnulib-356a414e
    ${gnutar}/bin/tar xf gnulib-356a414e.tar --strip-components=1 -C gnulib-356a414e
    rm gnulib-356a414e.tar
    (
      cd gnulib-356a414e
      rewrite_sh_shebangs
    )

    cp ${psyntaxBootstrapSrc} guile-psyntax-bootstrapping.tar.gz
    ${gzip}/bin/gzip -d -f guile-psyntax-bootstrapping.tar.gz
    ${gnutar}/bin/tar xf guile-psyntax-bootstrapping.tar
    rm guile-psyntax-bootstrapping.tar

        export PATH="${binutils}/bin:$PATH"

    # Prepare guile-3.0.7
    cd guile-3.0.7
    cp ${./import-gnulib-3.0.7.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    ${bash}/bin/bash ./import-gnulib.sh
    common_prepare

    ${coreutils}/bin/sha256sum module/ice-9/psyntax-pp.scm | tee psyntax-pp.sha256
    rm module/ice-9/psyntax-pp.scm
    echo '(primitive-load-path "psyntax-bootstrap/allsteps")' > module/ice-9/psyntax-pp.scm
    mkdir -p module/psyntax-bootstrap
    cp ../guile-psyntax-bootstrapping-guile-3.0.7/psyntax-bootstrap/*.scm module/psyntax-bootstrap
    (
      cd module/ice-9
      cp psyntax.scm psyntax-patched.scm
      ${gnupatch}/bin/patch < ../../../guile-psyntax-bootstrapping-guile-3.0.7/stage2.patch
    )

    # Prepare guile-3.0.9
    cd ../guile-3.0.9
    cp ${./import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    ${bash}/bin/bash ./import-gnulib.sh

    # Remove modules not needed for the bootstrap (autogen) from the
    # byte-compilation list. This trims ~110 files from each of the three
    # compilation stages.
    ${gnupatch}/bin/patch -p1 < ${./slim-bootstrap.patch}

    common_prepare

    # Configure
    for d in . ../guile-3.0.7; do
      (
        cd "$d"
        PKG_CONFIG_PATH="${pkgConfigPath}" \
          CONFIG_SHELL=${bash}/bin/bash \
          SHELL=${bash}/bin/bash \
          CC=cc \
          CXX=c++ \
          CPP="cc -E" \
          CXXCPP="c++ -E" \
          CPPFLAGS="-I${gmp}/include -I${libunistring}/include -I${libffi}/include -I${boehm-gc}/include" \
          LDFLAGS="-L${gmp}/lib -L${libunistring}/lib -L${libffi}/lib -L${boehm-gc}/lib" \
          ${bash}/bin/bash ./configure \
            --prefix=''${out} \
            --libdir=''${out}/lib \
            --build=${target} \
            --disable-shared \
            --disable-jit
      )
    done

    # Rebuild psyntax-pp.scm with guile-3.0.7
    # The 3.0.7 build has no .go files (only specific targets are built),
    # so we need GUILE_AUTO_COMPILE=0 for the psyntax-pp.scm.gen step
    # which invokes meta/guile via uninstalled-env.
    export GUILE_AUTO_COMPILE=0
    cd ../guile-3.0.7
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true config.h
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true libguile/scmconfig.h
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true .version
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true -C lib all
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true -C meta all
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true -C libguile all
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true -C module ice-9/psyntax-pp.scm.gen
    unset GUILE_AUTO_COMPILE

    # Build and install guile-3.0.9
    cp -f module/ice-9/psyntax-pp.scm ../guile-3.0.9/module/ice-9/
    cd ../guile-3.0.9

    # Skip guile-procedures doc generation (it requires texinfo and rnrs
    # modules which we removed from compilation).
    ${gnused}/bin/sed -i 's/^all-local:.*/all-local:/' libguile/Makefile
    ${gnused}/bin/sed -i 's/^schemelib_DATA = .*/schemelib_DATA =/' Makefile

    # Skip stage1 and stage2: a single stage0 (-O1) compilation is enough
    # for the bootstrap. The three-stage build exists to verify compiler
    # self-consistency (like GCC bootstrap), which we don't need.
    ${gnused}/bin/sed -i '/^\tstage1/d;/^\tstage2/d' Makefile

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash MAKEINFO=true
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true

    # Install stage0's .go files (normally stage2 does this via nobase_ccache_DATA)
    (
      cd stage0
      ${findutils}/bin/find . -name '*.go' | while read -r f; do
        dir="''${out}/lib/guile/3.0/ccache/$(dirname "$f")"
        mkdir -p "$dir"
        cp "$f" "$dir/"
      done
    )
  ''
