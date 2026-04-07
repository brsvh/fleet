{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  programs = {
    gpg = {
      enable = mkDefault true;
      homedir = mkDefault "${config.xdg.dataHome}/gnupg";
    };
  };

  services = {
    gpg-agent = {
      defaultCacheTtl = 28800;
      defaultCacheTtlSsh = 28800;
      enable = mkDefault true;
      enableExtraSocket = mkDefault true;
      enableSshSupport = mkDefault true;

      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';

      maxCacheTtl = mkDefault 28800;
      maxCacheTtlSsh = mkDefault 28800;

      pinentry = {
        package = mkDefault pkgs.pinentry-curses;
        program = mkDefault "pinentry-curses";
      };
    };
  };
}
