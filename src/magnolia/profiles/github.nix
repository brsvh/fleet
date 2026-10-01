{
  config,
  system,
  ...
}:
{
  imports = [
    system.modules.github-interaction-limits
  ];

  services = {
    github-interaction-limits = {
      enable = true;

      repositories = [
        "brsvh/fleet"
      ];

      tokenFile =
        config.sops.secrets.github-interaction-limits-token.path;
    };
  };

  sops = {
    secrets = {
      github-interaction-limits-token = {
        key = "github/interaction-limits-token";

        restartUnits = [
          "github-interaction-limits.service"
        ];
      };
    };
  };
}
