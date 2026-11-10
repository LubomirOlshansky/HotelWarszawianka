---
name: autopilot-playtest
description: Playtests Around Warsaw with Autopilot (an AI player in the Godot editor, Mac only) by the plan in docs/PLAYTEST.md and turns findings into PT-n bug log rows and fix threads. Use when asked to playtest, explore for bugs, find stuck spots, re-run a plan row after a fix, or "use Autopilot".
---

# Playtesting Around Warsaw with Autopilot

Autopilot (github.com/ramenvr/autopilot, Apache-2.0, plugin in `game/addons/autopilot/`) plays
the game in the Godot editor: Claude writes a harness from our code, a decision model on Aura
makes the moment-to-moment choices. Its own `autopilot` skill (installed by
`autopilot connect claude` into `~/.claude/skills/autopilot/`) is how to drive its MCP tools:
`start_run`, read the INSTRUCTIONS.md it names, `wait`, `report`, and frames only through the
`frame-describer` subagent. Follow that skill for the tools; this one says what to test, the
project's rules, and what happens with the results.

**Two things are called "autopilot".** This skill is the Aura plugin on the Mac (F says
"Autopilot Aura"). The game's own `--autopilot` flag is a scripted driver for missions, races and
jobs in headless checks (verify-game skill); it runs in the cloud and needs no Mac.

**What Autopilot is for** (lessons of 2026-11-02..08, PT-1..PT-45): it is good at finding a
*place and a symptom* a player meets off the scripted routes (a dead stop, a HUD overlap, a
card that never shows, a script error every frame). It is bad at saying *why*: its cause
guesses were wrong as often as right (PT-40 "the harness line", PT-44 "beside a tram" were both
real wall ends a car on the kerb or pavement hits). So a run delivers spots with `--at=`, and a
cloud fix thread proves the cause with headless lines in minutes.

## 0. Setup (once per Mac; the user does the account steps)

1. Install the `autopilot` CLI from the same release as the add-on (v1.0.0-753232a; the add-on no
   longer bundles `agent_service/`; get the installer from the ramenvr/autopilot release page). Claude
   Code's auto mode blocks it ("code from external"): the user runs it.
2. `autopilot connect claude`, then a new Claude Code session (it blocks this as
   self-modification too: the user runs it).
3. In the editor's Autopilot tab: sign in to Aura and choose **Aura** as the decision model (no
   TypeSafe key needed), runs sharing **off**.

## 1. Before every run

- **One Autopilot session on the Mac at a time.** Two threads in one editor, or two editors,
  corrupt each other's runs and the CPU makes both slow (the padel thread waited ~40 min on
  11-07 guessing whether the hunt was done from "quiet for 10 minutes"). Take the Mac with
  `tools/autopilot.sh on <thread name>`: it writes the lock `build/autopilot.lock` and refuses
  while another owner holds it with a Godot running. `tools/autopilot.sh status` names the
  owner. When you finish, `tools/autopilot.sh off` (frees the lock), close the editor, and tell
  the coordinator "the Mac is free" so the next thread in the queue starts.
- **Never overlap with exports or benches**: `tools/autopilot.sh off` before
  `tools/export_ios.sh`, `xcodebuild` or a bench; the exports refuse while the plugin is on.
- **Run on the latest main**: `git pull` (or merge main into the branch under test) and restart
  the editor before the first run. Hunt 2 nearly re-tested a day-old checkout after a merge
  train; an old checkout re-finds bugs that are already fixed.
- `tools/autopilot.sh on`, then open the editor (`godot --editor --path game`, in the
  background). The plugin and its game-side autoload are **off in git**: they must never ship,
  and the exports refuse to run while it is on. `tools/autopilot.sh off` before you commit
  `game/project.godot` or export. Opening the editor also writes `[autopilot] project_id` (the
  key of Autopilot's memory of the game): leave it out of commits too.
- Editor play always passes `--nosave` (`[editor] run/main_run_args` in project.godot), so a
  run never touches the player's save; never take that line out.
- Pick the next row of docs/TEST_BACKLOG.md, then docs/PLAYTEST.md "The test plan" (the first
  never run, then the oldest); one row per run, **under 6 minutes of play** (see "Short runs").
- **Cost:** the decision model bills to the user's Aura account. One row at a time; ask the user
  before more than three rows in one go or a run over 15 minutes.

## 2. The harness: what it must record

The first run lost its stuck positions (kept in memory only), so every harness here must write,
per event, to its trace file:
- **stops**: speed falls from over 20 km/h to under 3 km/h within 1 s, or under 5 km/h for 3 s
  with the gas held; **unsticks**: `car.gd`'s `unsticks` counter going up (and whether it freed
  the car); **height jumps**: the car's y against the frame before (over 2 m) and against the
  terrain under it (`map.drive_height`) (below by more than 1 m = under the ground);
  **clips**: the car inside a building's box.
