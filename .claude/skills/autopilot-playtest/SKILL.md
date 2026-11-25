---
name: autopilot-playtest
description: Playtests Around Warsaw with Autopilot (an AI player in the Godot editor, Mac only) by the plan in docs/PLAYTEST.md and turns findings into PT-n bug log rows and fix threads. Use when asked to playtest, explore for bugs, find stuck spots, re-run a plan row after a fix, or "use Autopilot".
---

# Playtesting Around Warsaw with Autopilot

Autopilot (github.com/ramenvr/autopilot, Apache-2.0, plugin in `game/addons/autopilot/`) plays
the game in the Godot editor. Its own `autopilot` skill (installed by `autopilot connect claude`
into `~/.claude/skills/autopilot/`) is how to drive its MCP tools: `start_run`, read the
INSTRUCTIONS.md it names, `wait`, `report`, and frames only through the `frame-describer`
subagent. Follow that skill for the tools; this one says what to test, the project's rules, and
what happens with the results.

**Two things are called "autopilot".** This skill is the Aura plugin on the Mac (F says
"Autopilot Aura"). The game's own `--autopilot` flag is a scripted driver for missions, races and
jobs in headless checks (verify-game skill); it runs in the cloud and needs no Mac.

## What it is, and what it is for (F, 2026-11-24)

**How it plays.** Two models. Claude (the coding agent) reads our code and writes a *harness*:
a few macro options ("drive to the goal", "tap ACCEPT", "back out") and a plan whose steps read
the game's state. A small fast decision model (Jev, about 0.25 s a choice) picks one option at a
time from the facts the harness hands it. Jev never sees the screen and does not know what a bug
is. Autopilot keeps a memory of the game per project and gets better at the same prompts run
after run.

**What it is sold for**, and what works for us: short, concrete prompts of four kinds:
**verify** (one claim: "the tow offer comes within 10 s of a pin at X"), **goal** (one outcome:
"win the race against Pani Halina"), **test** (go over one thing: every tab of the settings
card), **explore** (free play). The public tests are all small: a tiny arena, one task, a few
minutes. None drives a city.

**What our hunts showed** (2026-11-02..24, PT-1..PT-60, the 23-24 ride runs):
- *Good*: a **place and a symptom** a player meets (a HUD overlap, PT-35; a real wall end on the
  kerb, PT-40 and PT-44; script errors at start-up, #1032; the loader stuck for ~160 s) and
  whether cards and buttons work at all (calls Accept/Skip/Later, settings, race won at cruise 95).
- *Bad*: saying **why** (its cause guesses were wrong as often as right: PT-40 "the harness line"
  and PT-44 "beside a tram" were real wall ends), and **long drives**. Six ride runs on 11-23/24
  found no game bug in the driving: every failure was our harness (U-turns, off the road,
  buttons by index), and it steers with keys, so it leaves narrow streets a player keeps to.

**So:**
1. **One row = one short verify or goal**, started at its own start (section 1, "Start at the
   row"), with a verdict read from the game's state. No 15-minute chains (kebab, then wait for
   the app, then the ride): the start flags put the car at the ride, the race, the order.
2. **Driving routes go headless, in the cloud**: streets, bridges, tunnels, a way from A to B,
   "is there a car route" are `check_lane_drive`, `check_drive --debug=X,Z`,
   `check_playtest_route` and `check_stuck_spots` lines (minutes, no Mac, no cost). Autopilot
   drives only the few hundred metres a row needs, or the drive *is* the claim.
3. A finding is a place (`--at=`, street, place on the road, side offset) plus frames. A cloud
   fix thread proves the cause headless.

What goes where:

| Question | Tool |
| --- | --- |
| Does a card, button, call, quest beat, menu, hint work in play; is a label cut off at 1266x585 | **Autopilot** verify/test |
| Can a race, a boat race, a drag, a delivery be won or finished by a player | **Autopilot** goal, from its start flag |
| The helicopter: take-off, landings, roofs, the car given back | **Autopilot** goal (headless can't fly the HUD) |
| A street, bridge, tunnel, ramp: stops, kerbs, heights, the car under a deck | **headless** lines (`check_lane_drive`, `check_drive`), Autopilot only to film a spot a line found |
| Is there a road route from A to B; does the route loop | **headless** `playtest_route` / lane graph |
| A spot Autopilot flagged | **headless** repro in a fix thread, never a second Mac pass |

## 0. Setup (once per Mac; the user does the account steps)

1. Install the `autopilot` CLI from the same release as the add-on (v1.0.0-c84203c; the add-on
   in git leaves out `agent_service/`, so get the installer from the ramenvr/autopilot release
   page). Claude Code's auto mode blocks it ("code from external"): the user runs it.
2. `autopilot connect claude`, then a new Claude Code session (it blocks this as
   self-modification too: the user runs it).
3. In the editor's Autopilot tab: sign in to Aura and choose **Aura** as the decision model (no
   TypeSafe key needed), runs sharing **off**. Keep the project's memory (never empty it between
   hunts): the same prompts get better on it.

