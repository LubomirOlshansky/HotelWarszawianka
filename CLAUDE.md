# Around Warsaw: project instructions

Around Warsaw (formerly Nocna Warszawa; the Android package keeps `com.olshanskysoft.nocnawarszawa` (Play has it), the iOS bundle ID is `com.olshanskysoft.aroundwarsaw`,
build files keep `NocnaWarszawa`; the 87,3 radio station is KEBAB FM, id and folder `nocna_fm`).
A free fan game, source-available, non-commercial (PolyForm Noncommercial for code, CC BY-NC for art and sound, F 2026-11-06): an isometric small-car arcade drive (and a helicopter) through
the real centre of Warsaw, Godot 4.7.2 (Mobile renderer, iOS first, Metal), from OpenStreetMap and
GUGiK open data. Next milestone: a high-quality central-Warsaw demo on the iPhone (docs/DEMO.md).
The repo is meant to be private; the design wiki stays public until F decides.

## Where things are

| Path | What |
| --- | --- |
| `game/` | Godot project: `scripts/`, `shaders/`, `tools/` (check scripts, `bake_city.gd`), `data/`, `map/` (baked), `audio/` |
| `tools/` | Python bakes and helpers, `verify.sh`, `shots.sh`, `device_run.sh`, `check_map_data.py`, `export_ios.sh`, `hooks/guard_godot.py` (blocks game runs without `--nosave` or a quit flag) |
| `docs/DEVELOPMENT.md` | short INDEX. The full reference is `docs/archive/DEVELOPMENT-full.md` (~490 KB): never read it whole, grep a section and read that range |
| `docs/WORKFLOW.md` | the loop, owners, light/full definition of done, milestone gates |
| `docs/CITY_INVENTORY.md` (every characteristic place, ranked, street by street) · `docs/BACKLOG.md` (issues, decisions) · `docs/QUESTIONS.md` (parked questions, lanes in progress) · `docs/ROADMAP.md` (order of work) · `docs/DEMO.md` · `docs/LANDMARKS.md` · `docs/ADDONS.md` · `docs/PLAYTEST.md` (test plan, PT-n bug log) | read only the section you need |
| `.claude/agents`, `.claude/skills` | agents and skills (their descriptions say when to use them) |
| `data/raw/`, `build/`, `shots/`, `game_*/`, `refs/` | gitignored, never committed |
| `game/map/index.*`, `sectors/`, `proxies.scn`, `shared/`, `lod2.*`, `terrain.json` | derived, gitignored; a fresh clone runs `tools/setup_map.sh` once (`--full` for GUGiK data) |

## Model routing

The project default is **Sonnet**; the coordinator picks the model per thread. **Opus** only for
map geometry, gameplay design and feel, performance, device-gated work, root causes, and accepting
art. **Sonnet** for content, text, landing/site, docs, object polish and applying a spec.
**Haiku** for lookups, counts and log crunching. Agent files follow this (`gameplay-dev`,
`object-modeler`, `qa-tester` Sonnet; `map-engineer`, `perf-engineer`, `game-designer`,
`art-director`, `road-auditor`, `street-unslopper` Opus; `scout`, `street-scout`, `Explore` Haiku). A cheaper run that fails its gates or returns
open questions is re-run one tier up, not patched. Only the main session spawns agents. Delegate
file dumps, logs and shot sets; keep the summary. Say which model each delegation used.

## Backlog mode (standing rule)

The work never stops for a question: park it in `docs/QUESTIONS.md` with the default that was
built, and take the next item by priority (backlog-loop skill). One item per thread, one session
per area (driving, map, visuals, content, performance, landing, store); check open PRs, recent
main commits and "In progress" first. A cloud session merges its own PR once every check is green. When an item is done, check
ROADMAP "v1.0 checklist" for the next open line; if nothing is left, go street by street through
the centre (F, 2026-11-01): analyse every landmark and improve the houses, roads, parks and
everything else, with our best approaches, until the city feels alive and real.
Irreversible things, paid tools, device runs and store submissions wait for the user's yes.

