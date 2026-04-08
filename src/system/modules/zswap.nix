# For more information see https://github.com/NixOS/nixpkgs/pull/470366
#
# Reference documentation:
# - https://docs.kernel.org/admin-guide/mm/zswap.html
# - https://www.kernel.org/doc/html/v6.1/admin-guide/mm/zswap.html
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    toString
    types
    versionAtLeast
    ;

  cfg = config.boot.zswap;

  kernelVersion =
    config.boot.kernelPackages.kernel.version;

  zsmallocSupported = versionAtLeast kernelVersion "6.3";
in
{
  options = {
    boot = {
      zswap = {
        acceptThresholdPercent = mkOption {
          default = 90;

          description = ''
            Threshold percentage at which zswap starts accepting pages again
            after the pool becomes full (1-100).

            This parameter provides hysteresis to prevent pool oscillation.
            When the pool usage drops below this threshold, zswap starts
            accepting new pages.  Default is 90% as recommended by kernel
            documentation.
          '';

          type = types.ints.between 1 100;
        };

        compressor = mkOption {
          default = "zstd";

          description = ''
            Compression algorithm to use for zswap.

            Available options:
            - 'zstd': Best compression ratio, excellent for Nix builds (default)
            - 'lz4': Fastest compression, lowest latency
            - 'lz4hc': High-compression variant of lz4, slower but better ratio
            - 'lzo': Good balance of speed and compression (kernel default)
            - 'deflate': Higher compression, slower processing
            - '842': Hardware-accelerated compression on supported systems

            Note: The chosen algorithm must be supported by your kernel
            configuration.
          '';

          type = types.enum [
            "zstd"
            "lz4"
            "lzo"
            "lz4hc"
            "deflate"
            "842"
          ];
        };

        enable = mkEnableOption "Zswap (Compressed Cache for Swap Pages)";

        maxPoolPercent = mkOption {
          default = 25;

          description = ''
            The maximum percentage of system memory that Zswap can occupy.

            Higher values provide more compression cache but increase memory
            pressure.

            Default is 25% (higher than kernel default of 20%) for better Nix
            build performance.

            Recommended ranges:
            - Desktop systems: 15-25%
            - Low-memory systems: 30-50%
            - Server systems: 10-20%
          '';

          type = types.ints.between 1 100;
        };

        shrinkerEnabled = mkOption {
          default = true;

          description = ''
            Enable the zswap shrinker to reclaim memory when under pressure.

            When enabled, the shrinker will automatically reclaim compressed
            pages from the zswap pool when the system is under memory pressure,
            helping to prevent out-of-memory situations.

            It is recommended to keep this enabled for most workloads,
            especially on systems with limited memory.
          '';

          type = types.bool;
        };

        zpool = mkOption {
          default =
            if zsmallocSupported then "zsmalloc" else "zbud";

          description = ''
            Kernel zpool allocator.

            'zsmalloc' is strongly recommended for kernels >= 6.3 as it offers
            the best density.  For older kernels, 'zbud' is the fallback.

            Note: 'z3fold' was removed from Linux kernel 6.8 and later.
          '';

          type = types.enum [
            "zsmalloc"
            "zbud"
          ];
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.zramSwap.enable;

        message = ''
          Conflicting options enabled: 'boot.zswap.enable' and
          'zramSwap.enable'.

          You cannot enable Zswap and Zram simultaneously as it leads to double
          compression and inefficient memory management.

          Please disable one of them:
            - To use Zswap (requires a physical swap device): Set
              'zramSwap.enable = false'.
            - To use Zram (swap in RAM): Set 'boot.zswap.enable = false'.
        '';
      }
      {
        assertion = config.swapDevices != [ ];

        message = ''
          Zswap requires at least one physical swap device to function as a
          backing store.

          Try adding the following to your configuration (example):

          swapDevices = [ {
            device = "/var/lib/swapfile";
            size = 16 * 1024; # 16GB
          } ];
        '';
      }
      {
        assertion =
          (cfg.zpool == "zsmalloc") -> zsmallocSupported;

        message = ''

          Zswap allocator 'zsmalloc' is not supported on kernel version
          ${kernelVersion}.

          Support for zsmalloc in Zswap was added in Linux 6.3.

          Please use 'zbud' instead: boot.zswap.zpool = "zbud";
        '';
      }
    ];

    boot = {
      kernel = {
        sysfs = {
          module = {
            zswap = {
              parameters = {
                enabled = true;
                compressor = cfg.compressor;
                zpool = cfg.zpool;
                max_pool_percent = cfg.maxPoolPercent;
                accept_threshold_percent =
                  cfg.acceptThresholdPercent;
                shrinker_enabled = true;
              };
            };
          };
        };
      };

      kernelParams = [
        "zswap.enabled=1"
        "zswap.compressor=${cfg.compressor}"
        "zswap.zpool=${cfg.zpool}"
        "zswap.max_pool_percent=${toString cfg.maxPoolPercent}"
        "zswap.accept_threshold_percent=${toString cfg.acceptThresholdPercent}"
        "zswap.shrinker_enabled=${
          if cfg.shrinkerEnabled then "1" else "0"
        }"
      ];

      initrd = {
        kernelModules = [
          cfg.compressor
          cfg.zpool
        ];
      };
    };
  };
}
