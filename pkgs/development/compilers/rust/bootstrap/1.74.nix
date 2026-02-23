{
  stdenv,
  mrustc,
}:
stdenv.mkDerivation {
    pname = "rustc-bootstrap";
    version = "1.74.0";
    src = fetchurl {
      url = "https://static.rust-lang.org/dist/rustc-${version}-src.tar.xz";
      sha256 = "";
    };
}
