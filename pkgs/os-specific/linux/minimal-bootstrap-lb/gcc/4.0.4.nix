{
  lib,
  fetchurl,
  bash,
  buildPlatform,
  coreutils,
  diffutils,
  tinycc,
  musl,
  binutils,
  gnumake,
  gnutar,
  bzip2,
  gnused,
  grep,
  gawk,
  flex,
  bison,
  m4,
  perl,
  autoconf,
  automake19,
  automake10,
  libtool,
}:
let
  pname = "gcc";
  version = "4.0.4";
  target = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.kernel.name}-musl";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/gcc/gcc-${version}/gcc-core-${version}.tar.bz2";
    hash = "sha256-6b9Yx2Gk+YgxGu9rQfEv1cflHQlHdGj7c4Jq7MG+Muc=";
  };

  automakeSrc = fetchurl {
    url = "https://mirrors.kernel.org/gnu/automake/automake-1.16.3.tar.xz";
    hash = "sha256-/yv3ZWxNHG/do7i+uyHwkVOnNry6FpqvZeqyX6ETvzo=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      diffutils
      tinycc.compiler
      binutils
      gnumake
      gnutar
      bzip2
      gnused
      grep
      gawk
      flex
      bison
      m4
      perl
      autoconf
      automake19
      automake10
      libtool
    ];

    meta = {
      description = "GNU Compiler Collection";
      homepage = "https://gcc.gnu.org/";
      license = lib.licenses.gpl2Plus;
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
      mainProgram = "gcc";
    };
  }
  ''
    # Unpack
    cp ${src} gcc-core.tar.bz2
    ${bzip2}/bin/bzip2 -d -f gcc-core.tar.bz2
    ${gnutar}/bin/tar xf gcc-core.tar
    rm gcc-core.tar

    unxz --file ${automakeSrc} | ${gnutar}/bin/tar xf -

    cd gcc-${version}

    mkdir -p bootstrap-lib
    cp ${musl}/lib/* bootstrap-lib/
    cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

    cat > tcc <<EOF
    #!${bash}/bin/bash
    exec ${tinycc.compiler}/bin/tcc -B "''${PWD}/bootstrap-lib" "\$@"
    EOF
    chmod 555 tcc
    export PATH="''${PWD}:$PATH"

    # Prepare
    ${gnused}/bin/sed -i 's/ix86_attribute_table\[\]/ix86_attribute_table[10]/' gcc/config/i386/i386.c
    ${gnused}/bin/sed -i 's/struct siginfo/siginfo_t/' gcc/config/i386/linux-unwind.h
    for script in move-if-change mkinstalldirs install-sh; do
      if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^#! */bin/sh$'; then
        ${gnused}/bin/sed -i "1s|^#! */bin/sh$|#! ${bash}/bin/bash|" "$script"
        chmod +x "$script"
      fi
    done

    rm configure Makefile.in fixincludes/fixincl.x

    for dir in intl libcpp; do
      (
        cd "''${dir}"
        rm aclocal.m4
        AUTOM4TE=autom4te-2.61 aclocal-1.9 --acdir=../config
      )
    done

    for dir in fixincludes gcc intl libcpp libiberty; do
      (
        cd "''${dir}"
        rm configure
        autoconf-2.61
      )
    done

    (
      cd libmudflap
      AUTOMAKE=automake-1.10 ACLOCAL=aclocal-1.10 AUTOM4TE=autom4te-2.61 autoreconf-2.61 -f
    )

    for dir in fixincludes intl libmudflap; do
      (
        cd "''${dir}"
        rm -f config.in
        autoheader-2.61
      )
    done

    rm config.guess config.sub ltmain.sh
    libtoolize
    cp ../automake-1.16.3/lib/config.sub .

    rm gcc/c-parse.y libiberty/functions.texi
    rm libiberty/obstacks.texi
    touch libiberty/obstacks.texi

    rm libcpp/ucnid.h
    ${perl}/bin/perl libcpp/ucnid.pl < libcpp/ucnid.tab > libcpp/ucnid.h

    ${gnused}/bin/sed -i 's/YYLEX/yylex()/' gcc/c-parse.in
    rm gcc/c-parse.c
    rm gcc/gengtype-yacc.c gcc/gengtype-yacc.h
    rm intl/plural.c

    rm gcc/gengtype-lex.c

    rm -f gcc/po/*.gmo libcpp/po/*.gmo

    rm -f gcc/doc/*.info
    rm -f gcc/doc/*.1 gcc/doc/*.7

    # Configure
    mkdir build
    cd build

    for dir in libiberty libcpp gcc; do
      mkdir "''${dir}"
      (
        cd "''${dir}"
        CC=tcc \
          CFLAGS="-D HAVE_ALLOCA_H" \
          ../../''${dir}/configure \
            --prefix=''${out} \
            --libdir=''${out}/lib \
            --build=${target} \
            --target=${target} \
            --host=${target} \
            --disable-shared \
            --program-transform-name=
      )
    done
    cd ..

    ${gnused}/bin/sed -i 's/C_alloca/alloca/g' libiberty/alloca.c
    ${gnused}/bin/sed -i 's/C_alloca/alloca/g' include/libiberty.h

    # Build
    ln -s . "build/build-${target}"
    mkdir -p build/gcc/include
    ln -s ../../../gcc/gsyslimits.h build/gcc/include/syslimits.h

    ${gnumake}/bin/make -j1 -C build/gcc gengtype-yacc.c MAKEINFO=true build_tooldir=${musl}

    for dir in libiberty libcpp; do
      ${gnumake}/bin/make -j1 -C "build/''${dir}" \
        LIBGCC2_INCLUDES=-I${musl}/include \
        STMP_FIXINC= \
        MAKEINFO=true
    done

    ${gnumake}/bin/make -j1 -C build/gcc \
      LIBGCC2_INCLUDES=-I${musl}/include \
      STMP_FIXINC= \
      MAKEINFO=true \
      build_tooldir=${musl}

    # Install
    mkdir -p ''${out}/lib/gcc/${target}/${version}/install-tools/include
    ${gnumake}/bin/make -C build/gcc install STMP_FIXINC= MAKEINFO=true build_tooldir=${musl}

    mkdir -p ''${out}/lib/gcc/${target}/${version}/include
    rm -f ''${out}/lib/gcc/${target}/${version}/include/syslimits.h
    cp gcc/gsyslimits.h ''${out}/lib/gcc/${target}/${version}/include/syslimits.h
  ''
