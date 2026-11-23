"""The shared Autopilot harness that drives Around Warsaw by road (2026-11-23).

Usage: a hunt on the Mac copies this file into the run's harness.py (Autopilot's run folder) and
subclasses `RoadHarness` for its row: set `goal`, `plan` (Steps read from the game's own state)
and, if needed, `extra_obs()` and `row_options()`. Read tools/autopilot/README.md first. It runs
only inside Autopilot's agent service (`from autopilot.kit import *`), never on its own.

What it gives every row, so no run writes (and breaks) these again:
- driving by the lane graph to the arrow, or to a point of the row's own: one rc call a tick to
  game/scripts/playtest_route.gd `get_drive_state` (the route the minimap draws, an aim on a lane a
  second ahead, the speed for the next bend). Never straight at the arrow through a block (PT-60);
- the stuck rule (under 1.2 m/s for 2 s with the gas held; at 10 s reverse out and go on);
- the trace events the skill asks for (stops, unsticks, height jumps, under the ground), each with
  the world x, z, heading, speeds, street and the place on the road (`place`, `side_m`,
  `lane_gap_m`), which decides who fixes a stop;
- card buttons pressed through the UI as a player taps them, keys tapped (press, release a frame
  later), waits on Autopilot's Clock (it counts real time while the pause card is up).
"""

from autopilot.kit import *  # noqa: F401,F403 - the kit: Harness, Option, Step, Status, Result, Clock, wait

ROUTE = "res://scripts/playtest_route.gd"

# Steering: Classic controls (the default; editor runs pass --nosave): A / D steer car-relative,
# W is the gas, S brakes and reverses from a standstill.
STEER_DEADBAND = 6.0  # degrees either side of the aim with no steering key held
BRAKE_OVER_KMH = 8.0  # brake (S) only this far over the wanted speed, and only while moving forward
ARRIVE_M = 10.0  # the goal counts as reached this close (straight line); a row sets `arrive_m`

# Buttons never pressed by the generic option: they leave the row (the helicopter, menus, maps).
# Hunt 2026-11-23: press_button_N pressed HELI and the car flew off. A row presses what it means by
# its label with `press_label`.
SKIP_BUTTONS = ("HELI", "MENU", "MAPA", "MAP", "USTAWIENIA", "SETTINGS", "PAUZA", "PAUSE", "✕", "X")

# The stuck rule of the skill (section 2).
STUCK_MPS = 1.2
STUCK_AFTER_S = 2.0
STUCK_REVERSE_AFTER_S = 10.0
REVERSE_S = 1.6

# The stop rule of the skill: from over 20 km/h to under 3 within 1 s, or under 5 for 3 s with the gas held.
STOP_FROM_KMH = 20.0
STOP_TO_KMH = 3.0
CRAWL_KMH = 5.0
CRAWL_S = 3.0
HEIGHT_JUMP_M = 2.0
UNDER_GROUND_M = 1.0


