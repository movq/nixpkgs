{
  lib,
  fetchurl,
  kaem,
  tinycc,
  mes-libc,
  gnupatch,
  buildPlatform,
}:
let
  pname = "tinycc-for-musl-mes";
  version = "0.9.27";

  tccTarget =
    {
      i686-linux = "I386";
      x86_64-linux = "X86_64";
    }
    .${buildPlatform.system};

  tarball = fetchurl {
    url = "https://download.savannah.gnu.org/releases/tinycc/tcc-${version}.tar.bz2";
    hash = "sha256-3iOvePypDOMt/y3UWzQysjNHQLubt7Bb9g/b/Dls65w=";
  };

  patches = [
    ./static-link.patch
    ./ignore-static-inside-array.patch
    ./dont-skip-weak-symbols-ar.patch
  ];

  src =
    (kaem.runCommand "tcc-${version}-for-musl-source" { } ''
      unbz2 --file ${tarball} --output tcc.tar
      mkdir -p ''${out}
      cd ''${out}
      untar --file ''${NIX_BUILD_TOP}/tcc.tar
      cd tcc-${version}
      ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}
    '')
    + "/tcc-${version}";

  meta = {
    description = "TinyCC 0.9.27 with patches needed for early musl builds";
    homepage = "https://www.gnu.org/software/tinycc";
    license = lib.licenses.lgpl21Only;
    teams = [ lib.teams.minimal-bootstrap ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };

  compiler = kaem.runCommand "${pname}-${version}"
    {
      inherit pname version meta;

      passthru.tests.get-version =
        result:
        kaem.runCommand "${pname}-get-version-${version}" { } ''
          ${result}/bin/tcc -version
          mkdir ''${out}
        '';
    }
    ''
      catm config.h
      mkdir -p ''${out}/bin
      mkdir -p ''${out}/lib

      ${tinycc.compiler}/bin/tcc \
        -B ${tinycc.libs}/lib \
        -v \
        -static \
        -o ''${out}/bin/tcc \
        -I . \
        -I ${src} \
        -D TCC_TARGET_${tccTarget}=1 \
        -D CONFIG_TCCDIR=\"\" \
        -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
        -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
        -D CONFIG_TCC_LIBPATHS=\"{B}\" \
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"${mes-libc}/include\" \
        -D TCC_LIBGCC=\"libc.a\" \
        -D TCC_LIBTCC1=\"libtcc1.a\" \
        -D CONFIG_TCCBOOT=1 \
        -D CONFIG_TCC_STATIC=1 \
        -D CONFIG_USE_LIBGCC=1 \
        -D TCC_MES_LIBC=1 \
        -D TCC_VERSION=\"${version}\" \
        -D ONE_SOURCE=1 \
        ${src}/tcc.c

      ${tinycc.compiler}/bin/tcc \
        -B ${tinycc.libs}/lib \
        -c \
        -D HAVE_CONFIG_H=1 \
        ${src}/lib/libtcc1.c
      ${tinycc.compiler}/bin/tcc \
        -ar cr \
        ''${out}/lib/libtcc1.a \
        libtcc1.o
    '';

  libs = kaem.runCommand "${pname}-libs-${version}" { } ''
    mkdir -p ''${out}/lib
    cp ${tinycc.libs}/lib/crt1.o ''${out}/lib/crt1.o
    cp ${tinycc.libs}/lib/crtn.o ''${out}/lib/crtn.o
    cp ${tinycc.libs}/lib/crti.o ''${out}/lib/crti.o
    cp ${tinycc.libs}/lib/libc.a ''${out}/lib/libc.a
    cp ${tinycc.libs}/lib/libgetopt.a ''${out}/lib/libgetopt.a
    cp ${compiler}/lib/libtcc1.a ''${out}/lib/libtcc1.a
  '';
in
{
  inherit compiler libs;
  prev = tinycc;
}
