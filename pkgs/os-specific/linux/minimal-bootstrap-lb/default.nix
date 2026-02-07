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

          tinycc-for-musl-mes = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/for-musl.nix {
            tinycc = tinycc-bootstrappable;
            gnupatch = gnupatch-mes;
          });

          musl = i386self.callPackage ./musl/tcc.nix {
            bash = bash-mes;
            tinycc = tinycc-for-musl-mes;
            gnumake = gnumake-mes;
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
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-mes;
          };

          tinycc-musl-v2 = lib.recurseIntoAttrs (i386self.callPackage ./tinycc/musl-v2.nix {
            bash = bash-mes;
            tinycc = tinycc-musl;
            musl = musl-tcc;
            gnupatch = gnupatch-mes;
          });

          grep-2_4 = i386self.callPackage ./grep/2.4.nix {
            bash = bash-mes;
            tinycc = tinycc-musl-v2;
            gnumake = gnumake-mes;
          };

          musl-v3 = i386self.callPackage ./musl/v3.nix {
            bash = bash-mes;
            tinycc = tinycc-musl-v2;
            gnumake = gnumake-mes;
            gnupatch = gnupatch-mes;
            gnused = gnused-mes;
            grep = grep-2_4;
          };

          gnused-4_0_9 = i386self.callPackage ./gnused/musl-v3.nix {
            bash = bash-mes;
            tinycc = tinycc-musl-v2;
            musl = musl-v3;
            gnumake = gnumake-mes;
          };

          bzip2-1_0_8 = i386self.callPackage ./bzip2/musl-v3.nix {
            bash = bash-mes;
            tinycc = tinycc-musl-v2;
            musl = musl-v3;
            gnumake = gnumake-mes;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
          };

          m4-1_4_7 = i386self.callPackage ./m4/1.4.7.nix {
            bash = bash-mes;
            tinycc = tinycc-musl-v2;
            musl = musl-v3;
            gnumake = gnumake-mes;
            gnutar = gnutar-mes;
            bzip2 = bzip2-1_0_8;
          };
        });

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
        tinycc-0_9_27-mes
        gnumake-mes
        gnupatch-mes
        gzip-mes
        gnutar-mes
        gnused-mes
        bzip2-mes
        coreutils-mes
        oyacc-mes
        bash-mes
        tinycc-for-musl-mes
        musl
        tinycc-musl
        musl-tcc
        tinycc-musl-v2
        grep-2_4
        musl-v3
        gnused-4_0_9
        bzip2-1_0_8
        m4-1_4_7
        ;

      inherit (callPackage ./utils.nix { }) derivationWithMeta writeTextFile writeText;
    }
  )
