{
  lib,
  config,
  buildPlatform,
  hostPlatform,
  fetchurl,
  checkMeta,
}:

let
  # Early bootstrap runs as i386
  i386Platform = lib.systems.elaborate "i686-linux";
in

lib.makeScope
  # Prevent using top-level attrs to protect against introducing dependency on
  # non-bootstrap packages by mistake. Any top-level inputs must be explicitly
  # declared here.
  (
    extra:
    lib.callPackageWith (
      {
        inherit
          lib
          config
          buildPlatform
          hostPlatform
          fetchurl
          checkMeta
          ;
      }
      // extra
    )
  )
  (
    self: with self; let
      x86_64Base = {
        inherit lib config fetchurl checkMeta;
        buildPlatform = i386Platform;
        hostPlatform = hostPlatform;
        bash = i386Bootstrap.bash-5_2_15;
        coreutils = i386Bootstrap.coreutils-9_4;
        diffutils = i386Bootstrap.diffutils-2_7;
        buildGcc = i386Bootstrap.gcc-15_2_0;
        buildMusl = i386Bootstrap.musl-1_2_5-rebuild;
        crossBinutils = i386Bootstrap.cross-binutils-2_41;
        crossMusl = musl-1_2_5;
        gnumake = i386Bootstrap.gnumake-4_2_1;
        gnupatch = i386Bootstrap.gnupatch-2_7_6;
        gnutar = i386Bootstrap.gnutar-1_34;
        gzip = i386Bootstrap.gzip-mes;
        xz = i386Bootstrap.xz-5_6_4;
        findutils = i386Bootstrap.findutils-4_2_33;
        gnused = i386Bootstrap.gnused-4_8;
        grep = i386Bootstrap.grep-3_7;
        gawk = i386Bootstrap.gawk-3_0_4;
        m4 = i386Bootstrap.m4-1_4_7;
        perl = i386Bootstrap.perl-5_42_0;
        bzip2 = i386Bootstrap.bzip2-1_0_8;
        autoconf = i386Bootstrap.autoconf-2_69-rebuild;
        automake = i386Bootstrap.automake-1_15_1;
        autoconfArchive = i386Bootstrap.autoconf-archive-2021_02_19;
        libtool = i386Bootstrap.libtool-2_4_7;
        flex = i386Bootstrap.flex-2_5_33;
        bison = i386Bootstrap.bison-3_8_2;
        help2man = i386Bootstrap.help2man-1_36_4;
        pkgConfig = i386Bootstrap.pkg-config-0_29_2;
        gperf = i386Bootstrap.gperf-3_3;
        texinfo = i386Bootstrap.texinfo-6_7;
        autogen = i386Bootstrap.autogen-5_18_16;
        python = i386Bootstrap.python-3_11_1;
      };

      x86_64BaseGnu = x86_64Base // {
        crossBinutils = i386Bootstrap.cross-binutils-2_41-gnu;
      };

      callCrossSimple = lib.callPackageWith (x86_64Base // {
        crossGcc = i386Bootstrap.cross-gcc-15_2_0;
      });

      callCrossSimpleGnu = lib.callPackageWith (x86_64BaseGnu // {
        crossGcc = i386Bootstrap.cross-gcc-15_2_0-gnu;
      });

      callCrossFull = lib.callPackageWith (x86_64Base // {
        crossGcc = cross-gcc-full-15_2_0;
      });

      callCrossFullGnu = lib.callPackageWith (x86_64BaseGnu // {
        crossGcc = cross-gcc-full-15_2_0-gnu;
      });
    in {

      i386Bootstrap = lib.makeScope
        (extra: lib.callPackageWith ({
          inherit lib config fetchurl checkMeta;
          buildPlatform = i386Platform;
          hostPlatform = i386Platform;
        } // extra))
        (i386self: with i386self; let

          inherit (import ./wrappers.nix { inherit lib; }) wrapGcc wrapTcc;

          # Base arguments shared by all stage callPackage functions
          commonBase = {
            inherit lib config fetchurl checkMeta;
            buildPlatform = i386Platform;
            hostPlatform = i386Platform;
            inherit derivationWithMeta writeTextFile writeText mescc-tools-extra;
          };

          # Stage: tinycc-musl-v2 + musl-v3 + bash-mes
          # Used for most packages between tinycc-musl-v2 and gcc-4.0.4
          callTccMusl = lib.callPackageWith (commonBase // {
            bash = bash-mes;
            cc = cc-tcc;
            tinycc = tinycc-musl-v2;
            musl = musl-v3;
            gnumake = gnumake-with-sh-mes;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-4_0_9;
            grep = grep-2_4;
            bzip2 = bzip2-1_0_8;
            coreutils = coreutils-6_10;
            coreutils5 = coreutils-5_0;
            diffutils = diffutils-2_7;
            m4 = m4-1_4_7;
            gawk = gawk-3_0_4;
            perl = perl-5_6_2;
            oyacc = oyacc-mes;
            flex = flex-2_6_4;
            bison = bison-3_4_1;
            autoconf = autoconf-2_69;
            automake = automake-1_15_1;
            help2man = help2man-1_36_4;
            libtool = libtool-2_2_4;
            findutils = findutils-4_2_33;
          });

          # Stage: gcc-4.0.4-rebuild + musl-1.2.5 + binutils-2.30
          # Defaults to the "late" sub-stage (bash-5_2_15, gnumake-4_2_1, coreutils-9_4)
          callGcc404 = lib.callPackageWith (commonBase // {
            bash = bash-5_2_15;
            cc = cc-gcc404;
            gcc = gcc-4_0_4-rebuild;
            musl = musl-1_2_5;
            binutils = binutils-2_30;
            gnumake = gnumake-4_2_1;
            coreutils = coreutils-9_4;
            coreutils5 = coreutils-5_0;
            diffutils = diffutils-2_7;
            gnutar = gnutar-1_34;
            gzip = gzip-mes;
            gnupatch = gnupatch-mes;
            xz = xz-5_6_4;
            findutils = findutils-4_2_33;
            gnused = gnused-4_0_9;
            grep = grep-2_4;
            gawk = gawk-3_0_4;
            m4 = m4-1_4_7;
            perl = perl-5_6_2;
            oyacc = oyacc-mes;
            bzip2 = bzip2-1_0_8;
            autoconf = autoconf-2_69;
            automake = automake-1_15_1;
            autoconfArchive = autoconf-archive-2021_02_19;
            help2man = help2man-1_36_4;
            libtool = libtool-2_4_7;
            flex = flex-2_6_4;
            bison = bison-3_4_1;
            dist = dist-3_5;
            zlib = zlib-1_3_1;
            gmp = gmp-6_2_1;
            mpfr = mpfr-4_1_0;
            mpc = mpc-1_2_1;
          });

          # Stage: gcc-4.7.4 + musl-1.2.5-rebuild + binutils-2.41
          callGcc474 = lib.callPackageWith (commonBase // {
            bash = bash-5_2_15;
            cc = cc-gcc474;
            cxx = cc-gcc474-cxx;
            gcc = gcc-4_7_4;
            musl = musl-1_2_5-rebuild;
            binutils = binutils-2_41;
            gnumake = gnumake-4_2_1;
            coreutils = coreutils-9_4;
            coreutils5 = coreutils-5_0;
            diffutils = diffutils-2_7;
            gnutar = gnutar-1_34;
            gzip = gzip-mes;
            gnupatch = gnupatch-2_7_6;
            xz = xz-5_6_4;
            findutils = findutils-4_2_33;
            gnused = gnused-4_0_9;
            grep = grep-2_4;
            gawk = gawk-3_0_4;
            m4 = m4-1_4_7;
            perl = perl-5_12_5;
            oyacc = oyacc-mes;
            bzip2 = bzip2-1_0_8;
            autoconf = autoconf-2_69-rebuild;
            autoconf269 = autoconf-2_69-rebuild;
            automake = automake-1_15_1;
            autoconfArchive = autoconf-archive-2021_02_19;
            help2man = help2man-1_36_4;
            libtool = libtool-2_4_7;
            pkgConfig = pkg-config-0_29_2;
            flex = flex-2_5_33;
            bison = bison-3_4_1;
            dist = dist-3_5;
            zlib = zlib-1_3_1;
            gmp = gmp-6_2_1;
            mpfr = mpfr-4_1_0;
            mpc = mpc-1_2_1;
            gperf = gperf-3_3;
            texinfo = texinfo-6_7;
            autogen = autogen-5_18_16;
            python = python-3_11_1;
            libffi = libffi-3_3;
          });

        in {
          stage0-posix = i386self.callPackage ./stage0-posix { };

          inherit (i386self.stage0-posix)
            kaem
            m2libc
            mescc-tools
            mescc-tools-extra
            ;

          inherit (i386self.callPackage ./utils.nix { }) derivationWithMeta writeTextFile writeText;

          ln-boot = i386self.callPackage ./ln-boot { };

          mes = i386self.callPackage ./mes { };
          mes-libc = i386self.callPackage ./mes/libc.nix { };

          # Empty mes/config.h to avoid typedef conflicts
          mes-config-h-override = kaem.runCommand "mes-config-h-override" { } ''
            mkdir -p ''${out}/mes
            catm ''${out}/mes/config.h
          '';

          tinycc-bootstrappable = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/bootstrappable.nix { });
          tinycc-mes = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/mes.nix { });

          tinycc-0_9_27-mes = i386self.callPackage ./tinycc/0.9.27.nix {
            inherit mes-config-h-override;
          };

          gnumake-mes = i386self.callPackage ./gnumake/mes.nix { tinycc = tinycc-0_9_27-mes; };

          gnupatch-mes = i386self.callPackage ./gnupatch/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
          };

          gzip-mes = i386self.callPackage ./gzip/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
          };

          gnutar-mes = i386self.callPackage ./gnutar/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gzip = gzip-mes;
          };

          gnused-mes = i386self.callPackage ./gnused/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
          };

          bzip2-mes = i386self.callPackage ./bzip2/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
          };

          coreutils-mes = i386self.callPackage ./coreutils/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-mes;
            gnutar = gnutar-mes;
            bzip2 = bzip2-mes;
          };

          oyacc-mes = i386self.callPackage ./oyacc/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            coreutils = coreutils-mes;
          };

          bash-mes = i386self.callPackage ./bash/mes.nix {
            tinycc = tinycc-0_9_27-mes;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            coreutils = coreutils-mes;
            oyacc = oyacc-mes;
          };

          gnumake-with-sh-mes = i386self.callPackage ./gnumake/mes-with-sh.nix {
            bash = bash-mes;
            tinycc = tinycc-0_9_27-mes;
          };

          tinycc-for-musl-mes = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/for-musl.nix {
            tinycc = tinycc-bootstrappable;
            gnupatch = gnupatch-mes;
          });

          musl = i386self.callPackage ./musl/tcc.nix {
            bash = bash-mes;
            tinycc = tinycc-for-musl-mes;
            gnumake = gnumake-with-sh-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-mes;
          };

          tinycc-musl = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/musl.nix {
            bash = bash-mes;
            tinycc = tinycc-bootstrappable;
            musl = musl;
            gnupatch = gnupatch-mes;
          });

          musl-tcc = i386self.callPackage ./musl/tcc-musl.nix {
            bash = bash-mes;
            tinycc = tinycc-musl;
            gnumake = gnumake-with-sh-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-mes;
          };

          tinycc-musl-v2 = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/musl-v2.nix {
            bash = bash-mes;
            tinycc = tinycc-musl;
            musl = musl-tcc;
            gnupatch = gnupatch-mes;
          });

          # -- TCC-musl stage packages --

          grep-2_4 = callTccMusl ./grep/2.4.nix {};

          musl-v3 = callTccMusl ./musl/v3.nix { gnused = gnused-mes; };

          cc-tcc = wrapTcc { bash = bash-mes; tinycc = tinycc-musl-v2; musl = musl-v3; };

          gnused-4_0_9 = callTccMusl ./gnused/musl-v3.nix {};
          bzip2-1_0_8 = callTccMusl ./bzip2/musl-v3.nix {};
          m4-1_4_7 = callTccMusl ./m4/1.4.7.nix {};
          heirloom-devtools-070527 = callTccMusl ./heirloom-devtools/070527.nix {};
          flex-2_5_11 = callTccMusl ./flex/2.5.11.nix { heirloomDevtools = heirloom-devtools-070527; };
          flex-2_6_4 = callTccMusl ./flex/2.6.4.nix { oldFlex = flex-2_5_11; };
          bison-3_4_1 = callTccMusl ./bison/3.4.1.nix {};
          diffutils-2_7 = callTccMusl ./diffutils/2.7-i386.nix {};
          coreutils-5_0 = callTccMusl ./coreutils/5.0.nix {};
          coreutils-6_10 = callTccMusl ./coreutils/6.10.nix {};
          gawk-3_0_4 = callTccMusl ./gawk/3.0.4-i386.nix {};

          perl-5_000 = callTccMusl ./perl/5.000.nix {};
          perl-5_003 = callTccMusl ./perl/5.003.nix { oldPerl = perl-5_000; };
          perl-5_004_05 = callTccMusl ./perl/5.004_05.nix { oldPerl = perl-5_003; };
          perl-5_005_03 = callTccMusl ./perl/5.005_03.nix { oldPerl = perl-5_004_05; };
          perl-5_6_2 = callTccMusl ./perl/5.6.2.nix { oldPerl = perl-5_005_03; };

          autoconf-2_52 = callTccMusl ./autoconf/2.52.nix {};
          automake-1_6_3 = callTccMusl ./automake/1.6.3.nix { autoconf = autoconf-2_52; };
          autoconf-2_53 = callTccMusl ./autoconf/2.53.nix { autoconf = autoconf-2_52; automake = automake-1_6_3; };
          automake-1_7 = callTccMusl ./automake/1.7.nix { autoconf = autoconf-2_53; automake = automake-1_6_3; };
          autoconf-2_54 = callTccMusl ./autoconf/2.54.nix { autoconf = autoconf-2_53; automake = automake-1_7; };
          autoconf-2_55 = callTccMusl ./autoconf/2.55.nix { autoconf = autoconf-2_54; automake = automake-1_7; };
          automake-1_7_8 = callTccMusl ./automake/1.7.8.nix { autoconf = autoconf-2_55; automake = automake-1_7; };
          autoconf-2_57 = callTccMusl ./autoconf/2.57.nix { autoconf = autoconf-2_55; automake = automake-1_7_8; };
          autoconf-2_59 = callTccMusl ./autoconf/2.59.nix { autoconf = autoconf-2_57; automake = automake-1_7_8; };
          automake-1_8_5 = callTccMusl ./automake/1.8.5.nix { autoconf = autoconf-2_59; automake = automake-1_7_8; };
          help2man-1_36_4 = callTccMusl ./help2man/1.36.4.nix { autoconf = autoconf-2_59; automake = automake-1_8_5; };
          autoconf-2_61 = callTccMusl ./autoconf/2.61.nix { autoconf = autoconf-2_59; automake = automake-1_8_5; };
          automake-1_9_6 = callTccMusl ./automake/1.9.6.nix { autoconf = autoconf-2_61; automake = automake-1_8_5; };
          automake-1_10_3 = callTccMusl ./automake/1.10.3.nix { autoconf = autoconf-2_61; automake = automake-1_9_6; };
          autoconf-2_64 = callTccMusl ./autoconf/2.64.nix { autoconf = autoconf-2_61; automake = automake-1_10_3; };
          automake-1_11_2 = callTccMusl ./automake/1.11.2.nix { autoconf = autoconf-2_64; automake = automake-1_10_3; };
          autoconf-2_69 = callTccMusl ./autoconf/2.69.nix { autoconf = autoconf-2_64; automake = automake-1_11_2; };

          autoconf-2_64-rebuild = callGcc404 ./autoconf/2.64.nix {
            autoconf = autoconf-2_61;
            automake = automake-1_10_3;
          };
          autoconf-2_69-rebuild = callGcc404 ./autoconf/2.69.nix {
            autoconf = autoconf-2_64-rebuild;
            automake = automake-1_11_2;
          };
          libtool-2_2_4 = callTccMusl ./libtool/2.2.4.nix { autoconf = autoconf-2_61; automake = automake-1_10_3; };
          automake-1_15_1 = callTccMusl ./automake/1.15.1.nix { automake = automake-1_11_2; };

          binutils-2_30 = callTccMusl ./binutils/2.30.nix { autoconf = autoconf-2_64; automake = automake-1_11_2; };

          musl-v4 = callTccMusl ./musl/v4.nix { binutils = binutils-2_30; };
          tinycc-musl-v3 = lib.recurseIntoAttrs (callTccMusl ./tinycc/musl-v3.nix { musl = musl-v4; binutils = binutils-2_30; });

          gcc-4_0_4 = callTccMusl ./gcc/4.0.4.nix {
            tinycc = tinycc-musl-v3;
            musl = musl-v4;
            binutils = binutils-2_30;
            autoconf = autoconf-2_61;
            automake19 = automake-1_9_6;
            automake10 = automake-1_10_3;
          };

          findutils-4_2_33 = callTccMusl ./findutils/4.2.33-i386.nix {
            coreutils = coreutils-5_0;
            tinycc = tinycc-musl-v3;
            musl = musl-v4;
            binutils = binutils-2_30;
            autoconf = autoconf-2_61;
            automake = automake-1_10_3;
          };

          # -- Transitional: gcc-4.0.4 building musl-1.2.5 and rebuilding itself --

          musl-1_2_5 = callTccMusl ./musl/1.2.5-i386.nix {
            gcc = gcc-4_0_4;
            binutils = binutils-2_30;
          };

          linux-headers-4_14_341-openela = callTccMusl ./linux-headers/4.14.341-openela.nix {
            gcc = gcc-4_0_4;
            musl = musl-1_2_5;
            binutils = binutils-2_30;
          };

          gcc-4_0_4-rebuild = callTccMusl ./gcc/4.0.4-rebuild.nix {
            gcc = gcc-4_0_4;
            musl = musl-1_2_5;
            binutils = binutils-2_30;
            autoconf = autoconf-2_61;
            automake19 = automake-1_9_6;
            automake10 = automake-1_10_3;
          };

          cc-gcc404 = wrapGcc { bash = bash-mes; gcc = gcc-4_0_4-rebuild; musl = musl-1_2_5; };

          # -- GCC 4.0.4-rebuild stage: early sub-stage (gnumake-3_82, coreutils-6_10) --

          gnumake-3_82 = callGcc404 ./gnumake/3.82.nix {
            bash = bash-mes;
            coreutils = coreutils-6_10;
            gnumake = gnumake-with-sh-mes;
            gnutar = gnutar-mes;
            autoconf = autoconf-2_64;
            automake = automake-1_10_3;
          };

          ed-1_4 = callGcc404 ./ed/1.4.nix {
            bash = bash-mes;
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          bc-1_08_1 = callGcc404 ./bc/1.08.1.nix {
            bash = bash-mes;
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
            ed = ed-1_4;
          };

          bash-5_2_15 = callGcc404 ./bash/5.2.15-i386.nix {
            bash = bash-mes;
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          xz-5_6_4 = callGcc404 ./xz/5.6.4.nix {
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          file-5_44 = callGcc404 ./file/5.44.nix {
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
            libtool = libtool-2_2_4;
          };

          libtool-2_4_7 = callGcc404 ./libtool/2.4.7.nix {
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          gnutar-1_34 = callGcc404 ./gnutar/1.34-i386.nix {
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          coreutils-9_4 = callGcc404 ./coreutils/9.4-i386.nix {
            coreutils = coreutils-6_10;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
          };

          # -- GCC 4.0.4-rebuild stage: late sub-stage (gnumake-4_2_1, coreutils-9_4) --

          pkg-config-0_29_2 = callGcc404 ./pkg-config/0.29.2.nix { gnumake = gnumake-3_82; };
          gnumake-4_2_1 = callGcc404 ./gnumake/4.2.1-i386.nix { gnumake = gnumake-3_82; pkgConfig = pkg-config-0_29_2; };

          gmp-6_2_1 = callGcc404 ./gmp/6.2.1-i386.nix {};
          autoconf-archive-2021_02_19 = callGcc404 ./autoconf-archive/2021.02.19.nix {};
          mpfr-4_1_0 = callGcc404 ./mpfr/4.1.0-i386.nix { gmp = gmp-6_2_1; };
          mpc-1_2_1 = callGcc404 ./mpc/1.2.1-i386.nix { gmp = gmp-6_2_1; mpfr = mpfr-4_1_0; };
          flex-2_5_33 = callGcc404 ./flex/2.5.33.nix { oldFlex = flex-2_6_4; };
          bison-2_3 = callGcc404 ./bison/2.3.nix { flex = flex-2_5_33; };
          zlib-1_3_1 = callGcc404 ./zlib/1.3.1-i386.nix {};
          dist-3_5 = callGcc404 ./dist/3.5.nix {};
          perl-Devel-Tokenizer-C-0_11 = callGcc404 ./perl-Devel-Tokenizer-C/0.11.nix {};

          perl-5_8_9 = callGcc404 ./perl/5.8.9.nix {
            oldPerl = perl-5_6_2;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11;
          };

          perl-Devel-Tokenizer-C-0_11-perl-5_8_9 = callGcc404 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_8_9; };

          perl-5_12_5 = callGcc404 ./perl/5.12.5.nix {
            bison = bison-2_3;
            oldPerl = perl-5_8_9;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_8_9;
          };

          gnupatch-2_7_6 = callGcc404 ./gnupatch/2.7.6-i386.nix { perl = perl-5_12_5; };

          gcc-4_7_4 = callGcc404 ./gcc/4.7.4.nix {
            gnupatch = gnupatch-2_7_6;
            perl = perl-5_12_5;
            autoconf = autoconf-2_64-rebuild;
            automake = automake-1_11_2;
            automake15 = automake-1_15_1;
            flex = flex-2_6_4;
          };

          # -- GCC 4.7.4 stage --

          cc-gcc474 = wrapGcc { bash = bash-5_2_15; gcc = gcc-4_7_4; musl = musl-1_2_5-rebuild; dynamicLinker = true; };
          cc-gcc474-cxx = wrapGcc { bash = bash-5_2_15; gcc = gcc-4_7_4; musl = musl-1_2_5-rebuild; dynamicLinker = true; cxx = true; };

          binutils-2_41 = callGcc474 ./binutils/2.41-i386.nix {
            musl = musl-1_2_5;
            binutils = binutils-2_30;
            bison = bison-2_3;
          };

          musl-1_2_5-rebuild = callGcc474 ./musl/1.2.5-rebuild.nix { musl = musl-1_2_5; binutils = binutils-2_41; };

          python-2_0_1-pass1 = callGcc474 ./python/2.0.1-pass1.nix {};
          python-2_0_1 = callGcc474 ./python/2.0.1.nix { pythonPass1 = python-2_0_1-pass1; };
          python-2_3_7-pass1 = callGcc474 ./python/2.3.7-pass1.nix { oldPython = python-2_0_1; };
          python-2_3_7 = callGcc474 ./python/2.3.7.nix { pythonPass1 = python-2_3_7-pass1; };

          gperf-3_3 = callGcc474 ./gperf/3.3.nix {};
          texinfo-6_7 = callGcc474 ./texinfo/6.7.nix {};

          perl-Devel-Tokenizer-C-0_11-perl-5_12_5 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix {};

          # Perl bootstrap chain (5.15.7 → 5.42.0)
          perl-5_15_7 = callGcc474 ./perl/5.15.7.nix {
            bison = bison-2_3;
            oldPerl = perl-5_12_5;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_12_5;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_15_7 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_15_7; };

          perl-5_16_3 = callGcc474 ./perl/5.16.3.nix {
            bison = bison-2_3;
            oldPerl = perl-5_15_7;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_15_7;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_16_3 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_16_3; };

          perl-5_17_2 = callGcc474 ./perl/5.17.2.nix {
            bison = bison-2_3;
            oldPerl = perl-5_16_3;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_16_3;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_17_2 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_17_2; };

          perl-5_17_4 = callGcc474 ./perl/5.17.4.nix {
            bison = bison-2_3;
            oldPerl = perl-5_17_2;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_17_2;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_17_4 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_17_4; };

          perl-5_18_4 = callGcc474 ./perl/5.18.4.nix {
            bison = bison-2_3;
            oldPerl = perl-5_17_4;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_17_4;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_18_4 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_18_4; };

          automake-1_16_3 = callGcc474 ./automake/1.16.3.nix { perl = perl-5_18_4; automake = automake-1_15_1; };
          autoconf-2_71 = callGcc474 ./autoconf/2.71.nix { perl = perl-5_18_4; automake = automake-1_16_3; };

          bison-3_6_4 = callGcc474 ./bison/3.6.4.nix { perl = perl-5_18_4; };
          bison-3_7_6 = callGcc474 ./bison/3.7.6.nix { perl = perl-5_18_4; bison = bison-3_6_4; };

          perl-5_22_4 = callGcc474 ./perl/5.22.4.nix {
            bison = bison-2_3;
            oldPerl = perl-5_18_4;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_18_4;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_22_4 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_22_4; };

          perl-5_24_4 = callGcc474 ./perl/5.24.4.nix {
            bison = bison-2_3;
            oldPerl = perl-5_22_4;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_22_4;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_24_4 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_24_4; };

          perl-5_30_3 = callGcc474 ./perl/5.30.3.nix {
            bison = bison-2_3;
            oldPerl = perl-5_24_4;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_24_4;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_30_3 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_30_3; };

          perl-5_36_3 = callGcc474 ./perl/5.36.3.nix {
            bison = bison-3_7_6;
            oldPerl = perl-5_30_3;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_30_3;
          };
          perl-Devel-Tokenizer-C-0_11-perl-5_36_3 = callGcc474 ./perl-Devel-Tokenizer-C/0.11.nix { perl = perl-5_36_3; };

          bison-3_8_2 = callGcc474 ./bison/3.8.2.nix {
            perl = perl-5_36_3;
            autoconf = autoconf-2_71;
            bison = bison-3_7_6;
          };

          perl-5_42_0 = callGcc474 ./perl/5.42.0.nix {
            bison = bison-3_8_2;
            oldPerl = perl-5_36_3;
            perlDevelTokenizerC = perl-Devel-Tokenizer-C-0_11-perl-5_36_3;
          };

          libunistring-0_9_10 = callGcc474 ./libunistring/0.9.10.nix { perl = perl-5_42_0; };
          libffi-3_3 = callGcc474 ./libffi/3.3.nix { perl = perl-5_42_0; autoconf = autoconf-2_71; automake = automake-1_16_3; };
          libatomic_ops-7_6_10 = callGcc474 ./libatomic_ops/7.6.10.nix { perl = perl-5_42_0; autoconf = autoconf-2_71; automake = automake-1_16_3; };
          boehm-gc-8_0_4 = callGcc474 ./boehm-gc/8.0.4.nix { perl = perl-5_42_0; autoconf = autoconf-2_71; automake = automake-1_16_3; libatomic_ops = libatomic_ops-7_6_10; };

          guile-3_0_9 = callGcc474 ./guile/3.0.9.nix {
            perl = perl-5_42_0;
            autoconf = autoconf-2_71;
            automake = automake-1_16_3;
            libunistring = libunistring-0_9_10;
            boehm-gc = boehm-gc-8_0_4;
          };

          which-2_21 = callGcc474 ./which/2.21.nix { perl = perl-5_42_0; automake = automake-1_16_3; };
          grep-3_7 = callGcc474 ./grep/3.7-i386.nix { perl = perl-5_42_0; autoconf = autoconf-2_71; automake = automake-1_16_3; };
          gnused-4_8 = callGcc474 ./gnused/4.8-i386.nix { perl = perl-5_42_0; grep = grep-3_7; automake = automake-1_16_3; };

          autogen-5_18_16 = callGcc474 ./autogen/5.18.16.nix {
            perl = perl-5_42_0;
            grep = grep-3_7;
            autoconf = autoconf-2_71;
            automake = automake-1_16_3;
            guile = guile-3_0_9;
            which = which-2_21;
          };

          python-2_5_6 = callGcc474 ./python/2.5.6.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-2_3_7; };
          python-3_1_5-pass1 = callGcc474 ./python/3.1.5-pass1.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-2_5_6; };
          python-3_1_5 = callGcc474 ./python/3.1.5.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-2_5_6; pythonPass1 = python-3_1_5-pass1; };
          python-3_3_7 = callGcc474 ./python/3.3.7.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-3_1_5; };
          python-3_4_10 = callGcc474 ./python/3.4.10.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-3_3_7; };
          python-3_8_16 = callGcc474 ./python/3.8.16.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-3_4_10; };
          python-3_11_1 = callGcc474 ./python/3.11.1.nix { perl = perl-5_42_0; grep = grep-3_7; autoconf = autoconf-2_71; automake = automake-1_16_3; oldPython = python-3_8_16; };

          # Needed by glibc
          m4-1_4_20 = callGcc474 ./m4/1.4.20.nix { autoconf = autoconf-2_71; automake = automake-1_16_3; };
          autoconf-2_72 = callGcc474 ./autoconf/2.72.nix { autoconf = autoconf-2_71; automake = automake-1_16_3; m4 = m4-1_4_20; };

          # -- Late GCC stages (gcc-10.5.0, gcc-15.2.0, cross tools) --

          gcc-10_5_0 = callGcc474 ./gcc/10.5.0.nix { perl = perl-5_42_0; gnused = gnused-4_8; grep = grep-3_7; bison = bison-3_8_2; };
          binutils-2_41-pass2 = callGcc474 ./binutils/2.41-pass2.nix { gcc = gcc-10_5_0; perl = perl-5_42_0; gnused = gnused-4_8; grep = grep-3_7; bison = bison-3_8_2; };

          gcc-15_2_0 = callGcc474 ./gcc/15.2.0-i386.nix {
            gcc = gcc-10_5_0;
            binutils = binutils-2_41-pass2;
            perl = perl-5_42_0;
            gnused = gnused-4_8;
            grep = grep-3_7;
            bison = bison-3_8_2;
          };

          cross-binutils-2_41 = callGcc474 ./binutils/2.41-cross.nix {
            gcc = gcc-15_2_0;
            binutils = binutils-2_41-pass2;
            perl = perl-5_42_0;
            gnused = gnused-4_8;
            grep = grep-3_7;
            bison = bison-3_8_2;
          };

          cross-gcc-15_2_0 = callGcc474 ./gcc/15.2.0-cross.nix {
            gcc = gcc-15_2_0;
            binutils = binutils-2_41-pass2;
            crossBinutils = cross-binutils-2_41;
            perl = perl-5_42_0;
            gnused = gnused-4_8;
            grep = grep-3_7;
            bison = bison-3_8_2;
          };

          cross-binutils-2_41-gnu = callGcc474 ./binutils/2.41-cross-gnu.nix {
            gcc = gcc-15_2_0;
            binutils = binutils-2_41-pass2;
            perl = perl-5_42_0;
            gnused = gnused-4_8;
            grep = grep-3_7;
            bison = bison-3_8_2;
          };

          cross-gcc-15_2_0-gnu = callGcc474 ./gcc/15.2.0-cross-gnu.nix {
            gcc = gcc-15_2_0;
            binutils = binutils-2_41-pass2;
            crossBinutils = cross-binutils-2_41-gnu;
            perl = perl-5_42_0;
            gnused = gnused-4_8;
            grep = grep-3_7;
            bison = bison-3_8_2;
          };

        });

      # -- x86_64 packages using simple cross-gcc (no target libs) --

      musl-1_2_5 = callCrossSimple ./musl/1.2.5.nix {};

      glibc-2_42 = callCrossSimpleGnu ./glibc/2.42.nix {
        autoconf = i386Bootstrap.autoconf-2_72;
        buildBinutils = i386Bootstrap.binutils-2_41-pass2;
        linuxHeaders = i386Bootstrap.linux-headers-4_14_341-openela;
        buildZlib = i386Bootstrap.zlib-1_3_1;
        gawk = gawk-5_3_0;
      };

      cross-gcc-full-15_2_0 = callCrossSimple ./gcc/15.2.0-cross-full.nix {
        gcc = i386Bootstrap.gcc-15_2_0;
        musl = i386Bootstrap.musl-1_2_5-rebuild;
        binutils = i386Bootstrap.binutils-2_41-pass2;
        gmp = i386Bootstrap.gmp-6_2_1;
        mpfr = i386Bootstrap.mpfr-4_1_0;
        mpc = i386Bootstrap.mpc-1_2_1;
        zlib = i386Bootstrap.zlib-1_3_1;
      };

      cross-gcc-full-15_2_0-gnu = callCrossSimpleGnu ./gcc/15.2.0-cross-full-gnu.nix {
        gcc = i386Bootstrap.gcc-15_2_0;
        musl = i386Bootstrap.musl-1_2_5-rebuild;
        binutils = i386Bootstrap.binutils-2_41-pass2;
        crossGlibc = glibc-2_42;
        gmp = i386Bootstrap.gmp-6_2_1;
        mpfr = i386Bootstrap.mpfr-4_1_0;
        mpc = i386Bootstrap.mpc-1_2_1;
        zlib = i386Bootstrap.zlib-1_3_1;
      };

      zlib-1_3_1 = callCrossSimple ./zlib/1.3.1.nix {};
      zlib-1_3_1-gnu = callCrossSimpleGnu ./zlib/1.3.1-gnu.nix {
        crossGlibc = glibc-2_42;
      };
      gmp-6_2_1 = callCrossSimple ./gmp/6.2.1.nix {};

      mpfr-4_1_0 = callCrossSimple ./mpfr/4.1.0.nix {
        gmp = gmp-6_2_1;
        buildGmp = i386Bootstrap.gmp-6_2_1;
        buildMpfr = i386Bootstrap.mpfr-4_1_0;
      };

      mpc-1_2_1 = callCrossSimple ./mpc/1.2.1.nix {
        gmp = gmp-6_2_1;
        mpfr = mpfr-4_1_0;
      };

      # -- x86_64 packages using cross-gcc-full (with C++ / libstdc++) --

      binutils-2_41 = callCrossFull ./binutils/2.41.nix {
        buildBinutils = i386Bootstrap.binutils-2_41-pass2;
        zlib = zlib-1_3_1;
        buildZlib = i386Bootstrap.zlib-1_3_1;
      };

      gcc-15_2_0 = callCrossFull ./gcc/15.2.0.nix {
        nativeBinutils = binutils-2_41;
        gmp = gmp-6_2_1;
        mpfr = mpfr-4_1_0;
        mpc = mpc-1_2_1;
        zlib = zlib-1_3_1;
        buildGmp = i386Bootstrap.gmp-6_2_1;
        buildMpfr = i386Bootstrap.mpfr-4_1_0;
        buildMpc = i386Bootstrap.mpc-1_2_1;
        buildZlib = i386Bootstrap.zlib-1_3_1;
      };

      binutils-2_41-gnu = callCrossFullGnu ./binutils/2.41-gnu.nix {
        buildBinutils = i386Bootstrap.binutils-2_41-pass2;
        crossGlibc = glibc-2_42;
        zlib = zlib-1_3_1-gnu;
        buildZlib = i386Bootstrap.zlib-1_3_1;
      };

      gcc-15_2_0-gnu = callCrossFullGnu ./gcc/15.2.0-gnu.nix {
        nativeBinutils = binutils-2_41-gnu;
        crossGlibc = glibc-2_42;
        gmp = gmp-6_2_1;
        mpfr = mpfr-4_1_0;
        mpc = mpc-1_2_1;
        zlib = zlib-1_3_1-gnu;
        buildGmp = i386Bootstrap.gmp-6_2_1;
        buildMpfr = i386Bootstrap.mpfr-4_1_0;
        buildMpc = i386Bootstrap.mpc-1_2_1;
        buildZlib = i386Bootstrap.zlib-1_3_1;
      };

      patchelf-0_15_2 = callCrossFull ./patchelf/0.15.2.nix {};
      coreutils-9_4 = callCrossFull ./coreutils/9.4.nix {};

      gzip-1_13 = callCrossFull ./gzip/1.13.nix {
        autoconf = i386Bootstrap.autoconf-2_71;
        autoconf269 = i386Bootstrap.autoconf-2_69-rebuild;
        automake = i386Bootstrap.automake-1_16_3;
      };

      gnupatch-2_7_6 = callCrossFull ./gnupatch/2.7.6.nix {};
      gnutar-1_34 = callCrossFull ./gnutar/1.34.nix {};

      grep-3_7 = callCrossFull ./grep/3.7.nix {
        autoconf = i386Bootstrap.autoconf-2_71;
        autoconf269 = i386Bootstrap.autoconf-2_69-rebuild;
        automake = i386Bootstrap.automake-1_16_3;
      };

      gnused-4_8 = callCrossFull ./gnused/4.8.nix {
        automake = i386Bootstrap.automake-1_16_3;
      };

      findutils-4_2_33 = callCrossFull ./findutils/4.2.33.nix {
        autoconf = i386Bootstrap.autoconf-2_61;
        automake = i386Bootstrap.automake-1_10_3;
      };
      findutils-4_10_0 = callCrossFull ./findutils/4.10.0.nix { };

      bash-5_2_15 = callCrossFull ./bash/5.2.15.nix {};
      gnumake-4_2_1 = callCrossFull ./gnumake/4.2.1.nix {};
      gawk-3_0_4 = callCrossFull ./gawk/3.0.4.nix {};
      gawk-5_3_0 = callCrossFull ./gawk/5.3.0.nix {
        autoconf = i386Bootstrap.autoconf-2_71;
        automake = i386Bootstrap.automake-1_16_3;
      };
      diffutils-2_7 = callCrossFull ./diffutils/2.7.nix {};
      diffutils-3_10 = callCrossFull ./diffutils/3.10.nix { };
      bzip2-1_0_8 = callCrossFull ./bzip2/1.0.8.nix {};
      busybox = callCrossFull ./busybox/1.37.0.nix {};

      bootstrap-tools-assembled = callPackage ./bootstrap-tools-assembled.nix {
        bash = bash-5_2_15;
        musl = musl-1_2_5;
        gcc = gcc-15_2_0;
        binutils = binutils-2_41;
        coreutils = coreutils-9_4;
        diffutils = diffutils-3_10;
        findutils = findutils-4_10_0;
        gawk = gawk-5_3_0;
        gnumake = gnumake-4_2_1;
        gnupatch = gnupatch-2_7_6;
        gnutar = gnutar-1_34;
        gnused = gnused-4_8;
        grep = grep-3_7;
        gzip = gzip-1_13;
        bzip2 = bzip2-1_0_8;
        patchelf = patchelf-0_15_2;
        gmp = gmp-6_2_1;
        mpfr = mpfr-4_1_0;
        mpc = mpc-1_2_1;
        zlib = zlib-1_3_1;
      };

      bootstrap-tools-assembled-gnu = callPackage ./bootstrap-tools-assembled.nix {
        bash = bash-5_2_15;
        musl = musl-1_2_5;
        glibc = glibc-2_42;
        gcc = gcc-15_2_0-gnu;
        binutils = binutils-2_41-gnu;
        coreutils = coreutils-9_4;
        diffutils = diffutils-3_10;
        findutils = findutils-4_10_0;
        gawk = gawk-5_3_0;
        gnumake = gnumake-4_2_1;
        gnupatch = gnupatch-2_7_6;
        gnutar = gnutar-1_34;
        gnused = gnused-4_8;
        grep = grep-3_7;
        gzip = gzip-1_13;
        bzip2 = bzip2-1_0_8;
        patchelf = patchelf-0_15_2;
        gmp = gmp-6_2_1;
        mpfr = mpfr-4_1_0;
        mpc = mpc-1_2_1;
        zlib = zlib-1_3_1-gnu;
      };

      inherit (callPackage ./utils.nix { }) derivationWithMeta writeTextFile writeText;
    }
  )