## 1. Before every run

- **One Autopilot session on the Mac at a time.** Take the Mac with
  `tools/autopilot.sh on <thread name>`: it writes the lock `build/autopilot.lock` and refuses
  while another owner holds it with a Godot running. `tools/autopilot.sh status` names the owner.
  Also check no other `godot` runs (a bench, shots, an export): if one does, report "Mac busy"
  and stop, don't start beside it. When you finish, `tools/autopilot.sh off`, close the editor,
  restore the run args, and tell the coordinator "the Mac is free".
- **Never overlap with exports or benches**: the exports refuse while the plugin is on.
- **Run on the latest main**: pull and restart the editor before the first run; an old checkout
  re-finds bugs that are already fixed.
- The plugin and its game-side autoload are **off in git** (`tools/autopilot.sh on|off`); opening
  the editor writes `[autopilot] project_id`: leave both out of commits.
- `[editor] run/main_run_args` always has `--nosave` (a run never touches the player's save).
  Add `--prebuilt` after it (the city builds in about 2 min instead of 5+) and the row's start
  flags after that; restore the line before committing.
- **Start at the row** (the rule since 2026-11-24; it replaces "the drive is the test"). Put the
  row's own start in the run args, so the first episode plays the claim within a minute:
  - `--ride=N`: ride N's request, the car by its passenger (also `--ride-story=ID`,
    `--ride-quirk=`, `--stars=`);
  - `--kebab=N`: kebab order N;
  - `--race=N`: rival race N (1 Seba, 2 Mordor Mike, 3 Pani Halina, 4 Słoik, 5 Zbyszek, 6 Bartek);
  - `--boat-race[=call]`, `--meet=` / `--meet-at=`, `--police=N`, `--heli`, `--garage`, the call
    flags (`--call-in`, `--ev-call`, ...): see `game/scripts/dev_flags.gd` and the archive's flags
    table;
  - `--at=X,Z --heading=H` for a place; `--no-traffic` to split traffic from the map;
    `--time=night` / `--clock=HH:MM`.

  `--ride`, `--kebab` and `--race` skip the title and the first-hour guide (`show_title` off, so
  `first10` never starts and "TAP TO DRIVE" never shows: wait for "km/h"). A row *about* the
  guide runs with no start flag (or `--first10`). Name every start flag and teleport in the report.
- Pick the next row of docs/TEST_BACKLOG.md, then docs/PLAYTEST.md "The test plan".
- **Cost:** the decision model bills to the user's Aura account. One row at a time; ask the user
  before more than three rows in one go or a run over 15 minutes.

## 2. The harness

**Start from the shared harness**, `tools/autopilot/road_harness.py` (its README): driving by
road on the lane graph (`game/scripts/playtest_route.gd` over `rc`), the stuck rule, back to the
road, the three-point turn, card buttons by label, and the trace events. A row adds only its plan,
its reads and its `row_status`. Never steer straight at the arrow (PT-60).