- Each with game time, **Godot world x, z** (metres; what `--at=` takes), heading, speed
  before/after, the street name if the codex knows it, and **where on the road the car was**:
  its side offset from the road's centre line and whether it was in a lane, over the kerb, on
  the pavement or the tram strip. That one number decides who fixes it (see section 3).
- Time limits on elapsed episode time, never on the game clock that keeps running. **Waits run
  on real time too**: a wait on the game clock freezes while the pause card is open (PT-42 was
  that, not a bug).
- Drive by waypoints along real streets (the road data in `game/map`, the codex), not compass
  headings: players follow streets.
- **Teleports only to reach the row**: `--at=` or the map teleport may put the car at the start
  of the area, never next to the goal. The drive *is* the test: the padel run found PT-31 (no
  car route from Solec) only because it drove; the 11-08 padel re-test teleported to the club
  and so tested the match but not the way there. Name every teleport in the report.
- **Leave out traffic bumps**: a stop with a traffic car touching the player's, or a driver's
  "traffic" shout (dialogue.gd `_shout`: KIEROWCA, TAKSÓWKARZ...) within 2 s, is the player
  hitting a car: correct, not a bug (runs 3-8: every framed on-road stop was one). Log the
  shout, read `traffic` near the car each tick, or run with `--no-traffic` for map-only bugs.
- **Finish frame-describer before `report`**: after `report` the `frames` tool refuses (run 7
  lost its frames that way).
- **Keep the Mac awake** for the whole run (the user's Energy settings, or `caffeinate` if the
  permission check allows it): a sleep ends the run (run 4).
- **Phone shape**: the editor's game view is 16:9 and can't be resized from a run; set the root
  window's content scale to 1266x585 (aspect keep) at the start, and log
  `get_viewport().get_visible_rect()`. Edge cut-offs (PT-9) only show at the phone's shape.
  Run cards and HUD rows at **both** shapes when a feature adds a card: the padel point cards
  (PT-30, padel) were never placed at 16:9.
- **Flying**: cruise at about 50 m and come down only within 30 m of the target (run 13 aimed at the cassette's height and flew into the ground).
- **Story beats (P2)**: offer options from the guide's own state (`first10.gd` `fired`), not the
  agent's memory, and give each beat a real drive or fly option (run 10 only waited at the race
  and lost it). An edge check on rects misses text that slides off while it animates: look at
  the frames.
- **Count a stop only on the road**: within the carriageway of a road in `game/map/centrum.json`
  `roads` (`p` is a flat x,z list, `w` its width), kerb and pavement edge included. Run 3's
  framed hard stops were all the agent driving 30 m off the road into car park walls: correct
  collisions, not bugs. Off-road events go to a separate list, read only for clipping and
  under-the-ground.
- Compare the car's height with `map.drive_height`, never the raw terrain grid: dug ground (the
  excavation by Fangora) is below the grid on purpose.
- **One street per run** when the streets are far apart (run 3 kept the first street's momentum
  and never reached the last three); slow to about 50 km/h near waypoints 15 m apart.
- **One street per option**, forced in turn (run 2's agent picked Marszałkowska every time and
  never drove the other eight). A steering deadband of about 14° keeps it on the street.
- A **stuck** is under 1.2 m/s for over 2 s with the gas held; when one lasts 10 s, reverse or
  `--at=` back to the route and go on, so a trap costs time but doesn't end the run.
- **Controls**: Classic is the default since 2026-11-04 (editor runs pass `--nosave`, so they get
  it): A / D steer car-relative, W is the gas, S brakes and reverses from a standstill. A harness
  written for Point's screen-direction keys must add `--controls=point` to the run's arguments,
  or drive with A / D against the car's heading. Name the scheme in the trace.
- **Keys**: the game reads `physical_keycode` (main.gd `_unhandled_key_input`: H, Q, E, C...), so
  an injected key event must set it, or H "does nothing" (run 12). **Tap** a key (press, then
  release a frame later): a held Escape does nothing (PT-42 again, 11-08). The HELI button
  always works. During a job that rides in the car the helicopter is refused with a toast, by
  design.
