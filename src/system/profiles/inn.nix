{
  bingshan,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    attrValues
    concatLists
    filterAttrs
    mapAttrs
    mkDefault
    mkIf
    mkMerge
    optionalAttrs
    pipe
    ;

  news = filterAttrs (
    _: source: source ? endpoint
  ) (import bingshan.etc.news-sources);

  sources = mapAttrs (
    _: source:
    {
      inherit (source)
        endpoint
        ;

      groups = pipe source.groups [
        attrValues
        concatLists
      ];
    }
    // optionalAttrs (source ? username) {
      inherit (source)
        passwordCredential
        username
        ;
    }
  ) news;
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

          groups = pipe sources [
            attrValues
            (map (source: source.groups))
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
          upstreams = sources;
        };
      };
    })
  ];
}
