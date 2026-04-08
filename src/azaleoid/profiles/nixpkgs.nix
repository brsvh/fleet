{
  inputs,
  system,
  ...
}:
let
  inherit (inputs)
    emacs-overlay
    infix
    ;
in
{
  imports = [
    system.profiles.nixpkgs
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      emacs-overlay.overlays.default
      infix.overlays.default
      infix.overlays.emacs-packages
    ];
  };
}
