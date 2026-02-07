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
  bzip2,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  bison,
  oyacc,
  oldPerl,
  dist,
  perlDevelTokenizerC,
  zlib,
}:
let
  pname = "perl";
  version = "5.17.4";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl-${version}.tar.bz2";
    hash = "sha256-QufrDXJqY0S8VBQL6KDjY2Mw4b576Hk+D7dPQVZmuVs=";
  };

  metaconfigSrc = fetchurl {
    url = "https://github.com/Perl/metaconfig/archive/79b14e84d83fb88c2b1a07e0dec3b62ccb9a388c.tar.gz";
    hash = "sha256-hX4pWj4/8xITObNI/SleA0Wc6Nw6OChw6U+YwtqZpXM=";
  };

  socketSrc = fetchurl {
    url = "https://cpan.metacpan.org/authors/id/P/PE/PEVANS/Socket-2.000.tar.gz";
    hash = "sha256-kesN+q/fCORQqgPNijKF1H+s/UMvdfgSpb2v2eRFKXs=";
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
      bzip2
      findutils
      gnused
      grep
      gawk
      m4
      bison
      oyacc
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
    cp ${src} perl.tar.bz2
    ${bzip2}/bin/bzip2 -d -f perl.tar.bz2
    ${gnutar}/bin/tar xf perl.tar
    rm perl.tar

    cp ${metaconfigSrc} metaconfig.tar.gz
    ${gzip}/bin/gzip -d -f metaconfig.tar.gz
    ${gnutar}/bin/tar xf metaconfig.tar
    rm metaconfig.tar

    cp ${socketSrc} socket.tar.gz
    ${gzip}/bin/gzip -d -f socket.tar.gz
    ${gnutar}/bin/tar xf socket.tar
    rm socket.tar

    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/0001-Revert-regen-regcharclass.pl-Generate-macros-for-X-p.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/0002-Revert-regexec.c-Use-new-macros-instead-of-swashes.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/0003-Revert-Use-macro-not-swash-for-utf8-quotemeta.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/0004-Rename-property-involved-in-X-matching-for-clarity.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/Sort-files-returned-from-all_files_in_dir-for-consis.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/a2p-c-bison.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/duplicate-invlists-defn.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.17.4/patches/reproducible-mktables.patch}

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
    cp ${./5.17.4/files/config.over} config.over
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" config.over
    chmod +x config.over

        tokenizerPath="${perlDevelTokenizerC}/lib/perl5/$(${oldPerl}/bin/perl -v | ${gnused}/bin/sed -n -re 's/.*[ (]v([0-9\.]*)[ )].*/\1/p')"

    # Prepare
    chmod 644 cpan/Compress-Raw-Zlib/config.in
    ${gnused}/bin/sed "s:%LIBDIR%:${zlib}/lib:" ${./5.17.4/files/Compress-Raw-Zlib_config.in} \
      | ${gnused}/bin/sed "s:/usr/include:${zlib}/include:" \
      > cpan/Compress-Raw-Zlib/config.in

    rm -r cpan/Socket
    mv ../Socket-2.000 cpan/Socket

    rm Porting/Glossary cpan/Devel-PPPort/parts/apidoc.fnc \
      Configure config_h.SH x2p/a2p.c cpan/Win32API-File/cFile.pc \
      cpan/Sys-Syslog/win32/Win32.pm utils/Makefile
    rm win32/perlexe.ico
    rm -r cpan/Compress-Raw-Zlib/zlib-src
    rm cpan/Devel-PPPort/t/*.t cpan/Unicode-Collate/Collate/keys.txt

    rm lib/warnings.pm warnings.h regnodes.h reentr.h reentr.c \
      overload.h overload.c opcode.h opnames.h pp_proto.h \
      keywords.h embed.h embedvar.h perlapi.c perlapi.h \
      proto.h lib/overload/numbers.pm regcharclass.h perly.{tab,h,act} \
      mg_{raw.h,vtable.h,names.c} keywords.c l1_char_class_tab.h \
      lib/feature.pm unicode_constants.h charclass_invlists.h

    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen_perly.pl -b ${bison}/bin/bison-2.3
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/keywords.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/mk_PL_charclass.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/mk_invlists.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/unicode_constants.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen/regcharclass.pl

    ${gnused}/bin/sed -i "s|^#! */bin/sh$|#! ${bash}/bin/bash|" ../metaconfig*/U/modified/Head.U
    ${gnused}/bin/sed -i "s|newsh=/bin/sh|newsh=${bash}/bin/bash|" ../metaconfig*/U/modified/Head.U
    ${gnused}/bin/sed -i "s|xxx='/bin/sh'|xxx='${bash}/bin/bash'|" ../metaconfig*/U/modified/sh.U

    ln -s ../metaconfig*/.package .
    ln -s ../metaconfig*/U .
    metaconfig -L ${dist}/lib/perl5/5.6.2 -m

    (
      cd Porting
      ln -s ${dist}/lib/perl5/5.6.2/U .
      makegloss
    )

    ${bash}/bin/bash cpan/Devel-PPPort/devel/mkapidoc.sh . \
      cpan/Devel-PPPort/parts/apidoc.fnc \
      cpan/Devel-PPPort/parts/embed.fnc

    ${gnused}/bin/sed -i \
      's@my \$pwd = cwd() || die "Can.t figure out your cwd!";@my \$pwd = cwd(); if (!defined \$pwd) { chomp(\$pwd = `pwd`); }@' \
      cpan/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker.pm
    ${gnused}/bin/sed -i "s#'/bin/pwd',#'${coreutils}/bin/pwd',#" dist/Cwd/Cwd.pm
    ${gnused}/bin/sed -i "s#/usr/include/errno.h#${musl}/include/bits/errno.h#" ext/Errno/Errno_pm.PL

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
      -Dusedevel \
      -Uversiononly \
      -Dccflags="-U__DATE__ -U__TIME__" \
      -Darchname="i686-linux" \
      -Dmyhostname="(none)" \
      -Dmaildomain="(none)"

    (
      cd x2p
      ./Makefile.SH
      ${gnumake}/bin/make depend
    )
    (
      cd utils
      ${bash}/bin/bash Makefile.SH
    )

    # Build
    (
      cd x2p
      ${gnumake}/bin/make BYACC=yacc run_byacc
      ${bash}/bin/bash cflags.SH
    )
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out}

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
    rm -f ''${out}/*.0
  ''
