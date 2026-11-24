-- Around Warsaw forms (worker.js): the beta signups and the in-game / website feedback.
-- Applied once to the D1 database "aroundwarsaw-forms" on 2026-11-21.
CREATE TABLE IF NOT EXISTS submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,                 -- signup | feedback
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
  email TEXT,
  platform TEXT,                      -- iPhone | Android | -
  lang TEXT,
  message TEXT,
  topic TEXT,
  meta TEXT,                          -- JSON: source, build, device, where
  country TEXT,
  ip_hash TEXT,                       -- sha256(ip + salt), for the rate limit only
  notified INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS submissions_kind_created ON submissions(kind, created_at);
CREATE INDEX IF NOT EXISTS submissions_ip ON submissions(ip_hash, created_at);