## Hard rules

- **Runs.** Every game run passes `--nosave` and quits (`--quit-after N` or `--shots=`); autopilot
  runs never quit by themselves; `check_steering.gd` needs `--fixed-fps 60`. Engine flags before
  `--`, game flags after. macOS has no `timeout` (`perl -e 'alarm shift; exec @ARGV' 600 cmd...`).
- **Both city paths** (runtime build and prebuilt sectors) must work. After a map change:
  `python3 -I tools/bake_sectors.py`, then `godot --path game --resolution 320x180 --script
  res://tools/bake_city.gd` with a renderer, never `--headless`. Check looks with `--prebuilt` too.
- **Derived map files are never committed.** After any centrum.json re-bake run the whole chain
  and `python3 -I tools/check_map_data.py`; new counts only on purpose, recorded in that script
  and the archive's "Map data" together.
- **Performance is a gate.** The phone's frame grows with draw calls, not triangles. Report bench
  before/after for anything per-frame or adding geometry, materials or lights (archive section
  "Performance budgets").
- **Downloads are pre-approved** (free dev tools, data, Godot add-ons from official sources): name
  each in the PR with source, size and licence. Add-on rules and the installed list: docs/ADDONS.md.
  A paid tool or service needs the user's yes. Never write the PixelLab key (or any key) into a
  file; no project `.mcp.json`; up to 50 PixelLab generations per loop.
- **Content.** Original art, music and writing. Real place names are fine; brands only as
  parodies; affectionate humour, never about real private people; on-screen text in Polish with
  English (warsaw-tone skill).
- **Device runs** only when the user said so for the current loop (device-run skill); never write
  a device identifier into a tracked file.
- **Repo.** No secrets, keys, device identifiers, emails or absolute home paths in tracked files.

## Commands

```zsh
tools/verify.sh [--quick|--ios|--only=a,b]   # the verification set, one PASS/FAIL table
tools/shots.sh [--set=core|quick|names] [--size=2532x1170]   # phone-size screenshots
cd game && godot --path . --disable-vsync -- --bench --nosave  # bench
tools/export_ios.sh   # splits the map, prebuilds sectors, exports build/ios
tools/export_android.sh [--skip-city|--apk]   # the signed Play AAB
```

## Conventions

- GDScript: static types, tabs, `##` doc comments saying what and why. Python: `python3 -I`,
  standard library, a usage docstring. Checks are `game/tools/check_*.gd` printing `<name>: OK`
  and exiting 0/1; a new check joins `tools/verify.sh` in the same change. New test flags are
  parsed in `main.gd` and noted in the archive's flags table.
- **Docs bookkeeping: BACKLOG** (fixed removed, found added), plus ONE plain line under the day
  in `docs/CHANGELOG.md` only for a change the player or visitor can see (it feeds the live
  /progress/ page), and the item's line ticked (or added) in ROADMAP "v1.0 checklist" in the
  same PR, so progress stays checkable in one place. No progress-log row.
- **Add-ons check.** Whenever you create or change NPC/agent behaviour or a conversation, decide
  on Beehave / Dialogue Manager first (skills `beehave-trees`, `dialogue-scenes`) and write
  "used / not used, because ..." in the PR. Default: not used outside the police and authored
  branching scenes.
- **Definition of done** is light or full by change kind (docs/WORKFLOW.md): light for content,
  text, site, docs, polish; full (verify, shots, bench, `--ios`) for gameplay, geometry and
  anything per-frame. Name what only the phone can show.

## Git

Commit or push only when the user asks in the current conversation. Never force-push, rewrite
published history or delete a remote branch. Never commit `data/raw/`, `build/`, `shots/`,
`game_*/` copies, logs, keys, device identifiers or personal data. Subagents don't touch git
unless their brief says so.
