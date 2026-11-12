"""The day-by-day changelog: docs/changes/ notes and docs/CHANGELOG.md's short lines, plus ROADMAP's progress log.

Usage:
    python3 -I tools/changelog.py           prints the days it finds (site_build.py and wiki_build.py import it)
    python3 -I tools/changelog.py --check   every note in docs/changes/ is well formed (CI's tier job)
    python3 -I tools/changelog.py --fold    moves the notes' lines into docs/CHANGELOG.md, prints their
                                            Backlog and Roadmap sections for the bookkeeping PR, deletes the notes

Change notes (2026-11-12): a pull request no longer edits docs/CHANGELOG.md, BACKLOG.md or ROADMAP.md
(the three most edited files in the repo, so nearly every pull request conflicted on them). It adds
one file of its own, docs/changes/YYYY-MM-DD-short-name.md (docs/changes/README.md has the format):
"- " lines a player would understand, then optional "## Backlog" and "## Roadmap" sections. Two
pull requests never touch the same file. The pages read the notes straight away; one bookkeeping
pull request a week folds them into the three big files with --fold.

Every day in ROADMAP.md's "Progress log" table becomes one entry, newest first. The entry shows the
short lines written for that day in docs/changes/ and docs/CHANGELOG.md (a "## YYYY-MM-DD" section
with "- " lines). A day in the log that neither covers yet gets lines made from the log's own labels,
so a new day shows up before anyone writes it up. Each entry also counts the log's updates that day.
"""

from __future__ import annotations

import datetime
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANGES = ROOT / "docs" / "changes"
NOTE_NAME = re.compile(r"(20\d\d-\d\d-\d\d)-[a-z0-9][a-z0-9-]*\.md$")
NOTE_SECTIONS = ("Backlog", "Roadmap")


def log_rows() -> list[tuple[str, str]]:
    """(date, label) for each row of ROADMAP.md's progress log."""
    text = (ROOT / "docs" / "ROADMAP.md").read_text(encoding="utf-8")
    start = text.find("## Progress log")
    rows = []
    for ln in text[start:].splitlines():
        m = re.match(r"\|\s*(20\d\d-\d\d-\d\d)\s*\|\s*([^|]+?)\s*\|", ln)
        if m:
            rows.append((m.group(1), m.group(2)))
    return rows


def written() -> dict[str, list[str]]:
    """The short lines of docs/CHANGELOG.md by day."""
    days: dict[str, list[str]] = {}
    cur = None
    for ln in (ROOT / "docs" / "CHANGELOG.md").read_text(encoding="utf-8").splitlines():
        m = re.match(r"## (20\d\d-\d\d-\d\d)\s*$", ln)
        if m:
            cur = m.group(1)
            days[cur] = []
        elif cur and ln.startswith("- "):
            days[cur].append(ln[2:].strip())
        elif cur and ln.startswith("  ") and days[cur]:
            days[cur][-1] += " " + ln.strip()
    return days


def note_files() -> list[Path]:
    """docs/changes/*.md without the README, newest name first."""
    if not CHANGES.is_dir():
        return []
    return sorted((p for p in CHANGES.glob("*.md") if p.name != "README.md"), reverse=True)


def read_note(path: Path) -> dict:
    """One change note: {date, lines (the player's lines), sections {name: [lines]}, problems}."""
    note: dict = {"date": None, "lines": [], "sections": {}, "problems": []}
    m = NOTE_NAME.match(path.name)
    if not m:
        note["problems"].append("the name is not YYYY-MM-DD-short-name.md (lower case, digits, hyphens)")
    else:
        try:
            datetime.date.fromisoformat(m.group(1))
            note["date"] = m.group(1)
        except ValueError:
            note["problems"].append("%s is not a date" % m.group(1))
    section = None
    for n, ln in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not ln.strip():
            continue
        if ln.startswith("## "):
            section = ln[3:].strip()
            if section not in NOTE_SECTIONS:
                note["problems"].append("line %d: unknown section %r (use %s)" % (n, section, " or ".join(NOTE_SECTIONS)))
            note["sections"].setdefault(section, [])
            continue
        target = note["lines"] if section is None else note["sections"][section]
        if ln.startswith("- "):
            target.append(ln[2:].strip())
        elif ln.startswith("  ") and target:
            target[-1] += " " + ln.strip()
        else:
            note["problems"].append("line %d: expected a \"- \" line or a \"## \" section" % n)
    if not note["lines"] and not any(note["sections"].values()):
        note["problems"].append("empty: write a \"- \" line or a section")
    return note


