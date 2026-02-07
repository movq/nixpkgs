{
  lib,
  fetchurl,
  bash,
  gnumake,
  gnutar,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  help2man,
}:
let
  pname = "autoconf";
  version = "2.64";

  src = fetchurl {
    url = "mirror://gnu/autoconf/autoconf-${version}.tar.xz";
    hash = "sha256-Mtl3ITMguK52xxF1MFMBGX8rDgTnLXBpS8PT4q5sckg=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gnumake
      gnutar
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      help2man
    ];

    meta = {
      description = "GNU Autoconf";
      homepage = "https://www.gnu.org/software/autoconf/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "autoconf";
    };
  }
  ''
    # Unpack
    unxz --file ${src} | ${gnutar}/bin/tar xf -
    cd autoconf-${version}

    # Replace /bin/sh with store path to bash
    ${gnused}/bin/sed -i \
      -e "s|@%:@! /bin/sh|@%:@! ${bash}/bin/bash|" \
      -e "s|/bin/sh}|${bash}/bin/bash}|" \
      lib/m4sugar/m4sh.m4 lib/autoconf/general.m4 lib/autotest/general.m4
    for wrapper in tests/wrappl.in tests/wrapsh.in tests/wrapper.in; do
      if [ -f "$wrapper" ]; then
        ${gnused}/bin/sed -i -e "s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$wrapper"
      fi
    done
    for script in build-aux/*; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    # GNUmakefile hardcodes SHELL=/bin/sh and takes precedence over Makefile
    rm -f GNUmakefile

    # Prepare
    rm -f doc/*.info
    rm -f man/*.1
    rm -f tests/*.at

      rm -f configure
      AUTOMAKE=automake-1.10 \
      ACLOCAL=aclocal-1.10 \
      AUTOM4TE=autom4te-2.61 \
      AUTOCONF=autoconf-2.61 \
      ${autoconf}/bin/autoreconf-2.61 -f

    shopt -s nullglob
    for file in */*/Makefile.in */Makefile.in Makefile.in; do
      ${gnused}/bin/sed -i '/^pkgdatadir/s:$:-@VERSION@:' "$file"
    done
    shopt -u nullglob

    # Configure
    ./configure --prefix=''${out} --program-suffix=-${version}

    # Build
    ${gnumake}/bin/make MAKEINFO=true

    # Install
    ${gnumake}/bin/make install MAKEINFO=true
    ln -s autoconf-${version} ''${out}/bin/autoconf
    ln -s autoheader-${version} ''${out}/bin/autoheader
    ln -s autom4te-${version} ''${out}/bin/autom4te
    ln -s autoreconf-${version} ''${out}/bin/autoreconf
  ''
