{
  stdenv,
}:
stdenv.mkDerivation {
    pname = "rustc-bootstrap";
    version = "1.74.0";
}
