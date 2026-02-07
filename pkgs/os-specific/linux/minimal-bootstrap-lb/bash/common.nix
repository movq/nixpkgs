{ lib }:
{
  meta = {
    description = "GNU Bourne-Again shell";
    homepage = "https://www.gnu.org/software/bash";
    license = lib.licenses.gpl3Plus;
    teams = [ lib.teams.minimal-bootstrap ];
    platforms = lib.platforms.unix;
  };
}
