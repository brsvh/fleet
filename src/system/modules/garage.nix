{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optionalString
    toJSON
    types
    ;

  cfg = config.services.garage.provision;
  garage = config.services.garage;
  keys = cfg.keys;

  keyCommands = mapAttrsToList (name: key: ''
    ensure_key ${escapeShellArg name} ${escapeShellArg key.id}
  '') keys;

  bucketCommands = mapAttrsToList (name: bucket: ''
    ensure_bucket ${escapeShellArg name}
    ${optionalString (bucket.maximumSize != null) ''
      garage_admin bucket set-quotas ${escapeShellArg name} \
        --max-size ${toString bucket.maximumSize} > /dev/null
    ''}
    ${concatStringsSep "\n" (
      mapAttrsToList (key: write: ''
        set_permission ${escapeShellArg keys.${key}.id} ${
          if write then "true" else "false"
        }
      '') bucket.keys
    )}
    revoke_undeclared_permissions ${
      escapeShellArg (
        toJSON (
          mapAttrsToList (
            key: _: keys.${key}.id
          ) bucket.keys
        )
      )
    }
  '') cfg.buckets;
in
{
  options = {
    services = {
      garage = {
        provision = {
          buckets = mkOption {
            default = { };

            description = ''
              Buckets and read or read/write access grants.
            '';

            type =
              with types;
              attrsOf (submodule {
                options = {
                  keys = mkOption {
                    default = { };

                    description = ''
                      Key names mapped to whether writing is allowed.
                    '';

                    type = with types; attrsOf bool;
                  };

                  maximumSize = mkOption {
                    default = null;

                    description = ''
                      Optional logical object-size quota in bytes.
                    '';

                    type = with types; nullOr ints.positive;
                  };
                };
              });
          };

          capacity = mkOption {
            description = ''
              Local node capacity in bytes.
            '';

            type = types.ints.positive;
          };

          enable = mkEnableOption "declarative Garage provisioning";

          keys = mkOption {
            default = { };

            description = ''
              Named access keys imported from runtime secrets.
            '';

            type =
              with types;
              attrsOf (submodule {
                options = {
                  id = mkOption {
                    description = ''
                      Public Garage access key identifier.
                    '';

                    type = types.str;
                  };

                  secretFile = mkOption {
                    description = ''
                      Runtime file containing the secret access key.
                    '';

                    type = types.str;
                  };
                };
              });
          };

          rpcSecretFile = mkOption {
            description = ''
              Runtime path to the Garage RPC secret.
            '';

            type = types.str;
          };

          zone = mkOption {
            description = ''
              Local node zone.
            '';

            type = types.str;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      services = {
        garage-configure = {
          after = [
            "garage.service"
          ];

          path = [
            garage.package
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
            umask 077
            garage_capacity_bytes="${toString cfg.capacity}"
            garage_zone=${escapeShellArg cfg.zone}
            cluster_status_file="$STATE_DIRECTORY/cluster-status.json"
            cluster_layout_file="$STATE_DIRECTORY/cluster-layout.json"
            bucket_info_file="$STATE_DIRECTORY/bucket.json"

            garage_admin() {
              garage --rpc-secret-file \
                "$CREDENTIALS_DIRECTORY/garage-rpc-secret" "$@"
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
              local node_id attempt

              for attempt in $(seq 1 60); do
                node_id="$(garage_node_id)" && test -n "$node_id" && break
                sleep 1
              done

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

            ensure_key() {
              local name="$1" id="$2"

              if jq -n --arg id "$id" '{id: $id}' | \
                garage_json GetKeyInfo - > /dev/null 2>&1; then
                return
              fi

              jq -nR --arg accessKeyId "$id" --arg name "$name" '
                (input | sub("[\r\n]+$"; "")) as $secretAccessKey |
                {accessKeyId: $accessKeyId, name: $name,
                 secretAccessKey: $secretAccessKey}
              ' < "$CREDENTIALS_DIRECTORY/key-$name" | \
                garage_json ImportKey - > /dev/null
            }

            ensure_bucket() {
              local name="$1"

              if jq -n --arg globalAlias "$name" '{globalAlias: $globalAlias}' | \
                garage_json GetBucketInfo - > "$bucket_info_file" 2>/dev/null; then
                return
              fi

              jq -n --arg globalAlias "$name" '{globalAlias: $globalAlias}' | \
                garage_json CreateBucket - > "$bucket_info_file"
            }

            set_permission() {
              local id="$1" write="$2" bucket_id
              bucket_id="$(jq -r '.id' "$bucket_info_file")"

              if jq -e --arg id "$id" --argjson write "$write" '
                .keys[]? | select(.accessKeyId == $id
                  and .permissions.read == true
                  and .permissions.write == $write
                  and .permissions.owner == false)
              ' "$bucket_info_file" > /dev/null; then
                return
              fi

              # Remove elevated grants before applying the declared access.
              jq -n --arg bucketId "$bucket_id" --arg accessKeyId "$id" '
                {bucketId: $bucketId, accessKeyId: $accessKeyId,
                 permissions: {read: false, write: true, owner: true}}
              ' | garage_json DenyBucketKey - > /dev/null
              jq -n --arg bucketId "$bucket_id" --arg accessKeyId "$id" \
                --argjson write "$write" '
                {bucketId: $bucketId, accessKeyId: $accessKeyId,
                 permissions: {read: true, write: $write, owner: false}}
              ' | garage_json AllowBucketKey - > /dev/null
            }

            revoke_undeclared_permissions() {
              local declared_ids="$1"
              local bucket_id access_key_id undeclared_keys

              bucket_id="$(jq -r '.id' "$bucket_info_file")"
              undeclared_keys="$(
                jq -r --argjson declared "$declared_ids" '
                  .keys[]?
                  | select(
                      (.permissions.read or .permissions.write or .permissions.owner)
                      and (($declared | index(.accessKeyId)) == null)
                    )
                  | .accessKeyId
                ' "$bucket_info_file"
              )"

              while IFS= read -r access_key_id; do
                if test -z "$access_key_id"; then
                  continue
                fi

                jq -n --arg bucketId "$bucket_id" --arg accessKeyId "$access_key_id" '
                  {bucketId: $bucketId, accessKeyId: $accessKeyId,
                   permissions: {read: true, write: true, owner: true}}
                ' | garage_json DenyBucketKey - > /dev/null
              done <<< "$undeclared_keys"
            }

            ensure_layout
            ${concatStringsSep "\n" keyCommands}
            ${concatStringsSep "\n" bucketCommands}
          '';

          serviceConfig = {
            Group = "garage";

            LoadCredential = [
              "garage-rpc-secret:${cfg.rpcSecretFile}"
            ]
            ++ mapAttrsToList (
              name: key: "key-${name}:${key.secretFile}"
            ) keys;

            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            StateDirectory = "garage-configure";
            StateDirectoryMode = "0700";
            Type = "oneshot";
            UMask = "0077";
            User = "garage";
          };

          wantedBy = [
            "multi-user.target"
          ];
        };
      };
    };
  };
}
