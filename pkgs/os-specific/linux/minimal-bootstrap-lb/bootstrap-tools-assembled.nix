{
  lib,
  bash,
  busybox,
  musl,
  glibc ? null,
  gcc,
  binutils,
  coreutils,
  diffutils,
  findutils,
  gawk,
  gnumake,
  gnupatch,
  gnutar,
  gnused,
  grep,
  gzip,
  bzip2,
  patchelf,
  gmp,
  mpfr,
  mpc,
  zlib,
}:

derivation {
  name = "bootstrap-tools-assembled";
  inherit (bash) system;

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    "-u"
    "-o"
    "pipefail"
    "-c"
    "source \"$buildCommandPath\""
  ];

  passAsFile = [ "buildCommand" ];

  PATH = "${coreutils}/bin";

  buildCommand = ''
    link_entry() {
      local src="$1"
      local dst="$2"

      if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        return 0
      fi

      if [ -d "$src" ] && [ ! -L "$src" ]; then
        if [ ! -e "$dst" ]; then
          ln -s "$src" "$dst"
          return 0
        fi

        if [ -L "$dst" ]; then
          local previous
          previous="$(readlink -f "$dst")"
          rm "$dst"
          mkdir -p "$dst"
          link_entry "$previous" "$dst"
        elif [ ! -d "$dst" ]; then
          rm -rf "$dst"
          ln -s "$src" "$dst"
          return 0
        fi

        local entry base
        for entry in "$src"/* "$src"/.*; do
          base="$(basename "$entry")"
          case "$base" in
            .|..) continue ;;
          esac
          [ -e "$entry" ] || [ -L "$entry" ] || continue
          link_entry "$entry" "$dst/$base"
        done
        return 0
      fi

      if [ -d "$dst" ] && [ ! -L "$dst" ]; then
        rm -rf "$dst"
      fi
      rm -f "$dst"
      ln -s "$src" "$dst"
    }

    ensure_real_dir() {
      local dst="$1"
      if [ -L "$dst" ]; then
        local previous
        previous="$(readlink -f "$dst")"
        rm "$dst"
        mkdir -p "$dst"
        link_entry "$previous" "$dst"
      else
        mkdir -p "$dst"
      fi
    }

    merge_bin_dir() {
      local src="$1"
      if [ -d "$src/bin" ]; then
        link_entry "$src/bin" "$out/bin"
      fi
    }

    mkdir -p "$out"

    merge_bin_dir ${coreutils}
    merge_bin_dir ${bash}
    merge_bin_dir ${diffutils}
    merge_bin_dir ${findutils}
    merge_bin_dir ${gnused}
    merge_bin_dir ${grep}
    merge_bin_dir ${gawk}
    merge_bin_dir ${gnutar}
    merge_bin_dir ${gzip}
    merge_bin_dir ${bzip2}
    merge_bin_dir ${gnumake}
    merge_bin_dir ${gnupatch}
    merge_bin_dir ${patchelf}
    merge_bin_dir ${binutils}
    merge_bin_dir ${gcc}

    link_entry ${musl}/lib "$out/lib"
    ${lib.optionalString (glibc != null) ''
      link_entry ${glibc}/lib "$out/lib"
    ''}
    link_entry ${binutils}/lib "$out/lib"
    link_entry ${gcc}/lib "$out/lib"
    link_entry ${gmp}/lib "$out/lib"
    link_entry ${mpfr}/lib "$out/lib"
    link_entry ${mpc}/lib "$out/lib"
    link_entry ${zlib}/lib "$out/lib"

    link_entry ${gcc}/libexec "$out/libexec"

    mkdir -p "$out/include"
    link_entry ${musl}/include "$out/include-libc"
    ${
      if glibc != null then
        ''link_entry ${glibc}/include "$out/include-glibc"''
      else
        ''link_entry ${musl}/include "$out/include-glibc"''
    }
    link_entry ${gcc}/include/c++ "$out/include/c++"

    ensure_real_dir "$out/lib"
    ${lib.optionalString (glibc != null) ''
      for script in "$out"/lib/*.so; do
        if [ -f "$script" ] && head -n 1 "$script" | ${grep}/bin/grep -q '^/\* GNU ld script'; then
          ${gnused}/bin/sed -i \
            -e "s# //lib/# $out/lib/#g" \
            -e "s# =/lib/# $out/lib/#g" \
            -e "s# /lib/# $out/lib/#g" \
            -e "s# //usr/lib/# $out/lib/#g" \
            -e "s# =/usr/lib/# $out/lib/#g" \
            -e "s# /usr/lib/# $out/lib/#g" \
            "$script"
        fi
      done
    ''}
    if [ ! -e "$out/lib/ld-linux-x86-64.so.2" ] && [ -e "$out/lib/ld-musl-x86_64.so.1" ]; then
      ln -s ld-musl-x86_64.so.1 "$out/lib/ld-linux-x86-64.so.2"
    fi

    ensure_real_dir "$out/bin"

    write_script() {
      local path="$1"
      shift
      rm -f "$path"
      printf '%s\n' "$@" > "$path"
      chmod 555 "$path"
    }

    write_script "$out/bin/gcc" \
      "#!${bash}/bin/bash" \
      "exec ${gcc}/bin/gcc -std=gnu17 \"\$@\""

    rm -f "$out/bin/cc"
    ln -s gcc "$out/bin/cc"

    if [ -e "${gcc}/bin/cpp" ]; then
      write_script "$out/bin/cpp" \
        "#!${bash}/bin/bash" \
        "exec ${gcc}/bin/cpp -std=gnu17 \"\$@\""
    fi

    if [ -e "${gcc}/bin/x86_64-unknown-linux-musl-gcc" ]; then
      write_script "$out/bin/x86_64-unknown-linux-musl-gcc" \
        "#!${bash}/bin/bash" \
        "exec ${gcc}/bin/x86_64-unknown-linux-musl-gcc -std=gnu17 \"\$@\""
    fi

    if [ -e "${gcc}/bin/x86_64-unknown-linux-musl-cpp" ]; then
      write_script "$out/bin/x86_64-unknown-linux-musl-cpp" \
        "#!${bash}/bin/bash" \
        "exec ${gcc}/bin/x86_64-unknown-linux-musl-cpp -std=gnu17 \"\$@\""
    fi

    if [ -e "${gcc}/bin/x86_64-unknown-linux-gnu-gcc" ]; then
      write_script "$out/bin/x86_64-unknown-linux-gnu-gcc" \
        "#!${bash}/bin/bash" \
        "exec ${gcc}/bin/x86_64-unknown-linux-gnu-gcc -std=gnu17 \"\$@\""
    fi

    if [ -e "${gcc}/bin/x86_64-unknown-linux-gnu-cpp" ]; then
      write_script "$out/bin/x86_64-unknown-linux-gnu-cpp" \
        "#!${bash}/bin/bash" \
        "exec ${gcc}/bin/x86_64-unknown-linux-gnu-cpp -std=gnu17 \"\$@\""
    fi

    rm -f "$out/bin/sh"
    ln -s bash "$out/bin/sh"

    rm -f "$out/bin/bunzip2"
    ln -s bzip2 "$out/bin/bunzip2"

    write_script "$out/bin/gunzip" \
      "#!$out/bin/sh" \
      "exec $out/bin/gzip -d \"\$@\""

    write_script "$out/bin/egrep" \
      "#!$out/bin/sh" \
      "exec $out/bin/grep -E \"\$@\""

    write_script "$out/bin/fgrep" \
      "#!$out/bin/sh" \
      "exec $out/bin/grep -F \"\$@\""

    write_script "$out/bin/xz" \
      "#!${bash}/bin/bash" \
      "exec ${busybox} unxz \"\$@\""
  '';

  langC = true;
  langCC = true;
  isGNU = true;
  isAssembled = true;
  hardeningUnsupportedFlags = [
    "fortify3"
    "shadowstack"
    "pacret"
    "stackclashprotection"
    "trivialautovarinit"
    "zerocallusedregs"
  ];
}
