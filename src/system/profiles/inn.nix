{
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    attrValues
    concatLists
    mapAttrs
    mkDefault
    mkIf
    mkMerge
    pipe
    ;

  # Keep bootstrap and replication group sets identical on every host.
  archiveGroups = {
    eternal-september = [
      "comp.arch.fpga"
      "alt.folklore.computers"
      "alt.peeves"
      "comp.emacs"
      "rec.food.drink.tea"
      "rec.games.video.classic"
      "alt.comp.lang.rust"
      "comp.lang.c"
      "comp.lang.c++"
      "comp.lang.haskell"
      "comp.lang.lisp"
      "comp.lang.scheme"
      "comp.os.linux.networking"
      "rec.music.makers.synth"
      "rec.arts.books"
      "comp.security.ssh"
    ];

    gmane = [
      "gmane.emacs.devel"
      "gmane.emacs.help"
      "gmane.lisp.asdf.devel"
      "gmane.lisp.guile.devel"
      "gmane.lisp.guile.user"
      "gmane.lisp.scheme.chez"
      "gmane.lisp.scheme.mit-scheme.devel"
      "gmane.comp.kde.devel.general"
      "gmane.comp.hardware.riscv.isa.devel"
      "gmane.comp.hardware.riscv.opensbi.devel"
      "gmane.linux.ports.riscv"
      "gmane.comp.gcc.devel"
      "gmane.comp.gdb.devel"
      "gmane.comp.gnu.binutils"
      "gmane.comp.lib.glibc.alpha"
    ];

    olduse = [
      "net.arch"
      "net.general"
      "net.emacs"
      "net.movies"
      "net.games.trivia"
      "net.games.video"
      "net.lang.c"
      "net.lang.c++"
      "net.lang.forth"
      "net.lang.lisp"
      "net.music.classical"
      "net.music.synth"
      "net.books"
      "net.sf-lovers"
      "net.astro"
      "net.space"
      "net.crypt"
      "mod.compilers"
      "mod.std.c"
      "net.unix"
      "net.unix-wizards"
      "net.usenix"
    ];

    solani = [
      "comp.arch"
      "alt.callahans"
      "gnu.emacs.gnus"
      "rec.arts.movies.current-films"
      "rec.arts.movies.past-films"
      "rec.games.trivia"
      "comp.lang.forth"
      "comp.programming"
      "comp.os.linux.misc"
      "rec.music.classical.recordings"
      "rec.music.misc"
      "rec.music.rock-pop-r+b.1950s"
      "rec.arts.sf.written"
      "sci.astro"
      "comp.security.unix"
      "comp.unix.programmer"
    ];
  };
in
{
  imports = [
    system.modules.inn
  ];

  config = mkMerge [
    {
      services = {
        inn = {
          enable = mkDefault true;

          groups = pipe archiveGroups [
            attrValues
            concatLists
          ];

          organization = "Bingshan's news archive";
          primaryAddress = "100.64.0.2";
          primaryHost = "magnolia.tail.bingshan.org";
        };
      };
    }
    (mkIf (config.services.inn.role == "primary") {
      services = {
        inn = {
          upstreams = mapAttrs (_: groups: {
            inherit
              groups
              ;
          }) archiveGroups;
        };
      };
    })
  ];
}
