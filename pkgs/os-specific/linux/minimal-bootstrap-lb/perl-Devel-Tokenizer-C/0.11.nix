{
  lib,
  fetchurl,
  bash,
  coreutils,
  gnutar,
  gzip,
  gnused,
  perl,
}:
let
  pname = "perl-Devel-Tokenizer-C";
  version = "0.11";

  src = fetchurl {
    url = "https://cpan.metacpan.org/authors/id/M/MH/MHX/Devel-Tokenizer-C-${version}.tar.gz";
    hash = "sha256-UiLaWCulm+JqlEOhHFJcUqoHDa87/whRaAUUKzYrpIw=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      coreutils
      gnutar
      gzip
      gnused
      perl
    ];

    meta = {
      description = "Tokenizer module used by Perl regen scripts";
      homepage = "https://metacpan.org/release/Devel-Tokenizer-C";
      license = [ lib.licenses.artistic1 lib.licenses.gpl1Plus ];
      teams = [ lib.teams.minimal-bootstrap ];
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    cp ${src} tokenizer.tar.gz
    ${gzip}/bin/gzip -d -f tokenizer.tar.gz
    ${gnutar}/bin/tar xf tokenizer.tar
    rm tokenizer.tar
    cd Devel-Tokenizer-C-${version}

    # Install
    perlVersion="$(${perl}/bin/perl -v | ${gnused}/bin/sed -n -re 's/.*[ (]v([0-9\.]*)[ )].*/\1/p')"
    install -D lib/Devel/Tokenizer/C.pm ''${out}/lib/perl5/''${perlVersion}/Devel/Tokenizer/C.pm
  ''
