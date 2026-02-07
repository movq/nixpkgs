{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnumake,
  gnupatch,
  gnutar,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
}:
let
  pname = "libtool";
  version = "2.2.4";

  src = fetchurl {
    url = "mirror://gnu/libtool/libtool-${version}.tar.lzma";
    hash = "sha256-2Bg5+k1Wbb73wob9yptDDTUwmD//bTifrA8IuvJ+TDo=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      tinycc.compiler
      gnumake
      gnupatch
      gnutar
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
    ];

    meta = {
      description = "GNU Libtool";
      homepage = "https://www.gnu.org/software/libtool/";
      license = [ lib.licenses.gpl2Plus lib.licenses.lgpl21Plus ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "libtool";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -

    ${gnupatch}/bin/patch -Np0 -i ${./patches/archive-objs-order.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./patches/hostname.patch}

    cd libtool-${version}

    # Replace /bin/sh with store path to bash
    ${gnused}/bin/sed -i "s|#! /bin/sh|#! ${bash}/bin/bash|" libtoolize.m4sh
    ${gnused}/bin/sed -i "s|/bin/sh|${bash}/bin/bash|g" bootstrap
    chmod +x bootstrap libtoolize.m4sh

    # Prepare
    rm -f libtoolize.in
    rm -f configure
    rm -f libltdl/config/ltmain.sh libtool libltdl/m4/ltversion.m4
    rm -f doc/*.info
    rm -f tests/testsuite tests/defs.in tests/package.m4

    shopt -s nullglob
    for d in tests/*/configure tests/*/*/configure tests/*/*/*/configure tests/*/*/*/*/configure; do
      rm -r "$(dirname "''${d}")"
    done
    shopt -u nullglob

    AUTOMAKE=automake-1.10 \
      ACLOCAL=aclocal-1.10 \
      AUTOM4TE=autom4te-2.61 \
      AUTOCONF=autoconf-2.61 \
      AUTOHEADER=autoheader-2.61 \
      AUTORECONF=autoreconf-2.61 \
      ./bootstrap

    mkdir bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    cat > tcc-bootstrap <<EOS
#!${bash}/bin/bash
exec ${tinycc.compiler}/bin/tcc -B "''${PWD}/bootstrap-lib" "\$@"
EOS
    chmod 555 tcc-bootstrap
    ln -s tcc-bootstrap ld
    export PATH="''${PWD}:$PATH"

    ccWrapper="''${PWD}/tcc-bootstrap"

    # Configure
      LD="''${ccWrapper}" \
      CC="''${ccWrapper}" \
      AR=true \
      RANLIB=true \
      ./configure \
        --prefix=''${out} \
        --libdir=''${out}/lib \
        --disable-shared \
        --disable-ltdl-install \
        --host=i386-unknown-linux \
        --target=i386-unknown-linux \
        --build=i386-unknown-linux \
        ac_path_EGREP="egrep" \
        ac_path_FGREP="fgrep" \
        ac_path_GREP="grep" \
        ac_path_SED="sed"

    # Build
    AUTOM4TE=autom4te-2.61 ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true

    ${gnused}/bin/sed -i \
      -e "s/{EGREP=.*/{EGREP='egrep'}/" \
      -e "s/{FGREP=.*/{FREGP='fgrep'}/" \
      -e "s/{GREP=.*/{GREP='grep'}/" \
      -e "s/{SED=.*/{SED='sed'}/" \
      ''${out}/bin/libtool
  ''
