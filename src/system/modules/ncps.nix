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
    hasPrefix
    mkEnableOption
    mkForce
    mkIf
    removePrefix
    ;

  cfg = config.services.ncps;
  database = cfg.cache.databaseURL;

  migrationScript = pkgs.writeText "ncps-migrate.py" ''
    """Preflight ncps SQLite migrations before allowing changes to the live database."""

    import contextlib
    import os
    from pathlib import Path
    import shutil
    import sqlite3
    import subprocess
    import sys
    import tempfile
    import time


    # Compare identities instead of surrogate IDs, which migrations can renumber.
    QUERIES = {
        "narinfos": "SELECT hash, store_path, nar_hash, nar_size FROM narinfos",
        "references": """SELECT n.hash, r.reference FROM narinfo_references r
            JOIN narinfos n ON n.id = r.narinfo_id""",
        "signatures": """SELECT n.hash, s.signature FROM narinfo_signatures s
            JOIN narinfos n ON n.id = s.narinfo_id""",
        "nar links": """SELECT n.hash, f.hash, f.compression, f.query
            FROM narinfo_nar_files l JOIN narinfos n ON n.id = l.narinfo_id
            JOIN nar_files f ON f.id = l.nar_file_id""",
        "chunk links": """SELECT f.hash, f.compression, f.query, c.hash, l.chunk_index
            FROM nar_file_chunks l JOIN nar_files f ON f.id = l.nar_file_id
            JOIN chunks c ON c.id = l.chunk_id""",
        "pins": "SELECT hash FROM pinned_closures",
    }


    def connect(path):
        return sqlite3.connect(path.as_uri() + "?mode=ro", uri=True, timeout=30)


    def snapshot(path):
        with contextlib.closing(connect(path)) as db:
            if db.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
                raise RuntimeError("ncps database integrity check failed")

            if db.execute("PRAGMA foreign_key_check").fetchone():
                raise RuntimeError("ncps database has dangling foreign keys")

            tables = {r[0] for r in db.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
            )}
            data = {}

            for label, query in QUERIES.items():
                # Empty databases need no preservation checks. Unknown populated
                # historical schemas fail closed rather than silently losing data.
                if "narinfos" in tables:
                    data[label] = set(db.execute(query))

            versions = list(db.execute("SELECT * FROM schema_migrations")) \
                if "schema_migrations" in tables else []
            return data, versions


    def preserve(before, after):
        for label, rows in before.items():
            missing = rows - after.get(label, set())

            if missing:
                raise RuntimeError(
                    f"ncps migration would lose {len(missing)} {label} records"
                )


    def migrate(binary, path):
        subprocess.run([
            binary, "migrate", "up", "--cache-database-url", "sqlite:" + str(path),
        ], check=True)


    def protected_migrate(binary, database):
        database = Path(database).resolve()
        os.umask(0o077)
        database.parent.mkdir(parents=True, exist_ok=True)

        with tempfile.TemporaryDirectory(
            prefix=".ncps-migrate-", dir=database.parent,
        ) as temporary:
            original = Path(temporary) / "original.sqlite"

            with contextlib.closing(sqlite3.connect(original)) as backup:
                if database.exists():
                    with contextlib.closing(connect(database)) as live:
                        live.backup(backup)

            before, old_versions = snapshot(original)
            candidate = Path(temporary) / "candidate.sqlite"
            shutil.copyfile(original, candidate)
            migrate(binary, candidate)
            after, new_versions = snapshot(candidate)
            preserve(before, after)

            if old_versions == new_versions:
                print("ncps schema is current; no migration needed", flush=True)
                return

            if database.exists():
                current, versions = snapshot(database)

                if current != before or versions != old_versions:
                    raise RuntimeError("ncps database changed during preflight")

                directory = database.parent / "migration-backups"
                directory.mkdir(mode=0o700, exist_ok=True)
                saved = directory / f"before-{time.time_ns()}.sqlite"
                shutil.copyfile(original, saved)

                with saved.open("rb") as stream:
                    os.fsync(stream.fileno())

                print(f"ncps migration backup: {saved}", flush=True)

            migrate(binary, database)
            current, _ = snapshot(database)
            preserve(before, current)
            print("ncps migration preserved cache metadata", flush=True)


    if __name__ == "__main__":
        protected_migrate(sys.argv[1], sys.argv[2])
  '';

  sqlite =
    database != null && hasPrefix "sqlite:/" database;
in
{
  options = {
    services = {
      ncps = {
        protectMigrations = mkEnableOption "ncps SQLite migration preflight and backups";
      };
    };
  };

  config =
    mkIf (cfg.enable && cfg.protectMigrations)
      {
        assertions = [
          {
            assertion =
              sqlite && cfg.cache.databaseURLFile == null;

            message = ''
              ncps migration protection requires an explicit local SQLite database URL.
            '';
          }
        ];

        systemd = {
          services = {
            ncps = {
              # Replace the upstream unguarded migrate command, not just prepend it.
              preStart = mkForce ''
                ${getExe pkgs.python3} ${migrationScript} \
                  ${escapeShellArg (getExe cfg.package)} \
                  ${escapeShellArg (
                    removePrefix "sqlite:" database
                  )}
              '';
            };
          };
        };
      };
}
