{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    all
    concatLists
    concatStringsSep
    elem
    escapeShellArg
    escapeShellArgs
    filter
    hasAttr
    length
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    optionalString
    optionals
    types
    unique
    ;

  inherit (pkgs)
    coreutils
    gawk
    runCommand
    systemd
    util-linux
    writeScript
    writeShellScript
    writeText
    ;

  cfg = config.services.inn;

  upstreamType = types.submodule {
    options = {
      endpoint = mkOption {
        description = ''
          Upstream endpoint in pullnews host, port, and TLS-mode syntax.
        '';

        type = types.str;
      };

      groups = mkOption {
        default = [ ];

        description = ''
          Newsgroups mirrored from this upstream.
        '';

        type = with types; listOf str;
      };

      normalizeDuplicatePath = mkOption {
        default = false;

        description = ''
          Rename additional Path fields to X-Archive-Original-Path before
          importing articles from this upstream. Preserve the unmodified
          article in the archive originals directory.
        '';

        type = types.bool;
      };

      normalizeLegacyDate = mkOption {
        default = false;

        description = ''
          Convert recognized day-month-year Usenet dates to numeric-zone dates.
          Retain the original Date field and the unmodified article.
        '';

        type = types.bool;
      };

      passwordCredential = mkOption {
        default = null;

        description = ''
          systemd credential filename containing the upstream password.
        '';

        type = with types; nullOr str;
      };

      username = mkOption {
        default = null;

        description = ''
          Username used to authenticate to this upstream.
        '';

        type = with types; nullOr str;
      };
    };
  };

  subscribedGroups = concatLists (
    mapAttrsToList (_: upstream: upstream.groups) (
      cfg.upstreams
    )
  );

  groups = unique subscribedGroups;

  internalGroups = [
    "control"
    "control.cancel"
    "control.checkgroups"
    "control.newgroup"
    "control.rmgroup"
    "junk"
  ];

  activeGroups = internalGroups ++ groups;

  passwordCredentials =
    filter (credential: credential != null)
      (
        mapAttrsToList (
          _: upstream: upstream.passwordCredential
        ) cfg.upstreams
      );

  makeMarks =
    upstream:
    let
      authentication =
        optionalString (upstream.username != null)
          " ${upstream.username} @credential:${upstream.passwordCredential}";
    in
    ''
      ${upstream.endpoint}${authentication}
      ${concatStringsSep "\n" (
        map (group: "    ${group}") upstream.groups
      )}
    '';

  marks = writeText "pullnews.marks" (
    concatStringsSep "\n" (
      mapAttrsToList (_: makeMarks) cfg.upstreams
    )
  );

  backfillGroups = writeText "inn-backfill-groups" (
    concatStringsSep "\n" groups + "\n"
  );

  active = writeText "active" (
    concatStringsSep "\n" (
      map (
        group:
        "${group} 0000000000 0000000001 ${
          if elem group groups then "y" else "n"
        }"
      ) activeGroups
    )
    + "\n"
  );

  newsgroups = writeText "newsgroups" (
    concatStringsSep "\n" (
      map (
        group: "${group}\tLocal pullnews mirror"
      ) activeGroups
    )
    + "\n"
  );

  activeTimes = writeText "active.times" (
    concatStringsSep "\n" (
      map (group: "${group} 0 ${cfg.user}") (
        activeGroups
      )
    )
    + "\n"
  );

  perlWithTls =
    pkgs.perl.withPackages
      (perlPackages: [
        perlPackages.IOSocketSSL
        perlPackages.TimeDate
      ]);

  archiveConfiguration =
    (pkgs.formats.json { }).generate
      "inn-archive.json"
      {
        localEndpoint = "${cfg.bindAddress}:${toString cfg.port}";
        stateDirectory = cfg.stateDirectory;
        upstreams = mapAttrsToList (
          _: upstream: upstream
        ) cfg.upstreams;
      };

  archiveTool = pkgs.writeShellScriptBin "inn-archive" ''
    exec ${pkgs.python3}/bin/python3 ${writeText "inn-archive.py" ''
      """Private INN synchronization, inventory, and durable failed-article recovery."""

      import argparse
      from collections import Counter
      from contextlib import ExitStack, contextmanager
      from email.utils import format_datetime, parsedate_to_datetime
      import fcntl
      import hashlib
      import json
      import os
      from pathlib import Path
      import re
      import signal
      import socket
      import sqlite3
      import ssl
      import sys
      import tempfile
      import time


      class ProtocolError(RuntimeError):
          pass


      class NNTP:
          def __init__(self, endpoint, username=None, password=None, reader=True):
              self.endpoint = endpoint
              match = re.fullmatch(r"([^:\s]+)(?::([0-9]+))?(?:_(TLS|STARTTLS))?", endpoint)
              if not match:
                  raise ValueError("invalid NNTP endpoint")
              host, port, mode = match.groups()
              self.sock = socket.create_connection(
                  (host, int(port or (563 if mode == "TLS" else 119))), timeout=30
              )
              self.stream = None
              try:
                  if mode == "TLS":
                      self.sock = ssl.create_default_context().wrap_socket(
                          self.sock, server_hostname=host
                      )
                  self.stream = self.sock.makefile("rb")
                  self.expect(self.readline(), (200, 201))
                  if mode == "STARTTLS":
                      self.expect(self.command("STARTTLS"), (382,))
                      self.stream.close()
                      self.sock = ssl.create_default_context().wrap_socket(
                          self.sock, server_hostname=host
                      )
                      self.stream = self.sock.makefile("rb")
                  if username is not None:
                      reply = self.command("AUTHINFO USER " + username)
                      if reply.startswith("381 "):
                          reply = self.command("AUTHINFO PASS " + password)
                      # Do not include a server response that could echo credentials.
                      if not reply.startswith("281 "):
                          raise ProtocolError("NNTP authentication failed")
                  if reader:
                      self.expect(self.command("MODE READER"), (200, 201, 500, 501))
                      # Complete nnrpd's first-command handshake before waiting on an upstream.
                      self.expect(self.command("DATE"), (111, 500, 501))
              except BaseException:
                  self.close()
                  raise

          def __enter__(self):
              return self

          def __exit__(self, *args):
              self.close()

          def close(self):
              if self.stream is not None:
                  self.stream.close()
              self.sock.close()

          def readline(self):
              line = self.stream.readline()
              if not line:
                  raise ProtocolError(f"NNTP connection closed by {self.endpoint}")
              return line.rstrip(b"\r\n").decode("utf-8", "replace")

          def command(self, value):
              if any(character in value for character in "\r\n\x00"):
                  raise ValueError("newline or NUL in NNTP command")
              self.sock.sendall(value.encode("utf-8", "surrogateescape") + b"\r\n")
              return self.readline()

          @staticmethod
          def expect(reply, codes):
              if int(reply[:3]) not in codes:
                  raise ProtocolError(reply)
              return reply

          def multiline(self):
              while True:
                  line = self.stream.readline()
                  if not line:
                      raise ProtocolError(f"incomplete NNTP multiline response from {self.endpoint}")
                  if line == b".\r\n":
                      return
                  yield line[1:] if line.startswith(b"..") else line

          def group(self, name):
              fields = self.expect(self.command("GROUP " + name), (211,)).split()
              return tuple(int(value) for value in fields[1:4])

          def ids(self, first, last):
              """Read one bounded range completely before callers advance any cursor."""
              interval = f"{first}-{last}"
              reply = self.command("HDR Message-ID " + interval)
              if reply.startswith(("500 ", "501 ")):
                  reply = self.command("XHDR Message-ID " + interval)
              if reply.startswith(("500 ", "501 ")):
                  reply = self.command("XOVER " + interval)
              if reply.startswith(("423 ", "430 ")):
                  return []
              self.expect(reply, (221, 224, 225))
              overview = reply.startswith("224 ")
              result = []
              for line in self.multiline():
                  fields = (
                      line.rstrip(b"\r\n").split(b"\t")
                      if overview
                      else line.rstrip(b"\r\n").split(None, 1)
                  )
                  index = 4 if overview else 1
                  if len(fields) <= index or not fields[0].isdigit():
                      raise ProtocolError("malformed article index response")
                  number = int(fields[0])
                  if not first <= number <= last:
                      raise ProtocolError("article index number outside requested range")
                  result.append((number, fields[index].decode("utf-8", "replace")))
              if len({number for number, _ in result}) != len(result):
                  raise ProtocolError("duplicate article numbers in index response")
              return sorted(result)

          def exists(self, message_id):
              if not valid_message_id(message_id):
                  return False
              reply = self.command("STAT " + message_id)
              self.expect(reply, (223, 430))
              return reply.startswith("223 ")

          def article(self, number):
              reply = self.command("ARTICLE " + str(number))
              if reply.startswith(("423 ", "430 ")):
                  return None
              self.expect(reply, (220,))
              return b"".join(self.multiline())

          def offer(self, message_id, article):
              reply = self.command("IHAVE " + message_id)
              if reply.startswith("335 "):
                  lines = article.split(b"\r\n")
                  if lines[-1] == b"":
                      lines.pop()
                  wire = b"".join(
                      (b"." if line.startswith(b".") else b"") + line + b"\r\n"
                      for line in lines
                  )
                  self.sock.sendall(wire + b".\r\n")
                  reply = self.readline()
              self.expect(reply, (235, 435, 436, 437))
              return reply


      def valid_message_id(value):
          return (
              value.isascii()
              and re.fullmatch(r"<[^<>\s\x00-\x1f\x7f]+@[^<>\s\x00-\x1f\x7f]+>", value)
              is not None
          )


      def article_message_id(article):
          header = article.replace(b"\r\n", b"\n").split(b"\n\n", 1)[0]
          fields = re.findall(rb"(?im)^Message-ID:[ \t]*(.*)$", header)
          if len(fields) != 1:
              return None
          return fields[0].strip().decode("utf-8", "replace")


      def normalize_path(article):
          """Retain the first Path; preserve additional fields under an archival name."""
          header, separator, body = article.partition(b"\r\n\r\n")
          if not separator:
              raise ValueError("article has no CRLF header/body separator")
          seen = False
          fields = []
          for line in header.split(b"\r\n"):
              if line.lower().startswith(b"path:"):
                  if seen:
                      line = b"X-Archive-Original-Path:" + line.split(b":", 1)[1]
                  seen = True
              fields.append(line)
          return b"\r\n".join(fields) + separator + body


      def normalize_date(article):
          """Convert recognized old Usenet dates without guessing unknown time zones."""
          header, separator, body = article.partition(b"\r\n\r\n")
          if not separator:
              raise ValueError("article has no CRLF header/body separator")
          fields = []
          for line in header.split(b"\r\n"):
              match = re.fullmatch(
                  rb"Date:[ \t]*((?:[A-Za-z]{3},?\s+)?)([0-9]{1,2})-([A-Za-z]{3})-([0-9]{2}|[0-9]{4})"
                  rb"(\s+[0-9]{2}:[0-9]{2}(?::[0-9]{2})?\s+(?:UT|GMT|[ECMP][DS]T|[+-][0-9]{4}))[ \t]*",
                  line,
                  re.IGNORECASE,
              )
              if match:
                  prefix, day, month, year, suffix = match.groups()
                  date = parsedate_to_datetime(
                      (prefix + day + b" " + month + b" " + year + suffix).decode("ascii")
                  )
                  if date.tzinfo is None:
                      raise ValueError("legacy date has no known time zone")
                  fields.append(b"Date: " + format_datetime(date).encode("ascii"))
                  line = b"X-Archive-Original-Date:" + line.split(b":", 1)[1]
              fields.append(line)
          return b"\r\n".join(fields) + separator + body


      def atomic_write(path, data):
          path = Path(path)
          descriptor, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
          try:
              with os.fdopen(descriptor, "wb") as stream:
                  stream.write(data)
                  stream.flush()
                  os.fsync(stream.fileno())
              os.replace(temporary, path)
              directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
              try:
                  os.fsync(directory)
              finally:
                  os.close(directory)
          finally:
              if os.path.exists(temporary):
                  os.unlink(temporary)


      class State:
          def __init__(self, directory):
              self.directory = Path(directory) / "archive"
              self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
              self.raw = self.directory / "originals"
              self.raw.mkdir(mode=0o700, exist_ok=True)
              self.db = sqlite3.connect(self.directory / "articles.sqlite", timeout=30)
              self.db.execute("PRAGMA journal_mode=WAL")
              self.db.execute("PRAGMA synchronous=FULL")
              self.db.execute("""CREATE TABLE IF NOT EXISTS articles (
                  endpoint TEXT NOT NULL, newsgroup TEXT NOT NULL, number INTEGER NOT NULL,
                  message_id TEXT NOT NULL, status TEXT NOT NULL, reason TEXT NOT NULL,
                  retryable INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
                  next_attempt REAL NOT NULL DEFAULT 0, updated REAL NOT NULL,
                  original TEXT, PRIMARY KEY (endpoint, newsgroup, message_id))""")
              self.db.execute(
                  "CREATE INDEX IF NOT EXISTS retry_queue ON articles (retryable, status, next_attempt)"
              )
              self.db.commit()

          def close(self):
              self.db.close()

          def preserve(self, article):
              name = hashlib.sha256(article).hexdigest() + ".eml"
              path = self.raw / name
              if not path.exists():
                  atomic_write(path, article)
              return name

          def record(
              self,
              endpoint,
              group,
              number,
              message_id,
              status,
              reason,
              retryable,
              original=None,
              attempted=False,
          ):
              self.db.execute(
                  """INSERT INTO articles
                  (endpoint, newsgroup, number, message_id, status, reason, retryable,
                   attempts, next_attempt, updated, original) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                  ON CONFLICT(endpoint, newsgroup, message_id) DO UPDATE SET
                  number=excluded.number, status=excluded.status, reason=excluded.reason,
                  retryable=excluded.retryable, attempts=articles.attempts+excluded.attempts,
                  next_attempt=excluded.next_attempt, updated=excluded.updated,
                  original=COALESCE(excluded.original, articles.original)""",
                  (
                      endpoint,
                      group,
                      number,
                      message_id,
                      status,
                      reason,
                      int(retryable),
                      int(attempted),
                      (
                          time.time() + (900 if status == "error" else 86400)
                          if attempted and status != "resolved"
                          else 0
                      ),
                      time.time(),
                      original,
                  ),
              )
              self.db.commit()

          def resolve(self, endpoint, group, message_id):
              self.db.execute(
                  "UPDATE articles SET status='resolved', retryable=0, updated=? WHERE endpoint=? AND newsgroup=? AND message_id=?",
                  (time.time(), endpoint, group, message_id),
              )
              self.db.commit()

          def queue_missing(self, endpoint, group, missing, marked):
              # Inventory must not reset a failed article's backoff or erase its reason.
              self.db.executemany(
                  """INSERT INTO articles
                  (endpoint, newsgroup, number, message_id, status, reason, retryable, updated)
                  VALUES (?, ?, ?, ?, 'pending', 'missing during inventory', ?, ?)
                  ON CONFLICT(endpoint, newsgroup, message_id) DO UPDATE SET
                  number=excluded.number,
                  retryable=MAX(articles.retryable, excluded.retryable),
                  status=CASE WHEN articles.status='resolved' THEN 'pending' ELSE articles.status END,
                  updated=excluded.updated""",
                  (
                      (endpoint, group, number, mid, int(number <= marked), time.time())
                      for number, mid in missing
                  ),
              )
              self.db.commit()


      class Marks:
          def __init__(self, path):
              self.path = Path(path)
              self.lines = self.path.read_text().splitlines()
              self.positions = {}
              self.values = {}
              endpoint = None
              for index, line in enumerate(self.lines):
                  if not line.strip() or line.lstrip().startswith("#"):
                      continue
                  fields = line.split()
                  if not line[0].isspace():
                      endpoint = fields[0]
                  else:
                      key = (endpoint, fields[0])
                      self.positions[key] = index
                      self.values[key] = int(fields[2]) if len(fields) >= 3 else 0

          def get(self, endpoint, group):
              key = (endpoint, group)
              if key not in self.values:
                  raise ValueError("group is absent from marks: " + group)
              return self.values[key]

          def set(self, endpoint, group, number):
              key = (endpoint, group)
              self.values[key] = number
              self.lines[self.positions[key]] = f"    {group} {int(time.time())} {number}"

          def save(self):
              atomic_write(self.path, ("\n".join(self.lines) + "\n").encode())


      class Run:
          def __init__(self, seconds=None):
              self.stopping = False
              self.deadline = (
                  time.monotonic() + seconds if seconds is not None else float("inf")
              )

          def stop(self, *args):
              self.stopping = True

          def active(self):
              return not self.stopping and time.monotonic() < self.deadline


      def connect_upstream(upstream):
          credential = upstream.get("passwordCredential")
          password = None
          if credential:
              if Path(credential).name != credential or credential in (".", ".."):
                  raise ValueError("invalid credential name")
              directory = os.environ.get("CREDENTIALS_DIRECTORY")
              if not directory:
                  raise ValueError("CREDENTIALS_DIRECTORY is unset")
              password = (Path(directory) / credential).read_text().rstrip("\n")
              if not password or any(character in password for character in "\r\n\x00"):
                  raise ValueError("invalid credential contents")
          return NNTP(upstream["endpoint"], upstream.get("username"), password)


      def transfer(upstream, source, reader, feed, state, group, number, mid):
          endpoint = upstream["endpoint"]
          if reader.exists(mid):
              state.resolve(endpoint, group, mid)
              return "existing"
          article = source.article(number)
          if article is None:
              state.record(
                  endpoint,
                  group,
                  number,
                  mid,
                  "unavailable",
                  "upstream article unavailable",
                  True,
                  attempted=True,
              )
              return "unavailable"
          original = None
          if not valid_message_id(mid) or article_message_id(article) != mid:
              original = state.preserve(article)
              state.record(
                  endpoint,
                  group,
                  number,
                  mid,
                  "rejected",
                  "invalid or mismatched Message-ID",
                  True,
                  original,
                  attempted=True,
              )
              return "rejected"
          try:
              normalized = (
                  normalize_path(article)
                  if upstream.get("normalizeDuplicatePath", False)
                  else article
              )
              if upstream.get("normalizeLegacyDate", False):
                  normalized = normalize_date(normalized)
          except ValueError as error:
              original = state.preserve(article)
              state.record(
                  endpoint,
                  group,
                  number,
                  mid,
                  "rejected",
                  str(error),
                  True,
                  original,
                  attempted=True,
              )
              return "rejected"
          if normalized != article:
              original = state.preserve(article)
          reply = feed.offer(mid, normalized)
          if reply.startswith("235 ") or (reply.startswith("435 ") and reader.exists(mid)):
              if original:
                  state.record(
                      endpoint,
                      group,
                      number,
                      mid,
                      "resolved",
                      "legacy headers normalized; original retained",
                      False,
                      original,
                      attempted=True,
                  )
              else:
                  state.resolve(endpoint, group, mid)
              return "accepted"
          original = original or state.preserve(article)
          state.record(
              endpoint, group, number, mid, "rejected", reply, True, original, attempted=True
          )
          return "rejected"


      def sync(config, args, run, state):
          marks = Marks(args.marks)
          failures = []
          with NNTP(config["localEndpoint"]) as reader, NNTP(
              config["localEndpoint"], reader=False
          ) as feed:
              for upstream in config["upstreams"]:
                  groups = [
                      group
                      for group in upstream["groups"]
                      if args.group is None or group == args.group
                  ]
                  if not groups or not run.active():
                      continue
                  try:
                      with connect_upstream(upstream) as source:
                          for group in groups:
                              if not run.active():
                                  break
                              endpoint = upstream["endpoint"]
                              marked = marks.get(endpoint, group)
                              count, first, last = source.group(group)
                              if count == 0:
                                  continue
                              if last < marked:
                                  marked = first - 1
                              start = max(first, marked + 1)
                              end = (
                                  min(last, start + args.max_articles - 1)
                                  if args.max_articles
                                  else last
                              )
                              stats = Counter()
                              try:
                                  for lower in range(start, end + 1, 1000):
                                      if not run.active():
                                          break
                                      upper = min(lower + 999, end)
                                      articles = source.ids(lower, upper)
                                      complete = True
                                      for number, mid in articles:
                                          if not run.active():
                                              complete = False
                                              break
                                          outcome = transfer(
                                              upstream,
                                              source,
                                              reader,
                                              feed,
                                              state,
                                              group,
                                              number,
                                              mid,
                                          )
                                          stats[outcome] += 1
                                          # Failed transfers have been committed to SQLite before this point.
                                          marks.set(endpoint, group, number)
                                      if complete:
                                          marks.set(endpoint, group, upper)
                                      marks.save()
                              finally:
                                  marks.save()
                                  print(
                                      json.dumps(
                                          {
                                              "group": group,
                                              "marked": marks.get(endpoint, group),
                                              "upstream": last,
                                              **stats,
                                          }
                                      ),
                                      flush=True,
                                  )
                  except (OSError, ProtocolError) as error:
                      failures.append(upstream["endpoint"])
                      print(f"upstream {upstream['endpoint']}: {error}", file=sys.stderr)
          if failures:
              raise ProtocolError("synchronization failed for: " + ", ".join(failures))


      def inventory(config, args, run, state):
          started = time.time()
          marks = Marks(args.marks)
          local_ids = set()
          groups = [group for upstream in config["upstreams"] for group in upstream["groups"]]
          with NNTP(config["localEndpoint"]) as reader:
              for group in groups:
                  count, first, last = reader.group(group)
                  for lower in range(first, last + 1, 20000) if count else []:
                      if not run.active():
                          raise RuntimeError(
                              "inventory interrupted; previous complete report retained"
                          )
                      local_ids.update(
                          mid for _, mid in reader.ids(lower, min(lower + 19999, last))
                      )
          report = {
              "started": started,
              "local_snapshot_completed": time.time(),
              "local_unique": len(local_ids),
              "groups": [],
          }
          missing_ids = set()
          for upstream in config["upstreams"]:
              endpoint = upstream["endpoint"]
              with connect_upstream(upstream) as source:
                  for group in upstream["groups"]:
                      marked = marks.get(endpoint, group)
                      count, first, last = source.group(group)
                      stats = Counter(
                          dict.fromkeys(
                              (
                                  "enumerated",
                                  "present",
                                  "missing",
                                  "missing_before_cursor",
                                  "missing_after_cursor",
                              ),
                              0,
                          )
                      )
                      for lower in range(first, last + 1, 20000) if count else []:
                          if not run.active():
                              raise RuntimeError(
                                  "inventory interrupted; previous complete report retained"
                              )
                          missing = []
                          for number, mid in source.ids(lower, min(lower + 19999, last)):
                              stats["enumerated"] += 1
                              if mid in local_ids:
                                  stats["present"] += 1
                              else:
                                  stats["missing"] += 1
                                  stats[
                                      (
                                          "missing_before_cursor"
                                          if number <= marked
                                          else "missing_after_cursor"
                                      )
                                  ] += 1
                                  missing.append((number, mid))
                                  missing_ids.add(mid)
                          state.queue_missing(endpoint, group, missing, marked)
                      row = {
                          "endpoint": endpoint,
                          "group": group,
                          "marked": marked,
                          "upstream": last,
                          "pending_span": max(last - marked, 0),
                          **stats,
                      }
                      report["groups"].append(row)
                      print(json.dumps(row), flush=True)
          # Resolve old queue entries against this inventory without erasing failure evidence.
          for endpoint, group, mid in state.db.execute(
              "SELECT endpoint, newsgroup, message_id FROM articles WHERE status!='resolved'"
          ).fetchall():
              if mid in local_ids:
                  state.resolve(endpoint, group, mid)
          report.update(completed=time.time(), missing_unique=len(missing_ids))
          atomic_write(
              state.directory / "inventory.json",
              (json.dumps(report, indent=2) + "\n").encode(),
          )
          return 1 if missing_ids else 0


      def retry(config, args, run, state):
          upstreams = {upstream["endpoint"]: upstream for upstream in config["upstreams"]}
          entries = state.db.execute(
              """SELECT endpoint, newsgroup, number, message_id FROM articles
              WHERE retryable=1 AND status!='resolved' AND next_attempt<=?
              ORDER BY next_attempt, updated LIMIT ?""",
              (time.time(), args.max_articles or 1000),
          ).fetchall()
          stats = Counter()
          with ExitStack() as stack:
              reader = stack.enter_context(NNTP(config["localEndpoint"]))
              feed = stack.enter_context(NNTP(config["localEndpoint"], reader=False))
              sources = {}
              failed_sources = {}
              for endpoint, group, number, mid in entries:
                  if not run.active():
                      break
                  upstream = upstreams.get(endpoint)
                  if upstream is None or group not in upstream["groups"]:
                      state.record(
                          endpoint,
                          group,
                          number,
                          mid,
                          "unavailable",
                          "upstream group no longer configured",
                          False,
                      )
                      continue
                  if reader.exists(mid):
                      state.resolve(endpoint, group, mid)
                      stats["existing"] += 1
                      continue
                  try:
                      if endpoint in failed_sources:
                          raise ProtocolError(failed_sources[endpoint])
                      if endpoint not in sources:
                          sources[endpoint] = stack.enter_context(connect_upstream(upstream))
                      source = sources[endpoint]
                      source.group(group)
                      stats[
                          transfer(upstream, source, reader, feed, state, group, number, mid)
                      ] += 1
                  except (OSError, ProtocolError) as error:
                      failed_sources[endpoint] = str(error)
                      state.record(
                          endpoint,
                          group,
                          number,
                          mid,
                          "error",
                          str(error),
                          True,
                          attempted=True,
                      )
                      stats["error"] += 1
          print(json.dumps({"retry": dict(stats)}), flush=True)
          if stats["error"]:
              raise ProtocolError("some queued articles could not be retried")


      def progress(config, args):
          marks = Marks(args.marks)
          pending = 0
          for upstream in config["upstreams"]:
              with connect_upstream(upstream) as source:
                  for group in upstream["groups"]:
                      _, _, last = source.group(group)
                      marked = marks.get(upstream["endpoint"], group)
                      span = max(last - marked, 0)
                      pending += span
                      print(
                          json.dumps(
                              {
                                  "group": group,
                                  "marked": marked,
                                  "upstream": last,
                                  "pending_span": span,
                                  "completeness": "not checked",
                              }
                          ),
                          flush=True,
                      )
          return 1 if pending else 0


      def status(config):
          directory = Path(config["stateDirectory"]) / "archive"
          path = directory / "inventory.json"
          inventory_report = json.loads(path.read_text()) if path.exists() else None
          queue = None
          database = directory / "articles.sqlite"
          if database.exists():
              connection = sqlite3.connect(database.resolve().as_uri() + "?mode=ro", uri=True)
              try:
                  connection.execute("BEGIN")
                  queue = {
                      "observed": time.time(),
                      "by_status": dict(
                          connection.execute(
                              "SELECT status, COUNT(*) FROM articles GROUP BY status"
                          )
                      ),
                      "ready": connection.execute(
                          "SELECT COUNT(*) FROM articles WHERE retryable=1 AND status!='resolved' AND next_attempt<=?",
                          (time.time(),),
                      ).fetchone()[0],
                      "backoff": connection.execute(
                          "SELECT COUNT(*) FROM articles WHERE retryable=1 AND status!='resolved' AND next_attempt>?",
                          (time.time(),),
                      ).fetchone()[0],
                      "awaiting_backfill": connection.execute(
                          "SELECT COUNT(*) FROM articles WHERE retryable=0 AND status='pending'"
                      ).fetchone()[0],
                      "failure_reasons": [
                          dict(zip(("status", "reason", "count"), row))
                          for row in connection.execute(
                              "SELECT status, reason, COUNT(*) FROM articles WHERE status NOT IN ('resolved', 'pending') GROUP BY status, reason ORDER BY COUNT(*) DESC LIMIT 20"
                          )
                      ],
                  }
              finally:
                  connection.close()
          print(
              json.dumps(
                  {"inventory_snapshot": inventory_report, "queue_now": queue}, indent=2
              )
          )
          if inventory_report is None:
              print(
                  "No complete inventory exists; start inn-news-backfill-check.service.",
                  file=sys.stderr,
              )
              return 2
          return 1 if inventory_report["missing_unique"] else 0


      @contextmanager
      def operation_lock(directory, inherited, name="pullnews.lock"):
          path = Path(directory) / name
          # Scheduled wrappers hold this lock and pass it to their child process.
          if inherited:
              if not os.path.samestat(os.fstat(9), path.stat()):
                  raise ValueError("file descriptor 9 is not the archive lock")
              fcntl.flock(9, fcntl.LOCK_EX | fcntl.LOCK_NB)
              yield
              return
          with path.open("a") as stream:
              fcntl.flock(stream, fcntl.LOCK_EX)
              yield


      def main():
          parser = argparse.ArgumentParser(description=__doc__)
          parser.add_argument("--config", required=True)
          parser.add_argument(
              "operation", choices=("sync", "audit", "retry", "progress", "status")
          )
          parser.add_argument("--marks")
          parser.add_argument("--group")
          parser.add_argument("--max-articles", type=int)
          parser.add_argument("--max-seconds", type=int)
          parser.add_argument("--inherited-lock", action="store_true")
          args = parser.parse_args()
          if (args.max_articles is not None and args.max_articles <= 0) or (
              args.max_seconds is not None and args.max_seconds <= 0
          ):
              parser.error("limits must be positive")
          config = json.loads(Path(args.config).read_text())
          if args.group is not None and not any(
              args.group in upstream["groups"] for upstream in config["upstreams"]
          ):
              parser.error("group is not configured")
          args.marks = args.marks or str(
              Path(config["stateDirectory"]) / "pullnews-backfill.marks"
          )
          if args.operation == "progress":
              return progress(config, args)
          if args.operation == "status":
              return status(config)
          os.umask(0o077)
          run = Run(args.max_seconds)
          signal.signal(signal.SIGINT, run.stop)
          signal.signal(signal.SIGTERM, run.stop)
          # Audit reads marks once and only writes queue/report data, so it can coexist with sync.
          with operation_lock(
              config["stateDirectory"],
              args.inherited_lock,
              "inventory.lock" if args.operation == "audit" else "pullnews.lock",
          ):
              state = State(config["stateDirectory"])
              try:
                  if args.operation == "sync":
                      sync(config, args, run, state)
                  elif args.operation == "audit":
                      return inventory(config, args, run, state)
                  elif args.operation == "retry":
                      retry(config, args, run, state)
              finally:
                  state.close()
          return 0


      if __name__ == "__main__":
          try:
              sys.exit(main())
          except (OSError, ValueError, RuntimeError, sqlite3.Error) as error:
              print(f"inn-archive: {error}", file=sys.stderr)
              sys.exit(2)
    ''} \
      --config ${archiveConfiguration} "$@"
  '';

  recentMarksInitializer = writeScript "inn-recent-marks-initialize" ''
    #!${perlWithTls}/bin/perl

    use strict;
    use warnings;

    use Date::Parse qw(str2time);
    use Net::NNTP;

    my ($source_path, $destination_path, $lookback_days) = @ARGV;
    die "usage: $0 SOURCE DESTINATION LOOKBACK_DAYS\n"
      if !defined $lookback_days;
    die "LOOKBACK_DAYS must be a positive integer\n"
      if $lookback_days !~ /^[1-9][0-9]*$/;

    my $cutoff = time - $lookback_days * 24 * 60 * 60;
    my $block_size = 1000;

    sub resolve_password {
        my ($password) = @_;

        return substr($password, 1) if $password =~ /^@@/;
        return $password if $password !~ /^@(.*)$/;

        my $path = $1;
        if ($path =~ /^credential:(.+)$/) {
            my $credential = $1;
            my $directory = $ENV{'CREDENTIALS_DIRECTORY'};
            die "CREDENTIALS_DIRECTORY is unset\n"
              if !defined $directory || !length $directory;
            die "invalid credential name\n"
              if $credential =~ m{/} || $credential eq '.' || $credential eq '..';
            $path = "$directory/$credential";
        }

        open my $password_handle, '<', $path
          or die "cannot open password file $path: $!\n";
        my $password_value = <$password_handle>;
        close $password_handle
          or die "cannot close password file $path: $!\n";
        die "password file $path is empty\n" if !defined $password_value;
        chomp $password_value;
        die "password file $path contains more than one line\n"
          if $password_value =~ /[\r\n]/;
        return $password_value;
    }

    open my $source_handle, '<', $source_path
      or die "cannot open marks template $source_path: $!\n";

    my @servers;
    my $server;
    while (my $line = <$source_handle>) {
        next if $line =~ /^\s*(?:#|$)/;

        if ($line !~ /^\s/) {
            chomp $line;
            my ($endpoint, $username, $password) = split /\s+/, $line, 3;
            $server = {
                config_line => $line,
                endpoint => $endpoint,
                groups => [],
                username => $username,
                password => defined $password ? resolve_password($password) : undef,
            };
            push @servers, $server;
            next;
        }

        die "group appears before a server in $source_path\n"
          if !defined $server;
        my ($group) = split /\s+/, $line =~ s/^\s+//r;
        push @{$server->{groups}}, {
            group => $group,
        };
    }

    close $source_handle or die "cannot close $source_path: $!\n";

    for my $entry (@servers) {
        my ($host, $port, $tls_mode) =
          $entry->{endpoint} =~ /\A([^:]+)(?::([0-9]+))?(?:_(TLS|STARTTLS))?\z/;
        die "invalid upstream endpoint $entry->{endpoint}\n"
          if !defined $host;

        $port //= $tls_mode && $tls_mode eq 'TLS' ? 563 : 119;
        my %arguments = (
            Port => $port,
            Timeout => 60,
        );
        $arguments{SSL} = 1 if $tls_mode && $tls_mode eq 'TLS';

        my $nntp = Net::NNTP->new($host, %arguments)
          or die "cannot connect to $host:$port\n";

        if ($tls_mode && $tls_mode eq 'STARTTLS' && !$nntp->starttls()) {
            die "STARTTLS failed for $host:$port\n";
        }

        if (defined $entry->{username}
            && !$nntp->authinfo($entry->{username}, $entry->{password})) {
            die "authentication failed for $host:$port\n";
        }

        for my $group_entry (@{$entry->{groups}}) {
            my ($count, $first, $last) = $nntp->group($group_entry->{group});
            die "$host: group $group_entry->{group} is unavailable\n"
              if !defined $last;

            if ($count == 0) {
                $group_entry->{high} = $last;
                next;
            }

            my $upper = $last;
            my $oldest_recent;
            my $parsed_any = 0;

            while ($upper >= $first) {
                my $lower = $upper - $block_size + 1;
                $lower = $first if $lower < $first;

                my $dates = $nntp->xhdr('Date', $lower, $upper);
                if (!defined $dates) {
                    my $overview = $nntp->xover($lower, $upper);
                    die "$host: cannot read dates for $group_entry->{group}\n"
                      if !defined $overview;
                    $dates = {
                        map {
                            $_ => $overview->{$_}[2]
                        } keys %{$overview}
                    };
                }

                my $block_parsed = 0;
                my $block_recent = 0;
                for my $number (keys %{$dates}) {
                    my $timestamp = str2time($dates->{$number});
                    next if !defined $timestamp;
                    $block_parsed = 1;
                    $parsed_any = 1;
                    next if $timestamp < $cutoff;
                    $block_recent = 1;
                    $oldest_recent = $number
                      if !defined $oldest_recent || $number < $oldest_recent;
                }

                if ($block_parsed && !$block_recent) {
                    last;
                }

                $upper = $lower - 1;
            }

            die "$host: no parseable dates for $group_entry->{group}\n"
              if !$parsed_any;

            my $high = defined $oldest_recent ? $oldest_recent - 1 : $last;
            $high = 0 if $high < 0;
            $group_entry->{high} = $high;
        }

        $nntp->quit();
    }

    my $temporary_path = "$destination_path.new.$$";
    open my $destination_handle, '>', $temporary_path
      or die "cannot create $temporary_path: $!\n";
    chmod 0600, $temporary_path
      or die "cannot chmod $temporary_path: $!\n";

    print {$destination_handle} "# Format: (date is epoch seconds)\n";
    print {$destination_handle} "# hostname[:port][_tlsmode] [username password]\n";
    print {$destination_handle} "#     group date high\n";
    my $checked = time;
    for my $entry (@servers) {
        print {$destination_handle} "$entry->{config_line}\n";
        for my $group_entry (@{$entry->{groups}}) {
            print {$destination_handle} join(
                ' ',
                '   ',
                $group_entry->{group},
                $checked,
                $group_entry->{high},
            ), "\n";
        }
    }

    close $destination_handle
      or die "cannot close $temporary_path: $!\n";
    rename $temporary_path, $destination_path
      or die "cannot replace $destination_path: $!\n";
  '';

  stateDirectory = cfg.stateDirectory;
  databaseDirectory = "${stateDirectory}/db";
  spoolDirectory = "${stateDirectory}/spool";
  backfillCursorPath = "${stateDirectory}/pullnews-backfill.cursor";
  backfillMarksPath = "${stateDirectory}/pullnews-backfill.marks";
  legacyBackfillMarksPath = "${stateDirectory}/pullnews.marks";
  recentMarksPath = "${stateDirectory}/pullnews-recent.marks";
  recentBootstrapMarksPath = "${recentMarksPath}.bootstrap";
  pullnewsLockPath = "${stateDirectory}/pullnews.lock";

  innConf = writeText "inn.conf" ''
    mta:                         "${coreutils}/bin/false -oi -oem %s"
    organization:                "${cfg.organization}"
    ovmethod:                    tradindexed
    hismethod:                   hisv6
    domain:                      ${cfg.domain}
    pathhost:                    ${cfg.pathHost}
    pathnews:                    ${stateDirectory}
    runasuser:                   ${cfg.user}
    runasgroup:                  ${cfg.group}
    server:                      ${cfg.bindAddress}
    artcutoff:                   0
    bindaddress:                 ${cfg.bindAddress}
    docancels:                   none
    maxartsize:                  0
    pgpverify:                   false
    port:                        ${toString cfg.port}
    remembertrash:               false
    doinnwatch:                  false
    htmlstatus:                  false
    logstatus:                   false
    patharchive:                 ${spoolDirectory}/archive
    patharticles:                ${spoolDirectory}/articles
    pathbin:                     ${cfg.package}/bin
    pathcontrol:                 ${cfg.package}/bin/control
    pathdb:                      ${databaseDirectory}
    pathetc:                     @CONFIGURATION@
    pathfilter:                  ${cfg.package}/bin/filter
    pathhttp:                    ${cfg.package}/http
    pathincoming:                ${spoolDirectory}/incoming
    pathlog:                     ${stateDirectory}/log
    pathoutgoing:                ${spoolDirectory}/outgoing
    pathoverview:                ${spoolDirectory}/overview
    pathrun:                     ${stateDirectory}/run
    pathspool:                   ${spoolDirectory}
    pathtmp:                     ${stateDirectory}/tmp
  '';

  configuration =
    runCommand "inn-user-configuration" { }
      ''
        cp -r ${cfg.package}/etc $out
        chmod -R u+w $out
        cp ${innConf} $out/inn.conf
        substituteInPlace $out/inn.conf \
          --replace-fail '@CONFIGURATION@' "$out"
        cp ${writeText "incoming.conf" ''
          streaming: true
          max-connections: 2

          peer pullnews {
              hostname: "localhost, ${cfg.bindAddress}"
              patterns: "*"
          }
        ''} $out/incoming.conf
        cp ${writeText "readers.conf" ''
          auth "localhost" {
              hosts: "localhost, ${cfg.bindAddress}"
              default: "<localhost>"
          }

          access "localhost" {
              users: "<localhost>"
              read: "*,!control,!control.*,!junk"
              post: "!*"
          }
        ''} $out/readers.conf
        cp ${writeText "newsfeeds" ''
          ME:::
        ''} $out/newsfeeds
        cp ${writeText "storage.conf" ''
          method tradspool {
              newsgroups: *
              class: 0
          }
        ''} $out/storage.conf
        cp ${writeText "expire.ctl" ''
          /remember/:never
          *:A:never:never:never
        ''} $out/expire.ctl
      '';

  innEnvironment = [
    "INNCONF=${configuration}/inn.conf"
  ];

  credentials = mapAttrsToList (
    name: path: "${name}:${path}"
  ) cfg.credentials;

  credentialUnits = optional (
    cfg.credentialService != null
  ) cfg.credentialService;

  makePullnewsCommand =
    {
      marksPath,
      maxArticlesPerGroup,
      maxRunSeconds,
    }:
    escapeShellArgs (
      [
        "${archiveTool}/bin/inn-archive"
        "sync"
        "--inherited-lock"
        "--marks"
        marksPath
      ]
      ++ optionals (maxArticlesPerGroup != null) [
        "--max-articles"
        (toString maxArticlesPerGroup)
      ]
      ++ optionals (maxRunSeconds != null) [
        "--max-seconds"
        (toString maxRunSeconds)
      ]
    );

  backfillPullnewsCommand = makePullnewsCommand {
    inherit (cfg.backfill)
      maxArticlesPerGroup
      ;

    marksPath = backfillMarksPath;
    maxRunSeconds = null;
  };

  recentPullnewsCommand = makePullnewsCommand {
    inherit (cfg.recent)
      maxArticlesPerGroup
      maxRunSeconds
      ;

    marksPath = recentMarksPath;
  };

  backfillPullnews = writeShellScript "inn-news-backfill" ''
    set -euo pipefail

    trap 'exit 0' INT

    exec 9>${escapeShellArg pullnewsLockPath}
    ${util-linux}/bin/flock 9

    if ! test -e ${escapeShellArg backfillMarksPath}; then
      if test -e ${escapeShellArg legacyBackfillMarksPath}; then
        ${coreutils}/bin/install -m 0600 \
          ${escapeShellArg legacyBackfillMarksPath} \
          ${escapeShellArg backfillMarksPath}
      else
        ${coreutils}/bin/install -m 0600 \
          ${marks} \
          ${escapeShellArg backfillMarksPath}
      fi
    fi

    mapfile -t backfill_groups < ${backfillGroups}
    group_count="''${#backfill_groups[@]}"
    cursor=0

    if (( group_count == 0 )); then
      exit 0
    fi

    if test -r ${escapeShellArg backfillCursorPath}; then
      read -r cursor < ${escapeShellArg backfillCursorPath} || cursor=0
    fi

    case "$cursor" in
      ""|*[!0-9]*) cursor=0 ;;
    esac
    cursor=$((cursor % group_count))

    started=$SECONDS
    visited=0
    while (( visited < group_count )); do
      elapsed=$((SECONDS - started))
      remaining=$((${toString cfg.backfill.maxRunSeconds} - elapsed))
      if (( remaining <= 0 )); then
        break
      fi

      group="''${backfill_groups[$cursor]}"
      cursor=$(((cursor + 1) % group_count))
      ${coreutils}/bin/printf '%s\n' "$cursor" \
        > ${escapeShellArg "${backfillCursorPath}.new"}
      ${coreutils}/bin/mv \
        ${escapeShellArg "${backfillCursorPath}.new"} \
        ${escapeShellArg backfillCursorPath}

      ${backfillPullnewsCommand} \
        --group "$group" \
        --max-seconds "$remaining"
      visited=$((visited + 1))
    done
  '';

  recentPullnews = writeShellScript "inn-news-recent" ''
    set -euo pipefail

    cleanup_bootstrap() {
      ${coreutils}/bin/rm -f -- \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${escapeShellArg "${recentBootstrapMarksPath}.new"}.* \
        ${escapeShellArg "${recentBootstrapMarksPath}.pid"}
    }

    exec 9>${escapeShellArg pullnewsLockPath}
    if ! ${util-linux}/bin/flock --nonblock 9; then
      ${systemd}/bin/systemctl --user kill \
        --kill-whom=all \
        --signal=SIGINT \
        inn-news-backfill.service inn-news-retry.service \
        2>/dev/null || true
      ${util-linux}/bin/flock 9
    fi

    if ! test -e ${escapeShellArg recentMarksPath}; then
      cleanup_bootstrap
      trap cleanup_bootstrap EXIT

      ${recentMarksInitializer} \
        ${marks} \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${toString cfg.recent.lookbackDays}

      if ! ${gawk}/bin/awk '
        /^[[:space:]]+[^#[:space:]]/ && $2 == 0 { failed = 1 }
        END { exit failed }
      ' ${escapeShellArg recentBootstrapMarksPath}; then
        echo "recent marks initialization did not check every group" >&2
        exit 1
      fi

      ${coreutils}/bin/mv \
        ${escapeShellArg recentBootstrapMarksPath} \
        ${escapeShellArg recentMarksPath}
      trap - EXIT
      cleanup_bootstrap
    fi

    exec ${recentPullnewsCommand}
  '';

  retryArticles = writeShellScript "inn-news-retry" ''
    set -euo pipefail

    exec 9>${escapeShellArg pullnewsLockPath}
    ${util-linux}/bin/flock 9
    exec ${archiveTool}/bin/inn-archive retry \
      --inherited-lock \
      --max-articles ${toString cfg.retry.maxArticles} \
      --max-seconds ${toString cfg.retry.maxRunSeconds}
  '';

  makePullnewsService =
    {
      description,
      execStart,
      extraAfter ? [ ],
    }:
    {
      Service = {
        CPUWeight = 20;
        Environment = innEnvironment;
        ExecStart = execStart;
        IOWeight = 20;
        KillSignal = "SIGINT";
        LoadCredential = credentials;
        Nice = 10;
        TimeoutStartSec = "30m";
        Type = "oneshot";
        UMask = "0077";
      };

      Unit = {
        After = [
          "inn.service"
          "network.target"
        ]
        ++ extraAfter
        ++ credentialUnits;
        Description = description;
        Requires = [
          "inn.service"
        ]
        ++ credentialUnits;
      };
    };

  makePullnewsTimer =
    {
      description,
      onBootSec,
      syncInterval,
      unit,
    }:
    {
      Install = {
        WantedBy = [
          "timers.target"
        ];
      };

      Timer = {
        AccuracySec = "30s";
        OnBootSec = onBootSec;
        OnUnitInactiveSec = syncInterval;
        Persistent = true;
        Unit = unit;
      };

      Unit = {
        Description = description;
      };
    };

  preStart = writeShellScript "inn-pre-start" ''
    set -euo pipefail

    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg databaseDirectory}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/archive"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/articles"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/incoming"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/outgoing"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${spoolDirectory}/overview"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/log"}
    ${coreutils}/bin/install -d -m 0750 ${escapeShellArg "${stateDirectory}/run"}
    ${coreutils}/bin/install -d -m 0770 ${escapeShellArg "${stateDirectory}/tmp"}

    if ! test -e ${escapeShellArg "${databaseDirectory}/active"}; then
      ${coreutils}/bin/install -m 0644 ${active} ${escapeShellArg "${databaseDirectory}/active"}
      ${coreutils}/bin/install -m 0644 ${activeTimes} ${escapeShellArg "${databaseDirectory}/active.times"}
      ${coreutils}/bin/install -m 0644 ${newsgroups} ${escapeShellArg "${databaseDirectory}/newsgroups"}
    fi

    if ! test -e ${escapeShellArg "${databaseDirectory}/history"}; then
      ${coreutils}/bin/install -m 0644 /dev/null ${escapeShellArg "${databaseDirectory}/history"}
      ${cfg.package}/bin/makedbz -i -o -s 6000000
    fi

    if ! test -e ${escapeShellArg backfillMarksPath}; then
      if test -e ${escapeShellArg legacyBackfillMarksPath}; then
        ${coreutils}/bin/install -m 0600 \
          ${escapeShellArg legacyBackfillMarksPath} \
          ${escapeShellArg backfillMarksPath}
      else
        ${coreutils}/bin/install -m 0600 \
          ${marks} \
          ${escapeShellArg backfillMarksPath}
      fi
    fi

    ${cfg.package}/bin/innconfval -C
  '';

