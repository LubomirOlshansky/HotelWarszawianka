#!/usr/bin/env python3
"""Ratchet: no new private facade helpers in landmarks.gd (docs/design/facade-kit.md, rule 6).

    python3 -I tools/check_facade_kit.py [--list]

Windows, panes, balconies, ledges, cornices, pediments, columns and pilasters are parts of the
facade kit (game/scripts/facade_kit.gd, `kit_*`). The private helpers that existed before the kit
(`_euro_window`, `_fk_balcony` ...) are named in ALLOWED below, each with what keeps it from the
kit. The check fails when landmarks.gd holds a helper of those kinds that is not in ALLOWED (use
the kit part, or add a style to the kit), and when ALLOWED names one that is gone (delete its
line: the list only shrinks). It also fails when the kit loses a part the design doc names.
Prints `check_facade_kit: OK` and exits 0, or the problems and exits 1. --list prints the helpers
found, for writing ALLOWED.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANDMARKS = ROOT / "game" / "scripts" / "landmarks.gd"
KIT = ROOT / "game" / "scripts" / "facade_kit.gd"
DOC = ROOT / "docs" / "design" / "facade-kit.md"

KINDS = ("window", "windows", "pane", "panes", "balcony", "balconies", "ledge", "ledges", "cornice",
         "pediment", "column", "columns", "colonnade", "colonnades", "pilaster", "pilasters")
HELPER = re.compile(r"^(?:static )?func (_[a-z0-9]+(?:_[a-z0-9]+)*_(?:%s)(?:_[a-z0-9]+)?)\(" % "|".join(KINDS), re.M)

# name: what keeps it from the kit today. A landmark's helper leaves this list when the landmark
# is next reworked onto kit parts (with its look check).
ALLOWED = {
@ALLOWED@
}


def main() -> int:
    found = HELPER.findall(LANDMARKS.read_text(encoding="utf-8"))
    if "--list" in sys.argv[1:]:
        for name in found:
            print(name)
        return 0
    problems = []
    for name in found:
        if name not in ALLOWED:
            problems.append("landmarks.gd: new private facade helper `%s`: use a kit part (docs/design/facade-kit.md), "
                            "or add a style to the kit" % name)
    for name in ALLOWED:
        if name not in found:
            problems.append("ALLOWED names `%s`, which is gone from landmarks.gd: delete its line" % name)
    kit = KIT.read_text(encoding="utf-8")
    parts = set(re.findall(r"^func (kit_[a-z_]+)\(", kit, re.M))
    colours = set(re.findall(r"^const (PAL_[A-Z_]+)\b", kit, re.M))
    doc = DOC.read_text(encoding="utf-8")
    for name in sorted(set(re.findall(r"`(kit_[a-z_]+)[(`]", doc))):
        if name not in parts:
            problems.append("docs/design/facade-kit.md names `%s`, which facade_kit.gd does not have" % name)
    for name in sorted(parts):
        if "`%s" % name not in doc:
            problems.append("facade_kit.gd has `%s`, which docs/design/facade-kit.md does not describe" % name)
    for name in sorted(set(re.findall(r"`(PAL_[A-Z_]+)`", doc)) ^ colours):
        problems.append("palette colour `%s` is in only one of facade_kit.gd and docs/design/facade-kit.md" % name)
    print("check_facade_kit counts: %d kit parts, %d palette colours, %d private helpers left" % (
        len(parts), len(colours), len(found)))
    if problems:
        print("check_facade_kit: %d problems" % len(problems))
        for p in problems:
            print("  " + p)
        return 1
    print("check_facade_kit: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