def noted() -> dict[str, list[str]]:
    """The player's lines of docs/changes/ by day."""
    out: dict[str, list[str]] = {}
    for path in note_files():
        note = read_note(path)
        if note["date"]:
            out.setdefault(note["date"], []).extend(note["lines"])
    return out


def check() -> int:
    """--check: every note is well formed."""
    bad = 0
    files = note_files()
    for path in files:
        for problem in read_note(path)["problems"]:
            print("changelog: FAIL: docs/changes/%s: %s" % (path.name, problem))
            bad += 1
    if bad:
        return 1
    print("changelog: OK (%d change note%s waiting to be folded)" % (len(files), "" if len(files) == 1 else "s"))
    return 0


def fold() -> int:
    """--fold: the notes' lines go under their day in docs/CHANGELOG.md, the notes are deleted,
    and their Backlog and Roadmap sections are printed for the bookkeeping pull request."""
    if check():
        return 1
    files = note_files()
    if not files:
        return 0
    path = ROOT / "docs" / "CHANGELOG.md"
    text = path.read_text(encoding="utf-8").splitlines()
    for date, lines in sorted(noted().items()):
        new = ["- " + x for x in lines]
        if not new:
            continue
        heading = "## " + date
        if heading in text:
            at = text.index(heading) + 1
            text[at:at] = new
        else:
            # Before the first older day (the file is newest first), else at the end.
            older = [i for i, ln in enumerate(text) if re.match(r"## 20\d\d-\d\d-\d\d\s*$", ln) and ln[3:13] < date]
            at = older[0] if older else len(text)
            text[at:at] = [heading] + new + [""]
    path.write_text("\n".join(text) + "\n", encoding="utf-8")
    for f in sorted(files):
        note = read_note(f)
        for name in NOTE_SECTIONS:
            for ln in note["sections"].get(name, []):
                print("%s (%s): %s" % (name, f.name, ln))
        f.unlink()
    print("changelog: folded %d note%s into docs/CHANGELOG.md; apply the Backlog and Roadmap lines above by hand" % (len(files), "" if len(files) == 1 else "s"))
    return 0


def days() -> list[dict]:
    """Newest first: {date, label (e.g. "31 October 2026"), lines, written, updates}."""
    counts: dict[str, list[str]] = {}
    for d, label in log_rows():
        counts.setdefault(d, []).append(label)
    lines = written()
    # A day's notes come first: they are newer than what is already folded into CHANGELOG.md.
    for d, new in noted().items():
        if new:
            lines[d] = new + lines.get(d, [])
    out = []
    for d in sorted(set(counts) | set(lines), reverse=True):
        auto = [re.sub(r"^loop ", "", lab) for lab in counts.get(d, [])]
        out.append({
            "date": d,
            "label": datetime.date.fromisoformat(d).strftime("%-d %B %Y"),
            "lines": lines.get(d) or ["Updates: " + ", ".join(auto) + "."],
            "written": d in lines,
            "updates": len(counts.get(d, [])),
        })
    return out


def inline(text: str) -> str:
    t = html.escape(text)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    return re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', t)


def html_days(heading: str = "h2") -> str:
    """The days as HTML: a heading, a count, the short lines."""
    out = []
    for day in days():
        n = day["updates"]
        count = f' <span class="day-count">{n} update{"s" if n != 1 else ""}</span>' if n else ""
        items = "".join(f"<li>{inline(x)}</li>" for x in day["lines"])
        out.append(f'<{heading} id="d{day["date"]}">{day["label"]}{count}</{heading}>\n<ul class="day">{items}</ul>')
    return "\n".join(out)


def main() -> int:
    if "--check" in sys.argv[1:]:
        return check()
    if "--fold" in sys.argv[1:]:
        return fold()
    for day in days():
        print(day["date"], day["updates"], "written" if day["written"] else "from the log", len(day["lines"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
