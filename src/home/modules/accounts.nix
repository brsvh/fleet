{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStringsSep
    filter
    filterAttrs
    foldlAttrs
    head
    length
    mapAttrs'
    mapAttrsToList
    mkOption
    nameValuePair
    unique
    types
    ;

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

      addressbookId = mkOption {
        description = ''
          Identifier of the local vCard addressbook.
        '';

        type = types.str;
      };

      default = mkOption {
        default = false;

        description = ''
          Whether this addressbook is the default Emacs write target.
        '';

        type = types.bool;
      };

      id = mkOption {
        description = ''
          Stable internal identifier for this addressbook.
        '';

        type = types.str;
      };

      khardName = mkOption {
        description = ''
          Addressbook name accepted by khard.
        '';

        type = types.str;
      };

      name = mkOption {
        description = ''
          Human-readable addressbook name shown in Emacs.
        '';

        type = types.str;
      };

      path = mkOption {
        description = ''
          Local directory containing this addressbook's vCard files.
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

      syncCollection = mkOption {
        description = ''
          Vdirsyncer collection selected when Emacs synchronizes contacts.
        '';

        type = types.str;
      };
    };
  };

  contactAccounts =
    config.accounts.contact.accounts;

  addressbooks = foldlAttrs (
    result: accountName: account:
    result
    // mapAttrs' (
      addressbookId: addressbook:
      nameValuePair "${accountName}/${addressbookId}" {
        inherit
          accountName
          addressbookId
          ;

        inherit (addressbook)
          default
          khardName
          name
          path
          readOnly
          syncCollection
          ;

        id = "${accountName}/${addressbookId}";
      }
    ) account.emacs.addressbooks
  ) { } contactAccounts;

  defaultAddressbookNames = attrNames (
    filterAttrs (
      _: addressbook: addressbook.default
    ) addressbooks
  );

  defaultAddressbook =
    if length defaultAddressbookNames == 1 then
      addressbooks.${head defaultAddressbookNames}
    else
      null;

  syncCollections = unique (
    mapAttrsToList (
      _: addressbook: addressbook.syncCollection
    ) addressbooks
  );

  invalidAddressbookNames = attrNames (
    filterAttrs (
      _: addressbook:
      addressbook.addressbookId == ""
      || addressbook.khardName == ""
      || addressbook.path == ""
      || addressbook.syncCollection == ""
    ) addressbooks
  );

  readOnlyDefaultAddressbookNames = filter (
    name: addressbooks.${name}.readOnly
  ) defaultAddressbookNames;

  missingKhardAccountNames = attrNames (
    filterAttrs (
      _: account:
      account.emacs.addressbooks != { }
      && !account.khard.enable
    ) contactAccounts
  );

  missingVdirsyncerAccountNames = attrNames (
    filterAttrs (
      _: account:
      account.emacs.addressbooks != { }
      && !account.vdirsyncer.enable
    ) contactAccounts
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
              let
                accountName = name;
                account = config;
              in
              {
                options = {
                  emacs = {
                    addressbooks = mkOption {
                      default = { };

                      description = ''
                        Local vCard addressbooks exposed to Emacs.
                      '';

                      type = types.attrsOf (
                        types.submodule (
                          { name, ... }:
                          {
                            options = {
                              default = mkOption {
                                default = false;

                                description = ''
                                  Whether this addressbook is the default Emacs
                                  write target.
                                '';

                                type = types.bool;
                              };

                              khardName = mkOption {
                                default = name;

                                description = ''
                                  Addressbook name accepted by khard.
                                '';

                                type = types.str;
                              };

                              name = mkOption {
                                default = mkDisplayName accountName name;

                                description = ''
                                  Human-readable addressbook name shown in
                                  Emacs.
                                '';

                                type = types.str;
                              };

                              path = mkOption {
                                default = "${account.local.path}/${name}";

                                description = ''
                                  Local directory containing this addressbook's
                                  vCard files.
                                '';

                                type = types.str;
                              };

                              readOnly = mkOption {
                                default = false;

                                description = ''
                                  Whether Emacs should treat this addressbook
                                  as read-only.
                                '';

                                type = types.bool;
                              };

                              syncCollection = mkOption {
                                default = "contacts_${accountName}/${name}";

                                description = ''
                                  Vdirsyncer collection selected when Emacs
                                  synchronizes contacts.
                                '';

                                type = types.str;
                              };
                            };
                          }
                        )
                      );
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
              Local contact addressbooks exposed to Emacs.
            '';

            type = types.attrsOf emacsAddressbookType;
          };

          defaultAddressbook = mkOption {
            readOnly = true;

            description = ''
              Default writable addressbook exposed to Emacs.
            '';

            type = with types; nullOr emacsAddressbookType;
          };

          syncCollections = mkOption {
            readOnly = true;

            description = ''
              Vdirsyncer contact collections synchronized by Emacs.
            '';

            type = types.listOf types.str;
          };
        };
      };

      email = {
        accounts = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                folders = {
                  junk = mkOption {
                    default = "Junk";

                    description = ''
                      Name of the maildir used for junk messages.
                    '';

                    type = with types; nullOr str;
                  };
                };
              };
            }
          );
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
            defaultAddressbook
            syncCollections
            ;
        };
      };
    };

    assertions = [
      {
        assertion = length defaultAddressbookNames <= 1;
        message =
          "At most one Emacs contact addressbook may be default, but found: "
          + concatStringsSep ", " defaultAddressbookNames;
      }
      {
        assertion =
          readOnlyDefaultAddressbookNames == [ ];
        message =
          "Default Emacs contact addressbooks must be writable: "
          + concatStringsSep ", " readOnlyDefaultAddressbookNames;
      }
      {
        assertion = invalidAddressbookNames == [ ];
        message =
          "Emacs contact addressbooks must define non-empty local identifiers, "
          + "paths, khard names, and vdirsyncer collections: "
          + concatStringsSep ", " invalidAddressbookNames;
      }
      {
        assertion = missingKhardAccountNames == [ ];
        message =
          "Emacs contact accounts must enable khard: "
          + concatStringsSep ", " missingKhardAccountNames;
      }
      {
        assertion = missingVdirsyncerAccountNames == [ ];
        message =
          "Emacs contact accounts must enable vdirsyncer: "
          + concatStringsSep ", " missingVdirsyncerAccountNames;
      }
    ];
  };
}
