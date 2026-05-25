{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    hasSuffix
    last
    length
    mapAttrs'
    match
    mkEnableOption
    mkOption
    nameValuePair
    removeSuffix
    splitString
    types
    ;

  trimTrailingSlashes =
    value:
    if hasSuffix "/" value then
      trimTrailingSlashes (removeSuffix "/" value)
    else
      value;

  isAddressbookHomeSet =
    url:
    match ".*/addressbooks/users/[^/]+" (
      trimTrailingSlashes url
    ) != null;

  remoteUrl =
    account:
    if account.remote == null then
      null
    else
      account.remote.url;

  mkAddressbookId =
    account:
    let
      url = remoteUrl account;
    in
    if url == null || isAddressbookHomeSet url then
      "contacts"
    else
      last (splitString "/" (trimTrailingSlashes url));

  mkAddressbookUrl =
    url: addressbookId:
    if url == null then
      null
    else
      let
        trimmedUrl = trimTrailingSlashes url;

        lastSegment = last (splitString "/" trimmedUrl);

        collectionUrl =
          if lastSegment == addressbookId then
            trimmedUrl
          else
            "${trimmedUrl}/${addressbookId}";
      in
      "${collectionUrl}/";

  mkDisplayName =
    accountName: addressbookId:
    if addressbookId == "contacts" then
      "Contacts"
    else
      "${accountName}/${addressbookId}";

  emacsAddressbookType = types.submodule {
    options = {
      accountName = mkOption {
        description = ''
          Name of the Home Manager contact account that owns this addressbook.
        '';

        type = types.str;
      };

      addressbook-id = mkOption {
        description = ''
          Remote CardDAV collection identifier.
        '';

        type = types.str;
      };

      default = mkOption {
        default = false;

        description = ''
          Whether this addressbook is the default write target.
        '';

        type = types.bool;
      };

      id = mkOption {
        description = ''
          Stable internal identifier for this addressbook.
        '';

        type = types.str;
      };

      name = mkOption {
        description = ''
          Human-readable addressbook name.
        '';

        type = types.str;
      };

      readOnly = mkOption {
        default = false;

        description = ''
          Whether Emacs should treat this addressbook as read-only.
        '';

        type = types.bool;
      };

      source = mkOption {
        default = "carddav";

        description = ''
          Source backend used by this addressbook.
        '';

        type = types.enum [
          "carddav"
        ];
      };

      url = mkOption {
        description = ''
          CardDAV collection URL for this addressbook.
        '';

        type = types.str;
      };
    };
  };

  enabledAccounts = filterAttrs (
    _: account: account.emacs.enable
  ) config.accounts.contact.accounts;

  addressbooks = mapAttrs' (
    accountName: account:
    nameValuePair account.emacs.id {
      inherit accountName;

      inherit (account.emacs)
        addressbook-id
        default
        id
        name
        readOnly
        source
        url
        ;
    }
  ) enabledAccounts;

  writableAddressbooks = filterAttrs (
    _: addressbook: !addressbook.readOnly
  ) addressbooks;

  readOnlyAddressbooks = filterAttrs (
    _: addressbook: addressbook.readOnly
  ) addressbooks;

  defaultAddressbookNames = attrNames (
    filterAttrs (
      _: addressbook: addressbook.default
    ) addressbooks
  );

  missingUrlAccountNames = attrNames (
    filterAttrs (
      _: account: account.emacs.url == null
    ) enabledAccounts
  );
in
{
  options = {
    accounts = {
      contact = {
        accounts = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, config, ... }:
              {
                options = {
                  emacs = {
                    addressbook-id = mkOption {
                      default = mkAddressbookId config;

                      description = ''
                        Remote CardDAV collection identifier consumed by Emacs.
                      '';

                      type = types.str;
                    };

                    default = mkOption {
                      default = false;

                      description = ''
                        Whether this addressbook is the default Emacs write
                        target.
                      '';

                      type = types.bool;
                    };

                    enable = mkEnableOption "Emacs contact addressbook access";

                    id = mkOption {
                      default = "${name}/${config.emacs.addressbook-id}";

                      description = ''
                        Stable internal identifier used as the generated Emacs
                        addressbook key.
                      '';

                      type = types.str;
                    };

                    name = mkOption {
                      default = mkDisplayName name config.emacs.addressbook-id;

                      description = ''
                        Human-readable addressbook name shown in Emacs.
                      '';

                      type = types.str;
                    };

                    readOnly = mkOption {
                      default = false;

                      description = ''
                        Whether Emacs should treat this addressbook as
                        read-only.
                      '';

                      type = types.bool;
                    };

                    source = mkOption {
                      default = "carddav";

                      description = ''
                        Contact synchronization backend consumed by Emacs.
                      '';

                      type = types.enum [
                        "carddav"
                      ];
                    };

                    url = mkOption {
                      default = mkAddressbookUrl (remoteUrl config) config.emacs.addressbook-id;

                      description = ''
                        CardDAV collection URL consumed by Emacs.
                      '';

                      type = with types; nullOr str;
                    };
                  };
                };
              }
            )
          );
        };

        emacs = {
          addressbooks = mkOption {
            readOnly = true;

            description = ''
              Emacs-consumable contact addressbooks generated from
              `accounts.contact.accounts`.
            '';

            type = types.attrsOf emacsAddressbookType;
          };

          readOnlyAddressbooks = mkOption {
            readOnly = true;

            description = ''
              Emacs contact addressbooks that should not be written to.
            '';

            type = types.attrsOf emacsAddressbookType;
          };

          writableAddressbooks = mkOption {
            readOnly = true;

            description = ''
              Emacs contact addressbooks that can be written to.
            '';

            type = types.attrsOf emacsAddressbookType;
          };
        };
      };
    };
  };

  config = {
    accounts = {
      contact = {
        emacs = {
          inherit
            addressbooks
            readOnlyAddressbooks
            writableAddressbooks
            ;
        };
      };
    };

    assertions = [
      {
        assertion = missingUrlAccountNames == [ ];
        message =
          "Emacs contact accounts must define a CardDAV URL: "
          + concatStringsSep ", " missingUrlAccountNames;
      }
      {
        assertion = length defaultAddressbookNames <= 1;
        message =
          "At most one Emacs contact addressbook may be default, but found: "
          + concatStringsSep ", " defaultAddressbookNames;
      }
    ];
  };
}
