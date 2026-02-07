{ lib }:

{
  # Wrap TinyCC with bootstrap library paths and musl includes.
  # Output: $out/bin/tcc, $out/bin/cc (symlink), $out/bin/ar
  # $out/lib contains copies of musl libs + libtcc1.a
  wrapTcc =
    {
      bash,
      tinycc,
      musl,
    }:
    bash.runCommand "tcc-wrapped"
      {
        pname = "tcc-wrapped";
        meta = {
          description = "TinyCC with musl bootstrap libraries";
          license = lib.licenses.lgpl21Only;
          teams = [ lib.teams.minimal-bootstrap ];
          platforms = lib.platforms.unix;
        };
      }
      ''
        mkdir -p ''${out}/bin ''${out}/lib

        cp ${musl}/lib/* ''${out}/lib/
        cp ${tinycc.libs}/lib/libtcc1.a ''${out}/lib/

        cat > ''${out}/bin/tcc <<EOF
        #!${bash}/bin/bash
        export CPATH="${musl}/include\''${CPATH:+:\''${CPATH}}"
        exec ${tinycc.compiler}/bin/tcc \
          -B ''${out}/lib \
          "\$@"
        EOF
        chmod 555 ''${out}/bin/tcc

        ln -s tcc ''${out}/bin/cc

        cat > ''${out}/bin/ar <<EOF
        #!${bash}/bin/bash
        exec ${tinycc.compiler}/bin/tcc -ar "\$@"
        EOF
        chmod 555 ''${out}/bin/ar
      '';

  # Wrap GCC with musl sysroot flags (-isystem, -B, -L).
  # Output: $out/bin/gcc, $out/bin/cc (symlink)
  # Optionally: $out/bin/g++, $out/bin/c++ (symlink)
  wrapGcc =
    {
      bash,
      gcc,
      musl,
      extraIncludes ? [ ],
      extraLibs ? [ ],
      dynamicLinker ? false,
      cxx ? false,
      extraFlags ? [ ],
    }:
    let
      flags =
        (map (p: "-isystem ${p}/include") ([ musl ] ++ extraIncludes))
        ++ [ "-B ${musl}/lib" ]
        ++ (map (p: "-L ${p}/lib") (extraLibs ++ [ musl ]))
        ++ lib.optionals dynamicLinker [
          "-Wl,--dynamic-linker=${musl}/lib/ld-musl-i386.so.1"
          "-Wl,-rpath,${musl}/lib"
        ]
        ++ extraFlags;
      flagsStr = lib.concatStringsSep " " flags;
    in
    bash.runCommand "gcc-wrapped"
      {
        pname = "gcc-wrapped";
        meta = {
          description = "GCC with musl sysroot flags";
          license = lib.licenses.gpl3Plus;
          teams = [ lib.teams.minimal-bootstrap ];
          platforms = lib.platforms.unix;
        };
      }
      ''
        mkdir -p ''${out}/bin

        cat > ''${out}/bin/gcc <<EOF
        #!${bash}/bin/bash
        exec ${gcc}/bin/gcc ${flagsStr} "\$@"
        EOF
        chmod 555 ''${out}/bin/gcc

        ln -s gcc ''${out}/bin/cc

        ${lib.optionalString cxx ''
          cat > ''${out}/bin/g++ <<EOF
          #!${bash}/bin/bash
          exec ${gcc}/bin/g++ ${flagsStr} "\$@"
          EOF
          chmod 555 ''${out}/bin/g++

          ln -s g++ ''${out}/bin/c++
        ''}
      '';

  # Wrap a cross-compiler (runs on buildPlatform, targets hostPlatform).
  # Output: $out/bin/{gcc,cc,g++,c++} (all target the host)
  # Also: $out/bin/build-{gcc,cc} for build-platform compilation
  wrapCrossGcc =
    {
      bash,
      buildGcc,
      buildMusl,
      crossGcc,
      crossBinutils,
      crossMusl,
      buildExtraIncludes ? [ ],
      buildExtraLibs ? [ ],
      crossExtraIncludes ? [ ],
      crossExtraLibs ? [ ],
      buildExtraFlags ? [ ],
      crossExtraFlags ? [ ],
      cxx ? false,
      target ? "x86_64-unknown-linux-musl",
    }:
    let
      buildFlags =
        (map (p: "-isystem ${p}/include") ([ buildMusl ] ++ buildExtraIncludes))
        ++ [ "-B ${buildMusl}/lib" ]
        ++ (map (p: "-L ${p}/lib") (buildExtraLibs ++ [ buildMusl ]))
        ++ [
          "-Wl,--dynamic-linker=${buildMusl}/lib/ld-musl-i386.so.1"
          "-Wl,-rpath,${buildMusl}/lib"
        ]
        ++ buildExtraFlags;
      buildFlagsStr = lib.concatStringsSep " " buildFlags;

      crossFlags =
        [ "--sysroot=${crossMusl}" ]
        ++ (map (p: "-isystem ${p}/include") ([ crossMusl ] ++ crossExtraIncludes))
        ++ (map (p: "-L ${p}/lib") (crossExtraLibs))
        ++ [
          "-Wl,--dynamic-linker=${crossMusl}/lib/ld-musl-x86_64.so.1"
          "-Wl,-rpath,${crossMusl}/lib"
        ]
        ++ crossExtraFlags;
      crossFlagsStr = lib.concatStringsSep " " crossFlags;
    in
    bash.runCommand "cross-gcc-wrapped"
      {
        pname = "cross-gcc-wrapped";
        meta = {
          description = "Cross GCC wrapper (${target})";
          license = lib.licenses.gpl3Plus;
          teams = [ lib.teams.minimal-bootstrap ];
          platforms = lib.platforms.unix;
        };
      }
      ''
        mkdir -p ''${out}/bin

        # Build-platform compiler (i386)
        cat > ''${out}/bin/build-gcc <<EOF
        #!${bash}/bin/bash
        exec ${buildGcc}/bin/gcc ${buildFlagsStr} "\$@"
        EOF
        chmod 555 ''${out}/bin/build-gcc
        ln -s build-gcc ''${out}/bin/build-cc

        # Cross compiler (target)
        cat > ''${out}/bin/gcc <<EOF
        #!${bash}/bin/bash
        exec ${crossGcc}/bin/${target}-gcc ${crossFlagsStr} "\$@"
        EOF
        chmod 555 ''${out}/bin/gcc
        ln -s gcc ''${out}/bin/cc
        ln -s gcc ''${out}/bin/${target}-gcc

        ${lib.optionalString cxx ''
          # Build-platform C++ compiler
          cat > ''${out}/bin/build-g++ <<EOF
          #!${bash}/bin/bash
          exec ${buildGcc}/bin/g++ ${buildFlagsStr} "\$@"
          EOF
          chmod 555 ''${out}/bin/build-g++
          ln -s build-g++ ''${out}/bin/build-c++

          # Cross C++ compiler
          cat > ''${out}/bin/g++ <<EOF
          #!${bash}/bin/bash
          exec ${crossGcc}/bin/${target}-g++ ${crossFlagsStr} "\$@"
          EOF
          chmod 555 ''${out}/bin/g++
          ln -s g++ ''${out}/bin/c++
          ln -s g++ ''${out}/bin/${target}-g++
        ''}

        # Symlink cross binutils
        for tool in ${crossBinutils}/bin/${target}-*; do
          name=$(basename "$tool")
          if [ ! -e ''${out}/bin/"$name" ]; then
            ln -s "$tool" ''${out}/bin/"$name"
          fi
        done
      '';
}
