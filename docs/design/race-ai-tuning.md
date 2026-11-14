# Race AI: the tuning guide

The short companion to [race-ai.md](race-ai.md). That document says why the racer AI is built the
way it is and what every step measured; this one says **which number to turn, where it lives, how
to test the change and what bites**. Keep it current: a step that adds a knob adds its row here.

Read first: the one rule (section 1), then the part you want to change.

## 1. The one rule

**A rival's speed never depends on the player's speed or position.** A rival is hard because of
how that rival drives. The root cause of "Halina drives like the mob" (F, 2026-11-09) was a
rubber band: she took 74 s alone and 180 s beside a player who never moved. The bench's
**Independence** mark holds the rule; a change that ties pace to the player fails it.

The only thing left of "keeping it close" is **effort** (`race_session.gd` `effort_of`): 0.9 to 1.04
of the rival's own pace, by the time gap, moving 0.05 a second at most. Do not widen it to fix
difficulty. Change the skill profile.

Also decided by F: the first race is a real race the player can lose; rivals queue honestly in
traffic (step 4b), so they are slower there; a difficulty option, when it comes, changes the
profiles and never makes a rival wait.

## 2. The parts, in the order a race uses them

| Part | Script | What it decides | Section of race-ai.md |
| --- | --- | --- | --- |
| Profiles | `game/scripts/ladder.gd` | every rival's numbers; the easier rematch; Halina's gentle day | 6, 6.1 |
| Shortcuts, yards, hops | `game/scripts/race_cuts.gd`, `game/data/race_links.json`, `tools/race_links.py` | which ways off the streets exist and which a rival knows | 5.4, 5.5 |
| Route | `game/scripts/race_planner.gd` | the streets, by the rival's own seconds to the finish, traffic counted | 5.1 |
| Line and speed | `game/scripts/race_line.gd` | the racing line and a speed for every metre | 5.2 |
| Driver | `game/scripts/traffic.gd` (the Driver's part for racers) | following, passing, lane changes, blocked streets, recovery, delay out of sight | 5.1, 5.3 |
| Session | `game/scripts/race_session.gd` | one race's mechanics for every race mode: course, racers, plans, start, legs, effort, order, reroutes, lights, end | 6.2 |
| Race | `game/scripts/rivals.gd` | the challenge, the words, the cards, the pay, the ghost, the player's checkpoints, the rival's car (the mechanics are the session's) | 4, 6 |
| Pack race | `game/scripts/street_meet.gd`, `ladder.gd` `CLUB` | the night club's race: who comes onto the road when, and the eight club profiles | 6.2 |
| Police chase | `game/scripts/police/chase_route.gd`, `ladder.gd` `POLICE` | the chasers' way to the player (replan, goal, the chase's session) and their numbers; the top is `police.chase_top()` | 6.3 |
| Lights | `game/scripts/race_signals.gd` | what the car shows; changes no driving | 6.1 |
| Result card | `game/scripts/race_report.gd`, `hud.gd` `set_card_art` | both routes and what decided the race | 6.1 |
| Bench | `game/tools/race_bench.gd`, `check_race_bench.gd`, `tools/race_bench.sh`, `game/data/race_bench.json` | the marks every change is held against | 7 |

## 3. The knobs

### 3.1 A rival's profile (`ladder.gd` `RUNGS`, `FIRST_RACER`, `FINAL_RACER`, `DEFAULT_RACER`)

This is where difficulty and character are tuned. One row per rival; every key must be in
**every** profile (a `Ladder.racer()` copy carries only `DEFAULT_RACER`'s keys).

| Key | Meaning | Range in use | Turn it when |
| --- | --- | --- | --- |
| `share` | share of a road's racing speed held on the straights | 0.65 to 1.0 (floor 0.58) | a rival is too slow or fast everywhere. Under 0.58 it crawls and the bench fails No crawl |
| `race_accel` | pull out of a corner, m/s² | 7 to 13.5 (the car: 15) | it is slow away from junctions |
| `brake` | braking, m/s² | 4 to 13 (the car: 30) | it brakes too early or too late |
| `lat` | sideways grip used in a corner, m/s² | 9.5 to 16.5 (the car: 19) | it is slow or wild in corners. Real grip since step 4a |
| `knows` | share of the town's traffic its plan counts | 0 to 1 | it should (not) avoid queues. Słoik 0: plans as if roads were empty |
| `caution` | how much more it counts a street with no way past | 0 to 0.8 | it dives into one-lane streets too readily |
| `cuts`, `yards` | share of shortcuts and yards it knows away from home | 0 to 1 | it should find more or fewer ways through |
| `narrow` | the narrowest way it takes, m | 2.8 to 4.5 | a van should not fit an alley |
| `hops` | takes a one-block wrong-way hop when the street is empty | 0 or 1 (Seba, Mike) | F's decision; not for other rivals without asking |
| `home` | districts (ids of `data/districts.json`) where it knows every cut and yard | list | a rival should own a neighbourhood |
| `mistake` | chance of running wide out of a corner | 0.03 to 0.2 | it is too clean or too clumsy |
| `wrong` | wrong turns a race | 0 or 1 (Słoik) | the satnav joke |
| `block` | chance of moving across the player's line when chased | 0 to 0.9 | it should defend more or less; never ram |
| `phone` | a one-second brake for a call | Mike | |
| `dare` | nerve in a pass over the centre line: spare metres × `dare`; over 1 the oncoming car's metres count that many times | 0.5 to 2.5 | it passes too boldly or too timidly. Under 1 only trims the spare metres |
| `indicate` | seconds before a turn its indicator comes on; 0 never | 0 to 3 | character only |
| `flash` | seconds behind a slower car before it flashes; 0 never | 0 to 3 | character only |

Also here: `EASE_STEP` 0.05 and `EASE_MAX` 0.15 (a rival is 5 % slower for each race lost to it
in a row, 15 % at most; between races, never during one), and Halina's gentle day
(`FIRST_RACER`, until she is beaten once).

**To make the whole ladder easier or harder**, move `share` and `lat` together and keep the
order of the times; check the Skill ladder and Ladder curve marks (each rung 3 to 12 % quicker
than the one below).

**The club's pack has its own table, `ladder.gd` `CLUB`** (eight profiles: six ring cars, Darek,
Lena), with the same keys as `RUNGS`; `CLUB_PACE` is the pace the pack is held to. To make the
club easier or harder, move `share` and `lat` together here too and keep the order of the eight
(ring 0 the slowest, Lena the quickest: 161.6 s to 140.6 s alone on the club course). No club car
may be over the player's car (Honest car). The Pack order mark holds the order: on clear roads
the club comes home in the order of its racers' own pace, neighbours less than 1.5 % apart may
swap. Race-ai.md 6.2 has the table.

**The police chasers have `ladder.gd` `POLICE`** (one profile, the same keys). To make a chase
harder or easier move `lat`, `race_accel` and `brake` (12, 7 and 6 now), a little at a time, and
never the top: the top is `police.chase_top()`, 0.8 of the player's car, held by `v_cap`. A
chaser through corners faster than that makes the fast player's escape slower and the bench's
**Chase balance** mark is the guard (the average player's gap at 20 and 30 s within 12 m of the
old driver's, the fast player's escape within 15 %). The first try, 10 / 9 / 12.5, was too much on
the Powiśle course. **Chase keeps off** must stay a pass: no chaser overlaps the player's car or
is in front of it. Race-ai.md 6.3 has the table.

### 3.2 Effort and the race (`race_session.gd`)

| Constant | Value | Meaning |
| --- | --- | --- |
| `EFFORT_EASE`, `EFFORT_PUSH` | 0.9, 1.04 | the pace when far ahead and far behind |
| `EASE_FROM`, `EASE_FULL` | 3, 10 s ahead | where managing a lead starts and is full |
| `PUSH_FROM`, `PUSH_FULL` | 1, 5 s behind | where pushing starts and is full |
| `EFFORT_RATE` | 0.05 a second | how fast effort moves |
| `PUSH_MISTAKES` | 1.5 | mistakes while pushing |
| `FINISH_RADIUS` | 16 m | the finish circle, the same line for both cars |
| `FIRST_*` | | the guided first race only: its start, waits and stalls |

### 3.3 The driver (`traffic.gd`, constants for racers)

| Group | Constants | Meaning |
| --- | --- | --- |
| Speed | `RACE_CLASS_TOP` [33, 29, 25, 16] m/s | a road's racing speed by class; everybody's `share` is of this |
| Following | `RACE_HEADWAY` 0.6 s, `RACE_DECEL` 8, `RACE_LOOK` 30 m | how close it follows and how far it looks |
| Lights | `RACE_RED_SLOW` 0.75, `RACE_RED_LOOK` 30 m | a racer slows for a red, it does not stop |
| Pass over the centre line | `PASS_MARGIN` 10 m, `PASS_KEEP` 4 m (both × `dare`), `PASS_MOST` 7 s, `PASS_WAIT` 1.5 s, `RACE_PASS_BACK` 0.7 s, `PASS_QUEUE`, `PASS_END` | when a pass starts, is kept and is given up |
| Lane | `RACE_LANE_HOLD` 2 s | a lane is held after a change |
| Blocked street | `BOX_WAIT` 3 s, `BOX_WAIT_PASS` 8 s | how long it waits behind the player's stopped car before it turns back or goes round |
| Wrong turn | `WRONG_CHANCE` 0.2, `WRONG_SURE` 0.5, `WRONG_FAR` 300 m, `WRONG_DAZE` 0.9 s, `WRONG_SHOW` 2.4 s | where one may happen, the lift and the hazards after |
| Hop | `HOP_DECIDE` 12 m, `HOP_STOP` 6 m | where it looks before a wrong-way hop |
| Out of sight | `RACE_STUCK` [0.77, 0.44, 0.46], `RACE_STUCK_END` 0.7, `RACE_STUCK_LIGHTS` 7.4, `AWAY_ROOM`, `AWAY_TAU`, `AWAY_EASE` | the delay a racer pays for the town's traffic where no town cars exist. **Fitted, not hand-set**: `tools/race_traffic.sh` |
| Pack rules | `_race_cross_look`, `_merge_gap` | between racers that have plans only: in the look across a junction a racer behind (still on the street it leaves, or less far along the same curve) is not in the way and one ahead on a shortcut's curve is; two racers level in two lanes into one shortcut: the one behind follows the other in. Without them the pack drives through itself at the first shortcut |
| Held up (lights only) | `HELD_GAP` 14 m, `HELD_SLOWER` 3 m/s | when "behind a slower car" counts for the headlight flash |
| Limits | `RACE_GRIP_MOST` 19 | never over the player's car |
| Police chasers | `_chase_end_speed`, `_on_carriageway` | a chaser's line ends at the slowest way on from its goal junction at its grip (the player's next turn is not known); its look at the player is 4 m wide as before, or anywhere on its own carriageway when it is on its line (a line may pick another lane than the player's). It still keeps `CHASE_GAP` behind and never passes or rams |

### 3.4 The route (`race_planner.gd`)

`SWITCH_GAIN` 3 s (a new plan must be this much better to switch), `RED_SHARE` 0.5 (the share of
a light's red a plan counts), `WRONG_LEAST` 4 s and `WRONG_MOST` 15 s (what a wrong turn may
cost), `END_*` (the finish circle). The traffic delay it plans with is `traffic.gd`
`race_delay` (`RACE_STUCK*` above), scaled by the rival's `knows`.

### 3.5 The line (`race_line.gd`)

`SPEED_LEAST` 6 m/s (slowest corner), `TURN_RADIUS` 5 m, `HAIRPIN` 2.4 rad, `UTURN_SPEED` 3.5,
`CUT_TOP` 16 m/s (top speed in a shortcut or yard), `SIDE_MAX` 1 m (how far off the lane's
centre the line goes). A corner's speed is `sqrt(lat × radius)` on the racer's own line.

### 3.6 Shortcuts, yards, hops

Not tuned by hand. `python3 -I tools/race_links.py` finds them from the map,
`tools/race_links.sh` proves each with the player's own car (about a minute a link; needs
`game/map/terrain.json`, or the yard list changes), and a rival is handed only a proven link.
After a map change run both and `check_race_links`, `check_race_cuts`.

