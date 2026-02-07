{
  lib,
  fetchurl,
  bash,
  gnutar,
  bzip2,
  gnused,
  grep,
  gawk,
  m4,
}:
let
  pname = "autoconf";
  version = "2.52";

  src = fetchurl {
    url = "mirror://gnu/autoconf/autoconf-${version}.tar.bz2";
    hash = "sha256-RoG8u5ySmMUG9kBafetixU/DsznTI5qPNqXfg9quyU8=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gnutar
      bzip2
      gnused
      m4
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        PATH="${gnused}/bin:${grep}/bin:${gawk}/bin:${m4}/bin:$PATH" \
          ${result}/bin/autoconf --version
        mkdir ''${out}
      '';

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
    cp ${src} autoconf.tar.bz2
    ${bzip2}/bin/bzip2 -d -f autoconf.tar.bz2
    ${gnutar}/bin/tar xf autoconf.tar
    rm autoconf.tar
    cd autoconf-${version}

    # Configure
    rm doc/*.info
    cp autoconf.in autoconf
    ${gnused}/bin/sed -i \
      -e "s# @SHELL@#${bash}/bin/sh#" \
      -e "s/@M4@/m4/" \
      -e "s/@AWK@/awk/" \
      -e "s/@PACKAGE_NAME@/Autoconf/" \
      -e "s/@VERSION@/${version}/" \
      -e "s#@datadir@#''${out}/share/autoconf-${version}#" \
      autoconf
    chmod +x autoconf

    # Replace /bin/sh with store path to bash
    ${gnused}/bin/sed -i \
      -e "s|@%:@! /bin/sh|@%:@! ${bash}/bin/bash|" \
      -e "s|/bin/sh}|${bash}/bin/bash}|" \
      acgeneral.m4

    # Build
    ${m4}/bin/m4 autoconf.m4 --freeze-state=autoconf.m4f

    # Install
    mkdir -p ''${out}/bin ''${out}/share/autoconf-${version}
    install -m 555 autoconf ''${out}/bin/autoconf-${version}
    cp -r -- *.m4* ''${out}/share/autoconf-${version}/
    ln -s autoconf-${version} ''${out}/bin/autoconf
  ''
