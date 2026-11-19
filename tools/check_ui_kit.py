#!/usr/bin/env python3
"""Ratchet: the interface's colours come from the UI kit (docs/design/ui-kit.md).

    python3 -I tools/check_ui_kit.py [--list]

Every card, button, chip and text colour on screen is a constant of game/scripts/ui_kit.gd (F
2026-11-19: "one style ... no different elements"). The UI scripts below still hold their own
colour literals from before the kit (`Color("#...")` and `Color(r, g, b[, a])` written out);
BASELINE names how many each may have. The check fails when a script has more than its line
allows (use a UiKit constant, or add a token to the kit and the design doc), when it has fewer
(lower its line: the numbers only fall), when a game script makes a StyleBoxFlat and is neither
in BASELINE nor OUTSIDE, and when the kit loses a token the design doc names.
Prints `check_ui_kit: OK` and `check_ui_kit counts: ...`, exits 0; or the problems, exits 1.
--list prints every script's count, for writing BASELINE.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "game" / "scripts"
KIT = SCRIPTS / "ui_kit.gd"
DOC = ROOT / "docs" / "design" / "ui-kit.md"

LITERAL = re.compile(r'Color\("#[0-9a-fA-F]{6,8}"\)|Color\(\s*[0-9.]+\s*,\s*[0-9.]+\s*,\s*[0-9.]+\s*(?:,\s*[0-9.]+\s*)?\)')
STYLEBOX = re.compile(r"StyleBoxFlat\.new\(\)")

# script (relative to game/scripts): colour literals it may still hold. Falls as screens move onto
# the kit (steps 1 to 4 of the design doc); a 3D scene's own light colours count too until they
# move to a named palette of that scene.
BASELINE = {
    "hud.gd": 80,
    "full_map.gd": 25,
    "quests_screen.gd": 7,
    "settings_panel.gd": 14,
    "garage_card.gd": 4,
    "notebook_page.gd": 4,
    "fotka.gd": 4,
    "bubbles.gd": 4,
    "title.gd": 26,
    "club.gd": 113,
    "police/police_balloon.gd": 25,
    "first10.gd": 6,
    "gamepad.gd": 1,
}

# scripts that make a StyleBoxFlat but are not interface: why.
OUTSIDE = {
    "ui_kit.gd": "the kit itself",
}

# tokens the design doc names; the kit must keep them.
TOKENS = ("CARD", "RAISED", "GLASS", "EDGE", "EDGE_STRONG", "INK", "SUB", "FAINT", "GOLD",
          "GOLD_TINT", "ON_GOLD", "ALERT", "GO", "POLICE", "HEAT", "NEON_PINK", "NEON_CYAN",
          "T_BANNER", "T_CLOCK", "T_TITLE", "T_BODY", "T_SUB", "T_LABEL", "R_SMALL", "R_CARD")


def count(path: pathlib.Path) -> int:
    n = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("#"):
            continue
        n += len(LITERAL.findall(line))
    return n


def main() -> int:
    problems = []
    found = {}
    for path in sorted(SCRIPTS.rglob("*.gd")):
        rel = path.relative_to(SCRIPTS).as_posix()
        text = path.read_text(encoding="utf-8")
        if rel in BASELINE or STYLEBOX.search(text):
            found[rel] = count(path)
    if "--list" in sys.argv:
        for rel, n in sorted(found.items(), key=lambda kv: -kv[1]):
            print("%5d  %s" % (n, rel))
        return 0
    for rel, n in sorted(found.items()):
        if rel in OUTSIDE:
            continue
        if rel not in BASELINE:
            problems.append("%s makes a StyleBoxFlat but is not in BASELINE: dress it with ui_kit.gd "
                            "(or name it in OUTSIDE with the reason)" % rel)
            continue
        allowed = BASELINE[rel]
        if n > allowed:
            problems.append("%s has %d colour literals, %d allowed: use a UiKit constant" % (rel, n, allowed))
        elif n < allowed:
            problems.append("%s has %d colour literals: lower its BASELINE line from %d to %d" % (rel, n, allowed, n))
    for rel in BASELINE:
        if not (SCRIPTS / rel).exists():
            problems.append("BASELINE names %s, which is gone: delete its line" % rel)
    kit = KIT.read_text(encoding="utf-8") if KIT.exists() else ""
    doc = DOC.read_text(encoding="utf-8") if DOC.exists() else ""
    for token in TOKENS:
        if not re.search(r"^const %s := " % token, kit, re.M):
            problems.append("ui_kit.gd lost the token %s" % token)
        if "`%s`" % token not in doc:
            problems.append("docs/design/ui-kit.md does not name the token `%s`" % token)
    total = sum(found.get(rel, 0) for rel in BASELINE)
    print("check_ui_kit counts: %d UI scripts, %d colour literals left, %d tokens" % (len(BASELINE), total, len(TOKENS)))
    for p in problems:
        print("check_ui_kit: " + p)
    if problems:
        return 1
    print("check_ui_kit: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