- **Short runs**: on F's Mac the run's sandbox ends (-9) at about 6 minutes of play (runs 11-14,
  every hunt since): plan rows that need under 6 minutes, start what you test in the first 2-3
  minutes, and restart the editor before a run; flush the trace every tick and describe frames
  as they come in. Split a long line (the Podwózka story ride, a whole quest) into rows that
  each start where the last ended.
- After the run, frame-describer on the frames of every stop and height event: a hard stop can
  be a kerb, a tram island or just a traffic car, and only the picture tells. Raise
  `frames_fps` to 10 around a spot the building see-through patch hides (PT-45).

Don't change the project's files during a run; the game is acted on only through play.

## 3. After the run

1. **Take the PT id from the register first**: the next free number is the highest in
   `/mnt/project-files/autopilot/bug-log.md`, main's docs/PLAYTEST.md *and* every open PR that
   touches PLAYTEST.md. Write the id into bug-log.md at once (it is shared and instant), then the
   row. Two threads on two branches both took PT-30..PT-32 on 11-07.
2. Add each finding to docs/PLAYTEST.md "The bug log" as `PT-<n>`, status `suspect`, with
   the place, `--at=x,z`, heading, the side offset, what happens, the run id and trace. Copy
   frames worth keeping to `shots/autopilot/<run>/` (gitignored), never into git. Mirror the
   short line into bug-log.md.
3. **Sort by who can tell, not by guessing the cause:**
   - *Harness-only* (closed here, no fix thread): the car 10+ m off the road, a traffic bump, a
     key the harness held or sent without `physical_keycode`, a wait frozen under the pause.
   - *Everything a player could do* (a stop in a lane, on the kerb, on the pavement or the tram
     strip; a card that never shows; a script error): **send it to the coordinator straight
     away** with the PT id, `--at=`, heading, offset and speed, one bug or one street's small
     batch per message. A cloud fix thread reproduces it with headless lines (lane centre,
     kerb lane, `--no-traffic`) in minutes; don't spend a second Mac pass "confirming" first.
     Never call a stop "the harness line" unless a kerb-lane line clears it too: PT-40 was
     waved off that way and was a real wall end.
4. Update the plan row's "Last run" and "Result", and tick the TEST_BACKLOG line.
5. Never fix in the playtest thread, and don't wait on a merge train: the hunt's docs PR is
   small; the fix PRs carry their own PLAYTEST.md status change.
6. Re-run the rows of an area whenever its map geometry changes (a bake, new kerbs, decks,
   props): clipping and out-of-bounds bugs come back with geometry. After a merge train lands,
   one short hunt on the touched areas is worth more than an hourly one on a quiet main.
7. Fix threads: prove the cause (with and without `--no-traffic`), fix, add the spot to a check
   (`check_stuck_spots.gd` for car spots, showing old main fails and the fix passes; `check_hud`
   for HUD), set `fixed (PR)`. The next run of that row sets `verified` or reopens it; list it
   under TEST_BACKLOG "Fixes waiting for proof".

## 4. Scheduling hunts

- **Autopilot never gates a merge** (F, 2026-11-08: waiting would slow merges down badly). A PR
  merges on its green CI and the usual go; Autopilot then plays it from main in the next hunt.
  A feature thread doesn't queue for the Mac before merging, and nobody holds a merge for a run.
- Hunts run in a Remote Control session on the Mac, which only starts from F's own message and
  goes offline when the Mac sleeps or the session idles. A routine in the cloud can't start one
  and can't message it. So: a hunt starts on F's "start" or after a merge train, not on a timer;
  a routine that finds the Mac offline stays silent instead of posting "no change".
- The coordinator keeps the Mac queue (hunt, feature threads that want a run, exports) and hands
  the Mac to the next thread when the last one says it is free.

## Gotchas

- Enabling the plugin by editing project.godot by hand skips its `_enable_plugin()`, so the
  autoload is missing: use `tools/autopilot.sh on`.
- Godot headless (Autopilot's own CI path) never captures the mouse and has no renderer: our
  shots and looks don't work there; use the editor path.
- The city takes about a minute to build at the start of each play session (the "A frame took
  61 s" error is that, not a bug).
- Coordinates: Autopilot's kit frame is centimetres, `kit = 100 * (-z, x, y)`; convert with
  `game.to_native` before writing `--at=` (Godot x, z in metres).
- A fresh save runs the first-10-minutes guide, which keeps friends from walking up for those
  10 minutes: a quest's in-person start needs a save past the guide (or the quest's own flag).
- On-road hard stops with a driver's shout bubble are traffic bumps (dialogue.gd `_shout`).
