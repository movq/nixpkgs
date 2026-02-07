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
}:
let
  pname = "perl";
  version = "5.8.9";

  src = fetchurl {
    url = "https://www.cpan.org/src/5.0/perl-${version}.tar.bz2";
    hash = "sha256-EJf7zUjOzLK8c10RnJ2zmaAqirn33FPinkfmqNDXLnk=";
  };

  metaconfigSrc = fetchurl {
    url = "https://github.com/Perl/metaconfig/archive/40501436c87602cc17baae64ee6b3ca26d74e354.tar.gz";
    hash = "sha256-awyTfhqu9oSnsvDAib6ik8ep0lXWUT5RCFZ/TBDj9N0=";
  };

  digestShaSrc = fetchurl {
    url = "https://cpan.metacpan.org/authors/id/M/MS/MSHELOR/Digest-SHA-6.04.tar.gz";
    hash = "sha256-7pH499uJTufG7gA9qsEKmQVsSUimdO9GrNu2PIGkq+s=";
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

    cp ${digestShaSrc} digest-sha.tar.gz
    ${gzip}/bin/gzip -d -f digest-sha.tar.gz
    ${gnutar}/bin/tar xf digest-sha.tar
    rm digest-sha.tar

    ${gnupatch}/bin/patch -Np0 -i ${./5.8.9/patches/0001-Revert-Patch-Configure-doesn-t-pick-up-Hash-Util-Fie.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.8.9/patches/Sort-files-returned-from-all_files_in_dir-for-consis.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.8.9/patches/a2p-c-bison.patch}
    ${gnupatch}/bin/patch -Np0 -i ${./5.8.9/patches/encode-disable-recursive-subdirs.patch}

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
    cp ${./5.8.9/files/config.over} config.over
    ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" config.over
    chmod +x config.over

    bisonCmd="${bison}/bin/bison"
    if [ ! -x "''${bisonCmd}" ]; then
      bisonCmd="${bison}/bin/bison-2.3"
    fi

    # Prepare
    mv ../Digest-SHA-6.04 ext/Digest/SHA/

    rm Porting/Glossary lib/unicore/mktables.lst \
      ext/Sys/Syslog/win32/Win32.pm ext/Win32API/File/cFile.pc \
      ext/Devel/PPPort/parts/apidoc.fnc Configure config_h.SH \
      x2p/a2p.c
    rm ext/Devel/PPPort/t/*.t
    rm -r jpl

    ${gnused}/bin/sed -i '/yydestruct/d' perly.y
    rm -f perly.c perly.h
    PATH="${bison}/bin:${m4}/bin:$PATH" \
      M4="${m4}/bin/m4" \
      "''${bisonCmd}" -d perly.y
    ln -s perly.tab.h perly.h
    ln -s perly.tab.c perly.c

    tokenizerPath="${perlDevelTokenizerC}/lib/perl5/$(${oldPerl}/bin/perl -v | ${gnused}/bin/sed -n -re 's/.*[ (]v([0-9\.]*)[ )].*/\1/p')"

    ${gnused}/bin/sed '/The following code was generated/,$d' toke.c | head -n -1 > toke.c.new
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl perl_keyword.pl >> toke.c.new
    ${gnused}/bin/sed '1,/The following code was generated/d' toke.c | ${gnused}/bin/sed '1,/^}$/d' >> toke.c.new
    mv toke.c.new toke.c

    rm lib/warnings.pm warnings.h regnodes.h reentr.h reentr.c reentr.inc \
      overload.h overload.c opcode.h opnames.h pp_proto.h \
      pp.sym keywords.h embed.h embedvar.h global.sym perlapi.c perlapi.h \
      proto.h pod/perlintern.pod pod/perlapi.pod \
      pod/perlmodlib.pod ext/ByteLoader/byterun.{h,c} \
      ext/B/B/Asmdata.pm
    PERL5LIB="''${tokenizerPath}" ${oldPerl}/bin/perl regen.pl

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

    ${bash}/bin/bash ext/Devel/PPPort/devel/mkapidoc.sh . \
      ext/Devel/PPPort/parts/apidoc.fnc \
      ext/Devel/PPPort/parts/embed.fnc

    ${gnused}/bin/sed -i \
      's@my \$pwd = cwd() || die "Can.t figure out your cwd!";@my \$pwd = cwd(); if (!defined \$pwd) { chomp(\$pwd = `pwd`); }@' \
      lib/ExtUtils/MakeMaker.pm
    ${gnused}/bin/sed -i "s#/usr/include/errno.h#${musl}/include/bits/errno.h#" ext/Errno/Errno_pm.PL

    # Configure
    rm MANIFEST
    ./Configure -des \
      -Dprefix=''${out} \
      -Dcc=cc \
      -Dusedl=false \
      -Ddate=':' \
      -Dccflags="-U__DATE__ -U__TIME__" \
      -Darchname="i686-linux" \
      -Dmyhostname="(none)" \
      -Dmaildomain="(none)"

    # Build
    (
      cd x2p
      ${gnumake}/bin/make BYACC=yacc run_byacc
      ${bash}/bin/bash cflags.SH
    )
    ${gnumake}/bin/make -j $NIX_BUILD_CORES PREFIX=''${out}

    # Install
    ${gnumake}/bin/make install PREFIX=''${out}
    rm -f ''${out}/*.0
  ''
