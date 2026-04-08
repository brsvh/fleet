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
    home.profiles.accounts
    home.profiles.emacs
  ];

  home = {
    packages = with pkgs; [
      black
      clang-tools
      emacs-lsp-booster
      hunspell
      hunspellDicts.en_US-large
      nerd-fonts.symbols-only
      pyright
      nixd
      nixfmt
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
          cape
          citar
          citar-denote
          citar-embark
          citre
          consult
          consult-denote
          consult-eglot
          consult-eglot-embark
          consult-jinx
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
          org-modern
          org-modern-indent
          paredit
          pass
          pinentry
          rainbow-delimiters
          sly
          sly-asdf
          sly-macrostep
          sly-named-readtables
          sly-stepper
          smartparens
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

      package = pkgs.emacs-git.override {
        withGTK3 = true;
      };
    };
  };
}
