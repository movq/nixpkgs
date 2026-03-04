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
  crossBinutils,
  crossMusl,
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
  pname = "cross-gcc-full";
  version = "15.2.0";
  buildTarget = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  target = "x86_64-unknown-linux-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gcc/gcc-${version}/gcc-${version}.tar.xz";
    hash = "sha256-Q4/ZloJrDIJIWinaA6ctcdbjVBqD7HAt9Ccfb+Al0k4=";
  };

  sarifSpec = fetchurl {
    url = "https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html";
    hash = "sha256-g1pNBD5EFadmaMjzjVYF9Ob4rCJ536t+YcPwbpIo3Rw=";
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
      crossBinutils
      crossMusl
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
      description = "GNU Compiler Collection 15.2.0 full cross compiler (C, C++) for x86_64-unknown-linux-musl";
      homepage = "https://gcc.gnu.org/";
      license = lib.licenses.gpl3Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "${target}-gcc";
    };
  }
  ''
    # Unpack
    ${xz}/bin/unxz -c ${src} | ${gnutar}/bin/tar xf -
    cd gcc-${version}
    chmod -R u+w .
    cp ${./4.7.4/files/decDPD.h.preamble} decDPD.h.preamble
    cp ${./4.7.4/files/decDPD_generate.c} decDPD_generate.c
    cp ${sarifSpec} ../sarif-v2.1.0-errata01-os-complete.html

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

    cat > build-tools/${buildTarget}-gcc <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gcc-for-build" "\$@"
    EOF
    chmod 555 build-tools/${buildTarget}-gcc

    cat > build-tools/${buildTarget}-g++ <<EOF
    #!${bash}/bin/bash
    exec "''${PWD}/gxx-for-build" "\$@"
    EOF
    chmod 555 build-tools/${buildTarget}-g++

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

    export PATH="''${PWD}/build-tools:''${PWD}:${binutils}/bin:${crossBinutils}/bin:$PATH"
    export ACLOCAL_PATH="${libtool}/share/aclocal"
    export CPATH="${zlib}/include"
    export LIBRARY_PATH="${zlib}/lib"

    # Prepare
    rm libsanitizer/include/sanitizer/netbsd_syscall_hooks.h \
      libsanitizer/sanitizer_common/sanitizer_syscalls_netbsd.inc
    rm -r libgfortran/generated
    rm gcc/testsuite/go.test/test/bench/go1/jsondata_test.go \
      gcc/testsuite/go.test/test/bench/go1/parserdata_test.go \
      gcc/testsuite/go.test/test/cmplxdivide1.go \
      gcc/testsuite/go.test/test/fixedbugs/issue6866.go
    rm gcc/testsuite/gcc.target/x86_64/abi/test_3_element_struct_and_unions.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_basic_returning.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_passing_floats.c \
      gcc/testsuite/gcc.target/x86_64/abi/test_passing_integers.c \
      gcc/testsuite/gcc.target/x86_64/abi/avx512fp16/test_passing_floats.c \
      gcc/testsuite/gcc.target/x86_64/abi/avx512fp16/test_basic_returning.c \
      gcc/testsuite/gcc.target/x86_64/abi/avx512fp16/test_3_element_struct_and_unions.c \
      gcc/testsuite/gcc.target/x86_64/abi/bf16/test_passing_floats.c \
      gcc/testsuite/gcc.target/x86_64/abi/bf16/test_3_element_struct_and_unions.c
    rm gcc/testsuite/c-c++-common/analyzer/flex-with-call-summaries.c \
      gcc/testsuite/c-c++-common/analyzer/flex-without-call-summaries.c
    rm gcc/testsuite/gdc.test/compilable/dtoh_windows.d
    rm gcc/testsuite/sarif-replay.dg/2.1.0-valid/malloc-vs-local-4.c.sarif \
      gcc/testsuite/sarif-replay.dg/2.1.0-valid/signal-1.c.sarif

    rm gcc/testsuite/gm2/projects/pim/run/pass/tower/advflex.c \
      gcc/testsuite/gm2/projects/pim/run/pass/tower/AdvParse.mod
    rm -r gcc/testsuite/gdc.test/compilable
    rm gcc/config/rs6000/rs6000-tables.opt \
      gcc/config/rs6000/fusion.md \
      gcc/config/h8300/mova.md \
      gcc/config/aarch64/aarch64-tune.md \
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
      gcc/config/mips/mips-tables.opt \
      gcc/config/nvptx/nvptx-gen.opt \
      gcc/config/nvptx/nvptx-gen.h
    rm libphobos/src/std/internal/unicode_tables.d \
      libphobos/src/std/internal/unicode_decomp.d \
      libphobos/src/std/internal/unicode_grapheme.d \
      libphobos/src/std/internal/unicode_norm.d
    rm libgo/go/math/bits/example_test.go \
      libgo/go/math/bits/bits_tables.go \
      libgo/go/math/big/accuracy_string.go \
      libgo/go/math/big/roundingmode_string.go \
      libgo/go/strconv/isprint.go \
      libgo/go/strconv/eisel_lemire.go \
      libgo/go/sort/zfuncversion.go \
      libgo/go/golang.org/x/net/route/zsys_*.go \
      libgo/go/golang.org/x/net/idna/*.go \
      libgo/go/golang.org/x/text/unicode/bidi/t*.go \
      libgo/go/golang.org/x/text/unicode/norm/tables*.go \
      libgo/go/golang.org/x/tools/internal/typeparams/typeterm.go \
      libgo/go/golang.org/x/tools/internal/typeparams/termlist.go \
      libgo/go/golang.org/x/crypto/curve25519/internal/field/fe_amd64.go \
      libgo/go/internal/syscall/windows/registry/zsyscall_windows.go \
      libgo/go/internal/syscall/windows/zsyscall_windows.go \
      libgo/go/encoding/gob/*_helpers.go \
      libgo/go/index/suffixarray/sais2.go \
      libgo/go/net/http/*_bundle.go \
      libgo/go/runtime/sizeclasses.go \
      libgo/go/runtime/fastlog2table.go \
      libgo/go/html/template/*_string.go \
      libgo/go/crypto/md5/md5block.go \
      libgo/go/crypto/tls/common_string.go \
      libgo/go/crypto/elliptic/internal/fiat/p*.go \
      libgo/go/crypto/ed25519/internal/edwards25519/field/fe_amd64.go \
      libgo/go/time/zoneinfo_abbrs_windows.go \
      libgo/go/unicode/tables.go \
      libgo/go/regexp/syntax/doc.go \
      libgo/go/regexp/syntax/op_string.go \
      libgo/go/regexp/syntax/perl_groups.go \
      libgo/go/image/internal/imageutil/impl.go \
      libgo/go/image/color/palette/palette.go \
      libgo/go/cmd/internal/objabi/*_string.go \
      libgo/go/cmd/go/internal/test/flagdefs.go \
      libgo/go/debug/dwarf/*_string.go \
      libgo/go/debug/macho/reloctype_string.go \
      libgo/go/internal/goexperiment/exp_*.go \
      libgo/go/time/tzdata/zipdata.go \
      libgo/go/go/constant/kind_string.go
    rm libgo/go/compress/bzip2/testdata/*.bin \
      libgo/go/go/internal/gccgoimporter/testdata/v1reflect.gox \
      libgo/go/go/internal/gccgoimporter/testdata/time.gox \
      libgo/go/go/internal/gccgoimporter/testdata/unicode.gox \
      libgo/go/go/internal/gccgoimporter/testdata/escapeinfo.gox \
      libgo/go/go/internal/gccgoimporter/testdata/libimportsar.a \
      libgo/go/go/internal/gcimporter/testdata/versions/*.a
    rm -r libgo/go/compress/*/testdata \
      libgo/go/runtime/pprof/testdata \
      libgo/go/debug/*/testdata \
      libgo/go/internal/trace/testdata \
      libgo/go/time/testdata \
      libgo/go/internal/xcoff/testdata \
      libgo/go/archive/*/testdata
    rm gcc/d/dmd/common/identifiertables.d
    rm -r gcc/rust/checks/errors/borrowck/ffi-polonius/vendor \
      libgrust/libformat_parser/vendor
    ${findutils}/bin/find fixincludes/tests -name "*.h" -delete
    rm gcc/m2/mc/mcp*.bnf
    rm -r gcc/m2/pge-boot \
      gcc/m2/mc-boot
    rm libgcc/config/sh/lib1funcs.S \
      libgcc/config/sh/lib1funcs-4-300.S \
      libgcc/config/arc/lib1funcs.S
    rm -r zlib

    rm gcc/cp/cfns.h gcc/cp/std-name-hint.h
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
        AUTOMAKE=automake-1.15 ACLOCAL=aclocal-1.15 autoreconf-2.69 -fiv
      )
    done

    cp -f ${automake}/share/automake-1.15/depcomp .

    (
      cd gcc/m2/gm2-libs
      autoconf-2.69 -f config-host.in > config-host
    )

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

    rm gcc/cobol/parse.cc gcc/cobol/parse.h
    rm gcc/cobol/cdf.cc gcc/cobol/cdf.h

    rm gcc/gengtype-lex.cc
    rm gcc/cobol/scan.cc

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

    rm gcc/sarif-spec-urls.def
    cp -t contrib ../sarif-v2.1.0-errata01-os-complete.html
    (
      cd contrib
      ${gnused}/bin/sed -i "s/'windows-1252'/'latin-1'/g" regenerate-sarif-spec-index.py
      python3 regenerate-sarif-spec-index.py
    )

    rm gcc/text-art/box-drawing-chars.inc
    python3 contrib/unicode/gen-box-drawing-chars.py > gcc/text-art/box-drawing-chars.inc

    rm libcpp/combining-chars.inc
    python3 contrib/unicode/gen-combining-chars.py > libcpp/combining-chars.inc

    rm libcpp/printable-chars.inc
    python3 contrib/unicode/gen-printable-chars.py > libcpp/printable-chars.inc

    rm libstdc++-v3/include/bits/unicode-data.h
    (
      cd contrib/unicode
      python3 gen_libstdcxx_unicode_data.py > ../../libstdc++-v3/include/bits/unicode-data.h
    )

    (
      cd gcc/config/loongarch
      rm loongarch-evolution.cc loongarch-evolution.h loongarch-str.h loongarch.opt
      ./genopts/genstr.sh evolution_c > loongarch-evolution.cc
      ./genopts/genstr.sh evolution_h > loongarch-evolution.h
      ./genopts/genstr.sh header > loongarch-str.h
      ./genopts/genstr.sh opt > loongarch.opt
    )

    (
      cd gcc/config/gcn
      rm gcn-tables.opt
      ${gawk}/bin/awk -f gen-opt-tables.awk gcn-devices.def > gcn-tables.opt
    )

    ${findutils}/bin/find . -name "*.gmo" -delete
    ${findutils}/bin/find . -name "*.info" -delete
    ${findutils}/bin/find . -type f -name '*.[1-9]' -delete
    rm libiberty/functions.texi
    rm gcc/jit/docs/conf.py
    rm gcc/jit/docs/_build/texinfo/libgccjit.texi \
      gcc/ada/gnat_rm.texi \
      gcc/ada/gnat_ugn.texi

    rm gcc/doc/avr-mmcu.texi
    gcc -o gen-avr-mmcu-texi gcc/config/avr/gen-avr-mmcu-texi.cc
    ./gen-avr-mmcu-texi > gcc/doc/avr-mmcu.texi

    # Configure
    mkdir build
    cd build

    CPPFLAGS="-I${gmp}/include -I${mpfr}/include -I${mpc}/include -I${zlib}/include" \
      LDFLAGS="-static -L${gmp}/lib -L${mpfr}/lib -L${mpc}/lib -L${zlib}/lib" \
      ../configure \
      --prefix=''${out} \
      --libdir=''${out}/lib \
      --build=${buildTarget} \
      --host=${buildTarget} \
      --target=${target} \
      --disable-bootstrap \
      --enable-static \
      --disable-shared \
      --disable-plugins \
      --disable-nls \
      --disable-threads \
      --disable-libssp \
      --disable-libsanitizer \
      --disable-libgomp \
      --disable-libquadmath \
      --disable-libatomic \
      --disable-decimal-float \
      --disable-libmpx \
      --disable-libstdcxx-backtrace \
      --disable-linux-futex \
      --disable-libvtv \
      --disable-libitm \
      --with-gmp=${gmp} \
      --with-mpfr=${mpfr} \
      --with-mpc=${mpc} \
      --with-as=${crossBinutils}/bin/${target}-as \
      --with-ld=${crossBinutils}/bin/${target}-ld \
      --program-transform-name= \
      --enable-languages=c,c++ \
      --with-system-zlib \
      --with-sysroot=${crossMusl} \
      --with-native-system-header-dir=/include \
      --disable-multilib

    # Build
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      STMP_FIXINC= \
      AR_FOR_TARGET=${crossBinutils}/bin/${target}-ar \
      AS_FOR_TARGET=${crossBinutils}/bin/${target}-as \
      LD_FOR_TARGET=${crossBinutils}/bin/${target}-ld \
      NM_FOR_TARGET=${crossBinutils}/bin/${target}-nm \
      RANLIB_FOR_TARGET=${crossBinutils}/bin/${target}-ranlib \
      STRIP_FOR_TARGET=${crossBinutils}/bin/${target}-strip \
      all-gcc all-target-libgcc all-target-libstdc++-v3 \
      MAKEINFO=true

    # Install
    ${gnumake}/bin/make -j "$NIX_BUILD_CORES" \
      STMP_FIXINC= \
      AR_FOR_TARGET=${crossBinutils}/bin/${target}-ar \
      AS_FOR_TARGET=${crossBinutils}/bin/${target}-as \
      LD_FOR_TARGET=${crossBinutils}/bin/${target}-ld \
      NM_FOR_TARGET=${crossBinutils}/bin/${target}-nm \
      RANLIB_FOR_TARGET=${crossBinutils}/bin/${target}-ranlib \
      STRIP_FOR_TARGET=${crossBinutils}/bin/${target}-strip \
      install-gcc install-target-libgcc install-target-libstdc++-v3 \
      MAKEINFO=true

    cd ''${out}/bin
    for f in *; do
      case "$f" in
        ${target}-*)
          base="''${f#${target}-}"
          [ -e "$base" ] || ln -s "''${out}/bin/''${f}" "$base"
          ;;
        *)
          [ -e "${target}-''${f}" ] || ln -s "''${out}/bin/''${f}" "${target}-''${f}"
          ;;
      esac
    done
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
