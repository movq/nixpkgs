{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  cc,
  gnumake,
  gnupatch,
  gnutar,
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
}:
let
  pname = "binutils";
  version = "2.30";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";
  gnuTarget = lib.replaceStrings [ "-musl" ] [ "-gnu" ] target;

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/binutils/binutils-${version}.tar.xz";
    hash = "sha256-bka4rq4vcno28L2VBeQFdopyIY8XlvDQl1fUUgmHGuY=";
  };

  patches = [
    ./patches/libiberty-add-missing-config-directory-reference.patch
    ./patches/new-gettext.patch
    ./patches/opcodes-ensure-i386-init-dependencies-are-satisfied.patch
  ];
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      cc
      gnumake
      gnupatch
      gnutar
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
    unxz --file ${src} | ${gnutar}/bin/tar xf -
    ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np0 -i ${f}") patches}
    cd binutils-${version}

    # Prepare
    rm etc/Makefile.in etc/configure

    touch -- */*.y
    rm binutils/arparse.c binutils/arparse.h binutils/defparse.c \
      binutils/defparse.h binutils/mcparse.c binutils/mcparse.h \
      binutils/nlmheader.c binutils/rcparse.c binutils/rcparse.h \
      binutils/sysinfo.c binutils/sysinfo.h gas/bfin-parse.c \
      gas/bfin-parse.h gas/m68k-parse.c gas/rl78-parse.c gas/rl78-parse.h \
      gas/rx-parse.c gas/rx-parse.h gas/itbl-parse.c gas/itbl-parse.h \
      gold/yyscript.c gold/yyscript.h intl/plural.c ld/deffilep.c \
      ld/deffilep.h ld/ldgram.c ld/ldgram.h

    touch -- */*.l */*/*.l
    rm binutils/arlex.c binutils/deflex.c binutils/syslex.c gas/bfin-lex.c \
      gas/itbl-lex.c ld/ldlex.c

    rm bfd/doc/bfd.info binutils/doc/binutils.info
    rm gas/doc/as.info gprof/gprof.info ld/ld.info
    rm */*.1 */*/*.1 */*/*.man
    rm libiberty/functions.texi

    rm -f */po/*.gmo

    rm opcodes/i386-init.h opcodes/i386-tbl.h opcodes/ia64-asmtab.c \
      opcodes/z8k-opc.h opcodes/aarch64-asm-2.c opcodes/aarch64-opc-2.c \
      opcodes/aarch64-dis-2.c
    rm $(${grep}/bin/grep -l 'MACHINE GENERATED' opcodes/*.c opcodes/*.h)
    rm include/opcode/riscv-opc.h

    rm bfd/go32stub.h bfd/libbfd.h bfd/bfd-in2.h bfd/libcoff.h \
      ld/emultempl/spu_icache.o_c ld/emultempl/spu_ovl.o_c \
      gprof/fsf_callg_bl.c gprof/bsd_callg_bl.c gprof/flat_bl.c

    rm gas/testsuite/gas/sh/arch/*.s \
      gas/testsuite/gas/sh/arch/arch_expected.txt \
      ld/testsuite/ld-sh/arch/*.s \
      ld/testsuite/ld-sh/arch/arch_expected.txt \
      ld/testsuite/ld-versados/*.ro \
      gas/testsuite/gas/xstormy16/allinsn.sh \
      gas/testsuite/gas/tic4x/opcodes.s \
      binutils/testsuite/binutils-all/x86-64/pr22451.o.bz2

    rm zlib/contrib/masmx86/*.obj \
      zlib/contrib/infback9/inffix9.h \
      zlib/contrib/blast/test.pk \
      zlib/contrib/puff/zeros.raw \
      zlib/contrib/dotzlib/DotZLib.chm \
      zlib/crc32.h zlib/inffixed.h

    (
      cd libiberty
      ${gnused}/bin/sed -n '/^   #include <stdio.h>/,/^   \}$/p' crc32.c > crcgen.c
      tcc -o crcgen crcgen.c
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
        ACLOCAL=aclocal-1.11 \
        AUTOMAKE=automake-1.11 \
        autoreconf-2.64 -fi
      CC=tcc \
        LD=true \
        ./configure \
          --build=${gnuTarget} \
          --host=${gnuTarget} \
          --target=${gnuTarget}
      ${gnumake}/bin/make headers
      mv configure.ac.bak configure.ac
      ${gnumake}/bin/make clean
    )

    for dir in bfd binutils gas gprof gold intl ld libiberty opcodes zlib; do
      (
        cd "''${dir}"
        AUTOPOINT=true \
          ACLOCAL=aclocal-1.11 \
          AUTOMAKE=automake-1.11 \
          autoreconf-2.64 -fi
      )
    done
    rm Makefile.in
    ACLOCAL=aclocal-1.11 autoreconf-2.64 -fi

    for dir in bfd binutils gas gprof gold ld opcodes; do
      makeIn="''${dir}/po/Make-in"
      if [ -f "''${makeIn}" ]; then
        ${gnused}/bin/sed -i "s|^SHELL = /bin/sh$|SHELL = ${bash}/bin/bash|" "''${makeIn}"
      fi
    done

    (
      cd libiberty
      CC=tcc ./configure --enable-maintainer-mode
      ${gnumake}/bin/make maint-deps
      ${gnumake}/bin/make clean
    )

    ${perl}/bin/perl ./bfd/mep-relocs.pl

    # Configure
    for dir in intl libiberty opcodes bfd binutils gas gprof ld zlib; do
      (
        cd "''${dir}"
        LD=true \
          AR=ar \
          CC=tcc \
          CFLAGS="-DBUILDFIXED=1 -DDYNAMIC_CRC_TABLE=1" \
          ./configure \
            --disable-nls \
            --enable-deterministic-archives \
            --enable-64-bit-bfd \
            --build=${gnuTarget} \
            --host=${gnuTarget} \
            --target=${gnuTarget} \
            --program-prefix="" \
            --prefix=''${out} \
            --libdir=''${out}/lib \
            --with-sysroot= \
            --srcdir=. \
            --enable-compressed-debug-sections=all \
            lt_cv_sys_max_cmd_len=32768
      )
    done

    # Build
    ${gnumake}/bin/make -C bfd headers
    for dir in libiberty zlib bfd opcodes binutils gas gprof ld; do
      ${gnumake}/bin/make -j1 -C "''${dir}" \
        tooldir=''${out} \
        CPPFLAGS="-DPLUGIN_LITTLE_ENDIAN" \
        MAKEINFO=true
    done

    # Install
    for dir in libiberty zlib bfd opcodes binutils gas gprof ld; do
      ${gnumake}/bin/make -C "''${dir}" \
        tooldir=''${out} \
        install \
        MAKEINFO=true
    done

    cd ''${out}/bin
    for f in *; do
      ln -s "''${out}/bin/''${f}" "${target}-''${f}"
    done
  ''
