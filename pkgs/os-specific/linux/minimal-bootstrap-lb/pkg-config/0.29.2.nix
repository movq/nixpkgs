{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  cc,
  binutils,
  gnumake,
  gnutar,
  gzip,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
}:
let
  pname = "pkg-config";
  version = "0.29.2";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://pkgconfig.freedesktop.org/releases/pkg-config-${version}.tar.gz";
    hash = "sha256-b8acAWiMlFilfrmhZkyaujcszaQgoCv0Qp/mEOfn1ZE=";
  };

  unicodeSources = [
    {
      name = "UnicodeData-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/UnicodeData.txt";
        hash = "sha256-iyzRgkdSeqCOwyDDNStqAbldYxmfILO1k+pdUhe90XA=";
      };
    }
    {
      name = "LineBreak-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/LineBreak.txt";
        hash = "sha256-Xi6wCbB4Vp55VHibLXtcAmsLQL5vuUAMbh7MfRP0oT8=";
      };
    }
    {
      name = "SpecialCasing-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/SpecialCasing.txt";
        hash = "sha256-cHIJpp1/dg48xGHOJteJ+D1vtpQzbIOxRlLNREE6ozQ=";
      };
    }
    {
      name = "CaseFolding-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/CaseFolding.txt";
        hash = "sha256-XL2a/d3ZH+5ThxybNqNImbClvN9FacoaPJjK4+w9YzM=";
      };
    }
    {
      name = "CompositionExclusions-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/CompositionExclusions.txt";
        hash = "sha256-Oz9QUb104h338rGyZOrUi+Ymze77BhwEznKAojWO//k=";
      };
    }
    {
      name = "Scripts-6.2.0.txt";
      src = fetchurl {
        url = "http://ftp.unicode.org/Public/6.2.0/ucd/Scripts.txt";
        hash = "sha256-TN62m2v+rRwXCoG1ROdIhUlXVJNxWrYyvXSSvJLEgj4=";
      };
    }
  ];
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      cc
      binutils
      gnumake
      gnutar
      gzip
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libtool
    ];

    meta = {
      description = "Manage compile and link flags for libraries";
      homepage = "https://www.freedesktop.org/wiki/Software/pkg-config/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "pkg-config";
    };
  }
  ''
    # Unpack
    cp ${src} pkg-config.tar.gz
    ${gzip}/bin/gzip -d -f pkg-config.tar.gz
    ${gnutar}/bin/tar xf pkg-config.tar
    rm pkg-config.tar
    cd pkg-config-${version}

    # Prepare
    rm glib/glib/gunidecomp.h glib/glib/gunibreak.h glib/glib/gscripttable.h \
      glib/glib/gunichartables.h

    pushd glib/glib
    mkdir unidata
    ${lib.concatMapStringsSep "\n" (f: "cp ${f.src} unidata/${f.name}") unicodeSources}
    perl gen-unicode-tables.pl -both 6.2.0 unidata
    perl gen-script-table.pl unidata/Scripts-6.2.0.txt > gscripttable.h
    popd

      rm -f configure
      ACLOCAL_PATH="${libtool}/share/aclocal" \
    AUTOMAKE=automake-1.15 \
      ACLOCAL=aclocal-1.15 \
      autoreconf-2.69 -fi

    # Configure
    CC=cc \
      ./configure \
        --prefix=''${out} \
        --build=${target} \
        --with-internal-glib

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES"

    # Install
    ${gnumake}/bin/make install
  ''