in
{
  options = {
    services = {
      inn = {
        enable = mkEnableOption "a private user-level INN archive";

        bindAddress = mkOption {
          default = "127.0.0.1";

          description = ''
            Local IPv4 address on which INN listens.
          '';

          type = types.str;
        };

        credentials = mkOption {
          default = { };

          description = ''
            systemd credential filenames mapped to password source paths.
          '';

          type = with types; attrsOf str;
        };

        credentialService = mkOption {
          default = null;

          description = ''
            User unit that must prepare credential source files before sync.
          '';

          type = with types; nullOr str;
        };

        domain = mkOption {
          default = "local";

          description = ''
            Domain INN uses when the local hostname is not fully qualified.
          '';

          type = types.str;
        };

        expectedGroupCount = mkOption {
          default = null;

          description = ''
            Expected number of subscribed group entries, when checked.
          '';

          type = with types; nullOr ints.unsigned;
        };

        group = mkOption {
          default = "users";

          description = ''
            Primary group of the user running INN.
          '';

          type = types.str;
        };

        backfill = {
          maxArticlesPerGroup = mkOption {
            default = 1000;

            description = ''
              Maximum number of article numbers processed before rotating to the next backfill group.
            '';

            type = types.ints.positive;
          };

          maxRunSeconds = mkOption {
            default = 600;

            description = ''
              Maximum duration in seconds of one rotating backfill pass.
            '';

            type = types.ints.positive;
          };

          syncInterval = mkOption {
            default = "15m";

            description = ''
              Delay between completed rotating backfill passes.
            '';

            type = types.str;
          };
        };

        recent = {
          enable = mkEnableOption "a recent-news pull channel";

          lookbackDays = mkOption {
            default = 7;

            description = ''
              Number of days included when the recent-news marks are initialized.
            '';

            type = types.ints.positive;
          };

          maxArticlesPerGroup = mkOption {
            default = 1000;

            description = ''
              Maximum number of article numbers processed per group in one recent-news pull.
            '';

            type = types.ints.positive;
          };

          maxRunSeconds = mkOption {
            default = null;

            description = ''
              Maximum duration in seconds of one recent-news pull.
            '';

            type = with types; nullOr ints.positive;
          };

          syncInterval = mkOption {
            default = "5m";

            description = ''
              Delay between completed recent-news pulls.
            '';

            type = types.str;
          };
        };

        retry = {
          maxArticles = mkOption {
            default = 100;

            description = ''
              Maximum queued failures or previously skipped articles retried per run.
            '';

            type = types.ints.positive;
          };

          maxRunSeconds = mkOption {
            default = 300;

            description = ''
              Maximum duration of one retry pass. Recent updates can interrupt it.
            '';

            type = types.ints.positive;
          };

          syncInterval = mkOption {
            default = "15m";

            description = ''
              Delay between completed retry passes. Rejections back off for one
              day; connection failures back off for fifteen minutes.
            '';

            type = types.str;
          };
        };

        organization = mkOption {
          default = "${config.home.username}'s local news archive";

          description = ''
            Organization header value used by INN.
          '';

          type = types.str;
        };

        package = mkOption {
          apply =
            package:
            package.overrideAttrs (
              _: previousAttrs: {
                configureFlags =
                  (previousAttrs.configureFlags or [ ])
                  ++ [
                    "--with-news-user=${cfg.user}"
                    "--with-news-group=${cfg.group}"
                  ];
              }
            );
          default = pkgs.inn;
          defaultText = "pkgs.inn";

          description = ''
            INN package used by the daemon and synchronization tools.
          '';

          type = types.package;
        };

        pathHost = mkOption {
          default = "${config.home.username}.localhost";

          description = ''
            Path identity inserted into accepted articles.
          '';

          type = types.str;
        };

        port = mkOption {
          default = 1119;

          description = ''
            Unprivileged local NNTP port used by INN.
          '';

          type = types.port;
        };

        stateDirectory = mkOption {
          default = "${config.xdg.stateHome}/inn";

          description = ''
            Persistent directory containing articles, overview, and marks.
          '';

          type = types.str;
        };

        upstreams = mkOption {
          default = { };

          description = ''
            Ordered pullnews upstream definitions and subscribed groups.
          '';

          type = with types; attrsOf upstreamType;
        };

        user = mkOption {
          default = config.home.username;

          description = ''
            User account running INN.
          '';

          type = types.str;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.expectedGroupCount == null
          ||
            length subscribedGroups == cfg.expectedGroupCount;
        message = "The INN mirror has an unexpected number of subscribed group entries.";
      }
      {
        assertion =
          length groups == length subscribedGroups;
        message = "The INN mirror must not contain duplicate group entries.";
      }
      {
        assertion =
          all
            (
              upstream:
              (upstream.username == null)
              == (upstream.passwordCredential == null)
            )
            (
              mapAttrsToList (
                _: upstream: upstream
              ) cfg.upstreams
            );
        message = "Each authenticated INN upstream must define both username and passwordCredential.";
      }
      {
        assertion = all (
          credential: hasAttr credential cfg.credentials
        ) passwordCredentials;
        message = "Every INN upstream passwordCredential must exist in services.inn.credentials.";
      }
    ];

    home = {
      packages = [
        archiveTool
        cfg.package
      ];
    };

    systemd = {
      user = {
        services = {
          inn = {
            Install = {
              WantedBy = [
                "default.target"
              ];
            };

            Service = {
              Environment = innEnvironment;
              ExecStart = "${cfg.package}/bin/innd -d -4 ${cfg.bindAddress} -P ${toString cfg.port}";
              ExecStartPre = "${preStart}";
              ExecStop = "${cfg.package}/bin/ctlinnd -t 60 shutdown systemd-stop";
              Restart = "on-failure";
              RestartSec = "5s";
              Type = "simple";
              UMask = "0027";
            };

            Unit = {
              After = [
                "network.target"
              ];
              Description = "Private user InterNetNews archive";
            };
          };

          inn-news-backfill-check = {
            Service = {
              Environment = innEnvironment;
              ExecStart = "${archiveTool}/bin/inn-archive audit";
              LoadCredential = credentials;
              Nice = 10;
              SuccessExitStatus = [
                0
                1
              ];
              TimeoutStartSec = "30m";
              UMask = "0077";
              Type = "oneshot";
            };

            Unit = {
              After = [
                "inn.service"
              ]
              ++ credentialUnits;
              Description = "Inventory INN articles and queue missing history";
              Requires = [
                "inn.service"
              ]
              ++ credentialUnits;
            };
          };

          inn-news-retry = makePullnewsService {
            description = "Retry failed and previously skipped INN articles";
            execStart = retryArticles;
          };

          inn-news-backfill = makePullnewsService {
            description = "Rotate through private INN backfill groups";
            execStart = backfillPullnews;
            extraAfter = optional cfg.recent.enable "inn-news-recent.service";
          };
        }
        // optionalAttrs cfg.recent.enable {
          inn-news-recent = makePullnewsService {
            description = "Pull recent private INN news";
            execStart = recentPullnews;
          };
        };

        timers = {
          inn-news-retry = makePullnewsTimer {
            description = "Periodically retry missing INN articles";
            onBootSec = "20m";
            syncInterval = cfg.retry.syncInterval;
            unit = "inn-news-retry.service";
          };

          inn-news-backfill = makePullnewsTimer {
            description = "Periodically rotate private INN backfill groups";
            onBootSec = "10m";
            inherit (cfg.backfill) syncInterval;

            unit = "inn-news-backfill.service";
          };
        }
        // optionalAttrs cfg.recent.enable {
          inn-news-recent = makePullnewsTimer {
            description = "Periodically update recent private INN news";
            onBootSec = "2m";
            inherit (cfg.recent) syncInterval;

            unit = "inn-news-recent.service";
          };
        };
      };
    };
  };
}
