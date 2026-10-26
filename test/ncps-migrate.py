import contextlib
import importlib.util
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch


sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location("guard", sys.argv.pop(1))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)

SCHEMA = """
CREATE TABLE narinfos (id INTEGER PRIMARY KEY, hash TEXT, store_path TEXT,
                      nar_hash TEXT, nar_size INTEGER);
CREATE TABLE narinfo_references (narinfo_id INTEGER REFERENCES narinfos(id)
                                ON DELETE CASCADE, reference TEXT);
CREATE TABLE narinfo_signatures (narinfo_id INTEGER REFERENCES narinfos(id)
                                ON DELETE CASCADE, signature TEXT);
CREATE TABLE nar_files (id INTEGER PRIMARY KEY, hash TEXT,
                       compression TEXT, query TEXT);
CREATE TABLE narinfo_nar_files (narinfo_id INTEGER REFERENCES narinfos(id)
                               ON DELETE CASCADE, nar_file_id INTEGER);
CREATE TABLE chunks (id INTEGER PRIMARY KEY, hash TEXT);
CREATE TABLE nar_file_chunks (nar_file_id INTEGER, chunk_id INTEGER,
                             chunk_index INTEGER);
CREATE TABLE pinned_closures (hash TEXT);
CREATE TABLE schema_migrations (version_id INTEGER);
INSERT INTO schema_migrations VALUES (1);
"""

DATA = """
INSERT INTO narinfos VALUES (1, 'root', '/nix/store/root', 'sha256:test', 42);
INSERT INTO narinfo_references VALUES (1, 'dependency');
INSERT INTO narinfo_signatures VALUES (1, 'key:signature');
INSERT INTO nar_files VALUES (1, 'nar', 'xz', '');
INSERT INTO narinfo_nar_files VALUES (1, 1);
"""


@contextlib.contextmanager
def open_database(path):
    with contextlib.closing(sqlite3.connect(path)) as db:
        with db:
            yield db


class MigrationProtection(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.database = self.directory / "db.sqlite"

        with open_database(self.database) as db:
            db.executescript(SCHEMA + DATA)

    def migrate(self, _, path):
        with open_database(path) as db:
            current = db.execute("SELECT max(version_id) FROM schema_migrations").fetchone()[0]

            if current == 1:
                db.execute("ALTER TABLE narinfos ADD COLUMN extra TEXT")
                db.execute("INSERT INTO schema_migrations VALUES (2)")

    def test_upgrade_backs_up_and_preserves_metadata(self):
        with open_database(self.database) as db:
            before = list(db.iterdump())

        with patch.object(guard, "migrate", self.migrate):
            guard.protected_migrate("ncps", self.database)

        backups = list((self.directory / "migration-backups").glob("*.sqlite"))
        self.assertEqual(len(backups), 1)
        with open_database(backups[0]) as db:
            self.assertEqual(list(db.iterdump()), before)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)

        with open_database(self.database) as db:
            self.assertEqual(db.execute("SELECT signature FROM narinfo_signatures").fetchall(), [("key:signature",)])
            self.assertEqual(db.execute("SELECT max(version_id) FROM schema_migrations").fetchone(), (2,))

    def test_no_pending_migration_does_not_touch_live_database(self):
        self.migrate("ncps", self.database)
        before = self.database.read_bytes()

        with patch.object(guard, "migrate", wraps=self.migrate) as migrate:
            guard.protected_migrate("ncps", self.database)
            self.assertEqual(migrate.call_count, 1)

        self.assertEqual(self.database.read_bytes(), before)
        self.assertFalse((self.directory / "migration-backups").exists())

    def test_cascading_delete_is_rejected_before_live_migration(self):
        before = self.database.read_bytes()

        def destructive(_, path):
            with open_database(path) as db:
                db.executescript("""
                    PRAGMA foreign_keys = ON;
                    BEGIN;
                    PRAGMA foreign_keys = OFF;
                    CREATE TABLE replacement (id INTEGER PRIMARY KEY, hash TEXT,
                        store_path TEXT, nar_hash TEXT, nar_size INTEGER);
                    INSERT INTO replacement SELECT * FROM narinfos;
                    DROP TABLE narinfos;
                    ALTER TABLE replacement RENAME TO narinfos;
                    COMMIT;
                """)

        with patch.object(guard, "migrate", destructive):
            with self.assertRaisesRegex(RuntimeError, "references"):
                guard.protected_migrate("ncps", self.database)

        self.assertEqual(self.database.read_bytes(), before)

    def test_equal_counts_cannot_hide_replaced_signatures(self):
        before = self.database.read_bytes()

        def replace_signature(_, path):
            with open_database(path) as db:
                db.execute("UPDATE narinfo_signatures SET signature = 'wrong'")

        with patch.object(guard, "migrate", replace_signature):
            with self.assertRaisesRegex(RuntimeError, "signatures"):
                guard.protected_migrate("ncps", self.database)

        self.assertEqual(self.database.read_bytes(), before)

    def test_failed_migration_leaves_live_database_untouched(self):
        before = self.database.read_bytes()

        with patch.object(guard, "migrate", side_effect=RuntimeError("failed")):
            with self.assertRaisesRegex(RuntimeError, "failed"):
                guard.protected_migrate("ncps", self.database)

        self.assertEqual(self.database.read_bytes(), before)


unittest.main()
