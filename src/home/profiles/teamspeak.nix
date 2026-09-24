{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      teamspeak6-client
    ];
  };
}
