{
  eternal-september = {
    endpoint = "news.eternal-september.org:563_TLS";

    groups = {
      Architecture = [
        "comp.arch.fpga"
      ];

      Conversation = [
        "alt.folklore.computers"
        "alt.peeves"
      ];

      Emacs = [
        "comp.emacs"
      ];

      Food = [
        "rec.food.drink.tea"
      ];

      Games = [
        "rec.games.video.classic"
      ];

      Languages = [
        "alt.comp.lang.rust"
        "comp.lang.c"
        "comp.lang.c++"
        "comp.lang.haskell"
        "comp.lang.lisp"
        "comp.lang.scheme"
      ];

      Linux = [
        "comp.os.linux.networking"
      ];

      Music = [
        "rec.music.makers.synth"
      ];

      Reading = [
        "rec.arts.books"
      ];

      Security = [
        "comp.security.ssh"
      ];
    };

    passwordCredential = "eternal-september";
    username = "bingshan";
  };

  gmane = {
    endpoint = "news.gmane.io:119_STARTTLS";

    groups = {
      Emacs = [
        "gmane.emacs.devel"
        "gmane.emacs.help"
      ];

      Languages = [
        "gmane.lisp.asdf.devel"
        "gmane.lisp.guile.devel"
        "gmane.lisp.guile.user"
        "gmane.lisp.scheme.chez"
        "gmane.lisp.scheme.mit-scheme.devel"
      ];

      Linux = [
        "gmane.comp.kde.devel.general"
      ];

      "RISC-V" = [
        "gmane.comp.hardware.riscv.isa.devel"
        "gmane.comp.hardware.riscv.opensbi.devel"
        "gmane.linux.ports.riscv"
      ];

      Toolchain = [
        "gmane.comp.gcc.devel"
        "gmane.comp.gdb.devel"
        "gmane.comp.gnu.binutils"
        "gmane.comp.lib.glibc.alpha"
      ];
    };

    initialCatchupGroups = [
      "gmane.comp.kde.devel.general"
    ];

    mailingLists = {
      "gmane.comp.gcc.devel" = "gcc@gcc.gnu.org";
      "gmane.comp.gdb.devel" = "gdb@sourceware.org";
      "gmane.comp.gnu.binutils" =
        "binutils@sourceware.org";
      "gmane.comp.hardware.riscv.isa.devel" =
        "isa-dev@groups.riscv.org";
      "gmane.comp.hardware.riscv.opensbi.devel" =
        "opensbi@lists.infradead.org";
      "gmane.comp.kde.devel.general" =
        "kde-devel@kde.org";
      "gmane.comp.lib.glibc.alpha" =
        "libc-alpha@sourceware.org";
      "gmane.emacs.devel" = "emacs-devel@gnu.org";
      "gmane.emacs.help" = "help-gnu-emacs@gnu.org";
      "gmane.linux.ports.riscv" =
        "linux-riscv@lists.infradead.org";
      "gmane.lisp.asdf.devel" =
        "asdf-devel@lists.common-lisp.net";
      "gmane.lisp.guile.devel" = "guile-devel@gnu.org";
      "gmane.lisp.guile.user" = "guile-user@gnu.org";
      "gmane.lisp.scheme.chez" =
        "chez-scheme@googlegroups.com";
      "gmane.lisp.scheme.mit-scheme.devel" =
        "mit-scheme-devel@gnu.org";
    };
  };

  local = {
    groups = {
      Local = [
        "nndraft:delayed"
        "nndraft:drafts"
        "nndraft:queue"
      ];
    };
  };

  olduse = {
    endpoint = "olduse.net:11940";

    groups = {
      Architecture = [
        "net.arch"
      ];

      Conversation = [
        "net.general"
      ];

      Emacs = [
        "net.emacs"
      ];

      Film = [
        "net.movies"
      ];

      Games = [
        "net.games.trivia"
        "net.games.video"
      ];

      Languages = [
        "net.lang.c"
        "net.lang.c++"
        "net.lang.forth"
        "net.lang.lisp"
      ];

      Music = [
        "net.music.classical"
        "net.music.synth"
      ];

      Reading = [
        "net.books"
        "net.sf-lovers"
      ];

      Science = [
        "net.astro"
        "net.space"
      ];

      Security = [
        "net.crypt"
      ];

      Toolchain = [
        "mod.compilers"
        "mod.std.c"
      ];

      Unix = [
        "net.unix"
        "net.unix-wizards"
        "net.usenix"
      ];
    };
  };

  solani = {
    endpoint = "news.solani.org:563_TLS";

    groups = {
      Architecture = [
        "comp.arch"
      ];

      Conversation = [
        "alt.callahans"
      ];

      Emacs = [
        "gnu.emacs.gnus"
      ];

      Film = [
        "rec.arts.movies.current-films"
        "rec.arts.movies.past-films"
      ];

      Games = [
        "rec.games.trivia"
      ];

      Languages = [
        "comp.lang.forth"
        "comp.programming"
      ];

      Linux = [
        "comp.os.linux.misc"
      ];

      Music = [
        "rec.music.classical.recordings"
        "rec.music.misc"
        "rec.music.rock-pop-r+b.1950s"
      ];

      Reading = [
        "rec.arts.sf.written"
      ];

      Science = [
        "sci.astro"
      ];

      Security = [
        "comp.security.unix"
      ];

      Unix = [
        "comp.unix.programmer"
      ];
    };

    passwordCredential = "solani";
    username = "bingshan";
  };
}
