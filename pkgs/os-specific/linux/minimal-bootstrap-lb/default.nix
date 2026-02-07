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

          bzip2-mes = i386self.callPackage ./bzip2/mes.nix {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
            gnupatch = patch-2_5_9;
            gnutar = gnutar-mes;
            gzip = gzip-mes;
          };

          coreutils-5_0 = i386self.callPackage ./coreutils {
            tinycc = tinycc-0_9_27;
            gnumake = gnumake-3_82;
            gnupatch = patch-2_5_9;
            gnused = gnused-mes;
            gnutar = gnutar-mes;
            bzip2 = bzip2-mes;
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
        tinycc-0_9_27
        gnumake-3_82
        patch-2_5_9
        gzip-mes
        gnutar-mes
        gnused-mes
        bzip2-mes
        coreutils-5_0
        ;

      inherit (callPackage ./utils.nix { }) derivationWithMeta writeTextFile writeText;
    }
  )
