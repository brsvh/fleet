{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    elemAt
    genAttrs
    genList
    length
    mkDefault
    mkIf
    mkMerge
    optionalString
    splitString
    ;

  inherit (lib.generators)
    toINI
    ;

  inherit (lib.gvariant)
    mkTuple
    ;

  inherit (config.services.xserver)
    xkb
    ;

  layouts = splitString "," xkb.layout;
  variants = splitString "," xkb.variant;

  sources = genList (
    index:
    let
      layout = elemAt layouts index;

      variant =
        if index < length variants then
          elemAt variants index
        else
          "";
    in
    mkTuple [
      "xkb"
      (
        layout
        + optionalString (variant != "") "+${variant}"
      )
    ]
  ) (length layouts);
in
{
  config = mkMerge [
    {
      console = {
        useXkbConfig = mkDefault true;
      };

      environment = {
        sessionVariables = {
          XKB_DEFAULT_LAYOUT = xkb.layout;
          XKB_DEFAULT_MODEL = xkb.model;
          XKB_DEFAULT_OPTIONS = xkb.options;
          XKB_DEFAULT_VARIANT = xkb.variant;
        };
      };
    }
    (mkIf
      config.services.desktopManager.plasma6.enable
      {
        environment = {
          etc = {
            "xdg/kxkbrc" = {
              text = toINI { } {
                Layout = {
                  LayoutList = xkb.layout;
                  Model = xkb.model;
                  Options = xkb.options;
                  ResetOldOptions = true;
                  Use = true;
                  VariantList = xkb.variant;
                };
              };
            };
          };
        };
      }
    )
    (mkIf config.services.desktopManager.gnome.enable
      {
        programs = {
          dconf = {
            profiles = genAttrs [ "user" "gnome" ] (_: {
              databases = [
                {
                  settings = {
                    "org/gnome/desktop/input-sources" = {
                      inherit
                        sources
                        ;

                      xkb-options = splitString "," xkb.options;
                    };
                  };
                }
              ];
            });
          };
        };
      }
    )
  ];
}
