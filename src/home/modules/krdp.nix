{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.krdp;

  certificateDirectory = "${config.xdg.dataHome}/krdpserver";

  certificateFile = "${certificateDirectory}/krdp.crt";

  keyFile = "${certificateDirectory}/krdp.key";

  createCertificate = pkgs.writeShellApplication {
    name = "create-krdpserver-certificate";

    runtimeInputs = with pkgs; [
      coreutils
      openssl
      systemd
    ];

    text = ''
      dir=${escapeShellArg certificateDirectory}
      crt_file=${escapeShellArg certificateFile}
      key_file=${escapeShellArg keyFile}
      hostname=${escapeShellArg cfg.hostname}
      key_usage=critical,digitalSignature
      key_usage="$key_usage,keyEncipherment"

      install -d -m 0700 "$dir"

      is_valid=true

      if [ ! -s "$crt_file" ] \
        || [ ! -s "$key_file" ]; then
        is_valid=false
      elif ! openssl x509 -checkend 2592000 \
        -in "$crt_file" -noout >/dev/null 2>&1; then
        is_valid=false
      elif ! openssl x509 -checkhost "$hostname" \
        -in "$crt_file" -noout >/dev/null 2>&1; then
        is_valid=false
      elif ! openssl pkey -check \
        -in "$key_file" -noout >/dev/null 2>&1; then
        is_valid=false
      fi

      if [ "$is_valid" = true ]; then
        exit 0
      fi

      tmp_dir="$(mktemp -d "$dir/.crt_file.XXXXXX")"

      trap 'rm -rf -- "$tmp_dir"' EXIT
      umask 077

      openssl req \
        -addext "subjectAltName=DNS:$hostname" \
        -addext "basicConstraints=critical,CA:FALSE" \
        -addext "keyUsage=$key_usage" \
        -addext "extendedKeyUsage=serverAuth" \
        -days 825 \
        -keyout "$tmp_dir/krdp.key" \
        -newkey rsa:3072 \
        -nodes \
        -out "$tmp_dir/krdp.crt" \
        -sha256 \
        -subj "/CN=$hostname" \
        -x509

      chmod 0600 "$tmp_dir/krdp.key"
      chmod 0644 "$tmp_dir/krdp.crt"

      mv "$tmp_dir/krdp.key" "$key_file"
      mv "$tmp_dir/krdp.crt" "$crt_file"

      systemctl --user --no-block try-restart \
        app-org.kde.krdpserver.service || true
    '';
  };
in
{
  options = {
    services = {
      krdp = {
        enable = mkEnableOption "KRDP server certificate and configuration";

        hostname = mkOption {
          description = ''
            Hostname embedded in the generated KRDP TLS certificate.
          '';

          type = types.str;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs = {
      plasma = {
        configFile = {
          krdpserverrc = {
            General = {
              Autostart = true;
              Certificate = certificateFile;
              CertificateKey = keyFile;
              SystemUserEnabled = true;
            };
          };
        };
      };
    };

    systemd = {
      user = {
        services = {
          krdpserver-certificate = {
            Install = {
              WantedBy = [
                "graphical-session.target"
              ];
            };

            Service = {
              ExecStart = getExe createCertificate;
              Type = "oneshot";
            };

            Unit = {
              Before = [
                "app-org.kde.krdpserver.service"
              ];

              Description = "Generate the KRDP server certificate";

              PartOf = [
                "graphical-session.target"
              ];
            };
          };
        };
      };
    };
  };
}
