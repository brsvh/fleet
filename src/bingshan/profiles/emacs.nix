{
  bingshan,
  config,
  home,
  pkgs,
  ...
}:
let
  inherit (config.home)
    username
    ;

  email =
    config.accounts.email.accounts.${username};

  libext =
    pkgs.stdenv.targetPlatform.extensions.sharedLibrary;
in
{
  imports = [
    bingshan.profiles.accounts
    bingshan.profiles.fonts
    bingshan.profiles.global
    home.profiles.emacs
  ];

  home = {
    packages = with pkgs; [
      black
      clang-tools
      codesearch
      emacs-lsp-booster
      hunspell
      hunspellDicts.en_US-large
      nerd-fonts.symbols-only
      nixd
      nixfmt
      pyright
      ripgrep
      silver-searcher
    ];
  };

  programs = {
    emacs = {
      earlyInitFile = bingshan.etc.emacs.early-init;

      extraConfig = ''
        (use-package emacs
          :demand t
          :no-require t

          :custom
          (user-full-name "${email.realName}"))

        (use-package emacs
          :demand t
          :no-require t
          :when (display-graphic-p)

          :config
          (set-fontset-font t 'cjk-misc (font-spec :family "Microsoft YaHei"))
          (set-fontset-font t 'han (font-spec :family "Microsoft YaHei")))

        (use-package epa-hook
          :config
          (add-to-list 'epa-file-encrypt-to "${email.gpg.key}"))

        (use-package startup
          :demand t
          :no-require t

          :custom
          (user-mail-address "${email.address}"))
      '';

      extraPackages =
        epkgs: with epkgs; [
          anzu
          apheleia
          beframe
          benchmark-init
          blamer
          bs
          bufferlo
          calfw
          cape
          citar
          citar-denote
          citar-embark
          citre
          consult
          consult-ag
          consult-codesearch
          consult-denote
          consult-eglot
          consult-eglot-embark
          consult-jinx
          consult-project-extra
          corfu
          corfu-candidate-overlay
          denote
          denote-explore
          denote-journal
          denote-menu
          denote-org
          denote-search
          diff-hl
          diredfl
          doom-modeline
          eat
          edit-indirect
          editorconfig
          eglot
          eglot-booster
          eldoc-box
          eldoc-mouse
          emacs-gc-stats
          embark
          embark-consult
          envrc
          flymake-popon
          form-feed
          geiser
          geiser-guile
          git-cliff
          git-modes
          haskell-mode
          haskell-ts-mode
          hl-todo
          htmlize
          ibuffer-project
          jinx
          macrostep-geiser
          magit
          magit-section
          marginalia
          modus-themes
          mwim
          nerd-icons
          nerd-icons-corfu
          nerd-icons-dired
          nerd-icons-ibuffer
          nix-mode
          nix-ts-mode
          orderless
          org-appear
          org-contrib
          org-gtd
          org-modern
          org-modern-indent
          org-ql
          org-super-agenda
          paredit
          pass
          rainbow-delimiters
          sly
          sly-asdf
          sly-macrostep
          sly-named-readtables
          sly-stepper
          smartparens
          spacious-padding
          switch-window
          tabspaces
          treemacs
          treemacs-magit
          treemacs-nerd-icons
          treemacs-tab-bar
          unicode-fonts
          vertico
          vui
          winum
          with-editor
        ];

      initFile = bingshan.etc.emacs.init;

      package = pkgs.emacs-igc-pgtk;
    };
  };
}
