"""Check that docs/architecture names every game script, and hold the code's boundaries and ratchets.

Usage: python3 -I tools/check_architecture.py [--root=DIR | --selftest]

1. Every .gd file under game/scripts/ (path relative to it, e.g. `police/guards.gd`, or for a
   top-level script its bare name, e.g. `traffic.gd`) must appear in backticks in
   docs/architecture/systems.md or docs/architecture/city-ai.md, and a page's link to a file in
   docs/architecture/ must exist.
2. Boundaries at zero (docs/architecture/tech-debt.md, "What is clean today"): what one owner
   alone does stays with it (BOUNDARIES; comments and strings do not count). The tree's pause
   (step `pause`), the command line (step `devflags`) and the checks' private fakes (step
   `fakes`) have their own steps.
3. Ratchets (RATCHETS): a count that may go down, not up. An exact one fails above its number
   and warns below it, so the pull request that lowers it writes the new number here (the warning
   does not hold up another lane's change). A band (main.gd's size) has room above the measured
   count for the feature changes that land meanwhile; only a structural change lowers its number.

Prints `check_architecture counts: ...`, then a `check_architecture: WARN ...` line for each exact
ratchet to lower, then `check_architecture: OK` and exits 0, or lists the problems and exits 1.
--root=DIR checks another copy of the repo. --selftest breaks each rule once on a copy in a
temporary folder (and tries comments, strings and the allowed scripts beside them) and prints
`check_architecture selftest: OK`; verify step `architecture` and CI run both.
"""
import functools
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGES = ["systems.md", "city-ai.md"]

# Polish letters: a string literal with one is on-screen text (TD-19).
POLISH = re.compile("[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]")
# Scripts whose Polish words are the city's own (signs, shop fronts, place and street names, the
# font's glyphs), not lines of play: TD-19 counts the rest. A place script (`extends place.gd`)
# and anything under landmarks/ count as signs too.
SIGN_SCRIPTS = {"landmarks.gd", "storefronts.gd", "neon_signs.gd", "map_builder.gd", "map_icons.gd", "pixel_font.gd"}

# Boundaries at zero: (name, regex, whether the regex reads the strings, the scripts allowed). The
# regex reads the code with comments and strings blanked, or with comments only blanked when the
# third field is true. Measured on main 2026-11-15 (f0cdc155): every one at zero.
BOUNDARIES = [
    ("ConfigFile.new() outside the save and the settings", r"\bConfigFile\.new\s*\(", False,
        {"wallet.gd", "settings.gd"}),
    ("an AudioServer bus change outside sfx.gd",
        r"\bAudioServer\.(?:set_\w+|add_bus\w*|remove_bus\w*|move_bus|swap_bus_effects)\s*\(", False, {"sfx.gd"}),
    ("Input.vibrate_handheld outside haptics.gd", r"\bInput\.vibrate_handheld\s*\(", False, {"haptics.gd"}),
    ("an absolute node path", r"(?:\b(?:get_node|get_node_or_null|has_node|NodePath)\s*\(\s*[&^]?\"/|\$\"?/)", True,
        set()),
    # activities.gd `abort` (2026-11-15): the ✕ goes through the director to one activity; the kit's base
    # hears it itself only before it joins.
    ("hud.abort_pressed heard outside the kit", r"\babort_pressed\.connect\s*\(", False,
        {"activity.gd", "missions.gd", "activities.gd"}),
]

