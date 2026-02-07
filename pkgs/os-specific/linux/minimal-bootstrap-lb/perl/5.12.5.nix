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
  version = "5.12.5";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl-${version}.tar.bz2";
    hash = "sha256-EHSUF/0wEKrjIKNBga1M1qSFXB/GNAO4f6TWMLGOlmw=";
  };

  metaconfigSrc = fetchurl {
    url = "https://github.com/Perl/metaconfig/archive/7ae9aa2926eed6b1f0b68b0e61c80a0f39b14a25.tar.gz";
    hash = "sha256-CKEOJmkn685/6M0kEiudEnShc8VxcEFFRWM+vr131lw=";
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

    ${gnupatch}/bin/patch -Np0 -i ${./5.12.5/patches/Sort-files-returned-from-all_files_in_dir-for-consis.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.12.5/patches/a2p-c-bison.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.12.5/patches/encode-disable-recursive-subdirs.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.12.5/patches/make-ext-handle-subdirs.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.12.5/patches/reproducible-mktables.patch}

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
    ${gnused}/bin/sed -i "s#'/bin/pwd',#'${coreutils}/bin/pwd',#" cpan/Cwd/Cwd.pm

    tokenizerPath="${perlDevelTokenizerC}/lib/perl5/$(${oldPerl}/bin/perl -v | ${gnused}/bin/sed -n -re 's/.*[ (]v([0-9\.]*)[ )].*/\1/p')"

    # Prepare
    chmod 644 cpan/Compress-Raw-Zlib/config.in
    ${gnused}/bin/sed "s:%LIBDIR%:${zlib}/lib:" ${./5.12.5/files/Compress-Raw-Zlib_config.in} \
      | ${gnused}/bin/sed "s:/usr/include:${zlib}/include:" \
      > cpan/Compress-Raw-Zlib/config.in

    rm Porting/Glossary cpan/Devel-PPPort/parts/apidoc.fnc \
      Configure config_h.SH x2p/a2p.c cpan/Win32API-File/cFile.pc \
      cpan/Sys-Syslog/win32/Win32.pm
    rm win32/perlexe.ico
    rm -r cpan/Compress-Raw-Zlib/zlib-src
    rm cpan/Devel-PPPort/t/*.t cpan/Unicode-Collate/Collate/keys.txt

    ${gnused}/bin/sed '/The following code was generated/,$d' toke.c | head -n -1 > toke.c.new
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl perl_keyword.pl >> toke.c.new
    ${gnused}/bin/sed '1,/The following code was generated/d' toke.c | ${gnused}/bin/sed '1,/^}$/d' >> toke.c.new
    mv toke.c.new toke.c

    rm lib/warnings.pm warnings.h regnodes.h reentr.h reentr.c pp.sym \
      overload.h overload.c opcode.h opnames.h pp_proto.h \
      keywords.h embed.h embedvar.h global.sym perlapi.c perlapi.h \
      proto.h lib/overload/numbers.pm regcharclass.h perly.{tab,h,act}
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen.pl
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen_perly.pl -b ${bison}/bin/bison-2.3
    touch regcharclass.h
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl Porting/regcharclass.pl

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
      -Dccflags="-U__DATE__ -U__TIME__" \
      -Darchname="i686-linux" \
      -Dmyhostname="(none)" \
      -Dmaildomain="(none)"

    (
      cd x2p
      ./Makefile.SH
      ${gnumake}/bin/make depend
      ${gnumake}/bin/make BYACC=yacc run_byacc
      ${bash}/bin/bash cflags.SH
    )
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" lib/auto/Cwd/Cwd.a
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" PREFIX=''${out}

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install.perl PREFIX=''${out}
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install.man PREFIX=''${out}
    rm -f ''${out}/*.0
  ''
