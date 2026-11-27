# Loop 3h part 1 (the demo loop): hand-over brief

Written 2026-10-31 by the content thread for a **fresh thread** to take. Nothing is built yet: the
agent that started it was stopped before it wrote anything (the working tree was clean, nothing
lost). The claim row in `docs/QUESTIONS.md` is removed; claim the item again when you start.

**How to run it** (the project's pattern, see `CLAUDE.md` and `docs/WORKFLOW.md`): give the brief below
to a `gameplay-dev` agent on Opus (design calls included: the user's standing rule is to make
reasonable calls and park the question with the default built), verify yourself (rerun the checks,
look at the shots), park its Open Questions in `docs/QUESTIONS.md`, commit, merge `origin/main`
(ROADMAP.md and DEVELOPMENT.md conflict often: keep both sides, main's rows first), run
`godot --headless --path game --editor --quit` for `.uid` files, push, open the PR, merge once CI is
green (the user's standing yes for cloud sessions).

**Pitfalls learned on the way**
- The derived map files in the cloud container are stale (before map north; no `lod2.*` or
  `terrain.json`): shots use `--monolithic`, and `check_landmarks` and the other map-only checks
  fail on main there too. Run `tools/setup_map.sh --if-needed` if you need them fresh (a window opens).
- A check that plays a sound must free its players before quitting (the Mac has a real audio
  driver); see `game/tools/check_tape.gd`.
- Scale: split into several fresh threads if the survey says it is too big (save v2 + districts,
  then the Syrenki, then the ladder and "Trzy mosty", then the first 10 minutes and the end card).
- `docs/QUESTIONS.md` "In progress" table: one row per lane; push claims straight to main.
- Pending context from the same day: the content thread's merged work is listed in ROADMAP's last rows
  (night buses, the vintage tram, the garage, the couriers, Plac Piłsudskiego, the L-shaped map);
  46 of 47 eggs are reachable (E35 waits on the user's "from 2010" tapes answer).

---

You are doing loop 3h, "the demo loop", part 1, on Around Warsaw, a free, open-source (MIT) fan game: an isometric small-car arcade drive through the real centre of Warsaw, made in Godot 4.7.2, Mobile renderer, iOS first (Metal). The project is the repository you are in.

Act as the project's `gameplay-dev` agent: read `.claude/agents/gameplay-dev.md` first and follow it (lane, code style, gates, report), except where this brief says otherwise. Where a call is design (numbers, wording, order), also read `.claude/agents/game-designer.md` and make the call yourself (the user's standing rule: autopilot, make reasonable calls, park the question with the default you built).

WHY: docs/DEMO.md section 6 and loop 3h ("The demo loop": the first-10-minutes script, rival ladder and final race, Syrenki and cassettes, the garage, district cards, the end card, save v2). The checklist it must turn green: A1 to A5, F1 to F4, G1 to G3, I1 to I2 (DEMO.md section 1). Already built by other loops: the garage and paints (loop "garage": `garage.gd`), eggs (46/47: `eggs.json`, `egg_book.gd`), the notebook (MW-1: places and chapters), KASETA/cassette viewer, Łuber, kebab, jobs (courier race, round-up), police (3g), PÓŁNOC FM, Fotka, the L-shaped map up north, the rivals (`rivals.gd`). Missing or partial (survey first, then fix this list): the rival ladder with its final race "Trzy mosty", the Syrenki (20 collectibles), district discovery and completion (cards, "?" marks, the pause card, shown on the map: G3), the guided first 10 minutes (hint finger, the guaranteed first order, first-race tuning, the Powiśle card at about 8:00), the end card and "free roam" after, save v2 (a version number and a migration for the garage/notebook/eggs/wallet sections already in the save).

Model: opus (design and gameplay judgment).

Read first: CLAUDE.md; docs/WORKFLOW.md; docs/DEMO.md sections 1 (checklist), 2 (the area), 6 (6.1-6.3 and the progression text), 7 (the loop table row 13) and the "Open questions" if any; docs/design/vision.md for the notebook, places, districts (grep district) and the eggs; docs/BACKLOG.md (grep ladder, Syrenk, district, save, end card, first order, hint); docs/DEVELOPMENT.md (save, wallet, rivals, jobs, notebook, eggs, HUD, pause card, flags, "Performance budgets"); the code: `rivals.gd`, `jobs.gd`, `missions.gd`, `wallet.gd`, `save` handling (grep `ConfigFile` / `user://`), `settings.gd`, `notebook.gd`, `egg_book.gd`, `garage.gd`, `hud.gd`, `full_map.gd`, `main.gd` (flags and the start), `game/data/places.json` (districts?), `dialogue.json`. Skills (read as files): verify-game, screenshot-review (+ art-bible.md), warsaw-tone, godot-mobile-perf.

## Lanes
Driving (`car.gd`, `drive_controls.gd`, `follow_camera.gd`, `traffic.gd`) is idle and ours now, but keep changes there to what an item needs, listed. Map (`tools/bake_*.py`, `game/map/`, `map_builder.gd`) and landmarks/models (`models.gd`, `landmarks.gd`) are other threads': don't edit; use existing roads and places, and list what the map lane should add. Shaders (`game/shaders/`) are the visuals lane's: no edits.

## Items, in order (finish one cleanly before the next; stop cleanly after a finished item if time runs short, and say where you stopped)
1. **Survey and plan** (a short section in your report, not a new doc): per checklist row A1-A5, F1-F4, G1-G3, I1-I2, what is already green, what this loop turns green, and what stays for part 2 (device-gated or too big). Do this first, in a few lines, then build.
2. **Save v2**: a `version` in the save, a migration from the current unversioned save (keep wallet, garage paints, notebook discoveries, eggs, settings; never lose progress), a `--nosave` that still never writes; a check for the round-trip and the migration (an old-format fixture in the check).
3. **Districts**: the demo's hero districts as data (Śródmieście, Powiśle, Praga, Stare Miasto, Wola up to Rondo Daszyńskiego, Mokotów edge, ...: take them from DEMO.md/vision; assign each place and egg/Syrenka a district, `district` in places.json is allowed as a new field; don't rewrite existing words), discovery (enter a district: the "discovered" card with the district's name, e.g. "Powiśle discovered", 3 "?" marks on the map per district), completion (jobs done + eggs + Syrenki found as a % per district), shown on the map (full map/minimap tint or a list in the pause card). G3.
4. **Syrenki**: 20 collectibles (small mermaid figurines; the real statues count too: Syrenka on the Old Town Market Square, on Powiśle's embankment/Karowa, at Praga's...: use places the map has; invented figurines elsewhere), each a small prop (instanced, +0 draw calls via an existing MultiMesh path) with a pickup, a counter, a toast, a district tie, and a reward (gold paint already unlocks at 5 eggs; add a reward ladder: 5/10/20 Syrenki → something that feeds the garage, radio or ladder: see F4). Words Polish above English, ≤ 70 chars, warsaw-tone.
5. **The rival ladder and the final race "Trzy mosty"**: the 6 rivals in order of stake (Halina 60 → Mordor Mike 300 zł), each unlocking the next by respect; the final race at night against Seba, three bridges, from Rondo Daszyńskiego to the stadium's stands; the existing `rivals.gd` races stay; add the ladder UI (pause card / notebook section) and gating. Tune so the first race is won narrowly (A-checks).
6. **The first 10 minutes**: the ghost finger hint after 4 s of no touch, the guaranteed first order (a hand-picked 700 m delivery past the Rotunda), the first-race tuning (800 m to the Palm, Seba loses narrowly), the Powiśle card at ~8:00 (falls out of item 3 if the route crosses it), the garage marker (already after first earnings). A `--first10` flag that scripts the beats' triggers for a replay check (the check: a scripted headless replay hits each 6.2 beat's trigger within its time window).
7. **The end card**: after the demo's activities (≥ N jobs, M eggs, the final race won: your call, state it) show a thank-you / "this was the demo" card (Polish above English, a wink, F's link text from README: don't invent URLs; use the repo name only) with "free roam" to continue.
8. **Checks and docs**: new/extended checks (save v2, districts, Syrenki, ladder gating, first10 replay, end card trigger), map-free where possible, joined to `tools/verify.sh` and CI's quick list; DEVELOPMENT.md sections and flags table; ROADMAP progress-log row (last row); BACKLOG (strike what this closes; list part 2).

## Budget
DEMO.md's: scripts ≤ +0.2 ms for the loop (report headless bench before/after), +0 draw calls where possible (Syrenki instanced in an existing MultiMesh, UI on the existing HUD mesh), no per-frame scans (timers).

## Environment (Linux cloud container, not the Mac)
- Godot 4.7.2 at `/usr/local/bin/godot`; zsh, ffmpeg installed. Headless checks and runs work; derived map files are present (gitignored) but STALE (pre map-north, no lod2/terrain): screenshots with `--monolithic`.
- Screenshots: the software Vulkan driver is under a scratch folder where you rebuild it (earlier loops kept it under their scratchpad `mw1`; if missing, unpack Ubuntu 24.04 `mesa-vulkan-drivers` with `dpkg-deb -x` and write an ICD json with the absolute path to `libvulkan_lvp.so`) (find the ICD json; `VK_ICD_FILENAMES=<json> xvfb-run -s "-screen 0 2900x1400x24" godot --path game --rendering-driver vulkan --rendering-method mobile --resolution 2532x1170 ... -- ... --shots=... --nosave`).
- Map-only checks (drape, drive, water, roads, landmarks) fail in this container on main too. No Xcode: skip `--ios`.
- The Mac has a real audio driver: any check that plays a sound must free its players before quitting (see `check_tape.gd`), or skip playback.
- Scratch: your scratchpad folder. New scripts need .uid files: `godot --headless --editor --path game --quit` once at the end.
- Flaky checks are bugs: seed or wait for the condition; run each new check 10 times.

## Constraints (hard)
- Don't touch git. The orchestrator commits.
- Don't rewrite existing words in dialogue.json/eggs.json/places.json (new fields and new entries are fine). Brands only as parodies; no real private person.
- Every game run: `--nosave` and `--quit-after N` or `--shots=`. Engine flags before `--`, game flags after.

## Acceptance
- New checks green 10/10; `tools/verify.sh --only=hud,eggs,tape,crowds,life,jobs2,couriers,parodies,buses,oldtram,garage,radio,sounds,sfx,police,rides,steering,settings,cost,plain,ram,sites,edge` plus every new step: PASS, table pasted.
- Screenshots you looked at (2532x1170 and 2868x1320): a district discovered card, a Syrenka in the world and the counter, the ladder UI, the end card. List paths.
- Bench before/after.

## Report format
The survey (checklist rows: green / turned green / left), what you changed per item, files new/changed (and any hook in another lane's file with why), check output, screenshot paths, the bench table, what F should try on the phone (a short first-10-minutes script to play), known issues, what is left for part 2, and **Open Questions** (each with the default you built).
