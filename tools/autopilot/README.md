# The Autopilot hunts' shared harness

One harness file the hunts start from, so no run writes (and re-breaks) driving, the stuck rule
and the trace events again. The skill is `.claude/skills/autopilot-playtest/SKILL.md`; this is
the code it points at.

| File | What |
| --- | --- |
| `road_harness.py` | `RoadHarness`: drives by road to the arrow (or the row's own point), the stuck rule, the trace events (stops, unsticks, height jumps, under the ground, each with the place on the road), card buttons and waits. Runs only inside Autopilot's agent service (`from autopilot.kit import *`). |
| `game/scripts/playtest_route.gd` | The game side: static `get_goal`, `get_drive_state`, `clear_route`, called over the add-on's `rc`. Reads only. Checked headless by `game/tools/check_playtest_route.gd` (verify step `playtestroute`). |

## A row's harness

Copy `road_harness.py` into the run's `harness.py` and add the row at the bottom:

```python
class KebabRow(RoadHarness):
    goal = "Take the kebab order from the first stand and deliver it to the door"

    def extra_obs(self, game):
        # the row's own reads: find the node and its fields with game.describe("/root/Main")
        return {"job_on": bool(game.ret("/root/Main/...", "busy"))}

    def setup(self, game):
        super().setup(game)
        self.plan = [
            Step("to_stand", "Drive to the stand the arrow shows", lambda o: o["job_on"],
                 options=["drive_to_goal", "press_button_1", "wait_here", "reverse_out"]),
            Step("deliver", "Drive the order to the door", lambda o: ...,
                 options=["drive_to_goal", "press_button_1", "reverse_out"]),
        ]
```

A row sets `want_labels` (e.g. `("START", "ACCEPT", "AKCEPTUJ")`) for the buttons it means to
press: they are offered first, by label, never by their place in the list. The generic
`press_button_N` never offers HELI, the menus or the maps (2026-11-23: it pressed HELI and the car
flew off). `arrive_m` (default 10) is how close counts as there: 4 for a stand's 7 m ring.

Rows learned so far (2026-11-23):
- The Łuber app shows only after the guide's first kebab order: a ride row starts with the
  kebab (or from a save past it), never waits for the app.
- A goal under 40 m straight whose way by road is over three times longer (a stand on the far
  carriageway) is driven to straight (`pull_in` in the state), as a player pulls in.
- Pani Halina's race is not won at 70 km/h with stops (about 80 s against her 55 s on 1.5 km):
  a race row sets `cruise_kmh = 95` (third run: won by 22.7 s).
- Off every lane for 4 s with the goal over 40 m away (after a pickup inside Plac Grzybowski), the
  harness drives back along its own trail to the last lane it was on (`back_to_road`,
  `back_on_road` in the trace), then follows the route. A goal nearer than 40 m is off the road on
  purpose (a stand, a passenger) and is driven to as before.
- An aim more than 110° off the nose at a crawl (the route turns round, fifth run after the pickup
  on Próżna) is a three-point turn: back up with the wheels the other way, then on (`turn_round`), only
  after 3 s of it and once per 20 s (sixth run: 36 turns in 700 s, the car shuttled).

Autopilot takes the last `Harness` subclass in the file. Keep the plan's `done` on the game's
state, never on which options ran, so `run_harness(restart=False)` resumes it after the 360 s
episode cap.

## What it drives by

`get_drive_state` gives, every tick, the car (`x`, `z`, `y`, `heading_deg`, `speed_kmh`,
`unsticks`), where it is on the road (`street`, `place`: lane, lane_edge, junction, kerb, off;
`side_m`, `lane_gap_m`), the goal (`goal_source`: target, main_target, main_line or own: the row's point) and
the way by road (`left_m`, `aim_x`, `aim_z`, `bearing_deg` + right, `bend_deg`, `want_kmh`). The
route is the one the minimap draws (`route_line.gd`), walked again from the car on every call, so
a wrong turn is driven round, not fought. The aim sits on the lane nearest the route's line
(`kerb = True`: the kerb lane, for the second pass a kerb-side stop needs).

Its limits: it steers with the A / D keys and a 6° deadband (no analog steering on the keyboard),
it does not read traffic (a stop with a traffic car touching is the player hitting it: check the
frame, or run with `--no-traffic` for map-only bugs), and it has no plan for the helicopter.
