{
  camellia,
  ...
}:
let
  bucket = "chinese-fonts-overlay-site";
in
{
  imports = [
    camellia.profiles.nginx
  ];

  services = {
    nginx = {
      virtualHosts = {
        "s3.bingshan.org" = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/" = {
              return = "404";
            };

            "~ ^/${bucket}(?:/|$)" = {
              extraConfig = ''
                client_max_body_size 1000m;
                client_body_timeout 300s;
                proxy_pass http://127.0.0.1:3900;
                proxy_http_version 1.1;
                proxy_set_header Host $host;
                proxy_set_header Connection "";
                proxy_request_buffering off;
                proxy_buffering off;
                proxy_max_temp_file_size 0;
                proxy_read_timeout 300s;
                proxy_send_timeout 300s;
              '';
            };
          };
        };
      };
    };
  };
}
