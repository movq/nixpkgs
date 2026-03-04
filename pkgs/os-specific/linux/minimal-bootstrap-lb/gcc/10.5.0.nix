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
  gzip,
  xz,
  findutils,
  gnused,
  grep,
  gawk,
  m4,
  perl,
  autoconf,
  automake,
  libtool,
  flex,
  bison,
  gperf,
  texinfo,
  autogen,
  python,
  gmp,
  mpfr,
  mpc,
  zlib,
}:
let
  pname = "gcc";
  version = "10.5.0";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gcc/gcc-${version}/gcc-${version}.tar.xz";
    hash = "sha256-JRCVQ/30bzl8NHtdi3osflaUpaUczkucbh6opxyjB8E=";
  };
in
bash.runCommand "${pname}-${version}"
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
      gzip
      xz
      findutils
      gnused
      grep
      gawk
      m4
      perl
      autoconf
      automake
      libtool
      flex
      bison
      gperf
      texinfo
      autogen
      python
      gmp
      mpfr
      mpc
      zlib
    ];

    meta = {
      description = "GNU Compiler Collection 10.5.0 rebuilt from regenerated sources";
      homepage = "https://gcc.gnu.org/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gcc";
    };
  }
  ''
    # Unpack
    ${xz}/bin/unxz -c ${src} | ${gnutar}/bin/tar xf -

    for patch in ${./10.5.0/patches}/*.patch; do
      ${gnupatch}/bin/patch -Np0 -i "$patch"
    done

    cd gcc-${version}
    chmod -R u+w .
    cp ${./4.7.4/files/decDPD.h.preamble} decDPD.h.preamble
    cp ${./4.7.4/files/decDPD_generate.c} decDPD_generate.c

    cat > gcc-for-build <<EOF
    #!${bash}/bin/bash
    exec ${gcc}/bin/gcc \
      -isystem ${musl}/include \
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
      -isystem ${musl}/include \
      -isystem ${zlib}/include \
      -B ${musl}/lib \
      -L ${zlib}/lib \
      -L ${musl}/lib \
      -Wl,--dynamic-linker=${musl}/lib/ld-musl-i386.so.1 \
      -Wl,-rpath,${musl}/lib \
      "\$@"
    EOF
    chmod 555 gxx-for-build

    mkdir -p build-tools

    cat > build-tools/gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 build-tools/gcc

    cat > build-tools/g++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 build-tools/g++

    cat > build-tools/${target}-gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 build-tools/${target}-gcc

    cat > build-tools/${target}-g++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 build-tools/${target}-g++

    cat > build-tools/cc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 build-tools/cc

    cat > build-tools/c++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 build-tools/c++

    cat > build-tools/flex <<EOF
    #!${bash}/bin/bash
    exec ${flex}/bin/flex-2.5.33 "\$@"
    EOF
    chmod 555 build-tools/flex

    cat > build-tools/bison <<EOF
    #!${bash}/bin/bash
    exec ${bison}/bin/bison "\$@"
    EOF
    chmod 555 build-tools/bison

    cat > build-tools/yacc <<EOF
    #!${bash}/bin/bash
    exec ${bison}/bin/yacc "\$@"
    EOF
    chmod 555 build-tools/yacc

    export PATH="''${PWD}/build-tools:''${PWD}:${binutils}/bin:$PATH"
    export ACLOCAL_PATH="${libtool}/share/aclocal"

    # Prepare
    rm libsanitizer/include/sanitizer/netbsd_syscall_hooks.h \
      libsanitizer/sanitizer_common/sanitizer_syscalls_netbsd.inc
    rm -r libgfortran/generated
    rm gcc/testsuite/go.test/test/bench/go1/jsondata_test.go \
      gcc/testsuite/go.test/test/bench/go1/parserdata_test.go \
      gcc/testsuite/go.test/test/bench/shootout/mandelbrot.txt
    rm gcc/testsuite/go.test/test/cmplxdivide1.go
    rm gcc/testsuite/gcc.target/x86_64/abi/test_3_element_struct_and_unions.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_basic_returning.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_passing_floats.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_passing_integers.c
    rm gcc/config/rs6000/rs6000-tables.opt \
      gcc/config/h8300/mova.md \
      gcc/config/aarch64/aarch64-tune.md \
      gcc/config/nios2/ldstwm.md \
      gcc/config/riscv/t-elf-multilib \
      gcc/config/riscv/t-linux-multilib \
      gcc/config/arm/arm-tune.md \
      gcc/config/arm/arm-tables.opt \
      gcc/config/arm/ldmstm.md \
      gcc/config/arc/t-multilib \
      gcc/config/m68k/m68k-tables.opt \
      gcc/config/c6x/c6x-mult.md \
      gcc/config/c6x/c6x-tables.opt \
      gcc/config/c6x/c6x-sched.md \
      gcc/config/csky/csky_tables.opt \
      gcc/config/mips/mips-tables.opt
    rm libphobos/src/std/internal/unicode_tables.d
    rm libgo/go/math/bits/example_test.go \
      libgo/go/math/bits/bits_tables.go \
      libgo/go/math/big/accuracy_string.go \
      libgo/go/math/big/roundingmode_string.go \
      libgo/go/strconv/isprint.go \
      libgo/go/sort/zfuncversion.go \
      libgo/go/golang.org/x/net/route/zsys_*.go \
      libgo/go/golang.org/x/net/idna/*.go \
      libgo/go/golang.org/x/text/unicode/bidi/t*.go \
      libgo/go/golang.org/x/text/unicode/norm/tables*.go \
      libgo/go/internal/syscall/windows/registry/zsyscall_windows.go \
      libgo/go/internal/syscall/windows/zsyscall_windows.go \
      libgo/go/encoding/gob/*_helpers.go \
      libgo/go/index/suffixarray/sais2.go \
      libgo/go/net/http/*_bundle.go \
      libgo/go/runtime/sizeclasses.go \
      libgo/go/runtime/fastlog2table.go \
      libgo/go/html/template/*_string.go \
      libgo/go/crypto/x509/root_darwin_armx.go \
      libgo/go/crypto/md5/md5block.go \
      libgo/go/time/zoneinfo_abbrs_windows.go \
      libgo/go/unicode/tables.go \
      libgo/go/regexp/syntax/doc.go \
      libgo/go/regexp/syntax/op_string.go \
      libgo/go/regexp/syntax/perl_groups.go \
      libgo/go/image/internal/imageutil/impl.go \
      libgo/go/image/color/palette/palette.go \
      libgo/go/cmd/internal/objabi/*_string.go \
      libgo/go/debug/dwarf/*_string.go \
      libgo/go/debug/macho/reloctype_string.go
    rm libgo/go/internal/xcoff/testdata/bigar* \
      libgo/go/internal/xcoff/testdata/gcc* \
      libgo/go/internal/trace/testdata/* \
      libgo/go/compress/bzip2/testdata/*.bin \
      libgo/go/go/internal/gccgoimporter/testdata/v1reflect.gox \
      libgo/go/go/internal/gccgoimporter/testdata/time.gox \
      libgo/go/go/internal/gccgoimporter/testdata/unicode.gox \
      libgo/go/go/internal/gccgoimporter/testdata/escapeinfo.gox \
      libgo/go/go/internal/gccgoimporter/testdata/libimportsar.a \
      libgo/go/go/internal/gcimporter/testdata/versions/*.a
    rm -r libgo/go/compress/flate/testdata \
      libgo/go/runtime/pprof/testdata \
      libgo/go/debug/*/testdata
    ${findutils}/bin/find fixincludes/tests -name "*.h" -delete
    rm libgcc/config/sh/lib1funcs.S \
      libgcc/config/sh/lib1funcs-4-300.S \
      libgcc/config/arc/lib1funcs.S
    rm -r zlib

    rm gcc/cp/cfns.h
    gperf -o -C -E -k '1-6,$' -j1 -D -N 'libc_name_p' -L C++ \
      gcc/cp/cfns.gperf --output-file gcc/cp/cfns.h

    ${findutils}/bin/find . -type f -exec ${grep}/bin/grep -l '^#! */bin/sh' {} + | while IFS= read -r script; do
      ${gnused}/bin/sed -i "1s|^#! */bin/sh\\(.*\\)$|#! ${bash}/bin/bash\\1|" "$script"
      chmod 755 "$script"
    done
    ${gnused}/bin/sed -i "s|^SHELL=/bin/sh$|SHELL=${bash}/bin/bash|" fixincludes/genfixes

    rm Makefile.in fixincludes/fixincl.x
    autogen Makefile.def
    (
      cd fixincludes
      ./genfixes
    )

    ${findutils}/bin/find . -name configure | ${gnused}/bin/sed 's:/configure::' | while read -r d; do
      (
        cd "$d"
        rm -f configure
        AUTOMAKE=automake-1.15 ACLOCAL=aclocal-1.15 AUTOPOINT=true autoreconf-2.69 -fiv
      )
    done

    cp -f ${automake}/share/automake-1.15/depcomp .
    back="$PWD"
    ${findutils}/bin/find . -type d \
      -exec test -e "{}/Makefile.am" -a ! -e "{}/configure" \; \
      -print | while read -r d; do
      d="$(${coreutils}/bin/readlink -f "$d")"
      cd "$d"
      while [ ! -e configure ]; do
        cd ..
      done
      automake-1.15 -fai "$d/Makefile"
      cd "$back"
    done

    rm intl/plural.c
    rm gcc/gengtype-lex.c

    ${gnused}/bin/sed -i 's/@USE_INCLUDED_LIBINTL@/no/' intl/Makefile.in

    (
      cd libiberty
      ${gnused}/bin/sed -n '/^   #include <stdio.h>/,/^   \}$/p' crc32.c > crcgen.c
      gcc -o crcgen crcgen.c
      ${gnused}/bin/sed '/crc_v3\.txt/{n; q}' crc32.c > crc32.c.new
      ./crcgen >> crc32.c.new
      ${gnused}/bin/sed '1,/^};$/d' crc32.c >> crc32.c.new
      mv crc32.c.new crc32.c
    )

    rm libdecnumber/decDPD.h
    gcc -std=c99 -o decDPD_generate decDPD_generate.c
    cp decDPD.h.preamble libdecnumber/decDPD.h
    chmod u+w libdecnumber/decDPD.h
    ./decDPD_generate >> libdecnumber/decDPD.h

    ${findutils}/bin/find . -name "*.gmo" -delete
    ${findutils}/bin/find . -name "*.info" -delete
    ${findutils}/bin/find . -type f -name '*.[1-9]' -delete
    rm libiberty/functions.texi
    rm gcc/jit/docs/conf.py
    rm gcc/jit/docs/_build/texinfo/libgccjit.texi \
      gcc/ada/gnat_rm.texi \
      gcc/ada/gnat_ugn.texi

    rm gcc/doc/avr-mmcu.texi
    gcc -o gen-avr-mmcu-texi gcc/config/avr/gen-avr-mmcu-texi.c
    ./gen-avr-mmcu-texi > gcc/doc/avr-mmcu.texi

    # Configure
    mkdir build
    cd build

    CPPFLAGS="-I${gmp}/include -I${mpfr}/include -I${mpc}/include -I${zlib}/include" \
      CFLAGS="-std=gnu11" \
      LDFLAGS="-static -L${gmp}/lib -L${mpfr}/lib -L${mpc}/lib -L${zlib}/lib" \
      ../configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --build=${target} \
      --target=${target} \
      --host=${target} \
      --disable-bootstrap \
      --enable-static \
      --program-transform-name= \
      --enable-languages=c,c++ \
      --with-system-zlib \
      --with-gmp=${gmp} \
      --with-mpfr=${mpfr} \
      --with-mpc=${mpc} \
      --with-sysroot=${musl} \
      --with-build-sysroot=${musl} \
      --with-native-system-header-dir=/include \
      --disable-sjlj-exceptions \
      --disable-multilib \
      --enable-threads=posix \
      --disable-libsanitizer \
      --disable-libssp

    # Build
    targetLdflags="-Wl,--dynamic-linker=${musl}/lib/ld-musl-i386.so.1 -Wl,-rpath,${musl}/lib"
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      STMP_FIXINC= \
      LDFLAGS_FOR_TARGET="$targetLdflags" \
      CFLAGS_FOR_TARGET="-O2" \
      MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" install \
      STMP_FIXINC= \
      LDFLAGS_FOR_TARGET="$targetLdflags" \
      CFLAGS_FOR_TARGET="-O2" \
      MAKEINFO=true
    ln -s gcc ''${out}/bin/cc
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