class RoadHarness(Harness):
    goal = "Drive by road to the arrow on the screen"
    tempo = 1.0
    tick_hz = 15.0
    trace_every = 0.5
    stall_seconds = 90.0
    step_seconds = 240.0

    # The row may change these.
    kerb = False  # drive the kerb-side lane (a second pass: PT-40, a stop only on the kerb lane)
    cruise_kmh = 50.0
    target = None  # (x, z) Godot metres of the row's own goal; None: the arrow's (get_goal)
    arrive_m = ARRIVE_M  # a stand's ring is 7 m: 4 m stops inside it (hunt 2026-11-23)
    # Labels (any case, a part is enough) the row wants pressed when they show, in order of
    # preference, e.g. ("START", "AKCEPTUJ", "ACCEPT"): offered as `press_wanted` (urgent).
    want_labels = ()

    # --- the row's hooks -------------------------------------------------------------------------

    def extra_obs(self, game) -> dict:
        """The row's own reads (a job's state, a race's place). Keys starting with "_" stay hidden from Jev."""
        return {}

    def row_options(self, obs) -> list:
        """The row's own options beside driving, pressing card buttons and waiting."""
        return []

    def row_status(self, obs) -> Status:
        """The row's done / failed, read from the game's own state."""
        return Status()

    # --- setup and observing ---------------------------------------------------------------------

    def setup(self, game):
        game.release_all()
        self._held = set()
        self._last = None
        self._fast_t = None  # game time the car was last over STOP_FROM_KMH
        self._crawl_since = None
        self._stuck_since = None
        self._gas = False
        self._ui_t = -999.0
        self._buttons = []
        game.ret(ROUTE, "clear_route")
        game.log("harness", t=game.t, controls="classic", kerb=self.kerb, cruise_kmh=self.cruise_kmh,
                 target=self.target)

    def observe(self, game):
        args = {"kerb": self.kerb, "cruise_kmh": self.cruise_kmh}
        if self.target is not None:
            args["x"], args["z"] = self.target
        st = game.ret(ROUTE, "get_drive_state", **args) or {}
        if game.t - self._ui_t > 1.0:  # the card buttons once a second: a ui() listing costs a frame
            self._ui_t = game.t
            self._buttons = [e for e in (game.ui() or []) if e.get("kind") == "button" and e.get("enabled", True)
                             and (e.get("label") or "").strip()]
        self._events(game, st)
        obs = {
            "_st": st,
            "_buttons": self._buttons,
            "speed_kmh": st.get("speed_kmh"),
            "street": st.get("street"),
            "place_on_road": st.get("place"),
            "goal": st.get("goal_source") or "none",
            "goal_by_road_m": st.get("left_m"),
            "goal_straight_m": st.get("goal_m"),
            "stuck": self.stuck_for(game) >= STUCK_AFTER_S,
            "buttons": [b.get("label") for b in self._buttons][:6],
            "flying": st.get("flying"),
        }
        obs.update(self.extra_obs(game))
        return obs

    def _events(self, game, st):
        """The skill's trace events, written the moment they happen with what decides who fixes them."""
        if "x" not in st:
            return
        t = game.t
        v = float(st.get("speed_kmh") or 0.0)
        where_on_road = {k: st.get(k) for k in ("x", "z", "y", "heading_deg", "street", "place", "side_m",
                                                "lane_gap_m")}
        last = self._last
        if v > STOP_FROM_KMH:
            self._fast_t = t
        elif v < STOP_TO_KMH and self._fast_t is not None and t - self._fast_t <= 1.0:
            game.log("stop", t=t, kind_="hard", speed_before=STOP_FROM_KMH, speed_after=v, **where_on_road)
            self._fast_t = None
        if self._gas and v < CRAWL_KMH:
            self._crawl_since = self._crawl_since if self._crawl_since is not None else t
            if t - self._crawl_since >= CRAWL_S:
                game.log("stop", t=t, kind_="crawl", speed_after=v, gas=True, **where_on_road)
                self._crawl_since = t + 999.0  # once per crawl
        else:
            self._crawl_since = None
        if self._gas and v / 3.6 < STUCK_MPS:
            self._stuck_since = self._stuck_since if self._stuck_since is not None else t
        else:
            self._stuck_since = None
        if last is not None and "x" in last:
            if int(st.get("unsticks", -1)) > int(last.get("unsticks", -1)) >= 0:
                game.log("unstick", t=t, count=st.get("unsticks"), **where_on_road)
            if abs(float(st.get("y", 0.0)) - float(last.get("y", 0.0))) > HEIGHT_JUMP_M:
                game.log("height_jump", t=t, y_before=last.get("y"), **where_on_road)
        if float(st.get("below_ground_m") or 0.0) > UNDER_GROUND_M and not st.get("flying"):
            game.log("under_ground", t=t, below_m=st.get("below_ground_m"), **where_on_road)
        self._last = st

    def stuck_for(self, game):
        return 0.0 if self._stuck_since is None else game.t - self._stuck_since

    # --- options ---------------------------------------------------------------------------------

    def options(self, obs):
        st = obs["_st"]
        opts = []
        if st.get("goal_source") and not st.get("flying"):
            opts.append(Option(
                "drive_to_goal", "Drive by road to the goal (the arrow), keeping to a lane and slowing for bends",
                self.drive, facts={"by_road_m": st.get("left_m"), "straight_m": st.get("goal_m"),
                                   "street": st.get("street")},
                effect=lambda a, b: (b["_st"].get("left_m") or 1e9) < (a["_st"].get("left_m") or 1e9) - 5.0,
                max_seconds=240.0))
        if obs["stuck"]:
            opts.append(Option("reverse_out", "Back out of what the car is pinned against, then drive on",
                               self.reverse_out, urgent=True, interruptible=False, max_seconds=6.0))
        wanted = self.wanted_button(obs["_buttons"])
        if wanted is not None:
            opts.append(Option("press_wanted", f"Tap '{wanted.get('label')}', the button this row is after",
                               self._press_button(wanted), facts={"label": wanted.get("label")}, urgent=True,
                               max_seconds=5.0))
        free = [b for b in obs["_buttons"] if not self._skipped(b)]
        for i, b in enumerate(free[:3]):
            opts.append(Option(f"press_button_{i + 1}", f"Tap the on-screen button '{b.get('label')}'",
                               self._press_button(b), facts={"label": b.get("label")}, max_seconds=5.0))
        opts.append(Option("wait_here", "Stop and wait a few seconds (a card's timer, a pickup)",
                           self.wait_here, max_seconds=12.0))
        return opts + self.row_options(obs)

    def status(self, obs):
        return self.row_status(obs)

    @staticmethod
    def _skipped(button):
        label = (button.get("label") or "").strip().upper()
        return any(label == k or label.startswith(k + " ") for k in SKIP_BUTTONS)

    def wanted_button(self, buttons):
        """The first shown button whose label holds one of `want_labels` (in their order), or None."""
        for want in self.want_labels:
            for b in buttons:
                if want.upper() in (b.get("label") or "").upper():
                    return b
        return None

    # --- executors -------------------------------------------------------------------------------

    def drive(self, game, obs):
        """Follow the route a tick at a time until the goal is within ARRIVE_M and the car has stopped."""
        while True:
            st = self._last or {}
            if not st.get("goal_source"):
                self._let_go(game)
                return Result(False, "no goal")
            if self.stuck_for(game) >= STUCK_REVERSE_AFTER_S:
                self._let_go(game)
                r = yield from self.reverse_out(game, obs)
                if not r:
                    return r
                continue
            arrived = float(st.get("goal_m") or 1e9) < self.arrive_m
            want = 0.0 if arrived else float(st.get("want_kmh") or self.cruise_kmh)
            self._steer(game, float(st.get("bearing_deg") or 0.0))
            self._pedals(game, float(st.get("speed_kmh") or 0.0), want)
            if arrived and float(st.get("speed_kmh") or 0.0) < STOP_TO_KMH:
                self._let_go(game)
                game.log("arrived", t=game.t, x=st.get("x"), z=st.get("z"), goal=st.get("goal_source"))
                return Result(True, "at the goal")
            yield

    def reverse_out(self, game, obs):
        """S held (reverse from a standstill) with the steering the other way, then let go."""
        st = self._last or {}
        b = float(st.get("bearing_deg") or 0.0)
        game.log("reverse_out", t=game.t, x=st.get("x"), z=st.get("z"), street=st.get("street"),
                 place=st.get("place"), stuck_s=round(self.stuck_for(game), 1))
        self._let_go(game)
        self._hold(game, "S")
        self._hold(game, "D" if b < 0 else "A")  # reversing: the tail swings away from the aim's side
        yield from wait(game, REVERSE_S)
        self._let_go(game)
        self._stuck_since = None
        return Result(True, "backed out")

    def wait_here(self, game, obs):
        self._let_go(game)
        yield from wait(game, 4.0)
        return Result(True, "waited")

    def _press_button(self, button):
        def run(game, obs):
            self._let_go(game)
            game.ui_act(id=button["id"], action="click")
            game.log("button", t=game.t, label=button.get("label"))
            yield from wait(game, 0.5)
            return Result(True, "pressed")
        return run

    # --- keys --------------------------------------------------------------------------------------

    def tap(self, game, key):
        """A tap: press, release a frame later (a held Escape does nothing in this game; PT-42)."""
        game.press(key)

    def _hold(self, game, key):
        game.hold(key)
        self._held.add(key)
        if key == "W":
            self._gas = True

    def _release(self, game, key):
        if key in self._held:
            game.release(key)
            self._held.discard(key)
        if key == "W":
            self._gas = False

    def _let_go(self, game):
        for k in list(self._held):
            self._release(game, k)

    def _steer(self, game, bearing):
        if bearing > STEER_DEADBAND:
            self._release(game, "A")
            self._hold(game, "D")
        elif bearing < -STEER_DEADBAND:
            self._release(game, "D")
            self._hold(game, "A")
        else:
            self._release(game, "A")
            self._release(game, "D")

    def _pedals(self, game, speed, want):
        if speed < want - 3.0:
            self._release(game, "S")
            self._hold(game, "W")
        elif speed > want + BRAKE_OVER_KMH or (want == 0.0 and speed > 1.0):
            self._release(game, "W")
            self._hold(game, "S")
        else:
            self._release(game, "W")
            self._release(game, "S")
