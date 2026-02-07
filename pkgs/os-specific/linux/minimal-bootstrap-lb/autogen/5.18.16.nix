{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  cc,
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
  guile,
  which,
}:
let
  pname = "autogen";
  version = "5.18.16";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  bootstrapSrc = fetchurl {
    url = "https://github.com/schierlm/gnu-autogen-bootstrapping/archive/refs/tags/autogen-${version}-v1.0.1.tar.gz";
    hash = "sha256-lTuhgLGKz/GIoKhwB3DHzy/JfhaDx7lpmlp0i1QszdU=";
  };

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/autogen/rel${version}/autogen-${version}.tar.xz";
    hash = "sha256-+KE0ZrSPqjupn+F6Bp5xyasAbZsc+r5pn4xgpH1btJo=";
  };

  srcSnapshot = fetchurl {
    url = "https://git.savannah.gnu.org/gitweb/?p=autogen.git;a=snapshot;h=v5.18.16;sf=tgz";
    hash = "sha256-jGp8myuOrntaPgx7KKk2tPUfKa0o9MYYHUtpDNIKG3c=";
    name = "autogen-v5.18.16.tar.gz";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/8f4538a5.tar.gz";
    hash = "sha256-rxTcOb9aMzLaEeVRvJfQLeFYZMnoaI8tcSD/yHxBSvI=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cc
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
      guile
      which
    ];

    meta = {
      description = "Automated text and program generation tool";
      homepage = "https://www.gnu.org/software/autogen/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "autogen";
    };
  }
  ''
    # Unpack
    cp ${bootstrapSrc} gnu-autogen-bootstrapping.tar.gz
    ${gzip}/bin/gzip -d -f gnu-autogen-bootstrapping.tar.gz
    ${gnutar}/bin/tar xf gnu-autogen-bootstrapping.tar
    rm gnu-autogen-bootstrapping.tar

    cp ${gnulibSrc} gnulib-8f4538a5.tar.gz
    ${gzip}/bin/gzip -d -f gnulib-8f4538a5.tar.gz
    mkdir -p gnulib-8f4538a5
    ${gnutar}/bin/tar xf gnulib-8f4538a5.tar --strip-components=1 -C gnulib-8f4538a5
    rm gnulib-8f4538a5.tar

    patch_shebangs() {
      local tree="$1"
      (
        cd "$tree"

        ${grep}/bin/grep -rl '^#! */bin/sh' . > sh-scripts.list || true
        while read -r script; do
          [ -n "''${script}" ] || continue
          ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/sh\\1|" "''${script}"
          chmod 755 "''${script}"
        done < sh-scripts.list
        rm -f sh-scripts.list

        ${grep}/bin/grep -rl '^#! */bin/bash' . > bash-scripts.list || true
        while read -r script; do
          [ -n "''${script}" ] || continue
          ${gnused}/bin/sed -i "1s|^#! */bin/bash\\(.*\\)$|#! ${bash}/bin/bash\\1|" "''${script}"
          chmod 755 "''${script}"
        done < bash-scripts.list
        rm -f bash-scripts.list

        ${grep}/bin/grep -rl '^#! */usr/bin/perl' . > perl-scripts.list || true
        while read -r script; do
          [ -n "''${script}" ] || continue
          ${gnused}/bin/sed -i "1s|^#! */usr/bin/perl\\(.*\\)$|#! ${perl}/bin/perl\\1|" "''${script}"
          chmod 755 "''${script}"
        done < perl-scripts.list
        rm -f perl-scripts.list
      )
    }

    patch_shebangs gnulib-8f4538a5

    cd gnu-autogen-bootstrapping-autogen-${version}-v1.0.1
    mkdir -p build
    cp ${src} build/autogen-${version}.tar.xz
    cp ${srcSnapshot} autogen-v5.18.16.tar.gz
    ${gzip}/bin/gzip -d -f autogen-v5.18.16.tar.gz
    mkdir -p build/src
    ${gnutar}/bin/tar xf autogen-v5.18.16.tar --strip-components=1 -C build/src
    rm autogen-v5.18.16.tar
    rm -f build/src/add-on/char-mapper/cm.tar

    export PATH="${binutils}/bin:$PATH"

    export PKG_CONFIG_PATH="${guile}/lib/pkgconfig"
    export FINALPREFIX="''${out}"
    export GUILE_STATIC="--static"
    export GNULIBDIR="''${PWD}/../gnulib-8f4538a5"
    export MAN_PAGE_DATE=1970-01-01
    export CC=cc
    export CFLAGS=""
    export CONFIGURE_FLAGS=""
    export VERBOSE=false
    export MAKEFLAGS="-j1"
    export ACLOCAL=aclocal-1.16
    export AUTOMAKE=automake-1.16
    ${gnused}/bin/sed -i "s@/bin/bash@${bash}/bin/bash@g" agBootstrap.c

    set +x
    rm -f configure
    SKIP_MAIN=1 . ./bootstrap_tarball.sh

    bootstrap_tpl_config() {
      echo "=== Bootstrapping tpl-config.tlib ==="

      export PATH="$PREFIX/bin:$PATH"

      rm -R build/tarball
      cp -ar build/autogen-${version} build/tarball
      mkdir -p build/stage1/lib/autogen
      cd build/tarball
      ${gnused}/bin/sed 's/@EGREP@/egrep/g;s/@GREP@/grep/g' \
        < autoopts/tpl/tpl-config-tlib.in \
        > "$PREFIX/lib/autogen/tpl-config.tlib"
      cp autoopts/tpl/*.lic "$PREFIX/lib/autogen"
      sed -i -e 's/aclocal/aclocal-1.16/' -e 's/automake/automake-1.16/' config/bootstrap
      SOURCE_DIR="$(pwd)" ${bash}/bin/bash ./config/bootstrap
      chmod 555 configure
      CONFIG_SHELL=${bash}/bin/bash SHELL=${bash}/bin/bash \
        ${bash}/bin/bash ./configure --prefix="$PREFIX" --disable-dependency-tracking ''${CONFIGURE_FLAGS}
      ${gnumake}/bin/make -j1 SHELL=${bash}/bin/bash shdefs
      cd autoopts
      ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash tpl-config-stamp
      cp tpl/tpl-config.tlib "$PREFIX/lib/autogen/tpl-config.tlib"
      cd ../../..
    }
    prepare_tarball
    ${gnupatch}/bin/patch -Np1 -i ${./5.18.16/gperf-3.3.patch} -d build/autogen-${version}
    patch_shebangs build/autogen-${version}
    ${gnused}/bin/sed -i \
      's@one_year_limit > ''${top_srcdir}/ChangeLog@one_year_limit > ''${top_srcdir}/ChangeLog || true@' \
      build/autogen-${version}/config/bootstrap.local
    ${gnused}/bin/sed -i \
      's@f=''\${f%/bin}@f=''\${f%/bin}/share@' \
      build/autogen-${version}/config/bootstrap.local
    ${gnused}/bin/sed -i \
      's@install_m4 pkg.m4@install_m4 pkg.m4 ${pkgConfig}/share@' \
      build/autogen-${version}/config/bootstrap.local
    ${gnused}/bin/sed -i \
      "/^dispatch()/,/^}/{s/ '&'//}" \
      build/autogen-${version}/agen5/mk-stamps.sh
    bootstrap_columns
    bootstrap_getdefs
    bootstrap_autogen

    bootstrap_tpl_config

    # Build stage2 autogen
    rm -R build/tarball
    cp -ar build/autogen-${version} build/tarball
    chmod -R u+w build/tarball
    cd build/tarball
    export PATH="''${PREFIX}/bin:$PATH"

    # These files do not respect MAN_PAGE_DATE.
    ${gnused}/bin/sed -i "s/+%Y/+1970/; s/%m/01/; s/%d'/01'/; s/%Y/2018/" autoopts/aoconf.tpl
    ${gnused}/bin/sed -i 's/%Y/2018/' autoopts/options_h.tpl

    sed -i -e 's/aclocal/aclocal-1.16/' -e 's/automake/automake-1.16/' config/bootstrap
    SOURCE_DIR="$PWD" ${bash}/bin/bash ./config/bootstrap
    chmod 555 configure

    CPPFLAGS=-D_LARGEFILE64_SOURCE=1 \
      CONFIG_SHELL=${bash}/bin/bash \
      SHELL=${bash}/bin/bash \
      CC=cc \
      CPP="cc -E" \
      ${bash}/bin/bash ./configure \
        --prefix="''${out}" \
        --libdir="''${out}/lib/${target}" \
        --disable-shared \
        --enable-timeout=15

    touch doc/agdoc.texi
    (
      cd agen5
      "''${PREFIX}/bin/getdefs" \
        output=functions.def \
        template=functions.tpl \
        srcfile \
        linenum \
        defs=macfunc \
        listattr=alias \
        $(${grep}/bin/grep -l '/\*=macfunc' *.c)
      "''${PREFIX}/bin/autogen" -L ../autoopts/tpl functions.def
      "''${PREFIX}/bin/autogen" -L ../autoopts/tpl guile-iface.def
    )
    touch agen5/autogen.1
    ${gnumake}/bin/make -j1 \
      SHELL=${bash}/bin/bash \
      CFLAGS="-Wno-error -Wno-format-contains-nul" \
      MAKEINFO=true

    # Remove embedded build path from generated man page.
    ${gawk}/bin/awk '{gsub("\\(/tmp/.*", "", $7); print}' agen5/autogen.1 > autogen.1
    mv autogen.1 agen5/autogen.1

    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" SHELL=${bash}/bin/bash install MAKEINFO=true
    rm "''${out}"/share/autogen/libopts-*.tar.gz
  ''
