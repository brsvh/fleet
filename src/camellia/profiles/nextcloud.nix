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
    writeText
    ;

  cfg = config.services.nextcloud;

  garage = {
    capacity = "53687091200";
    config = config.services.garage;

    env = writeText "garage.env" ''
      GARAGE_RPC_SECRET_FILE=${
        secrets."garage/rpc-secret".path
      }
    '';

    zone = "camellia";
  };

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
    system.profiles.garage
    system.profiles.nextcloud
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        443
      ];
    };

    hosts = {
      "95.133.228.83" = [
        officeServer
      ];

      "2a0b:7140:8:1:5054:ff:feef:6795" = [
        officeServer
      ];
    };
  };

  services = {
    garage = {
      environmentFile = garage.env;
    };

    nextcloud = {
      config = {
        adminpassFile = secrets."chang@bingshan.org".path;

        adminuser = "bingshan";

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

    onlyoffice = {
      enable = true;
      hostname = officeServer;
      jwtSecretFile =
        secrets."onlyoffice/jwt-secret".path;
      securityNonceFile =
        secrets."onlyoffice/security-nonce".path;
    };
  };

  systemd = {
    services = {
      garage-configure = {
        after = [
          "garage.service"
        ];

        before = [
          "nextcloud-setup.service"
        ];

        path = [
          garage.config.package
        ]
        ++ (with pkgs; [
          coreutils
          gnused
          jq
        ]);

        requires = [
          "garage.service"
        ];

        script = ''
          set -euo pipefail

          trap 'printf "garage-configure failed at line %s\n" "$LINENO" >&2' ERR

          garage_capacity_bytes="${garage.capacity}"
          garage_zone="${garage.zone}"
          nextcloud_bucket_name="${store.bucketName}"
          nextcloud_key_id="${store.keyId}"
          nextcloud_key_name="${store.keyName}"

          cluster_status_file="$STATE_DIRECTORY/cluster-status.json"
          cluster_layout_file="$STATE_DIRECTORY/cluster-layout.json"
          bucket_info_file="$STATE_DIRECTORY/nextcloud-bucket.json"
          key_info_file="$STATE_DIRECTORY/nextcloud-key.json"

          garage_admin() {
            garage \
              --rpc-secret-file "$CREDENTIALS_DIRECTORY/garage-rpc-secret" \
              "$@"
          }

          garage_json() {
            garage_admin json-api "$@"
          }

          refresh_cluster_files() {
            garage_json GetClusterStatus \
              > "$cluster_status_file"

            garage_json GetClusterLayout \
              > "$cluster_layout_file"
          }

          garage_node_id() {
            garage_admin node id \
              2> /dev/null \
              | sed -n 's/^\([0-9a-f]\{64\}\)@.*/\1/p' \
              | head -n 1
          }

          wait_for_local_node() {
            local attempt="$1"
            local node_id="$2"

            while test "$attempt" -le 60; do
              if refresh_cluster_files &&
                jq \
                  --exit-status \
                  --arg id "$node_id" \
                  '.nodes[]? | select(.id == $id and .isUp)' \
                  "$cluster_status_file" \
                  > /dev/null
              then
                return
              fi

              sleep 1
              attempt="$((attempt + 1))"
            done

            printf 'Garage local node %s did not become visible through the admin API.\n' \
              "$node_id" \
              >&2
            return 1
          }

          layout_is_desired() {
            local node_id="$1"

            jq \
              --exit-status \
              --arg id "$node_id" \
              --arg zone "$garage_zone" \
              --argjson capacity "$garage_capacity_bytes" \
              '
                .nodes[]?
                | select(
                    .id == $id
                    and .role != null
                    and .role.zone == $zone
                    and .role.tags == []
                    and .role.capacity == $capacity
                  )
              ' \
              "$cluster_status_file" \
              > /dev/null
          }

          refuse_non_empty_mismatch_layout() {
            local node_id="$1"

            if jq \
              --exit-status \
              --arg id "$node_id" \
              '.nodes[]? | select(.id == $id and .role != null)' \
              "$cluster_status_file" \
              > /dev/null
            then
              printf 'Garage node %s already has a non-matching layout role.\n' \
                "$node_id" \
                >&2
              return 1
            fi

            if jq \
              --exit-status \
              '.roles | length > 0' \
              "$cluster_layout_file" \
              > /dev/null
            then
              printf 'Garage cluster layout is not empty; refusing automatic reassignment.\n' \
                >&2
              return 1
            fi

            if jq \
              --exit-status \
              '(.stagedRoleChanges | length > 0) or (.stagedParameters != null)' \
              "$cluster_layout_file" \
              > /dev/null
            then
              printf 'Garage already has staged layout changes; refusing to overwrite them.\n' \
                >&2
              return 1
            fi
          }

          ensure_layout() {
            local next_layout_version
            local node_id

            node_id="$(garage_node_id)"

            if test -z "$node_id"; then
              printf 'Unable to determine the local Garage node id.\n' >&2
              return 1
            fi

            wait_for_local_node 1 "$node_id"

            if layout_is_desired "$node_id"; then
              return
            fi

            refuse_non_empty_mismatch_layout "$node_id"

            next_layout_version="$(
              jq --raw-output '.version + 1' "$cluster_layout_file"
            )"

            jq \
              --null-input \
              --arg id "$node_id" \
              --arg zone "$garage_zone" \
              --argjson capacity "$garage_capacity_bytes" \
              '{
                roles: [
                  {
                    id: $id,
                    zone: $zone,
                    tags: [],
                    capacity: $capacity
                  }
                ],
                parameters: {
                  zoneRedundancy: "maximum"
                }
              }' \
              | garage_json UpdateClusterLayout - \
              > /dev/null

            jq \
              --null-input \
              --argjson version "$next_layout_version" \
              '{ version: $version }' \
              | garage_json ApplyClusterLayout - \
              > /dev/null

            wait_for_local_node 1 "$node_id"

            if ! layout_is_desired "$node_id"; then
              printf 'Garage layout was applied but does not match the desired role.\n' \
                >&2
              return 1
            fi
          }

          get_nextcloud_key() {
            jq \
              --null-input \
              --arg id "$nextcloud_key_id" \
              '{ id: $id }' \
              | garage_json GetKeyInfo - \
              > "$key_info_file"
          }

          ensure_nextcloud_key() {
            if get_nextcloud_key 2> /dev/null; then
              return
            fi

            jq \
              --null-input \
              --raw-input \
              --arg accessKeyId "$nextcloud_key_id" \
              --arg name "$nextcloud_key_name" \
              '
                (input | sub("[\r\n]+$"; "")) as $secretAccessKey
                | {
                    accessKeyId: $accessKeyId,
                    secretAccessKey: $secretAccessKey,
                    name: $name
                  }
              ' \
              < "$CREDENTIALS_DIRECTORY/nextcloud-s3-secret-key" \
              | garage_json ImportKey - \
              > /dev/null

            get_nextcloud_key \
              > /dev/null
          }

          get_nextcloud_bucket() {
            jq \
              --null-input \
              --arg globalAlias "$nextcloud_bucket_name" \
              '{ globalAlias: $globalAlias }' \
              | garage_json GetBucketInfo - \
              > "$bucket_info_file"
          }

          ensure_nextcloud_bucket() {
            if get_nextcloud_bucket 2> /dev/null; then
              return
            fi

            jq \
              --null-input \
              --arg globalAlias "$nextcloud_bucket_name" \
              '{ globalAlias: $globalAlias }' \
              | garage_json CreateBucket - \
              > "$bucket_info_file"
          }

          ensure_nextcloud_bucket_permissions() {
            local bucket_id

            bucket_id="$(
              jq --raw-output '.id' "$bucket_info_file"
            )"

            if jq \
              --exit-status \
              --arg accessKeyId "$nextcloud_key_id" \
              '
                .keys[]?
                | select(
                    .accessKeyId == $accessKeyId
                    and .permissions.read
                    and .permissions.write
                  )
              ' \
              "$bucket_info_file" \
              > /dev/null
            then
              return
            fi

            jq \
              --null-input \
              --arg bucketId "$bucket_id" \
              --arg accessKeyId "$nextcloud_key_id" \
              '{
                bucketId: $bucketId,
                accessKeyId: $accessKeyId,
                permissions: {
                  read: true,
                  write: true,
                  owner: false
                }
              }' \
              | garage_json AllowBucketKey - \
              > "$bucket_info_file"
          }

          ensure_layout
          ensure_nextcloud_key
          ensure_nextcloud_bucket
          ensure_nextcloud_bucket_permissions
        '';

        serviceConfig = {
          Group = "garage";

          LoadCredential = [
            "garage-rpc-secret:${
              secrets."garage/rpc-secret".path
            }"
            "nextcloud-s3-secret-key:${store.secret}"
          ];

          StateDirectory = "garage-configure";
          Type = "oneshot";
          User = "garage";
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
    };
  };

  sops = {
    secrets = {
      "garage/rpc-secret" = {
        owner = "garage";

        restartUnits = [
          "garage.service"
          "garage-configure.service"
        ];
      };

      "chang@bingshan.org" = {
        restartUnits = [
          "nextcloud-configure.service"
          "nextcloud-setup.service"
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
}
