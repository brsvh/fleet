{
  camellia,
  config,
  pkgs,
  system,
  ...
}:
let
  onlyofficeHostName = "office.bingshan.org";

  nextcloudOcc = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
in
{
  imports = [
    camellia.profiles.garage
    camellia.profiles.sops
    system.profiles.nextcloud
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        443
      ];
    };

    hosts = {
      "107.158.128.86" = [
        onlyofficeHostName
      ];

      "2a0b:7140:8:1:5054:ff:feef:6795" = [
        onlyofficeHostName
      ];
    };
  };

  services = {
    nextcloud = {
      config = {
        adminpassFile =
          config.sops.secrets."nextcloud/admin-password".path;

        adminuser = "administrator";

        objectstore = {
          s3 = {
            bucket = "nextcloud";
            hostname = "127.0.0.1";
            key = "GK74f5107bc2ede82b9f049e23";
            port = 3900;
            region = "garage";

            secretFile =
              config.sops.secrets."nextcloud/s3-secret-key".path;

            usePathStyle = true;
            useSsl = false;
            verify_bucket_exists = true;
          };
        };
      };

      hostName = "cloud.bingshan.org";

      secrets = {
        mail_smtppassword =
          config.sops.secrets."cloud@bingshan.org".path;
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

        "overwrite.cli.url" =
          "https://cloud.bingshan.org";

        overwriteprotocol = "https";
      };
    };

    nginx = {
      virtualHosts = {
        "cloud.bingshan.org" = {
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

        ${onlyofficeHostName} = {
          enableACME = true;
          forceSSL = true;
        };
      };
    };

    nextcloud-whiteboard-server = {
      enable = true;

      secrets = [
        config.sops.secrets."nextcloud/whiteboard-env".path
      ];

      settings = {
        NEXTCLOUD_URL = "https://cloud.bingshan.org";
        PORT = "3002";
      };
    };

    onlyoffice = {
      enable = true;
      hostname = onlyofficeHostName;
      jwtSecretFile =
        config.sops.secrets."onlyoffice/jwt-secret".path;
      securityNonceFile =
        config.sops.secrets."onlyoffice/security-nonce".path;
    };
  };

  systemd = {
    services = {
      nextcloud-provision-users = {
        after = [
          "nextcloud-setup.service"
        ];

        requires = [
          "nextcloud-setup.service"
        ];

        script = ''
          set -euo pipefail

          trap 'printf "nextcloud-provision-users failed at line %s\n" "$LINENO" >&2' ERR

          password_hash() {
            local credential="$1"
            local hash

            hash="$(
              ${pkgs.coreutils}/bin/sha256sum \
                "$CREDENTIALS_DIRECTORY/$credential"
            )"
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
              ${nextcloudOcc} "$@"
          }

          user_exists() {
            local uid="$1"

            ${nextcloudOcc} \
              user:list \
              --output=json \
              | ${pkgs.jq}/bin/jq \
                --exit-status \
                --arg uid "$uid" \
                'has($uid)' \
                > /dev/null
          }

          delete_user_if_exists() {
            local uid="$1"

            if user_exists "$uid"; then
              ${nextcloudOcc} \
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

          ensure_display_name() {
            local uid="$1"
            local display_name="$2"
            local current_display_name

            current_display_name="$(
              ${nextcloudOcc} \
                user:setting \
                "$uid" \
                settings \
                display_name
            )"

            if test "$current_display_name" != "$display_name"; then
              ${nextcloudOcc} \
                user:setting "$uid" settings display_name "$display_name" \
                > /dev/null
            fi
          }

          ensure_user() {
            local uid="$1"
            local display_name="$2"
            local email="$3"
            local credential="$4"
            local marker="$5"

            if user_exists "$uid"; then
              ensure_password "$uid" "$credential" "$marker"
            else
              run_with_password "$credential" \
                user:add \
                --no-interaction \
                --password-from-env \
                --display-name="$display_name" \
                "$uid" \
                > /dev/null

              write_password_marker "$marker" "$credential"
            fi

            ${nextcloudOcc} \
              user:enable "$uid" \
              > /dev/null \
              2>&1 || true

            ${nextcloudOcc} \
              user:setting "$uid" settings email "$email" \
              > /dev/null

            ensure_display_name "$uid" "$display_name"

            ${nextcloudOcc} \
              user:setting "$uid" files quota none \
              > /dev/null
          }

          ensure_administrator() {
            local marker="$STATE_DIRECTORY/administrator-password.sha256"

            if user_exists administrator; then
              ensure_password \
                administrator \
                nextcloud-admin-password \
                "$marker"
            else
              run_with_password nextcloud-admin-password \
                user:add \
                --no-interaction \
                --password-from-env \
                --display-name=administrator \
                --group=admin \
                administrator \
                > /dev/null

              write_password_marker \
                "$marker" \
                nextcloud-admin-password
            fi

            ${nextcloudOcc} \
              user:enable administrator \
              > /dev/null \
              2>&1 || true

            ${nextcloudOcc} \
              group:adduser admin administrator \
              > /dev/null \
              2>&1 || true

            ${nextcloudOcc} \
              user:setting administrator files quota none \
              > /dev/null
          }

          rebuild_bingshan_account_once() {
            local marker="$STATE_DIRECTORY/bingshan-account-v1.done"

            delete_user_if_exists chang@bingshan.org

            if ! test -f "$marker"; then
              delete_user_if_exists bingshan

              rm -f \
                "$STATE_DIRECTORY/chang-password.sha256" \
                "$STATE_DIRECTORY/bingshan-password.sha256"

              touch "$marker"
            fi
          }

          ensure_administrator

          rebuild_bingshan_account_once

          ensure_user \
            bingshan \
            "Bingshan Chang" \
            chang@bingshan.org \
            chang-password \
            "$STATE_DIRECTORY/bingshan-password.sha256"

          ${nextcloudOcc} \
            group:removeuser admin bingshan \
            > /dev/null \
            2>&1 || true

          ${nextcloudOcc} \
            app:disable registration \
            > /dev/null \
            2>&1 || true

          source "$CREDENTIALS_DIRECTORY/whiteboard-env"

          ${nextcloudOcc} \
            config:app:set whiteboard collabBackendUrl \
            --value="https://cloud.bingshan.org/whiteboard" \
            > /dev/null

          ${nextcloudOcc} \
            config:app:set whiteboard jwt_secret_key \
            --value="$JWT_SECRET_KEY" \
            > /dev/null

          onlyoffice_jwt_secret="$(
            cat "$CREDENTIALS_DIRECTORY/onlyoffice-jwt-secret"
          )"

          ${nextcloudOcc} \
            config:app:set onlyoffice DocumentServerUrl \
            --value="https://${onlyofficeHostName}/" \
            > /dev/null

          ${nextcloudOcc} \
            config:app:set onlyoffice StorageUrl \
            --value="https://cloud.bingshan.org/" \
            > /dev/null

          ${nextcloudOcc} \
            config:app:set onlyoffice jwt_secret \
            --value="$onlyoffice_jwt_secret" \
            > /dev/null

          ${nextcloudOcc} \
            config:app:set onlyoffice jwt_header \
            --value="Authorization" \
            > /dev/null
        '';

        serviceConfig = {
          Group = "nextcloud";

          LoadCredential = [
            "chang-password:${
              config.sops.secrets."chang@bingshan.org".path
            }"
            "mail_smtppassword:${
              config.sops.secrets."cloud@bingshan.org".path
            }"
            "nextcloud-admin-password:${
              config.sops.secrets."nextcloud/admin-password".path
            }"
            "onlyoffice-jwt-secret:${
              config.sops.secrets."onlyoffice/jwt-secret".path
            }"
            "s3_secret:${
              config.sops.secrets."nextcloud/s3-secret-key".path
            }"
            "whiteboard-env:${
              config.sops.secrets."nextcloud/whiteboard-env".path
            }"
          ];

          StateDirectory = "nextcloud-provision-users";
          Type = "oneshot";
          User = "nextcloud";
        };

        wantedBy = [
          "multi-user.target"
        ];
      };
    };
  };

  sops = {
    secrets = {
      "chang@bingshan.org" = {
        restartUnits = [
          "nextcloud-provision-users.service"
        ];
      };

      "cloud@bingshan.org" = {
        restartUnits = [
          "phpfpm-nextcloud.service"
        ];
      };

      "nextcloud/admin-password" = {
        restartUnits = [
          "nextcloud-setup.service"
          "nextcloud-provision-users.service"
        ];
      };

      "nextcloud/s3-secret-key" = {
        restartUnits = [
          "nextcloud-setup.service"
          "phpfpm-nextcloud.service"
        ];
      };

      "nextcloud/whiteboard-env" = {
        restartUnits = [
          "nextcloud-provision-users.service"
          "nextcloud-whiteboard-server.service"
        ];
      };

      "onlyoffice/jwt-secret" = {
        group = "onlyoffice";
        mode = "0440";
        owner = "onlyoffice";

        restartUnits = [
          "nextcloud-provision-users.service"
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
}