# Ratchets: name -> (ceiling, kind). `exact`: the measured count; `band`: the measured count plus
# room. The 25 changes to main.gd from 2026-11-13 (#688) to 2026-11-15 (#810), the three structural
# ones (#733, #781, #798) aside, added 431 lines, 18 functions, 97 `_build_*` lines and 4 flag reads
# in all: the bands hold about a day of that for the lines, the functions and the wiring, and about a
# week for the flag reads. New code goes to its owner (docs/architecture/extending.md); a structural
# change makes room. Measured on main 2026-11-15 (f0cdc155), in the comments.
RATCHETS = {
    "main.gd lines": (7448, "band"),  # 7,298 + 150 after TD-4 b2; 7,372 after b6, 7,381 after b7, 7,338 after b8, 7,324 after b9, 7,306 after b10, 7,291 after b11, 7,288 after b12 (TD-4: under 6,000 by TD-1's end and TD-4 b)
    "main.gd functions": (258, "band"),  # 252 + 6
    "main.gd _build_* lines": (1613, "band"),  # 1,573 + 40 after TD-4 b12 (the wiring of the kit is out; phase 2 next)
    "main.gd flags. reads": (470, "band"),  # 460 + 10 after TD-4 b12 (activities read their own; test flags in the harness)
    "main.gd private busy tests": (4, "exact"),  # _free_block, _story_free, _world_free, _ev_free (TD-1)
    # TD-4 b (docs/design/wiring-out-of-main.md): an activity of the kit wires itself and main.gd joins
    # it with `_join` (or `_install`, then `_add`); this counts the calls still wired by hand (the two
    # tours share one). Measured on b1's head (2026-11-15): 12; on b2's: 11; on b3's: 10; on b4's: 9; on b5's: 8; on b6's: 7; on b7's: 6; on b8's: 4 (Łuber and the deliveries, two); on b9's: 3; on b10's: 2; on b11's: 1; on b12's: 0 (the rescue line, the last). It stays at 0.
    "main.gd activities.add outside _add": (0, "exact"),
    "hud.card_pressed listeners": (2, "exact"),  # story_quests.gd, first10.gd (TD-16)
    "Polish literals outside sign scripts": (1125, "band"),  # 1,105 + 20 (TD-19: spoken lines go to dialogue.json)
}


def blank(text: str) -> tuple[str, str, list[tuple[int, str]]]:
    """The script's text with comments blanked (`nocomment`), with strings blanked too (`code`), and its
    string literals outside comments with their line. Lines keep their numbers in both texts."""
    code, nocomment, strings = [], [], []
    i, n, line = 0, len(text), 1
    while i < n:
        c = text[i]
        if c == "#":
            j = text.find("\n", i)
            j = n if j < 0 else j
            code.append(" " * (j - i))
            nocomment.append(" " * (j - i))
            i = j
            continue
        if c in "\"'":
            q = text[i:i + 3] if text[i:i + 3] in ('"""', "'''") else c
            j = i + len(q)
            while j < n and not text.startswith(q, j):
                if text[j] == "\\":
                    j += 1
                elif text[j] == "\n" and len(q) == 1:
                    break
                j += 1
            j = min(n, j + len(q))
            body = text[i:j]
            strings.append((line, body))
            kept = re.sub(r"[^\n]", " ", body)
            closed = len(body) >= 2 * len(q) and body.endswith(q)
            code.append(q + kept[len(q):-len(q)] + q if closed else kept)
            nocomment.append(body)
            line += body.count("\n")
            i = j
            continue
        if c == "\n":
            line += 1
        code.append(c)
        nocomment.append(c)
        i += 1
    return "".join(nocomment), "".join(code), strings


def joins_by_hand(code: str) -> int:
    """`activities.add(` in main.gd outside its function `_add`: the activities still wired by hand."""
    n, inside = 0, False
    for line in code.split("\n"):
        if m := re.match(r"^(?:static )?func ([A-Za-z0-9_]+)", line):
            inside = m.group(1) == "_add"
        if not inside:
            n += len(re.findall(r"\bactivities\.add\s*\(", line))
    return n


def build_lines(code: str) -> int:
    """Lines of main.gd's `_build_*` functions, each from its `func` line to the next function, less the
    blank and doc-comment lines that end it (the next function's doc)."""
    lines = code.split("\n")
    starts = [(i, m.group(1)) for i, l in enumerate(lines) if (m := re.match(r"^(?:static )?func ([A-Za-z0-9_]+)", l))]
    starts.append((len(lines), ""))
    total = 0
    for (i, name), (j, _) in zip(starts, starts[1:]):
        if name.startswith("_build_"):
            k = j
            while k > i and lines[k - 1].strip() == "":
                k -= 1
            total += k - i
    return total


