{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  gcc,
  musl,
  binutils,
  gnumake,
  gnupatch,
  gnutar,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  flex,
  bison,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
  autogen,
  zlib,
}:
let
  pname = "binutils";
  version = "2.41";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz";
    hash = "sha256-rppXieI0WeWWBuZxRyPy0//DHAMXQZHvDQFb3wYAdFA=";
  };
in
bash.runCommand "${pname}-${version}-pass2"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      gcc
      musl
      binutils
      gnumake
      gnupatch
      gnutar
      xz
      findutils
      gnused
      grep
      gawk
      flex
      bison
      m4
      perl
      autoconf
      automake
      libtool
      autogen
      zlib
    ];

    meta = {
      description = "Tools for manipulating binaries (linker, assembler, etc.)";
      homepage = "https://www.gnu.org/software/binutils/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "ld";
    };
  }
  ''
    # Unpack
    ${xz}/bin/unxz -c ${src} | ${gnutar}/bin/tar xf -
    for patch in ${./2.41/patches}/*.patch; do
      ${gnupatch}/bin/patch -Np0 -i "$patch"
    done
    cd binutils-${version}

    cat > gcc-for-build <<EOF
    #!${bash}/bin/bash
    exec ${gcc}/bin/gcc \
      --sysroot=${musl} \
      -isystem ${zlib}/include \
      -B ${musl}/lib \
      -L ${zlib}/lib \
      -L ${musl}/lib \
      -Wl,--dynamic-linker=${musl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${musl}/lib \
      "\$@"
    EOF
    chmod 555 gcc-for-build

    cat > gxx-for-build <<EOF
    #!${bash}/bin/bash
    exec ${gcc}/bin/g++ \
      --sysroot=${musl} \
      -isystem ${zlib}/include \
      -B ${musl}/lib \
      -L ${zlib}/lib \
      -L ${musl}/lib \
      -Wl,--dynamic-linker=${musl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${musl}/lib \
      "\$@"
    EOF
    chmod 555 gxx-for-build

    cat > gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 gcc

    cat > g++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 g++

    cat > cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 cc

    cat > c++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 c++

    cat > flex <<EOF
    #!${bash}/bin/bash
    exec ${flex}/bin/flex-2.5.33 "\$@"
    EOF
    chmod 555 flex

    cat > bison <<EOF
    #!${bash}/bin/bash
    exec ${bison}/bin/bison "\$@"
    EOF
    chmod 555 bison

    cat > yacc <<EOF
    #!${bash}/bin/bash
    exec ${bison}/bin/bison -y "\$@"
    EOF
    chmod 555 yacc

    export PATH="''${PWD}:${binutils}/bin:$PATH"
    export ACLOCAL_PATH="${libtool}/share/aclocal"

    # Prepare
    rm etc/Makefile.in etc/configure
    rm -r zlib

    ${gnused}/bin/sed -i 's/@USE_INCLUDED_LIBINTL@/no/' intl/Makefile.in

    for mk in bfd binutils opcodes ld libctf gas gprof; do
      ${gnused}/bin/sed -i 's:\(--mode=link $(CCLD)\):\1 -all-static:' "$mk/Makefile.in"
    done

    touch -- */*.y
    rm binutils/arparse.c binutils/arparse.h binutils/defparse.c \
      binutils/defparse.h binutils/mcparse.c binutils/mcparse.h \
      binutils/rcparse.c binutils/rcparse.h binutils/sysinfo.c \
      binutils/sysinfo.h gas/config/bfin-parse.c gas/config/bfin-parse.h \
      gas/config/loongarch-parse.c gas/config/loongarch-parse.h \
      gas/config/m68k-parse.c gas/config/rl78-parse.c \
      gas/config/rl78-parse.h gas/config/rx-parse.c gas/config/rx-parse.h \
      gas/itbl-parse.c gas/itbl-parse.h gold/yyscript.c gold/yyscript.h \
      intl/plural.c ld/deffilep.c ld/deffilep.h ld/ldgram.c ld/ldgram.h

    touch -- */*.l */*/*.l
    rm binutils/arlex.c binutils/deflex.c binutils/syslex.c \
      gas/config/bfin-lex.c gas/config/loongarch-lex.c gas/itbl-lex.c \
      ld/ldlex.c

    ${findutils}/bin/find . -type f -name '*.info*' \
      -not -wholename './binutils/sysroff.info' -delete
    ${findutils}/bin/find . -type f \( -name '*.1' -or -name '*.man' \) -delete
    rm libiberty/functions.texi

    ${findutils}/bin/find . -type f -name '*.gmo' -delete

    for tmpl in $(${findutils}/bin/find . -type f -path '*/po/Make-in'); do
      ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" "$tmpl"
    done

    rm opcodes/i386-init.h opcodes/i386-tbl.h opcodes/i386-mnem.h \
      opcodes/ia64-asmtab.c opcodes/z8k-opc.h opcodes/aarch64-asm-2.c \
      opcodes/aarch64-opc-2.c opcodes/aarch64-dis-2.c \
      opcodes/msp430-decode.c opcodes/rl78-decode.c opcodes/rx-decode.c
    rm $(${grep}/bin/grep -l 'MACHINE GENERATED' opcodes/*.c opcodes/*.h)

    rm ld/emultempl/*.o_c
    rm gprof/bsd_callg_bl.c gprof/flat_bl.c gprof/fsf_callg_bl.c
    rm bfd/libcoff.h bfd/libbfd.h bfd/go32stub.h bfd/bfd-in2.h

    rm libsframe/testsuite/libsframe.decode/DATA* \
      ld/testsuite/ld-x86-64/*.obj.bz2 ld/testsuite/ld-sh/arch/*.s \
      ld/testsuite/ld-sh/arch/arch_expected.txt \
      ld/testsuite/ld-i386/pr27193a.o.bz2 \
      gas/testsuite/gas/xstormy16/allinsn.sh \
      gas/testsuite/gas/tic4x/opcodes.s gas/testsuite/gas/sh/arch/*.s \
      gas/testsuite/gas/sh/arch/arch_expected.txt \
      binutils/testsuite/binutils-all/x86-64/pr22451.o.bz2 \
      binutils/testsuite/binutils-all/x86-64/pr26808.dwp.bz2 \
      binutils/testsuite/binutils-all/x86-64/pr27708.exe.bz2 \
      binutils/testsuite/binutils-all/nfp/*.nffw \
      binutils/testsuite/binutils-all/pr26112.o.bz2 \
      binutils/testsuite/binutils-all/pr26160.dwp.bz2

    (
      cd libiberty
      ${gnused}/bin/sed -n '/^   #include <stdio.h>/,/^   \}$/p' crc32.c > crcgen.c
      cc -o crcgen crcgen.c
      ${gnused}/bin/sed '/crc_v3\.txt/{n; q}' crc32.c > crc32.c.new
      ./crcgen >> crc32.c.new
      ${gnused}/bin/sed '1,/^};$/d' crc32.c >> crc32.c.new
      mv crc32.c.new crc32.c
    )

    (
      cd bfd
      cp configure.ac configure.ac.bak
      ${gnused}/bin/sed -i "s/bfd-in3.h:bfd-in2.h //" configure.ac
      AUTOPOINT=true \
        ACLOCAL=aclocal-1.15 \
        AUTOMAKE=automake-1.15 \
        autoreconf-2.69 -fi
      CC=cc \
        CXX=c++ \
        CPP="cc -E" \
        CXXCPP="c++ -E" \
        CPPFLAGS="-I${zlib}/include" \
        LDFLAGS="-L${zlib}/lib" \
        ./configure \
        --build=${target} \
        --host=${target} \
        --target=${target}
      ${gnumake}/bin/make headers
      mv configure.ac.bak configure.ac
      ${gnumake}/bin/make distclean
    )

    ${autogen}/bin/autogen Makefile.def
    ACLOCAL=aclocal-1.15 AUTOPOINT=true autoreconf-2.69 -fi

    for dir in bfd binutils gas gold gprof intl ld libctf libiberty libsframe opcodes; do
      (
        cd "$dir"
        ACLOCAL=aclocal-1.15 \
          AUTOMAKE=automake-1.15 \
          AUTOPOINT=true \
          autoreconf-2.69 -fi
      )
    done
    (
      cd gprofng
      LIBTOOLIZE=true \
        ACLOCAL=aclocal-1.15 \
        AUTOMAKE=automake-1.15 \
        AUTOPOINT=true \
        autoreconf-2.69 -fi
    )

    (
      cd libiberty
      CC=cc ./configure --enable-maintainer-mode
      ${gnumake}/bin/make maint-deps
      ${gnumake}/bin/make distclean
    )

    ${perl}/bin/perl ./bfd/mep-relocs.pl

    # Configure
    mkdir build
    cd build

    CC=cc \
      CXX=c++ \
      CPP="cc -E" \
      CXXCPP="c++ -E" \
      CPPFLAGS="-I${zlib}/include" \
      LDFLAGS="-static -L${zlib}/lib" \
      ../configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --build=${target} \
      --host=${target} \
      --target=${target} \
      --enable-static \
      --disable-nls \
      --disable-multilib \
      --disable-plugins \
      --disable-gprofng \
      --enable-threads \
      --enable-64-bit-bfd \
      --enable-gold \
      --enable-ld=default \
      --enable-install-libiberty \
      --enable-deterministic-archives \
      --with-system-zlib \
      --program-prefix="" \
      --with-sysroot= \
      --srcdir=..

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" MAKEINFO=true install

    cd ''${out}/bin
    for f in *; do
      ln -s "''${out}/bin/''${f}" "${target}-''${f}"
    done

    rm -rf ''${out}/share/man
    # Strip debug symbols from toolchain artifacts to keep bootstrap outputs small.
    shopt -s nullglob globstar
    for f in ''${out}/bin/**/* ''${out}/lib/**/* ''${out}/libexec/**/*; do
      [ -f "$f" ] || continue
      if command -v strip >/dev/null 2>&1; then
        strip --strip-debug "$f" 2>/dev/null || true
      fi
      if command -v ${target}-strip >/dev/null 2>&1; then
        ${target}-strip --strip-debug "$f" 2>/dev/null || true
      fi
    done
  ''
