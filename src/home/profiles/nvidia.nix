{
  config,
  home,
  ...
}:
{
  imports = [
    home.profiles.xdg
  ];

  home = {
    sessionVariables = {
      CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    };
  };
}