@functools.lru_cache(maxsize=None)  # the selftest checks the same scripts 24 times
def script_facts(rel: str, text: str) -> tuple[tuple[str, ...], tuple[tuple[str, int], ...]]:
    """One script's boundary problems, and what it adds to the ratchets' counts."""
    nocomment, code, strings = blank(text)
    found = []
    for name, pattern, on_strings, allowed in BOUNDARIES:
        if rel in allowed:
            continue
        for m in re.finditer(pattern, nocomment if on_strings else code):
            line = (nocomment if on_strings else code).count("\n", 0, m.start()) + 1
            found.append(f"{name}: game/scripts/{rel}:{line}")
    own = {"hud.card_pressed listeners": len(re.findall(r"\bcard_pressed\.connect\s*\(", code))}
    sign = rel in SIGN_SCRIPTS or rel.startswith("landmarks/") or re.search(
            r'^extends\s+"res://scripts/place\.gd"', text, re.M) is not None
    if not sign:
        own["Polish literals outside sign scripts"] = sum(1 for _, s in strings if POLISH.search(s))
    if rel == "main.gd":
        own["main.gd lines"] = text.count("\n")
        own["main.gd functions"] = len(re.findall(r"^(?:static )?func ", code, re.M))
        own["main.gd _build_* lines"] = build_lines(code)
        own["main.gd activities.add outside _add"] = joins_by_hand(code)
        own["main.gd flags. reads"] = len(re.findall(r"\bflags\.[a-z_]+", code))
        own["main.gd private busy tests"] = len(re.findall(
                r"^(?:static )?func _(?:[a-z_]+_free|free_block)\s*\(", code, re.M))
    return tuple(found), tuple(own.items())


def run(root: pathlib.Path) -> tuple[list[str], list[str], dict, int]:
    """The problems, the warnings, the ratchets' counts and the number of scripts for the repo at `root`."""
    scripts_dir = root / "game" / "scripts"
    arch = root / "docs" / "architecture"
    problems, warns = [], []
    named = set()
    for page in PAGES:
        path = arch / page
        if not path.exists():
            problems.append(f"missing page docs/architecture/{page}")
            continue
        text = path.read_text(encoding="utf-8")
        named.update(re.findall(r"`([A-Za-z0-9_/]+\.gd)`", text))
        # Tree diagrams list scripts without backticks.
        named.update(re.findall(r"\b([A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*\.gd)\b", text))
        # A folder named in the tree ("police/") covers the scripts in it.
        named.update(f"{d}/" for d in re.findall(r"\b([a-z_]+)/(?=\s)", text))
    scripts = sorted(p.relative_to(scripts_dir).as_posix() for p in scripts_dir.rglob("*.gd"))
    for rel in scripts:
        top = rel.split("/")[0] + "/" if "/" in rel else ""
        if rel in named or (top and top in named):
            continue
        problems.append(f"game/scripts/{rel} is not named in docs/architecture/{' or '.join(PAGES)}")
    for page in arch.glob("*.md"):
        for link in re.findall(r"\]\(([a-z0-9_-]+\.md)\)", page.read_text(encoding="utf-8")):
            if not (arch / link).exists():
                problems.append(f"docs/architecture/{page.name} links to missing {link}")

    # 2. Boundaries, and the counts the ratchets read, in one pass over the scripts.
    counts = dict.fromkeys(RATCHETS, 0)
    for rel in scripts:
        found, own = script_facts(rel, (scripts_dir / rel).read_text(encoding="utf-8"))
        problems.extend(found)
        for k, v in own:
            counts[k] += v
    project = root / "game" / "project.godot"
    if project.exists():
        section = ""
        for line in project.read_text(encoding="utf-8").split("\n"):
            if line.startswith("["):
                section = line.strip()
            elif section == "[autoload]" and "=" in line:
                name, value = line.split("=", 1)
                if not value.strip().strip('"').lstrip("*").startswith("res://addons/"):
                    problems.append(f"an autoload of the game's own: game/project.godot [autoload] {name.strip()}")

    # 3. Ratchets.
    for name, (ceiling, kind) in RATCHETS.items():
        n = counts[name]
        if n > ceiling:
            why = "a band: the new code goes to its owner (docs/architecture/extending.md), or a structural " \
                    "change makes room; never raise it" if kind == "band" else "it may go down, not up"
            problems.append(f"ratchet {name}: {n:,} over {ceiling:,} ({why})")
        elif n < ceiling and kind == "exact":
            warns.append(f"ratchet {name} is {n:,}, under {ceiling:,}: write {n} in RATCHETS (tools/check_architecture.py)")

    return problems, warns, counts, len(scripts)


