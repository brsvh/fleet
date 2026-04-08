{
  config,
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMap
    filterAttrs
    getName
    mkDefault
    optional
    pipe
    removeSuffix
    ;

  inherit (pkgs)
    linkFarm
    ;

  libext =
    pkgs.stdenv.targetPlatform.extensions.sharedLibrary;

  mkEntry = drv: name: {
    name = "lib${name}${libext}";
    path = "${drv}/parser";
  };

  treeSitterGrammars =
    pipe pkgs.tree-sitter-grammars
      [
        (filterAttrs (
          name: _: name != "recurseForDerivations"
        ))
        attrValues
      ];

  treeSitterGrammarsPath =
    linkFarm "treesit-grammars"
      (
        concatMap (
          drv:
          let
            baseName = removeSuffix "-grammar" (getName drv);
          in
          [ (mkEntry drv baseName) ]
          # Fix markdown-inline grammars for markdown-ts-mode.
          ++ optional (
            baseName == "tree-sitter-markdown_inline"
          ) (mkEntry drv "tree-sitter-markdown-inline")
        ) treeSitterGrammars
      );
in
{
  imports = [
    home.modules.emacs
  ];

  programs = {
    emacs = {
      enable = true;

      extraConfig = ''
        (use-package emacs
          :demand t
          :no-require t

          :init
          (add-to-list 'treesit-extra-load-path "${treeSitterGrammarsPath}"))
      '';

      package = mkDefault pkgs.emacs-gtk;
    };
  };
}
