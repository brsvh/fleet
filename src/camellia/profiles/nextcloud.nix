{
  camellia,
  config,
  pkgs,
  system,
  ...
}:
let
  inherit (config.sops)
    secrets
    ;

  inherit (pkgs)
    coreutils
    jq
    ;

  cfg = config.services.nextcloud;

  store = {
    bucketName = "nextcloud";
    keyId = "GK74f5107bc2ede82b9f049e23";
    keyName = "nextcloud";
    secret = secrets."nextcloud/s3-secret-key".path;
  };

  jqBin = "${jq}/bin/jq";

  occBin = "${cfg.occ}/bin/nextcloud-occ";

  sha256sumBin = "${coreutils}/bin/sha256sum";

  officeServer = "office.bingshan.org";
in
{
  imports = [
    camellia.profiles.sops
    camellia.profiles.garage
    system.profiles.nextcloud
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        443
      ];
    };

    hosts = {
      "2a0b:7140:8:1:5054:ff:feef:6795" = [
        officeServer
      ];

      "95.133.228.83" = [
        officeServer
      ];
    };
  };

  services = {
    nextcloud = {
      config = {
        objectstore = {
          s3 = {
            bucket = store.bucketName;
            hostname = "127.0.0.1";
            key = store.keyId;
            port = 3900;
            region = "garage";
            secretFile = store.secret;
            usePathStyle = true;
            useSsl = false;
            verify_bucket_exists = true;
          };
        };
      };

      hostName = "cloud.bingshan.org";

      phpOptions = {
        "opcache.interned_strings_buffer" = "32";
      };

      secrets = {
        mail_smtppassword =
          secrets."cloud@bingshan.org".path;
      };

      settings = {
        default_phone_region = "US";
        mail_domain = "bingshan.org";
        mail_from_address = "cloud";
        mail_smtpauth = true;
        mail_smtphost = "mail.bingshan.org";
        mail_smtpmode = "smtp";
        mail_smtpname = "cloud@bingshan.org";
        mail_smtpport = 465;
        mail_smtpsecure = "ssl";
        maintenance_window_start = 5;
        "overwrite.cli.url" = "https://${cfg.hostName}";
        overwriteprotocol = "https";
      };
    };

    nextcloud-whiteboard-server = {
      enable = true;

      secrets = [
        secrets."nextcloud/whiteboard-env".path
      ];

      settings = {
        CHROME_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        NEXTCLOUD_URL = "https://${cfg.hostName}";
        PORT = "3002";
      };
    };

    nginx = {
      virtualHosts = {
        "${cfg.hostName}" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "^~ /whiteboard/" = {
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';

              proxyPass = "http://127.0.0.1:3002/";
              proxyWebsockets = true;
            };
          };
        };

        ${officeServer} = {
          enableACME = true;
          forceSSL = true;
        };
      };
    };

    onlyoffice = {
      enable = true;
      hostname = officeServer;
      jwtSecretFile =
        secrets."onlyoffice/jwt-secret".path;

      package =
        pkgs.onlyoffice-documentserver.override
          {
            # The scanner skips combine's symlinks.
            extra-fonts = with pkgs.microsoftPackages; [
              arial
              bahnschrift
              calibri
              cambria
              cambria-math
              candara
              comic-sans-ms
              consolas
              constantia
              corbel
              courier-new
              dengxian
              ebrima
              fangsong
              franklin-gothic-medium
              gabriola
              gadugi
              georgia
              impact
              ink-free
              javanese-text
              kaiti
              leelawadee-ui
              lucida-console
              lucida-sans-unicode
              malgun-gothic
              marlett
              microsoft-himalaya
              microsoft-jhenghei
              microsoft-new-tai-lue
              microsoft-phagspa
              microsoft-sans-serif
              microsoft-tai-le
              microsoft-yahei
              microsoft-yi-baiti
              mingliu
              mongolian-baiti
              ms-gothic
              mv-boli
              myanmar-text
              nirmala
              noto-sans-sc
              noto-serif-sc
              palatino-linotype
              sans-serif-collection
              segoe-icons
              segoe-print
              segoe-script
              segoe-ui
              segoe-ui-symbols
              segoe-ui-variable
              simhei
              simsun
              sitka
              sylfaen
              symbol
              tahoma
              times-new-roman
              trebuchet-ms
              verdana
              webdings
              wingdings
              yu-gothic
            ];
          };

      securityNonceFile =
        secrets."onlyoffice/security-nonce".path;
    };
  };

  sops = {
    secrets = {
      "chang@bingshan.org" = {
        restartUnits = [
          "nextcloud-configure.service"
        ];
      };

      "cloud@bingshan.org" = {
        restartUnits = [
          "phpfpm-nextcloud.service"
        ];
      };

      "nextcloud/s3-secret-key" = {
        restartUnits = [
          "garage-configure.service"
          "nextcloud-setup.service"
          "phpfpm-nextcloud.service"
        ];
      };

      "nextcloud/whiteboard-env" = {
        restartUnits = [
          "nextcloud-configure.service"
          "nextcloud-whiteboard-server.service"
        ];
      };

      "onlyoffice/jwt-secret" = {
        group = "onlyoffice";
        mode = "0440";
        owner = "onlyoffice";

        restartUnits = [
          "nextcloud-configure.service"
          "onlyoffice-converter.service"
          "onlyoffice-docservice.service"
        ];
      };

      "onlyoffice/security-nonce" = {
        group = "onlyoffice";
        mode = "0440";
        owner = "onlyoffice";

        restartUnits = [
          "nginx.service"
          "onlyoffice-docservice.service"
        ];
      };
    };
  };

  systemd = {
    services = {
      nextcloud-configure = {
        after = [
          "nextcloud-setup.service"
        ];

        requires = [
          "nextcloud-setup.service"
        ];

        script = ''
          set -euo pipefail

          trap 'printf "nextcloud-configure failed at line %s\n" "$LINENO" >&2' ERR

          password_hash() {
            local credential="$1"
            local hash

            hash="$(${sha256sumBin} "$CREDENTIALS_DIRECTORY/$credential")"
            printf '%s\n' "''${hash%% *}"
          }

          write_password_marker() {
            local marker="$1"
            local credential="$2"

            password_hash "$credential" > "$marker"
          }

          password_changed() {
            local marker="$1"
            local credential="$2"
            local current

            current="$(password_hash "$credential")"

            ! test -f "$marker" ||
              test "$(< "$marker")" != "$current"
          }

          run_with_password() {
            local credential="$1"

            shift

            NC_PASS="$(
              cat "$CREDENTIALS_DIRECTORY/$credential"
            )" \
              ${occBin} "$@"
          }

          user_exists() {
            local uid="$1"

            ${occBin} \
              user:list \
              --output=json \
              | ${jqBin} \
                --exit-status \
                --arg uid "$uid" \
                'has($uid)' \
                > /dev/null
          }

          delete_user_if_exists() {
            local uid="$1"

            if user_exists "$uid"; then
              ${occBin} \
                user:delete \
                --no-interaction \
                "$uid" \
                > /dev/null
            fi
          }

          ensure_password() {
            local uid="$1"
            local credential="$2"
            local marker="$3"

            if password_changed "$marker" "$credential"; then
              run_with_password "$credential" \
                user:resetpassword \
                --no-interaction \
                --password-from-env \
                "$uid" \
                > /dev/null

              write_password_marker "$marker" "$credential"
            fi
          }

          ensure_bingshan_admin() {
            local current_display_name
            local marker="$STATE_DIRECTORY/bingshan-password.sha256"

            if user_exists bingshan; then
              ensure_password \
                bingshan \
                chang-password \
                "$marker"
            else
              run_with_password chang-password \
                user:add \
                --no-interaction \
                --password-from-env \
                --display-name="Bingshan Chang" \
                --group=admin \
                bingshan \
                > /dev/null

              write_password_marker "$marker" chang-password
            fi

            ${occBin} \
              user:enable bingshan \
              > /dev/null \
              2>&1 || true

            ${occBin} \
              group:adduser admin bingshan \
              > /dev/null \
              2>&1 || true

            current_display_name="$(
              ${occBin} \
                user:setting \
                bingshan \
                settings \
                display_name
            )"

            if test "$current_display_name" != "Bingshan Chang"; then
              ${occBin} \
                user:setting bingshan settings display_name "Bingshan Chang" \
                > /dev/null
            fi

            ${occBin} \
              user:setting bingshan settings email chang@bingshan.org \
              > /dev/null

            ${occBin} \
              user:setting bingshan files quota none \
              > /dev/null
          }

          migrate_legacy_users_once() {
            local marker="$STATE_DIRECTORY/legacy-users-v1.done"

            if ! test -f "$marker"; then
              delete_user_if_exists chang@bingshan.org
              delete_user_if_exists administrator

              touch "$marker"
            fi
          }

          ensure_bingshan_admin

          migrate_legacy_users_once

          ${occBin} \
            app:disable registration \
            > /dev/null \
            2>&1 || true

          source "$CREDENTIALS_DIRECTORY/whiteboard-env"

          ${occBin} \
            config:app:set whiteboard collabBackendUrl \
            --value="https://${cfg.hostName}/whiteboard" \
            > /dev/null

          ${occBin} \
            config:app:set whiteboard jwt_secret_key \
            --value="$JWT_SECRET_KEY" \
            > /dev/null

          onlyoffice_jwt_secret="$(
            cat "$CREDENTIALS_DIRECTORY/onlyoffice-jwt-secret"
          )"

          ${occBin} \
            config:app:set onlyoffice DocumentServerUrl \
            --value="https://${officeServer}/" \
            > /dev/null

          ${occBin} \
            config:app:set onlyoffice StorageUrl \
            --value="https://${cfg.hostName}/" \
            > /dev/null

          ${occBin} \
            config:app:set onlyoffice jwt_secret \
            --value="$onlyoffice_jwt_secret" \
            > /dev/null

          ${occBin} \
            config:app:set onlyoffice jwt_header \
            --value="Authorization" \
            > /dev/null
        '';

        serviceConfig = {
          Group = "nextcloud";

          LoadCredential = [
            "chang-password:${
              secrets."chang@bingshan.org".path
            }"
            "mail_smtppassword:${
              secrets."cloud@bingshan.org".path
            }"
            "onlyoffice-jwt-secret:${
              secrets."onlyoffice/jwt-secret".path
            }"
            "s3_secret:${
              secrets."nextcloud/s3-secret-key".path
            }"
            "whiteboard-env:${
              secrets."nextcloud/whiteboard-env".path
            }"
          ];

          StateDirectory = "nextcloud-configure";
          Type = "oneshot";
          User = "nextcloud";
        };

        wantedBy = [
          "multi-user.target"
        ];
      };

      nextcloud-setup = {
        after = [
          "garage-configure.service"
        ];

        requires = [
          "garage-configure.service"
        ];
      };
    };
  };
}
