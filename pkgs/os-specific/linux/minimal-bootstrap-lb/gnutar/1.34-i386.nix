{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  coreutils5,
  cc,
  binutils,
  gnumake,
  gnutar,
  gzip,
  bzip2,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  bison,
}:
let
  pname = "tar";
  version = "1.34";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "http://mirrors.kernel.org/gnu/tar/tar-${version}.tar.xz";
    hash = "sha256-Y769JoecXh7qQ1Lw0DyZH5Zq6z3es8dEXJAlaNVBHSg=";
  };

  gnulibSrc = fetchurl {
    url = "https://github.com/coreutils/gnulib/archive/30820c.tar.gz";
    hash = "sha256-9VsMRxBhyRdsTzvEhoYfV6Y0jaDvH/yvq0w+bWXYsLw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      coreutils5
      cc
      binutils
      gnumake
      gnutar
      gzip
      bzip2
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      bison
    ];

    meta = {
      description = "GNU tar archiving program";
      homepage = "https://www.gnu.org/software/tar/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "tar";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -

    cp ${gnulibSrc} gnulib.tar.gz
    ${gzip}/bin/gzip -d -f gnulib.tar.gz
    ${gnutar}/bin/tar xf gnulib.tar
    rm gnulib.tar
    mv gnulib-* gnulib-30820c
    ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" gnulib-30820c/gnulib-tool
    chmod +x gnulib-30820c/gnulib-tool
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" gnulib-30820c/build-aux/po/Makefile.in.in

    cd tar-${version}

    # Prepare
    cp ${./import-gnulib.sh} import-gnulib.sh
    chmod 555 import-gnulib.sh
    ${bash}/bin/sh ./import-gnulib.sh
    ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" po/Makefile.in.in
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    rm gnu/parse-datetime.c gnu/parse-datetime-gen.h
    rm po/*.gmo
    rm doc/tar.info*
    rm tests/testsuite

      rm -f configure
      AUTOPOINT=true \
      AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    FORCE_UNSAFE_CONFIGURE=1 \
      CC=cc \
      ./configure \
        --prefix=''${out} \
        --disable-nls \
        --build=${target} \
        gl_cv_func_getcwd_path_max="no, but it is partly working"

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out} MAKEINFO=true

    # Install
    ${gnumake}/bin/make install PREFIX=''${out} MAKEINFO=true
  ''
