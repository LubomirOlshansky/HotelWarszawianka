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
    "_tarasy_ledges": "Złote Tarasy's podium ledges follow a curved ring with its own colours per level",
    "_tarasy_ledge": "same: one ledge of the curved podium, top and front in different materials",
    "_spire_columns": "Warsaw Spire's foot: leaning columns, not a classical order",
    "_dp_panes": "Dom Partii: 1,700 panes drawn as raw quads in its own frame; twin of kit_panes once its frame is a kit_front",
    "_dp_ledge": "Dom Partii: a ledge between two local points; kit_ledge once its frame is a kit_front",
    "_dp_ring_ledge": "Dom Partii: kit_ledge_ring with another front shade (5 % darker)",
    "_euro_balcony": "Hotel Europejski: a balcony along a curved path (the bows)",
    "_euro_column": "Hotel Europejski: kit_column CORINTHIAN, capital 0.5 m tall and 1.7 r wide (kit: 1.5 r)",
    "_euro_ledge": "Hotel Europejski: kit_ledge with a lighter top",
    "_euro_window": "Hotel Europejski: glass in M_GLASS (the shader's lit rooms), a flat surround with no sill",
    "_g77_windows": "a ring of windows round a curved plan",
    "_g77_balcony": "a balcony round a curved plan",
    "_fl_windows": "windows round a ring, floor by floor",
    "_teatr_pediment": "Teatr Wielki: a pediment with copper slopes through the whole block and its own relief",
    "_bank_colonnades": "the bank's colonnades with their entablature in one piece",
    "_zb_pediment": "Zbawiciela (merged the day the kit landed): its portal's pediment",
    "_elek_pane": "Elektrownia Powiśle: panes in its own two-axis frame",
    "_teresy_window": "a round-headed church window with lattice bars and a brick panel under it",
    "_wide_pediment": "a pediment built from a spec dictionary (statues, oculus)",
    "_orly_pediment": "Dom pod Orłami: a pediment carrying the eagles",
    "_hw_panes": "Hotel Warszawa: panes in M_GLASS on faces along u or v",
    "_hw_cornice": "Hotel Warszawa: a three-step cornice with a shadow line (kit_cornice_ring has two steps)",
    "_hw_back_panes": "Hotel Warszawa: the back's panes, as _hw_panes",
    "_kras_pediment": "Pałac Krasińskich: a pediment with a relief field and three statues",
    "_sn_column": "Sąd Najwyższy: a column that is a whole green pier from a mapped outline",
    "_fk_window": "Foksal: a window with a red frame between stone and glass, glass in M_GLASS",
    "_fk_balcony": "Foksal: kit_balcony STONE with a rail height argument",
    "_sm_pediment": "Smolna 38: a window pediment 2.2 m wide on its own cornice (kit PEDIMENT is stepped blocks)",
    "_lw_window": "Kamienica Ławrynowicza: two trim colours (red arch, stone sill), a sill 10 cm narrower than the kit's",
    "_lw_balcony": "Kamienica Ławrynowicza: three colours (stone slab, brick wall, red coping)",
    "_u47_window": "Ujazdowskie 47: frame bands over and under the pane (four boxes; SILL_HEAD has three)",
    "_u47_balcony": "Ujazdowskie 47: rail 13 cm lower than the kit's and no side rails",
    "_td_windows": "a whole wall of windows from one width",
    "_sm_window": "Stacja Muzeum: one unlit quad on a face of constant v",
    "_sm_window_v": "Stacja Muzeum: a red-framed quad on a face of constant u",
    "_n31_pane": "panes of several kinds between two plan points",
    "_m99_balcony": "a balcony between plan points, not in a front's frame",
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