The trace, per event: **stops** (over 20 km/h to under 3 within 1 s, or under 5 for 3 s with the
gas held), **unsticks** (`car.gd`'s counter), **height jumps** (over 2 m frame to frame) and
**under the ground** (over 1 m below `map.drive_height`, never the raw terrain grid), each with
game time, Godot world x, z (what `--at=` takes), heading, speed, street and **the place on the
road** (lane, lane_edge, junction, kerb, off; side offset). That place decides who fixes it
(section 3). Also `back_to_road`, `back_on_road`, `turn_round`, `reverse_out`, `arrived`, `button`.

Rules that cost a run each to learn:
- **A verdict reads the game's state, never a stage name or which options ran**: a ride's
  `Result` stage is also the *cancelled* card; paid = stage Ride was seen, `wallet.zl` went up, no
  "cancel" in the card text. Keep each `Step`'s done on state too, so `restart=False` resumes it.
- **Buttons by label, never by index** (`want_labels`): `press_button_N` once pressed HELI and the
  car flew off. Skip on a call card is "next call", Later the decline.
- **Rings are small**: a stand or pickup ring is 7 m; `arrive_m = 4` stops inside it.
- **Escape**: hold it 0.3 s, release, wait 1 s (a one-frame press does nothing). Other keys: an
  injected event must set `physical_keycode` (main.gd `_unhandled_key_input`), and is tapped
  (press, release a frame later). The HELI button always works; during a job that rides in the
  car the helicopter is refused with a toast, by design.
- **Controls**: Classic (the default): A / D steer car-relative, W gas, S brakes and reverses.
- **Time**: the episode cap and the game clock stop while a pause card is up; end a settings row's
  episode by wall time (`Status("done")` after N real seconds), and wait on real time.
- **Traffic bumps are not bugs**: a stop with a traffic car touching, or a driver's shout
  (dialogue.gd `_shout`) within 2 s. `--no-traffic` settles it: a stop that comes back with no
  traffic is the map or the route.
- **Phone shape**: set the root window's content scale to 1266x585 (aspect keep) at the start and
  log `get_viewport().get_visible_rect()`; a row about a card runs at 16:9 too.
- **Flying**: cruise at about 50 m and come down only within 30 m of the target.
- **Story beats**: options from the guide's own state (`first10.gd` `fired`), not Jev's memory.
- **Keep the Mac awake** (a sleep ends the run).

**Episodes.** The agent service caps one `run_harness` episode at 360 s of play
(`MAX_EPISODE`, autopilot/agents/session.py) and then stops the harness child: that was the old
"-9 at about 6 minutes", not a crash. A row that needs longer is one run with more episodes, each
later one `run_harness(restart=False)` (the game plays on); ask `time_limit_minutes` in
`start_run`. A `restart=True` episode starts a fresh game and rebuilds the city. Release
v1.0.0-c84203c has no `keep_game_open` (only upstream HEAD does): one row is one run, and the
editor restarts after each `report`. With start flags a row should fit one or two episodes.

**Frames.** Run frame-describer on the frames of every off-lane stop and height event before
`report` (after `report` the `frames` tool refuses). Raise `frames_fps` around a spot the
building see-through patch hides (PT-45).

Don't change the project's files during a run; the game is acted on only through play.

## 3. After the run

1. **Take the PT id from the register first**: the next free number is the highest in
   `/mnt/project-files/autopilot/bug-log.md`, main's docs/PLAYTEST.md *and* every open PR that
   touches PLAYTEST.md. Write the id into bug-log.md at once, then the row.
2. Add each finding to docs/PLAYTEST.md "The bug log" as `PT-<n>`, status `suspect`, with the
   place, `--at=x,z`, heading, the side offset, what happens, the run id and the start flags.
   Frames worth keeping go to `shots/autopilot/<run>/` (gitignored), never into git. Mirror the
   short line into bug-log.md (newest analysis on top).
3. **Sort by who can tell, not by guessing the cause:**
   - *Harness-only* (closed in the report, no PT id): the car 10+ m off the road, a traffic bump,
     a key held or sent without `physical_keycode`, a wait frozen under the pause, a verdict read
     from the wrong state.
   - *Everything a player could do* (a stop in a lane, on the kerb, the pavement or the tram
     strip; a card that never shows; a script error): **send it to the coordinator straight
     away** with the PT id, `--at=`, heading, offset and speed. A cloud fix thread reproduces it
     headless (lane centre, kerb lane, `--no-traffic`) in minutes; no second Mac pass first. Never
     call a stop "the harness line" unless a kerb-lane line clears it too (PT-40).
4. Update the plan row's "Last run" and "Result", and tick the TEST_BACKLOG line.
5. Never fix in the playtest thread. Harness fixes go to `tools/autopilot/` in a small PR of
   their own; game fixes to their fix threads.
6. Fix threads: prove the cause, fix, add the spot to a check (`check_stuck_spots.gd` for car
   spots, `check_hud` for HUD), set `fixed (PR)`. The next run of that row sets `verified` or
   reopens it (TEST_BACKLOG "Fixes waiting for proof").

**Report each row as**: pass / fail; the start flags; the timings (e.g. accept to START, START to
the drop); events with x, z, street, place, side_m; one frame line for each stop worth a fix
thread; harness faults; the run folder.

## 4. Scheduling hunts

- **Autopilot never gates a merge** (F, 2026-11-08): a PR merges on its green CI and the usual
  go; Autopilot plays it from main in the next hunt.
- Hunts run in a Remote Control session on the Mac, which starts only from F's own message. A
  hunt starts on F's "start" or after a merge train, not on a timer; re-run an area's rows when
  its geometry changes.
- The coordinator keeps the Mac queue and hands the Mac on when the last thread says it is free.

## 5. Row recipes (what worked 2026-11-23/24)

Each starts from `road_harness.py`, with frame-describer on every off-lane stop.

- **Settings tabs**: hold Escape, `game.ui()` for `tab_*`, click `pads_*` / `text_large_*` /
  `lang_*` and `close`; check fit with `hud.settings_panel.card_rect()`, `card_scale()` and
  `button_rects()` (the card scales, so raw control sizes read as off screen); close and reopen
  keeps the last tab. End by wall time.
- **Loader**: `restart=True` so the setup loop watches the percent text ("building the city… N %"
  / "budujemy miasto… N %": match `%`), then Space at the prompt. With `--prebuilt` the editor
  still holds the bar at 17-19 % for about 160 s: record it.
- **Guide** (no start flag): read `first10.t`, `fired`, `how`, `_beta_up`, `_choice_up` every 4 s;
  the clock stops in the settings pause; any key in the first 4 s makes the finger "met".
- **Calls**: `missions.held = False` (a research change, say so), `ring_in(2)`, tap the rescue
  pill, Accept / Skip / Later; the next ring can take 45-60 s (pacing, not a bug).
- **Podwózka ride**: `--ride=N`. Tap START THE RIDE by label, drive to the drop, verdict paid
  (above). Log pickup to START and START to the drop. The passenger cancels after about 250 s
  of waiting. The ride *offer* in a real session comes only after the guide's first kebab and its
  card expires: that is a separate guide row, not this one. Known spots (watch, not PT): Plac
  Grzybowski (-1360..-1440, -165..-325) and Zielna (-1220..-1255, -320..-396), off the lane with
  and without traffic; a headless drive keeps the lane there.
- **Kebab**: `--kebab=N`, `arrive_m = 4`, done = the order delivered (`jobs_done` up).
- **Race (Pani Halina)**: `--race=3`, `cruise_kmh = 95` wins (70 loses by about 40 s); done when
  `rivals.state` is Result and the panel reads 1ST.

## Gotchas

- Enabling the plugin by editing project.godot by hand skips its `_enable_plugin()`, so the
  autoload is missing: use `tools/autopilot.sh on`.
- Godot headless (Autopilot's own CI path) never captures the mouse and has no renderer: use the
  editor path.
- Coordinates: Autopilot's kit frame is centimetres, `kit = 100 * (-z, x, y)`; convert with
  `game.to_native` before writing `--at=` (Godot x, z in metres).
- A fresh save runs the first-10-minutes guide, which keeps friends from walking up for those 10
  minutes: a quest's in-person start needs its own flag or a save past the guide.
- The Autopilot add-on itself logs key-hold races (`playtest.gd:1023/1024/1027`) now and then:
  the add-on, not the game.
