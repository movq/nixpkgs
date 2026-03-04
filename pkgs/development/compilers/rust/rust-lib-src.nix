{ runCommand, rustc }:

runCommand "rust-lib-src" { } ''
  tar --strip-components=1 -xf ${rustc.src}
  mv library $out
''
