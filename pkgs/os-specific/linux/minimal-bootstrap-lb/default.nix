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
    self: with self; {

      i386Bootstrap = lib.makeScope
        (extra: lib.callPackageWith ({
          inherit lib config fetchurl checkMeta;
          buildPlatform = i386Platform;
          hostPlatform = i386Platform;
        } // extra))
        (i386self: with i386self; {
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

          tinycc-0_9_27 = i386self.callPackage ./tinycc/0.9.27.nix {
            inherit mes-config-h-override;
          };

          gnumake-3_82 = i386self.callPackage ./gnumake/3.82.nix { tinycc = tinycc-0_9_27; };

          patch-2_5_9 = i386self.callPackage ./patch/2.5.9.nix {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
          };

          gzip-mes = i386self.callPackage ./gzip {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
            gnupatch = patch-2_5_9;
          };

          gnutar-mes = i386self.callPackage ./gnutar/mes.nix {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
            gzip = gzip-mes;
          };

          gnused-mes = i386self.callPackage ./gnused/mes.nix {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
          };
        });

      bash_2_05 = callPackage ./bash/2.nix { tinycc = tinycc-mes; };

      bash = callPackage ./bash {
        bootBash = bash_2_05;
        tinycc = tinycc-musl;
        coreutils = coreutils-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };

      bash-static = callPackage ./bash/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      binutils = callPackage ./binutils {
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
      };

      binutils-static = callPackage ./binutils/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      bison = callPackage ./bison {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      busybox-static = callPackage ./busybox/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      bzip2 = callPackage ./bzip2 {
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };

      bzip2-static = callPackage ./bzip2/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      coreutils = callPackage ./coreutils { tinycc = tinycc-mes; };

      coreutils-musl = callPackage ./coreutils/musl.nix {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };
      coreutils-static = callPackage ./coreutils/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      diffutils = callPackage ./diffutils {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
      };

      diffutils-static = callPackage ./diffutils/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      findutils = callPackage ./findutils {
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
      };

      gawk-mes = callPackage ./gawk/mes.nix {
        bash = bash_2_05;
        tinycc = tinycc-mes;
        gnused = gnused-mes;
      };
      findutils-static = callPackage ./findutils/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      gawk = callPackage ./gawk {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
        bootGawk = gawk-mes;
      };

      gcc46 = callPackage ./gcc/4.6.nix {
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };

      gcc46-cxx = callPackage ./gcc/4.6.cxx.nix {
        gcc = gcc46;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };

      gcc10 = callPackage ./gcc/10.nix {
        gcc = gcc46-cxx;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      gcc-latest = callPackage ./gcc/latest.nix {
        gcc = gcc10;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      gcc-glibc = callPackage ./gcc/glibc.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      glibc = callPackage ./glibc {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gnugrep = gnugrep-static;
      };

      gnugrep = callPackage ./gnugrep {
        bash = bash_2_05;
        tinycc = tinycc-mes;
      };

      gnugrep-static = callPackage ./gnugrep/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      gnum4 = callPackage ./gnum4 {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      gnumake = callPackage ./gnumake { tinycc = tinycc-bootstrappable; };

      gnumake-musl = callPackage ./gnumake/musl.nix {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gawk = gawk-mes;
        gnumakeBoot = gnumake;
        gzip = gzip-mes;
      };

      gnumake-static = callPackage ./gnumake/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      gnupatch = callPackage ./gnupatch { tinycc = tinycc-mes; };

      gnupatch-static = callPackage ./gnupatch/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      gnused = callPackage ./gnused {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnused = gnused-mes;
        gzip = gzip-mes;
      };

      gnused-static = callPackage ./gnused/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      # FIXME: better package naming scheme
      gnutar-latest = callPackage ./gnutar/latest.nix {
        gcc = gcc46;
        gnumake = gnumake-musl;
        gnutarBoot = gnutar-musl;
        gzip = gzip-mes;
      };

      gnutar-musl = callPackage ./gnutar/musl.nix {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnused = gnused-mes;
      };

      gnutar-static = callPackage ./gnutar/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutarBoot = gnutar-latest;
        gzip = gzip-mes;
      };

      gzip-static = callPackage ./gzip/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      heirloom = callPackage ./heirloom {
        bash = bash_2_05;
        tinycc = tinycc-mes;
      };

      heirloom-devtools = callPackage ./heirloom-devtools { tinycc = tinycc-mes; };

      linux-headers = callPackage ./linux-headers {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      ln-boot = callPackage ./ln-boot { };

      musl-tcc-intermediate = callPackage ./musl/tcc.nix {
        bash = bash_2_05;
        tinycc = tinycc-mes;
        gnused = gnused-mes;
        gzip = gzip-mes;
      };

      musl-tcc = callPackage ./musl/tcc.nix {
        bash = bash_2_05;
        tinycc = tinycc-musl-intermediate;
        gnused = gnused-mes;
        gzip = gzip-mes;
      };

      musl = callPackage ./musl {
        gcc = gcc46;
        gnumake = gnumake-musl;
        gzip = gzip-mes;
      };

      patchelf-static = callPackage ./patchelf/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      python = callPackage ./python {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      # Early bootstrap stages run as i386
      inherit (i386Bootstrap)
        stage0-posix
        kaem
        m2libc
        mescc-tools
        mescc-tools-extra
        mes
        mes-libc
        tinycc-bootstrappable
        tinycc-mes
        tinycc-0_9_27
        gnumake-3_82
        patch-2_5_9
        gzip-mes
        gnutar-mes
        gnused-mes
        ;

      tinycc-musl-intermediate = lib.recurseIntoAttrs (
        callPackage ./tinycc/musl.nix {
          bash = bash_2_05;
          musl = musl-tcc-intermediate;
          tinycc = tinycc-mes;
          gzip = gzip-mes;
        }
      );

      tinycc-musl = lib.recurseIntoAttrs (
        callPackage ./tinycc/musl.nix {
          bash = bash_2_05;
          musl = musl-tcc;
          tinycc = tinycc-musl-intermediate;
          gzip = gzip-mes;
        }
      );

      gawk-static = callPackage ./gawk/static.nix {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
        gzip = gzip-mes;
      };

      xz = callPackage ./xz {
        bash = bash_2_05;
        tinycc = tinycc-musl;
        gnumake = gnumake-musl;
        gnutar = gnutar-musl;
        gzip = gzip-mes;
      };

      zlib = callPackage ./zlib {
        gcc = gcc-latest;
        gnumake = gnumake-musl;
        gnutar = gnutar-latest;
      };

      inherit (callPackage ./utils.nix { }) derivationWithMeta writeTextFile writeText;
      test = kaem.runCommand "minimal-bootstrap-test" { } (
        ''
          echo ${bash.tests.get-version}
          echo ${bash-static.tests.get-version}
          echo ${bash_2_05.tests.get-version}
          echo ${binutils.tests.get-version}
          echo ${binutils-static.tests.get-version}
          echo ${bison.tests.get-version}
          echo ${busybox-static.tests.get-version}
          echo ${bzip2.tests.get-version}
          echo ${bzip2-static.tests.get-version}
          echo ${coreutils-musl.tests.get-version}
          echo ${coreutils-static.tests.get-version}
          echo ${diffutils.tests.get-version}
          echo ${diffutils-static.tests.get-version}
          echo ${findutils.tests.get-version}
          echo ${findutils-static.tests.get-version}
          echo ${gawk.tests.get-version}
          echo ${gawk-mes.tests.get-version}
          echo ${gawk-static.tests.get-version}
          echo ${gcc46.tests.get-version}
          echo ${gcc46-cxx.tests.hello-world}
          echo ${gcc10.tests.hello-world}
          echo ${gcc-latest.tests.hello-world}
          echo ${gnugrep.tests.get-version}
          echo ${gnugrep-static.tests.get-version}
          echo ${gnum4.tests.get-version}
          echo ${gnumake-musl.tests.get-version}
          echo ${gnumake-static.tests.get-version}
          echo ${gnupatch-static.tests.get-version}
          echo ${gnused.tests.get-version}
          echo ${gnused-mes.tests.get-version}
          echo ${gnused-static.tests.get-version}
          echo ${gnutar-mes.tests.get-version}
          echo ${gnutar-latest.tests.get-version}
          echo ${gnutar-musl.tests.get-version}
          echo ${gnutar-static.tests.get-version}
          echo ${gzip-mes.tests.get-version}
          echo ${gzip-static.tests.get-version}
          echo ${heirloom.tests.get-version}
          echo ${mes.compiler.tests.get-version}
          echo ${musl.tests.hello-world}
          echo ${patchelf-static.tests.get-version}
          echo ${python.tests.get-version}
          echo ${tinycc-mes.compiler.tests.chain}
          echo ${tinycc-musl.compiler.tests.hello-world}
          echo ${xz.tests.get-version}
        ''
        + (lib.strings.optionalString (hostPlatform.libc == "glibc") ''
          echo ${gcc-glibc.tests.hello-world}
          echo ${glibc.tests.hello-world}
        '')
        + ''
          mkdir ''${out}
        ''
      );
    }
  )
