{
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  imports = [
    system.profiles.acme
  ];

  security = {
    acme = {
      defaults = {
        dnsProvider = mkDefault "cloudflare";
        # Validate public DNS instead of a Tailnet's split DNS zone.
        dnsResolver = mkDefault "1.1.1.1:53";
      };
    };
  };
}
