{
  lib,
  fetchurl,
  bash,
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
  pname = "automake";
  version = "1.15.1";

  src = fetchurl {
    url = "mirror://gnu/automake/automake-${version}.tar.xz";
    hash = "sha256-r2ujkUIiBofFAPebSqLxgdmyTk+NjsSXzqS6JsZL7a8=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
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
      description = "GNU Automake";
      homepage = "https://www.gnu.org/software/automake/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "automake-1.15";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -

    ${gnupatch}/bin/patch -Np0 -i ${./patches/1.15.1/aclocal_glob.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./patches/1.15.1/bootstrap.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./patches/1.15.1/shellcheck-bypass.patch}

    cd automake-${version}

    # Prepare
    rm -f doc/amhello-1.0.tar.gz doc/automake-history.info doc/automake.info*

    ${grep}/bin/grep "DO NOT EDIT BY HAND" -r t -l | while read -r f; do
      rm -f "''${f}"
    done

    ${gnused}/bin/sed -i '/doc\/Makefile.inc/d' Makefile.am
    ${gnused}/bin/sed -i '/t\/Makefile.inc/d' Makefile.am

    rm -f configure

    for script in bootstrap lib/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done
    ${gnused}/bin/sed -i "s|BOOTSTRAP_SHELL=/bin/sh|BOOTSTRAP_SHELL=${bash}/bin/bash|" bootstrap
    chmod +x bootstrap

    AUTOCONF="autoconf-2.69 -f" \
      AUTOM4TE=autom4te-2.69 \
      ./bootstrap

    # Configure
    AUTORECONF=autoreconf-2.69 \
      AUTOM4TE=autom4te-2.69 \
      AUTOHEADER=autoheader-2.69 \
      AUTOCONF="autoconf-2.69 -f" \
      ./configure --prefix=''${out} --build=i686-pc-linux-gnu

    # Build
    AUTORECONF=autoreconf-2.69 \
      AUTOM4TE=autom4te-2.69 \
      AUTOHEADER=autoheader-2.69 \
      AUTOCONF="autoconf-2.69 -f" \
      ${gnumake}/bin/make -j1 MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    rm -f ''${out}/bin/automake ''${out}/bin/aclocal
  ''