### 3.7 Lights and the card

`race_signals.gd`: `BRAKE_FROM` −2 m/s², `TURN_MIN` 0.45 rad, `TURN_LEAST` 10 m, `BLINK` 0.7 s,
`FLASH_AGAIN` 3.5 s, `WOBBLE_*`, the colours, and how big they read: `LAMP_SCALE` 1.3, the glow on the
road `BRAKE_POOL` 1.5 m, `INDICATOR_POOL` 1.1 m, `FLASH_POOL` 1.6 m, `POOL_ALPHA` 0.75. `race_report.gd`: `NAMED` 1 s (a cause must be
worth this to be named), `WALK` 1 m/s (under it a car stands). `rivals.gd` `REPORT_ART` (the
picture's size on the card) and `REPORT_LINES` (off since F, 2026-11-13: the card shows the
picture only, the report's lines go to the log).

## 4. How to test a change

1. **The fast checks** (seconds; all in CI's quick group):
   `tools/verify.sh --only=ladder,raceline,raceplanner,racecuts,racesignals,racereport,first10,racebench,meet,police`
2. **The quick bench** (41 races, under a minute): `tools/race_bench.sh --quick`.
3. **The full bench before and after** (416 races, about 26 minutes with `--jobs=3`):
   run it on main first (`--out=before`), then on the change with
   `--against=build/race_bench/before.json`. Report the marks and which races' times moved.
   One race: `tools/race_bench.sh --only=TEXT --trace`.
4. **Record the marks** only on purpose: `tools/race_bench.sh --write`. A mark that counts races
   in traffic is recorded `once:Linux` (or `once:macOS`) and becomes a pass only after the other
   machine's `--write`.
5. **After a change to how a racer meets the town's cars** (a new pass or lane rule):
   `tools/race_traffic.sh`, and move `RACE_STUCK*` when the fit has.
6. **The whole game** (not in CI, 5 to 7 minutes each, not repeatable run to run):
   `tools/verify.sh --only=race,first10-run,trzy-mosty`. Run `first10-run` after anything that
   touches the first race. All six rivals against the autopilot: `tools/race_ai.sh`.
7. **The frame bench before and after** for any change in `traffic.gd` or `rivals.gd` (CLAUDE.md
   "Performance is a gate"): traffic ms and draw calls must stay near main.
8. **Look**: `--race=N --autopilot` with `--shots=`, `--race-debug` (prints what holds a standing
   racer), `--rival=N`. The rival is rarely in view in a cloud run; the Mac is the place to look.

The marks, in one line each (full text in race-ai.md 7.3): Finishes, Independence (the one
rule), No crawl, Passes traffic, No ghosting, Re-routes, Recovers, Honest car (never over the
player's car), Route sense, Skill ladder, Ladder curve, Told apart, Yard links, Wrong-way hops
(and in traffic), Pack order, Pack in traffic, Chase keeps off, Chase balance, Same race twice. The state of each is in race-ai.md 7.4.

## 5. Traps

- **One machine's traffic is one draw.** The Mac and the cloud round differently, so every race
  in traffic comes out differently on each. A worst-case mark can pass on one and fail on the
  other. Never record a traffic mark as a pass from one run; judge over the bench's three draws.
- **One whole-game race proves nothing under about 7 s** (the same code gave 102 to 121 s).
- **Clear-road times are the truth.** They are the same on every machine to 0.4 s. Tune a
  profile on clear roads; read traffic over many races.
- **A daring rival gets no discount on physics.** `dare` under 1 trims only the spare metres of
  a pass; a pass that cannot be made is never taken. The same goes for grip: `lat` over 19 fails
  Honest car.
- **A refused way must be dropped for the whole plan** (the plan's `no_hop` and `shut` sets), and the
  metres (`RaceCuts.links`) rebuilt with the same sets, or the rival ping-pongs back to it and
  never finishes.
- **Do not edit game files while a bench runs**: it reads the working tree.
- **Deliberate-break runs rewrite source files**: run nothing else at the same time.
- **The crazy drivers** do not use the plan, the links, the lights or the report yet (step
  6b-3). The pack race, Trzy mosty and the police chasers do (the pack and the chasers have no
  report, the chasers no lights and no shortcuts). The police's search, escort, blockers and
  roadblocks still drive the old way, with no plan.
- **`race_to` resets the car's way.** A chaser is therefore sent again only when its goal junction
  changes (`RaceSession.retarget`); sent every replan, it twitches between lanes once a second.
  A fresh plan is searched in slices, one chaser a frame, and the car goes by the metres until the
  plan knows its street (`_choose_way`), so a chaser's first seconds are not on the line.
- **A pool car out of sight is driven every other frame.** A probe that reads a speed change
  must divide by the time since the car was last driven, not by the frame's time, or it reads a
  pull twice as big as it is (the bench's Probe does).
- **Eight racers into one shortcut need the merge rule** (`_merge_gap`) and the crossing look
  (`_race_cross_look`); a new shortcut rule that skips them brings the pack's driving through
  each other back (Pack order and No ghosting show it).
- **The out-of-sight delay is too large on wide streets.** `AWAY_*` was fitted on narrower
  streets; in Busy traffic a club racer far from the player pays up to 170 s of it on
  the 2.9 km club course, about twice its clear-road time (Pack in traffic holds that all get
  home; BACKLOG).
- **A new key in a profile** goes into every profile and into `check_first10.gd`'s toy racer when
  the driver reads it.
- **A new bench situation** (`SITUATIONS` in `race_bench.gd`) is picked up by other loops of the
  matrix in `check_race_bench.gd` unless skipped there.

## 6. Where a new thing goes

| You want | Put it in |
| --- | --- |
| a new rival, or a rival easier or harder | a row in `ladder.gd` `RUNGS` and `rivals.gd` `RIVALS` |
| a difficulty option | a scale over the profiles in `ladder.gd` (as `eased` does), never in the driver; tech-debt TD-12 |
| a new habit you can see | a trait in `ladder.gd`, read in `race_signals.gd` |
| a new way through the town | `tools/race_links.py`, proven by `tools/race_links.sh` |
| a new race mode | a `RaceSession` (`race_session.gd`: `course`, `add`, `start`, `advance`, `rank`), and the words, cards and pay in the mode's own script |
| a new line on the result card | `race_report.gd` `lines` |
| a new rule the racers must keep | a mark in `race_bench.gd`, its row in race-ai.md 7.3 |
