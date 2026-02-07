{
  lib,
  fetchurl,
  bash,
  tinycc,
  musl,
  gnupatch,
  buildPlatform,
}:
let
  pname = "tinycc-musl";
  version = "0.9.27";

  tccTarget =
    {
      i686-linux = "I386";
      x86_64-linux = "X86_64";
    }
    .${buildPlatform.system};

  src = fetchurl {
    url = "https://download.savannah.gnu.org/releases/tinycc/tcc-${version}.tar.bz2";
    hash = "sha256-3iOvePypDOMt/y3UWzQysjNHQLubt7Bb9g/b/Dls65w=";
  };

  patches = [
    ./static-link.patch
    ./ignore-static-inside-array.patch
    ./dont-skip-weak-symbols-ar.patch
  ];

  meta = {
    description = "TinyCC 0.9.27 linked against musl";
    homepage = "https://www.gnu.org/software/tinycc";
    license = lib.licenses.lgpl21Only;
    teams = [ lib.teams.minimal-bootstrap ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };

  compiler = bash.runCommand "${pname}-${version}"
    {
      inherit pname version meta;
      nativeBuildInputs = [
        tinycc.compiler
        gnupatch
      ];
    }
    ''
      unbz2 --file ${src} --output tcc.tar
      untar --file tcc.tar
      rm tcc.tar
      cd tcc-${version}

      catm config.h
      ${lib.concatMapStringsSep "\n" (f: "${gnupatch}/bin/patch -Np1 -i ${f}") patches}

      mkdir -p bootstrap-lib
      cp ${musl}/lib/* bootstrap-lib/
      cp ${tinycc.libs}/lib/libtcc1.a bootstrap-lib/libtcc1.a

      ${tinycc.compiler}/bin/tcc \
        -B ''${PWD}/bootstrap-lib \
        -v \
        -static \
        -o tcc-musl \
        -D TCC_TARGET_${tccTarget}=1 \
        -D CONFIG_TCCDIR=\"\" \
        -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
        -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
        -D CONFIG_TCC_LIBPATHS=\"{B}\" \
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"${musl}/include\" \
        -D TCC_LIBGCC=\"libc.a\" \
        -D TCC_LIBTCC1=\"libtcc1.a\" \
        -D CONFIG_TCC_STATIC=1 \
        -D CONFIG_USE_LIBGCC=1 \
        -D TCC_VERSION=\"${version}\" \
        -D ONE_SOURCE=1 \
        -I ${musl}/include \
        tcc.c

      rm -f libtcc1.a libtcc1.o
      ${tinycc.compiler}/bin/tcc \
        -B ''${PWD}/bootstrap-lib \
        -c \
        -D HAVE_CONFIG_H=1 \
        lib/libtcc1.c
      ${tinycc.compiler}/bin/tcc \
        -ar cr \
        libtcc1.a \
        libtcc1.o
      rm -f bootstrap-lib/libtcc1.a
      cp libtcc1.a bootstrap-lib/libtcc1.a

      ./tcc-musl \
        -B ''${PWD}/bootstrap-lib \
        -v \
        -static \
        -o tcc-musl \
        -D TCC_TARGET_${tccTarget}=1 \
        -D CONFIG_TCCDIR=\"\" \
        -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
        -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
        -D CONFIG_TCC_LIBPATHS=\"{B}\" \
        -D CONFIG_TCC_SYSINCLUDEPATHS=\"${musl}/include\" \
        -D TCC_LIBGCC=\"libc.a\" \
        -D TCC_LIBTCC1=\"libtcc1.a\" \
        -D CONFIG_TCC_STATIC=1 \
        -D CONFIG_USE_LIBGCC=1 \
        -D TCC_VERSION=\"${version}\" \
        -D ONE_SOURCE=1 \
        -I ${musl}/include \
        tcc.c

      rm -f libtcc1.a libtcc1.o
      ./tcc-musl \
        -B ''${PWD}/bootstrap-lib \
        -c \
        -D HAVE_CONFIG_H=1 \
        lib/libtcc1.c
      ./tcc-musl \
        -ar cr \
        libtcc1.a \
        libtcc1.o

      mkdir -p ''${out}/bin ''${out}/lib
      cp tcc-musl ''${out}/bin/tcc
      cp tcc-musl ''${out}/bin/tcc-musl
      cp libtcc1.a ''${out}/lib/libtcc1.a
      chmod 555 ''${out}/bin/tcc ''${out}/bin/tcc-musl
      chmod 444 ''${out}/lib/libtcc1.a
    '';

  libs = bash.runCommand "${pname}-libs-${version}" { } ''
    mkdir -p ''${out}/lib
    cp ${musl}/lib/* ''${out}/lib/
    cp ${compiler}/lib/libtcc1.a ''${out}/lib/libtcc1.a
  '';
in
{
  inherit compiler libs;
  prev = tinycc;
}
