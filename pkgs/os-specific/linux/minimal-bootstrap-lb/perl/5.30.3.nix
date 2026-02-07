{
  lib,
  fetchurl,
  bash,
  coreutils,
  cc,
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
  bison,
  oldPerl,
  dist,
  perlDevelTokenizerC,
  zlib,
}:
let
  pname = "perl";
  version = "5.30.3";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl-${version}.tar.xz";
    hash = "sha256-aWdZXy4/OpRUTDUVL5ol4MuOokrkX0vxiC8uM/SkAPQ=";
  };

  metaconfigSrc = fetchurl {
    url = "https://github.com/Perl/metaconfig/archive/5.30.3.tar.gz";
    hash = "sha256-XPmcUbvslRkuG5seDY9i2UE8q/ZND0vghFwfqzxMHJw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
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
      bison
      oldPerl
      dist
      perlDevelTokenizerC
      zlib
    ];

    meta = {
      description = "Practical Extraction and Report Language";
      homepage = "https://www.perl.org/";
      license = lib.licenses.artistic1;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "perl";
    };
  }
  ''
    # Unpack
    cp ${src} perl.tar.xz
    ${xz}/bin/xz -d -f perl.tar.xz
    ${gnutar}/bin/tar xf perl.tar
    rm perl.tar

    cp ${metaconfigSrc} metaconfig.tar.gz
    ${gzip}/bin/gzip -d -f metaconfig.tar.gz
    ${gnutar}/bin/tar xf metaconfig.tar
    rm metaconfig.tar

    ${gnupatch}/bin/patch -Np0 -i ${./5.30.3/patches/PPPort-pm-reproducible.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.30.3/patches/reproducible-mktables.patch}

    cd perl-${version}
    ${findutils}/bin/find . -type f -name "*.SH" -exec \
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" {} +
    ${findutils}/bin/find . -type f -name "*.SH" -exec chmod 755 {} +
    if [ -f Configure ]; then
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" Configure
      chmod 755 Configure
    fi
    ${findutils}/bin/find . -type f -name "*.sh" -exec \
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" {} +
    ${findutils}/bin/find . -type f -name "*.sh" -exec chmod 755 {} +
    if [ -f hints/linux.sh ]; then
      ${gnused}/bin/sed -i "s|/bin/sh -c exit|${bash}/bin/bash -c exit|" hints/linux.sh
    fi
    cp ${./5.30.3/files/config.over} config.over

        tokenizerPath="${perlDevelTokenizerC}/lib/perl5/$(${oldPerl}/bin/perl -v | ${gnused}/bin/sed -n -re 's/.*[ (]v([0-9\.]*)[ )].*/\1/p')"

    # Prepare
    chmod 644 cpan/Compress-Raw-Zlib/config.in
    ${gnused}/bin/sed "s:%LIBDIR%:${zlib}/lib:" ${./5.30.3/files/Compress-Raw-Zlib_config.in} \
      | ${gnused}/bin/sed "s:/usr/include:${zlib}/include:" \
      > cpan/Compress-Raw-Zlib/config.in

    rm Porting/Glossary dist/Devel-PPPort/parts/apidoc.fnc \
      Configure config_h.SH cpan/Win32API-File/cFile.pc \
      cpan/Sys-Syslog/win32/Win32.pm dist/ExtUtils-CBuilder/Makefile.PL \
      cpan/Test-Simple/lib/Test2/Util/HashBase.pm
    rm win32/perlexe.ico
    rm -r cpan/Compress-Raw-Zlib/zlib-src

    rm cpan/Unicode-Collate/Collate/keys.txt dist/Devel-PPPort/t/*.t

    rm lib/warnings.pm warnings.h regnodes.h reentr.h reentr.c overload.h \
      opcode.h opnames.h pp_proto.h keywords.h embed.h embedvar.h \
      perlapi.{c,h} proto.h lib/overload/numbers.pm regcharclass.h \
      perly.{tab,h,act} mg_{raw.h,vtable.h} keywords.c l1_char_class_tab.h \
      lib/feature.pm lib/B/Op_private.pm miniperlmain.c unicode_constants.h \
      charclass_invlists.h ebcdic_tables.h mg_names.inc overload.inc \
      packsizetables.inc uni_keywords.h
    touch lib/unicore/mktables.lst

    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen_perly.pl -b ${bison}/bin/bison-2.3
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/keywords.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/mk_PL_charclass.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/regcharclass.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/genpacksizetables.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/ebcdic.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/miniperlmain.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/unicode_constants.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl lib/unicore/mktables -C lib/unicore -P pod -maketest -makelist -p
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/mk_invlists.pl

    ${gnused}/bin/sed -i "s|^#! */bin/sh$|#! ${bash}/bin/bash|" ../metaconfig*/U/modified/Head.U
    ${gnused}/bin/sed -i "s|newsh=/bin/sh|newsh=${bash}/bin/bash|" ../metaconfig*/U/modified/Head.U
    ${gnused}/bin/sed -i "s|xxx='/bin/sh'|xxx='${bash}/bin/bash'|" ../metaconfig*/U/modified/sh.U

    mconfDir="$(echo ../metaconfig*)"
    ln -s "''${mconfDir}"/.package .
    ln -s "''${mconfDir}"/U .
    metaconfig -L ${dist}/lib/perl5/5.6.2 -m

    ln -s ../perl-* "''${mconfDir}"/perl
    ${oldPerl}/bin/perl "''${mconfDir}"/U/mkglossary > Porting/Glossary

    ${bash}/bin/bash dist/Devel-PPPort/devel/mkapidoc.sh . \
      dist/Devel-PPPort/parts/apidoc.fnc \
      dist/Devel-PPPort/parts/embed.fnc
    ${gnused}/bin/sed -i \
      's@my \$pwd = cwd() || die "Can.t figure out your cwd!";@my \$pwd = cwd(); if (!defined \$pwd) { chomp(\$pwd = `${coreutils}/bin/pwd`); }@' \
      cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker.pm
    ${gnused}/bin/sed -i "s#/usr/include/errno.h#${musl}/include/bits/errno.h#" ext/Errno/Errno_pm.PL
    ${gnused}/bin/sed -i "s#split / / => \$Config{locincpth}#\"${musl}/include\", split / / => \$Config{locincpth}#" ext/Errno/Errno_pm.PL

    while read -r line; do
      f="$(echo "''${line}" | ${coreutils}/bin/cut -d' ' -f1)"
      if [ -e "''${f}" ]; then
        echo "''${line}"
      fi
    done < MANIFEST > MANIFEST.new
    mv MANIFEST.new MANIFEST

    # Configure
    ./Configure -des \
      -Dprefix=''${out} \
      -Dcc=cc \
      -Dusedl=false \
      -Ddate=':' \
      -Dccflags='-DPERL_BUILD_DATE="null"' \
      -Darchname="i686-linux" \
      -Dmyhostname="(none)" \
      -Dmaildomain="(none)"

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out}

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
    rm -f ''${out}/*.0
  ''
