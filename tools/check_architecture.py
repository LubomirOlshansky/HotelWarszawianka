"""Check that docs/architecture names every game script, so the map of the code stays current.

Usage: python3 -I tools/check_architecture.py

Every .gd file under game/scripts/ (path relative to it, e.g. `police/guards.gd`, or for a
top-level script its bare name, e.g. `traffic.gd`) must appear in backticks in
docs/architecture/systems.md or docs/architecture/city-ai.md. Also fails when a page links to a
file in docs/architecture/ that does not exist. Prints `check_architecture: OK` and exits 0, or
lists what is missing and exits 1.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "game" / "scripts"
ARCH = ROOT / "docs" / "architecture"
PAGES = ["systems.md", "city-ai.md"]


def main() -> int:
    problems = []
    named = set()
    for page in PAGES:
        path = ARCH / page
        if not path.exists():
            problems.append(f"missing page docs/architecture/{page}")
            continue
        text = path.read_text(encoding="utf-8")
        named.update(re.findall(r"`([A-Za-z0-9_/]+\.gd)`", text))
        # Tree diagrams list scripts without backticks.
        named.update(re.findall(r"\b([A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*\.gd)\b", text))
        # A folder named in the tree ("police/") covers the scripts in it.
        named.update(f"{d}/" for d in re.findall(r"\b([a-z_]+)/(?=\s)", text))
    scripts = sorted(p.relative_to(SCRIPTS).as_posix() for p in SCRIPTS.rglob("*.gd"))
    for rel in scripts:
        top = rel.split("/")[0] + "/" if "/" in rel else ""
        if rel in named or (top and top in named):
            continue
        problems.append(f"game/scripts/{rel} is not named in docs/architecture/{' or '.join(PAGES)}")
    for page in ARCH.glob("*.md"):
        for link in re.findall(r"\]\(([a-z0-9_-]+\.md)\)", page.read_text(encoding="utf-8")):
            if not (ARCH / link).exists():
                problems.append(f"docs/architecture/{page.name} links to missing {link}")
    print(f"check_architecture counts: {len(scripts)} scripts, {len(PAGES)} pages")
    if problems:
        for p in problems:
            print(f"check_architecture: {p}")
        print(f"check_architecture: FAIL ({len(problems)})")
        return 1
    print("check_architecture: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