def selftest() -> int:
    """Each rule catches its break, and comments, strings and the allowed scripts pass: on a copy of the
    repo's scripts, their pages and project.godot in a temporary folder, one break at a time."""
    import shutil
    import tempfile
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="check_architecture_"))
    try:
        shutil.copytree(ROOT / "game" / "scripts", tmp / "game" / "scripts", ignore=shutil.ignore_patterns("*.uid"))
        shutil.copytree(ROOT / "docs" / "architecture", tmp / "docs" / "architecture")
        shutil.copy(ROOT / "game" / "project.godot", tmp / "game" / "project.godot")
        problems, base_warns, base, _ = run(tmp)
        failed = [f"the copy itself: {p}" for p in problems]
        scripts = tmp / "game" / "scripts"
        landmark = sorted(p.relative_to(scripts).as_posix() for p in (scripts / "landmarks").glob("*.gd"))[0]
        place = sorted(p.relative_to(scripts).as_posix() for p in scripts.glob("*.gd")
                if re.search(r'^extends\s+"res://scripts/place\.gd"', p.read_text(encoding="utf-8"), re.M))[0]

        def over(name: str) -> int:
            """How many more of a ratchet's things put it one over its number."""
            return RATCHETS[name][0] - base[name] + 1

        lines = "\n".join(f"# filler {i}" for i in range(over("main.gd lines")))
        funcs = "\n".join(f"func _selftest_{i}() -> void:\n\tpass" for i in range(over("main.gd functions")))
        build = "func _build_selftest() -> void:\n" + "\n".join("\tpass" for _ in range(over("main.gd _build_* lines")))
        reads = "func _selftest_reads() -> void:\n" + "\n".join(
                f"\tprint(flags.f{i})" for i in range(over("main.gd flags. reads")))
        busy = "\n".join(f"func _selftest_{chr(97 + i % 26) * (1 + i // 26)}_free() -> bool:\n\treturn true"
                for i in range(over("main.gd private busy tests")))
        cards = "func _selftest_cards() -> void:\n" + "\n".join(
                "\tcard_pressed.connect(_selftest_cards)" for _ in range(over("hud.card_pressed listeners")))
        polish = "func _selftest_words() -> void:\n" + "\n".join(
                f'\tprint("Zażółć {i}")' for i in range(over("Polish literals outside sign scripts")))
        few_polish = "func _selftest_words() -> void:\n" + "\n".join(f'\tprint("Zażółć {i}")' for i in range(40))
        # (file, text added at its end, what must be printed: the start of the one new problem, "WARN" for one new
        # warning, "" for nothing new, or "same <ratchet>" for a count that must not move). hud.gd stands for any script that is not an owner and not a sign script.
        cases = [
            ("hud.gd", "\nfunc _selftest() -> void:\n\tvar c := ConfigFile.new()\n", "ConfigFile.new() outside"),
            ("hud.gd", "\n# ConfigFile.new() in a comment\nconst T := \"ConfigFile.new()\"\n", ""),
            ("hud.gd", "\nfunc _selftest() -> void:\n\tAudioServer.set_bus_volume_db(0, 0.0)\n", "an AudioServer bus change"),
            ("hud.gd", "\nfunc _selftest() -> float:\n\treturn AudioServer.get_time_since_last_mix()\n", ""),
            ("sfx.gd", "\nfunc _selftest() -> void:\n\tAudioServer.set_bus_volume_db(0, 0.0)\n", ""),
            ("hud.gd", "\nfunc _selftest() -> void:\n\tInput.vibrate_handheld(40)\n", "Input.vibrate_handheld outside"),
            ("hud.gd", "\nfunc _selftest() -> Node:\n\treturn get_node(\"/root/Main\")\n", "an absolute node path"),
            ("hud.gd", "\nfunc _selftest() -> Node:\n\treturn $\"/root/Main\"\n", "an absolute node path"),
            ("hud.gd", "\nfunc _selftest() -> Node:\n\treturn get_node(\"Main/Car\")\n", ""),
            ("hud.gd", "\nfunc _selftest(h) -> void:\n\th.abort_pressed.connect(_selftest)\n", "hud.abort_pressed heard"),
            ("main.gd", "\n" + lines + "\n", "ratchet main.gd lines"),
            ("main.gd", "\n" + funcs + "\n", "ratchet main.gd functions"),
            ("main.gd", "\n" + build + "\n", "ratchet main.gd _build_* lines"),
            ("main.gd", "\n" + reads + "\n", "ratchet main.gd flags. reads"),
            ("main.gd", "\n" + busy + "\n", "ratchet main.gd private busy tests"),
            ("main.gd", "\nfunc _free_selftest_spot() -> bool:\n\treturn true\n", "same main.gd private busy tests"),
            ("main.gd", "\nfunc _selftest_join(a) -> void:\n\tactivities.add(a)\n", "ratchet main.gd activities.add outside _add"),
            ("main.gd", "\nfunc _selftest_join(a) -> void:\n\t# activities.add(a)\n\tprint(\"activities.add(a)\")\n",
                "same main.gd activities.add outside _add"),
            ("hud.gd", "\n" + cards + "\n", "ratchet hud.card_pressed listeners"),
            ("hud.gd", "\n" + polish + "\n", "ratchet Polish literals"),
            (landmark, "\n" + few_polish + "\n", ""),
            (place, "\n" + few_polish + "\n", ""),
            ("hud.gd", "\n# Zażółć\nfunc _selftest() -> void:\n\tpass # gęślą jaźń\n", ""),
            ("selftest_new.gd", "extends Node\n", "game/scripts/selftest_new.gd is not named"),
            ("../project.godot", "\n[autoload]\n\nGame=\"*res://scripts/main.gd\"\n", "an autoload of the game's own"),
            ("../project.godot", "\n[autoload]\n\nTool=\"*res://addons/selftest/tool.gd\"\n", ""),
            ("", "under", "WARN"),  # an exact ratchet whose number is above the count
        ]
        for rel, change, want in cases:
            if change == "under":
                name = "hud.card_pressed listeners"
                kept = RATCHETS[name]
                RATCHETS[name] = (base[name] + 1, "exact")
                problems, warns, counts, _ = run(tmp)
                RATCHETS[name] = kept
            else:
                path = scripts / rel
                old = path.read_text(encoding="utf-8") if path.exists() else None
                path.write_text((old or "") + change, encoding="utf-8")
                problems, warns, counts, _ = run(tmp)
                if old is None:
                    path.unlink()
                else:
                    path.write_text(old, encoding="utf-8")
            new_warns = [w for w in warns if w not in base_warns]
            if want == "WARN":
                said = f"ratchet {name} is {base[name]:,}, under {base[name] + 1:,}:"
                ok = not problems and any(w.startswith(said) for w in warns)
            elif want.startswith("same "):
                ok = counts[want[5:]] == base[want[5:]]
            elif want.startswith("ratchet "):
                # Text added to main.gd may also fill a band beside the one the case is about.
                ok = any(p.startswith(want) for p in problems) and all(p.startswith("ratchet ") for p in problems)
            elif want:
                ok = len(problems) == 1 and problems[0].startswith(want) and not new_warns
            else:
                ok = not problems and not new_warns
            if not ok:
                failed.append(f"{rel or 'RATCHETS'} (wanted {want or 'nothing'}): problems {problems}, new warnings {new_warns}")
        for f in failed:
            print(f"check_architecture selftest: {f}")
        print(f"check_architecture selftest: {'FAIL' if failed else 'OK'} ({len(cases)} cases)")
        return 1 if failed else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    root = ROOT
    for a in sys.argv[1:]:
        if a == "--selftest":
            return selftest()
        if a.startswith("--root="):
            root = pathlib.Path(a.split("=", 1)[1]).resolve()
    problems, warns, counts, nscripts = run(root)
    shown = ", ".join(f"{k} {counts[k]:,}/{RATCHETS[k][0]:,}" for k in RATCHETS)
    print(f"check_architecture counts: {nscripts} scripts, {len(PAGES)} pages, "
            f"{len(BOUNDARIES) + 1} boundaries at zero, ratchets {shown}")
    if problems:
        for p in problems:
            print(f"check_architecture: {p}")
        print(f"check_architecture: FAIL ({len(problems)})")
        return 1
    for w in warns:
        print(f"check_architecture: WARN {w}")
    print("check_architecture: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
