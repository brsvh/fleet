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
    getName
    hiPrio
    literalExpression
    mkDefault
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.antigravity-cli;

  upstreamGeminiDir = "${config.home.homeDirectory}/.gemini";

  useGeminiConfig =
    cfg.useLegacyGeminiConfig
    || (
      cfg.package != null
      && getName cfg.package == "gemini-cli"
    );

  redirectGeminiDir =
    cfg.enable
    && cfg.package != null
    && !useGeminiConfig
    && cfg.geminiDir != upstreamGeminiDir;

  # agy ignores XDG and directory env vars, so forward
  # ANTIGRAVITY_GEMINI_DIR via its --gemini_dir flag.
  geminiDirWrapper = pkgs.writeShellScriptBin "agy" ''
    has_gemini_dir=0
    for arg in "$@"; do
      case "$arg" in
        --)
          break
          ;;
        --gemini_dir|--gemini_dir=*|--gemini-dir|--gemini-dir=*)
          has_gemini_dir=1
          break
          ;;
      esac
    done

    if [ "$has_gemini_dir" -eq 0 ]; then
      gemini_dir=${escapeShellArg cfg.geminiDir}
      if [ -n "''${ANTIGRAVITY_GEMINI_DIR:-}" ]; then
        gemini_dir="$ANTIGRAVITY_GEMINI_DIR"
      fi

      exec ${getExe cfg.package} \
        --gemini_dir "$gemini_dir" \
        "$@"
    fi

    exec ${getExe cfg.package} "$@"
  '';
in
{
  options = {
    programs = {
      antigravity-cli = {
        geminiDir = mkOption {
          default = upstreamGeminiDir;

          defaultText = literalExpression ''
            "''${config.home.homeDirectory}/.gemini"
          '';

          description = ''
            Directory where Antigravity CLI stores its configuration and
            application data. When set to a path other than the upstream
            default, `ANTIGRAVITY_GEMINI_DIR` is exported and `agy` is
            wrapped to forward it via `--gemini_dir`.
          '';

          example = literalExpression ''
            "''${config.xdg.dataHome}/antigravity"
          '';

          type = types.str;
        };
      };
    };
  };

  config = {
    home = {
      packages = mkIf redirectGeminiDir [
        (hiPrio geminiDirWrapper)
      ];

      sessionVariables = mkIf redirectGeminiDir {
        ANTIGRAVITY_GEMINI_DIR = mkDefault cfg.geminiDir;
      };
    };
  };
}
