# TinyCC 0.9.27 - official release matching live-bootstrap
#
# This builds tcc 0.9.27 exactly as live-bootstrap does:
# - Uses official 0.9.27 release (not unstable snapshots)
# - Applies live-bootstrap's patches
# - CONFIG_TCC_SYSINCLUDEPATHS set to only mes-libc (no tcc headers)
#
# This is necessary because:
# - tcc's stddef.h declares `void *alloca(size_t)` which conflicts with
#   older software (like make 3.82) that declares `char *alloca()`
# - By using only mes-libc headers, we avoid this conflict
#
# Build steps adapted from:
# https://github.com/fosslinux/live-bootstrap/blob/main/steps/tcc-0.9.27/pass1.kaem

{
  lib,
  fetchurl,
  kaem,
  tinycc-bootstrappable,
  mes-libc,
  buildPlatform,
  # Optional: override directory with empty mes/config.h to avoid typedef conflicts
  mes-config-h-override ? null,
}:
let
  pname = "tinycc";
  version = "0.9.27";

  tccTarget = {
    i686-linux = "I386";
    x86_64-linux = "X86_64";
  }.${buildPlatform.system};

  # Tarball checksum from live-bootstrap
  tarball = fetchurl {
    url = "https://download.savannah.gnu.org/releases/tinycc/tcc-${version}.tar.bz2";
    hash = "sha256-3iOvePypDOMt/y3UWzQysjNHQLubt7Bb9g/b/Dls65w=";
  };

  # Patches from live-bootstrap (converted to nix store files)
  # static-link.patch - default to static linking
  staticLinkPatch = builtins.toFile "static-link.patch" ''
    --- a/libtcc.c
    +++ b/libtcc.c
    @@ -734,6 +734,7 @@
         ++nb_states;

         s->alacarte_link = 1;
    +    s->static_link = 1;
         s->nocommon = 1;
         s->warn_implicit_function_declaration = 1;
         s->ms_extensions = 1;
  '';

  # ignore-static-inside-array.patch
  ignoreStaticInsideArrayPatch = builtins.toFile "ignore-static-inside-array.patch" ''
    --- a/tccgen.c
    +++ b/tccgen.c
    @@ -4335,8 +4335,23 @@ static int post_type(CType *type, AttributeDef *ad, int storage, int td)
     	int saved_nocode_wanted = nocode_wanted;
             /* array definition */
             next();
    -        if (tok == TOK_RESTRICT1)
    -            next();
    +	while (1) {
    +	    /* XXX The optional type-quals and static should only be accepted
    +	       in parameter decls.  The '*' as well, and then even only
    +	       in prototypes (not function defs).  */
    +	    switch (tok) {
    +	    case TOK_RESTRICT1: case TOK_RESTRICT2: case TOK_RESTRICT3:
    +	    case TOK_CONST1:
    +	    case TOK_VOLATILE1:
    +	    case TOK_STATIC:
    +	    case '*':
    +		next();
    +		continue;
    +	    default:
    +		break;
    +	    }
    +	    break;
    +	}
             n = -1;
             t1 = 0;
             if (tok != ']') {
  '';

  # dont-skip-weak-symbols-ar.patch
  dontSkipWeakSymbolsPatch = builtins.toFile "dont-skip-weak-symbols-ar.patch" ''
    --- a/tcctools.c
    +++ b/tcctools.c
    @@ -200,6 +200,9 @@ ST_FUNC int tcc_tool_ar(TCCState *s1, int argc, char **argv)
                         (sym->st_info == 0x10
                         || sym->st_info == 0x11
                         || sym->st_info == 0x12
    +                    || sym->st_info == 0x20
    +                    || sym->st_info == 0x21
    +                    || sym->st_info == 0x22
                         )) {
                         //printf("symtab: %2Xh %4Xh %2Xh %s\n", sym->st_info, sym->st_size, sym->st_shndx, strtab + sym->st_name);
                         istrlen = strlen(strtab + sym->st_name)+1;
  '';

  src = (kaem.runCommand "tcc-${version}-source" { } ''
    unbz2 --file ${tarball} --output tcc.tar
    mkdir -p ''${out}
    cd ''${out}
    untar --file ''${NIX_BUILD_TOP}/tcc.tar

    cd tcc-${version}

    # Apply simple-patches using replace (matching live-bootstrap)

    # remove-fileopen + addback-fileopen: moves fopen call in tcctools.c
    # This is needed because mes-libc's fopen behavior differs
    replace --file tcctools.c --output tcctools.c \
      --match-on "if (ret == 1)
        return ar_usage(ret);

    if ((fh = fopen(argv[i_lib], \"wb\")) == NULL)
    {
        fprintf(stderr, \"tcc: ar: can't open file %s \n\", argv[i_lib]);
        goto the_end;
    }" \
      --replace-with "if (ret == 1)
        return ar_usage(ret);"

    replace --file tcctools.c --output tcctools.c \
      --match-on "// write header" \
      --replace-with "if ((fh = fopen(argv[i_lib], \"wb\")) == NULL)
    {
        fprintf(stderr, \"tcc: ar: can't open file %s \n\", argv[i_lib]);
        goto the_end;
    }

    // write header"

    # check-reloc-null: Fix SIGSEGV in fill_local_got_entries
    replace --file tccelf.c --output tccelf.c \
      --match-on "static void fill_local_got_entries(TCCState *s1)
{
    ElfW_Rel *rel;
    for_each_elem(s1->got->reloc, 0, rel, ElfW_Rel) {" \
      --replace-with "static void fill_local_got_entries(TCCState *s1)
{
    ElfW_Rel *rel;
    if (!s1->got->reloc)
	return;
    for_each_elem(s1->got->reloc, 0, rel, ElfW_Rel) {"

    # Static link by default (from static-link.patch)
    replace --file libtcc.c --output libtcc.c \
      --match-on "s->ms_extensions = 1;" \
      --replace-with "s->ms_extensions = 1; s->static_link = 1;"
  '') + "/tcc-${version}";

  meta = {
    description = "TinyCC 0.9.27 (bootstrap version matching live-bootstrap)";
    homepage = "https://www.gnu.org/software/tinycc";
    license = lib.licenses.lgpl21Only;
    teams = [ lib.teams.minimal-bootstrap ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };

  compiler = kaem.runCommand "${pname}-${version}" {
    inherit pname version meta;
    passthru.tests.get-version = result:
      kaem.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/tcc -version
        mkdir ''${out}
      '';
  } ''
    catm config.h
    mkdir -p ''${out}/bin
    ${tinycc-bootstrappable.compiler}/bin/tcc \
      -B ${tinycc-bootstrappable.libs}/lib \
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
      -D CONFIG_TCC_SYSINCLUDEPATHS=\"${if mes-config-h-override != null then "${mes-config-h-override}:" else ""}${mes-libc}/include\" \
      -D TCC_LIBGCC=\"libc.a\" \
      -D TCC_LIBTCC1=\"libtcc1.a\" \
      -D CONFIG_TCCBOOT=1 \
      -D CONFIG_TCC_STATIC=1 \
      -D CONFIG_USE_LIBGCC=1 \
      -D TCC_MES_LIBC=1 \
      -D TCC_VERSION=\"${version}\" \
      -D ONE_SOURCE=1 \
      ${src}/tcc.c
  '';

  # Recompile mes-libc with the new tcc (matching live-bootstrap)
  libs = kaem.runCommand "${pname}-libs-${version}" { } ''
    mkdir -p ''${out}/lib

    # crt1.o, crtn.o, crti.o
    ${compiler}/bin/tcc \
      -c -D HAVE_CONFIG_H=1 \
      -I ${mes-libc}/include \
      -I ${mes-libc}/include/linux/x86 \
      -o ''${out}/lib/crt1.o \
      ${mes-libc}/lib/crt1.c
    ${compiler}/bin/tcc \
      -c -D HAVE_CONFIG_H=1 \
      -I ${mes-libc}/include \
      -I ${mes-libc}/include/linux/x86 \
      -o ''${out}/lib/crtn.o \
      ${mes-libc}/lib/crtn.c
    ${compiler}/bin/tcc \
      -c -D HAVE_CONFIG_H=1 \
      -I ${mes-libc}/include \
      -I ${mes-libc}/include/linux/x86 \
      -o ''${out}/lib/crti.o \
      ${mes-libc}/lib/crti.c

    # libtcc1.a - use tcc's lib/libtcc1.c which has 64-bit float conversion functions
    ${compiler}/bin/tcc \
      -c \
      -D TCC_TARGET_${tccTarget}=1 \
      ${src}/lib/libtcc1.c
    ${compiler}/bin/tcc -ar cr ''${out}/lib/libtcc1.a libtcc1.o

    # libc.a
    ${compiler}/bin/tcc \
      -c -D HAVE_CONFIG_H=1 \
      -I ${mes-libc}/include \
      -I ${mes-libc}/include/linux/x86 \
      -o libc.o \
      ${mes-libc}/lib/libc.c
    ${compiler}/bin/tcc -ar cr ''${out}/lib/libc.a libc.o

    # libgetopt.a
    ${compiler}/bin/tcc \
      -c -D HAVE_CONFIG_H=1 \
      -I ${mes-libc}/include \
      -I ${mes-libc}/include/linux/x86 \
      -o libgetopt.o \
      ${mes-libc}/lib/libgetopt.c
    ${compiler}/bin/tcc -ar cr ''${out}/lib/libgetopt.a libgetopt.o
  '';

in {
  inherit compiler libs;
  prev = tinycc-bootstrappable;
}
