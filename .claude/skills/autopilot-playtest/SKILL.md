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

## 0. Setup (once per Mac; the user does the account steps)

1. Install the `autopilot` CLI from the same release as the add-on (v1.0.0-753232a; the add-on no
   longer bundles `agent_service/`; get the installer from the ramenvr/autopilot release page). Claude
   Code's auto mode blocks it ("code from external"): the user runs it.
2. `autopilot connect claude`, then a new Claude Code session (it blocks this as
   self-modification too: the user runs it).
3. In the editor's Autopilot tab: sign in to Aura and choose **Aura** as the decision model (no
   TypeSafe key needed), runs sharing **off**.

## 1. Before every run

- `tools/autopilot.sh on`, then open the editor (`godot --editor --path game`, in the
  background). The plugin and its game-side autoload are **off in git**: they must never ship,
  and the exports refuse to run while it is on. `tools/autopilot.sh off` before you commit
  `game/project.godot` or export. Opening the editor also writes `[autopilot] project_id` (the
  key of Autopilot's memory of the game): leave it out of commits too.
- Editor play always passes `--nosave` (`[editor] run/main_run_args` in project.godot), so a
  run never touches the player's save; never take that line out.
- Pick the next row of docs/PLAYTEST.md "The test plan" (the first never run, then the oldest);
  one row per run, 10 minutes of game time by default.
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
  before/after, the street name if the codex knows it.
- Time limits on elapsed episode time, never on the game clock that keeps running.
- Drive by waypoints along real streets (the road data in `game/map`, the codex), not compass
  headings: players follow streets.
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
- **Flying**: cruise at about 50 m and come down only within 30 m of the target (run 13 aimed at the cassette's height and flew into the ground).
- **Story beats (P2)**: offer options from the guide's own state (`first10.gd` `fired`), not the
  agent's memory, and give each beat a real drive or fly option (run 10 only waited at the race
  and lost it). An edge check on rects misses text that slides off while it animates: look at
  the frames.
- **Count a stop only on the road**: within the carriageway of a road in `game/map/centrum.json`
  `roads` (`p` is a flat x,z list, `w` its width). Run 3's framed hard stops were all the agent
  driving 30 m off the road into car park walls: correct collisions, not bugs. Off-road events
  go to a separate list, read only for clipping and under-the-ground.
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
- **Keys**: the game reads `physical_keycode` (main.gd `_unhandled_key_input`: H, Q, E, C...), so an injected key event must set it, or H "does nothing" (run 12). The HELI button always works. During a job that rides in the car the helicopter is refused with a toast, by design.
- **Short runs**: on F's Mac the run's sandbox ended (-9) about 5-6 minutes into the second episode in runs 11-14, even in a single episode (runs 13-14), at about 6 minutes of play: plan rows that need under 6 minutes, start what you test in the first 2-3 minutes, and restart the editor before a run; flush the trace every tick and describe frames as they come in.
- After the run, frame-describer on the frames of every stop and height event: a hard stop can
  be a kerb, a tram island or just a traffic car, and only the picture tells.

Don't change the project's files during a run; the game is acted on only through play.

## 3. After the run

1. Add each finding to docs/PLAYTEST.md "The bug log" as `PT-<next>`, status `suspect`, with
   the place, `--at=x,z`, what happens, the run id and trace. Copy frames worth keeping to
   `shots/autopilot/<run>/` (gitignored), never into git.
2. Confirm, cheapest first: drive there (`godot --path game -- --nosave --quit-after 600
   --at=X,Z --heading=H`), a `verify` run, or `check_drive.gd --debug=X,Z`. Set S1/S2/S3
   (PLAYTEST.md §3) or `closed (no repro)`.
3. Update the plan row's "Last run" and "Result".
4. Hand confirmed bugs to the coordinator (in a project thread: `message_coordinator`), one bug
   or one street's small batch per message, with the PT ids: the coordinator starts one fix
   thread per bug. Never fix in the playtest thread.
5. Re-run the rows of an area whenever its map geometry changes (a bake, new kerbs, decks,
   props): clipping and out-of-bounds bugs come back with geometry.
6. Fix threads: prove the cause (with and without `--no-traffic`), fix, add the spot to a check where one fits, set `fixed (PR)`.
   The next run of that row sets `verified` or reopens it.

## Gotchas

- Enabling the plugin by editing project.godot by hand skips its `_enable_plugin()`, so the
  autoload is missing: use `tools/autopilot.sh on`.
- Godot headless (Autopilot's own CI path) never captures the mouse and has no renderer: our
  shots and looks don't work there; use the editor path.
- The city takes about a minute to build at the start of each play session (the "A frame took
  61 s" error is that, not a bug).
- Coordinates: Autopilot's kit frame is centimetres, `kit = 100 * (-z, x, y)`; convert with
  `game.to_native` before writing `--at=` (Godot x, z in metres).
