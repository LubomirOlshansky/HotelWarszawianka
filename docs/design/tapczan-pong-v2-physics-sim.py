#!/usr/bin/env python3
"""Reference sim for THE TAPCZAN's beer pong v2 with real ball physics
(docs/design/tapczan-pong-v2-physics-and-fun.md; supersedes tapczan-pong-v2-sim.py's rules).

Design material, not game code: `Sim` below is what game/scripts/pong_sim.gd is ported from, line
for line: a deterministic pure sim at a fixed 60 Hz step, driven by two booleans a tick (finger
down, finger dragged low). The bots at the bottom are models of a thumb; the tables they print
are the numbers in the addendum, and the bands the headless check must hold.

Usage:
    python3 -I docs/design/tapczan-pong-v2-physics-sim.py               # the balance table (600 matches a cell)
    python3 -I docs/design/tapczan-pong-v2-physics-sim.py 3000          # more matches a cell
    python3 -I docs/design/tapczan-pong-v2-physics-sim.py 2000 choices  # which choice wins: cups, hold, bounce, dare
    python3 -I docs/design/tapczan-pong-v2-physics-sim.py 2000 lab      # one throw alone: odds by cup and by throw
    python3 -I docs/design/tapczan-pong-v2-physics-sim.py 0 trace       # one throw's path, tick by tick

Units: canvas px of the 216-row pixel canvas (padel's scale), seconds, x along the table towards
the rack being thrown at (0 = the first cup's centre in a full rack), y up from the table top.
Every throw is computed in this "thrower's frame"; the view mirrors it for the rival.
"""
import math
import random
import sys
from multiprocessing import Pool

HZ = 60
DT = 1.0 / HZ

# --- the table, the cups, the ball ---------------------------------------------------------------
G = 600.0             # px/s2: a lob is 0.73 s in the air (real gravity at this scale would be 0.5 s: too fast to read)
BALL_R = 1.5          # the 3x3 ball
HAND_X = -150.0       # the thrower's hand at release
HAND_Y = 34.0
TABLE_LO = -190.0     # the table top's ends (283 px)
TABLE_HI = 93.0
CUPS = 5
PITCH = 14.0
RIM_Y = 13.0          # a cup's height: the ball's centre crossing this plane going down is "at the mouth"
CUP_HALF = 4.5        # the body's half width (a red cup is 9 px); the tasting glass: 3.5
IN_R = 2.0            # |ball - cup centre| at the mouth: inside this, a drop (lips at +-4, less the ball, less a hair)
RIM_R = 5.5           # ... inside this, the ball touches a lip
MIN_GAP = 9.0         # two cups' centres are never closer (they touch)
A_LOB = 64.0          # a lob's apex above the table
A_BOUNCE = 44.0       # a bounce throw's apex: flatter and harder
E_TABLE = 0.62        # the table's bounce: vertical speed kept
F_TABLE = 0.80        # ... and forward speed kept
E_CUP = 0.35          # off a cup's side
E_SPENT = 0.30        # the table's bounce for a ball that has touched a cup (wet, off centre): it dies quickly
FLUKE_IN = 0.6        # ... and the mouth is this much smaller for it: a fluke stays a fluke
V_REST = 35.0         # a bounce slower than this: the ball is dead
MAX_BOUNCES = 3
MAX_FLIGHT = 3.0      # s: no ball lives longer
SLIDE_PER_V = 1.0 / 110.0   # a ball on a cup's side shoves it this many px per px/s ...
SLIDE_MIN, SLIDE_MAX = 0.5, 2.5

# --- the rim ---------------------------------------------------------------------------------------
K_BOUNCE = 0.85       # a ball coming in flat off the table sees a mouth this much smaller (a lob: 1)
SPIN_S = 0.50         # a lip touched on its inner half catches the ball: it spins. Further out it skips off (a tick, no spin)
P_RIM_0 = 0.75        # a lip just kissed from inside drops in this often ...
P_RIM_S = 0.65        # ... falling by this much to the edge of the catching part
P_RIM_SIDE = 0.08     # the far lip throws the ball back in, the near lip pops it short
P_RIM_FLAT = 0.25     # a flat entry (bounce shots) skips off: this much per unit of (1 - mouth factor)
SKIP_UP = 0.35        # a skip off a lip keeps this much of the fall as a hop ...
SKIP_ON, SKIP_BACK = 0.45, -0.25   # ... and this much forward speed off the far lip / the near lip
T_SPIN_0, T_SPIN_S = 0.50, 0.45   # the spin lasts 0.5 s + 0.45 s x how far out it touched
FLICK_FIRST, FLICK_LAP, FLICK_HALF = 0.25, 0.40, 0.085  # the defender's tap: the ball passes the tick at these times, +- this

# --- the swing and the breath ----------------------------------------------------------------------
M_LO, M_HI = 16.0, 12.0   # the ring swings from this far before the first standing cup to this far behind the last
P_REF, A_REF = 1.20, 42.0 # s there and back for a full rack; a shorter rack swings quicker: period ~ sqrt(span)
P_MIN, P_MAX = 0.80, 1.45
HOLD_SLOW = 0.40      # a held breath slows the swing by up to this much ...
HOLD_RAMP = 0.60      # ... reached after this long held
LUNG = 1.30           # s of breath a TURN (not a ball): two full holds do not fit
LUNG_DRINK = 0.10
LUNG_MIN = 0.70
LUNG_BACK = 0.40      # a clean hit gives this much breath back with the ball
GASP_V = 1.15         # out of breath: the swing this fast and the wobble GASP_WOB px wider until the throw
GASP_WOB = 0.8
SWEEP_V_DRINK = 0.05
WOB_0, WOB_DRINK, WOB_MAX = 0.3, 0.8, 5.0
SHOT_CLOCK = 5.0      # s; then the ball slips out of the hand (no throw)

# --- the match -------------------------------------------------------------------------------------
BALLS = 2
ROUNDS = 6            # then OSTATNIE ZAMOWIENIE: more cups taken wins
SUDDEN = 3
RERACK_AT = 2
CLEAN_R = 0.8         # a drop this near the centre: CZYSTO, the ball comes back (once a turn) ...
CLEAN_HEAT = 0.3      # ... wider by this per point of heat (0..3): 1.7 px at heat 3, most of the mouth
HEAT_MAX = 3
DARE_MIN_CUPS = 3     # the rival dares you to a middle cup while this many stand
T_INTRO, T_BANNER, T_BEAT, T_RIVAL_WIND, T_RERACK = 2.0, 0.6, 0.45, 0.5, 0.7
T_HITSTOP = 0.07      # the sim itself freezes this long on a drop (0.1 on a bounce-in): the weight of a hit
NUDGE_WARN = 0.4
NUDGE_BUSY = 0.6

RIVALS = {
    "office": dict(   # the open-space crew: three hasty balls, half an eye on the table
        stake=80, balls=3, sd=7.1, flick=0.0, swat=0.60, half=CUP_HALF, in_r=IN_R, rim_r=RIM_R,
        away_every=2.6, away_len=1.4),   # eyes on their phones 1.4 s in every 2.6
    "first": dict(    # Pani Gienia: lobs anywhere and guards nothing until she is "warmed up"
        stake=150, balls=2, sd=9.0, flick=0.0, swat=0.0, half=CUP_HALF, in_r=IN_R, rim_r=RIM_R,
        wake_cups=3, wake_round=4, late=dict(sd=2.55, flick=0.55, swat=0.85, nudge=4.0, nudge_p=0.5)),
    "sommelier": dict(  # Pan Hubert: tasting glasses, a guarding hand, and a ritual that takes his eyes off
        stake=120, balls=2, sd=4.5, flick=0.0, swat=0.75, half=3.5, in_r=1.2, rim_r=4.0,
        reset_after_hit=True, reset_busy=2.2, away_every=3.4, away_len=1.0, bonus_on_blank=True),
}

AIM, FLIGHT, SPIN, WAIT, DONE = range(5)
ME, THEM = 0, 1


def _lob_time():
    vy = math.sqrt(2.0 * G * (A_LOB - HAND_Y))
    return vy, (vy + math.sqrt(vy * vy + 2.0 * G * (HAND_Y - RIM_Y))) / G


def _bounce_times():
    vy = math.sqrt(2.0 * G * (A_BOUNCE - HAND_Y))
    t1 = (vy + math.sqrt(vy * vy + 2.0 * G * (HAND_Y - BALL_R))) / G
    v_in = G * t1 - vy
    v_up = E_TABLE * v_in
    t2 = (v_up + math.sqrt(v_up * v_up - 2.0 * G * (RIM_Y - BALL_R))) / G
    return vy, t1, t2


LOB_VY, LOB_T = _lob_time()
BNC_VY, BNC_T1, BNC_T2 = _bounce_times()


class Sim:
    """One match. tick(finger, low) 60 times a second; read phase, ring_x(), lung, cups, events."""

    def __init__(self, rival_id, seed, start_drinks=0):
        self.rng = random.Random(seed)
        self.id = rival_id
        self.r = RIVALS[rival_id]
        # cups[side] = the cups that side DEFENDS, each a one-item list [x] in the thrower's frame
        self.cups = [[[i * PITCH] for i in range(CUPS)], [[i * PITCH] for i in range(CUPS)]]
        self.reracked = [False, False]
        self.t = 0                    # ticks
        self.phase = WAIT
        self.wait = int(T_INTRO * HZ)
        self.after = self._start_round
        self.round_no = 0
        self.sudden = 0
        self.thrower = ME
        self.balls = 0
        self.back_used = False
        self.turn_takes = 0
        self.heat = 0
        self.drinks = start_drinks    # pints at the bar count; every cup lost adds one
        self.lost = 0                 # cups the rival took: what the view reports as `drinks`
        self.took = 0
        self.awake = False
        self.busy_until = 0           # the rival's eyes are off the table until this tick
        self.away_phase = self.rng.random() * 3.0
        self.dare = None              # the cup the rival dared
        self.karniak = False          # the rival owes a penalty: one ball fewer next turn
        self.winner = -1              # 0 you, 1 rival, 2 draw
        self.end = ""                 # "clear", "lost", "bell", "sudden", "draw"
        self.ball = None
        self.ball_no = 0
        self.events = []
        self.stats = {}
        # aim state
        self.phi = 0.0
        self.aim_t = 0
        self.held = 0.0
        self.lung = 0.0
        self.gasp = False
        self.armed = False            # the finger has been up since this aim began
        self.was_down = False
        self.nudge_at = -1
        self.sweep = (0.0, 1.0, 1.0)  # centre, amplitude, omega
        # spin state
        self.spin = None

    # ---- helpers ----
    def _ev(self, name, **kw):
        self.events.append((name, kw))
        self.stats[name] = self.stats.get(name, 0) + 1

    def target(self):
        """The rack the thrower aims at."""
        return self.cups[1 - self.thrower]

    def _cfg(self):
        return self.r["late"] if self.awake and "late" in self.r else self.r

    def rival_busy(self, ahead=0):
        """Eyes off the table (now, or `ahead` ticks on): no swat. The view shows the pose (nose in the glass, hand on the table)."""
        t = self.t + ahead
        if t < self.busy_until:
            return True
        if "away_every" in self.r:
            return (t * DT + self.away_phase) % self.r["away_every"] < self.r["away_len"]
        return False

    def wobble(self):
        amp = min(WOB_MAX, WOB_0 + WOB_DRINK * self.drinks) + (GASP_WOB if self.gasp else 0.0)
        s = self.t * DT
        return amp * (0.7 * math.sin(6.912 * s) + 0.3 * math.sin(16.96 * s + 1.0))

    def ring_x(self):
        c, a, _w = self.sweep
        return c - a * math.cos(self.phi) + self.wobble()

    def hold_factor(self):
        if self.gasp:
            return GASP_V
        return 1.0 - HOLD_SLOW * min(self.held / HOLD_RAMP, 1.0)

    def clean_r(self):
        return CLEAN_R + CLEAN_HEAT * self.heat

    # ---- the round ----
    def _start_round(self):
        if self.sudden == 0 and self.round_no >= ROUNDS:
            return self._bell()
        self.round_no += 1
        if "late" in self.r and not self.awake and self.round_no >= self.r["wake_round"]:
            self._wake()
        self._ev("round", n=self.round_no)
        self.thrower = ME
        self.balls = 1 if self.sudden else BALLS
        self.back_used = False
        self.turn_takes = 0
        self.lung = max(LUNG_MIN, LUNG - LUNG_DRINK * self.drinks)
        theirs = self.cups[THEM]
        self.dare = None
        if len(theirs) >= DARE_MIN_CUPS and not self.sudden:
            self.dare = theirs[1 + self.rng.randrange(len(theirs) - 2)]
            self._ev("dare")
        self._pause(T_BANNER, self._next_ball)

    def _wake(self):
        self.awake = True
        self._ev("wake")

    def _pause(self, secs, then):
        self.phase = WAIT
        self.wait = max(1, int(round(secs * HZ)))
        self.after = then

    def _next_ball(self):
        if self.winner >= 0:
            return
        if self.balls <= 0:
            return self._end_turn()
        self.balls -= 1
        self.ball_no += 1
        if self.thrower == ME:
            xs = [c[0] for c in self.cups[THEM]]
            lo, hi = min(xs) - M_LO, max(xs) + M_HI
            a = (hi - lo) * 0.5
            period = min(P_MAX, max(P_MIN, P_REF * math.sqrt(a / A_REF))) / (1.0 + SWEEP_V_DRINK * self.drinks)
            self.sweep = ((lo + hi) * 0.5, a, math.tau / period)
            self.phi = 0.0
            self.aim_t = 0
            self.held = 0.0
            self.gasp = False
            self.armed = False
            self.nudge_at = -1
            cfg = self._cfg()
            if cfg.get("nudge") and self.rng.random() < cfg["nudge_p"]:
                self.nudge_at = int((0.6 + 0.8 * self.rng.random()) * HZ)
            self.phase = AIM
        else:
            self._pause(T_RIVAL_WIND, self._rival_throw)

    def _end_turn(self):
        if self.thrower == ME:
            self.thrower = THEM
            n = self.r["balls"]
            if self.sudden:
                n = 1
            else:
                if self.r.get("bonus_on_blank") and self.turn_takes == 0:
                    n += 1
                    self._ev("bonus")
                if self.karniak:
                    n = max(1, n - 1)
            self.karniak = False
            self.balls = n
            self.turn_takes = 0
            self._pause(T_BANNER, self._next_ball)
        elif self.sudden:
            a, b = self.sudden_hit
            if a != b:
                return self._over(ME if a else THEM, "sudden")
            if self.sudden >= SUDDEN:
                return self._over(2, "draw")
            self.sudden += 1
            self.sudden_hit = [False, False]
            self._start_round()
        else:
            self._start_round()

    def _bell(self):
        self._ev("last_orders")
        mine, theirs = len(self.cups[ME]), len(self.cups[THEM])
        if mine != theirs:
            return self._over(ME if theirs < mine else THEM, "bell")
        self.sudden = 1
        self.sudden_hit = [False, False]
        self._ev("sudden")
        self._start_round()

    def _over(self, who, how):
        self.winner = who
        self.end = how
        self.phase = DONE
        self._ev("over", winner=who)

    # ---- throws ----
    def _launch(self, x_t, low):
        """The ball leaves the hand so that it comes down through the mouth plane exactly at x_t:
        straight there (a lob), or after one bounce off the table (low)."""
        if low:
            vx = (x_t - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
            vy = BNC_VY
        else:
            vx = (x_t - HAND_X) / LOB_T
            vy = LOB_VY
        self.ball = dict(x=HAND_X, y=HAND_Y, vx=vx, vy=vy, low=low, fresh=True, bounces=0, age=0, aim=x_t)
        self.phase = FLIGHT
        self._ev("throw" if self.thrower == ME else "rival_throw", low=low)

    def _rival_throw(self):
        cfg = self._cfg()
        cup = self.rng.choice(self.cups[ME])
        self._launch(cup[0] + self.rng.gauss(0.0, cfg["sd"]), False)

    def _aim_tick(self, finger, low):
        self.aim_t += 1
        if self.nudge_at >= 0:
            if self.aim_t == self.nudge_at - int(NUDGE_WARN * HZ):
                self._ev("nudge_warn")
                self.busy_until = self.t + int((NUDGE_WARN + NUDGE_BUSY) * HZ)
            if self.aim_t == self.nudge_at:
                self._nudge()
        if not finger and not self.was_down:
            self.armed = True
        if finger and self.armed:
            if self.lung > 0.0:
                self.held += DT
                self.lung -= DT
                if self.lung <= 0.0:
                    self.lung = 0.0
                    self.gasp = True
                    self._ev("gasp")
        released = self.armed and self.was_down and not finger
        self.was_down = finger and self.armed
        if released:
            if self.nudge_at >= 0 and self.aim_t < self.nudge_at - int(NUDGE_WARN * HZ):
                self.nudge_at = -1        # thrown before her hand moved: no nudge
            self.low = low
            return self._launch(self.ring_x(), low)
        if self.aim_t >= int(SHOT_CLOCK * HZ):
            self._ev("slip")
            self.was_down = False
            return self._ball_done(False)
        self.phi += self.sweep[2] * self.hold_factor() * DT

    def _nudge(self):
        d = self._cfg()["nudge"] * (1.0 if self.rng.random() < 0.5 else -1.0)
        for c in self.cups[THEM]:
            c[0] += d
        self.nudge_at = -2            # done; a ball already in the air meets the moved cups
        self._ev("nudge", d=d)

    # ---- the ball ----
    def _flight_tick(self):
        b = self.ball
        b["age"] += 1
        if self.thrower == ME and self.nudge_at >= 0:
            self.aim_t += 1
            if self.aim_t == self.nudge_at:
                self._nudge()
        rem = DT
        for _ in range(8):
            t_rim = self._fall_time(b, RIM_Y)
            t_tab = self._fall_time(b, BALL_R)
            t = min(t_rim, t_tab, rem)
            b["x"] += b["vx"] * t
            b["y"] += b["vy"] * t - 0.5 * G * t * t
            b["vy"] -= G * t
            rem -= t
            if t == t_rim and t_rim <= t_tab:
                b["y"] = RIM_Y
                if self._at_mouth(b):
                    return
                b["y"] = RIM_Y - 1e-6
            elif t == t_tab:
                b["y"] = BALL_R
                if self._on_table(b):
                    return
            self._walls(b)
            if rem <= 1e-9:
                break
        if b["y"] < -30.0 or b["age"] > MAX_FLIGHT * HZ:
            self._ball_done(False)

    @staticmethod
    def _fall_time(b, level):
        """Seconds until the ball's centre comes DOWN through `level` (inf if it does not)."""
        disc = b["vy"] * b["vy"] + 2.0 * G * (b["y"] - level)
        if disc < 0.0:
            return math.inf
        t = (b["vy"] + math.sqrt(disc)) / G
        return t if t > 1e-9 else math.inf

    def _on_table(self, b):
        if not TABLE_LO <= b["x"] <= TABLE_HI:
            b["y"] = BALL_R - 1e-6      # past the end: it falls to the floor
            return False
        b["bounces"] += 1
        v_in = -b["vy"]
        b["vy"] = (E_TABLE if b["fresh"] else E_SPENT) * v_in
        b["vx"] *= F_TABLE
        self._ev("tock", v=v_in)
        if b["low"] and b["fresh"] and b["bounces"] == 1 and self.thrower == ME:
            if not self.rival_busy() and self.rng.random() < self._cfg()["swat"]:
                self._ev("swat")
                self._ball_done(False)
                return True
        if b["bounces"] > MAX_BOUNCES or b["vy"] < V_REST:
            self._ball_done(False)
            return True
        return False

    def _walls(self, b):
        if b["y"] >= RIM_Y or b["y"] < BALL_R - 1e-3:
            return
        reach = self.r["half"] if self.thrower == ME else CUP_HALF
        reach += BALL_R
        cups = self.target()
        for i, c in enumerate(cups):
            d = b["x"] - c[0]
            if abs(d) >= reach:
                continue
            side = (1.0 if d > 0 else -1.0) if abs(d) > reach - 1.6 else (-1.0 if b["vx"] > 0 else 1.0)
            b["x"] = c[0] + side * (reach + 0.01)
            if b["vx"] * side < 0.0:      # moving into the cup: shove it, bounce off
                push = min(SLIDE_MAX, max(SLIDE_MIN, abs(b["vx"]) * SLIDE_PER_V)) * -side
                lo = cups[i - 1][0] + MIN_GAP if i > 0 else -40.0
                hi = cups[i + 1][0] - MIN_GAP if i + 1 < len(cups) else TABLE_HI - 8.0
                nx = min(hi, max(lo, c[0] + push))
                self._ev("body", slide=nx - c[0], clink=nx != c[0] + push)
                b["x"] += nx - c[0]
                c[0] = nx
                b["vx"] *= -E_CUP
            b["fresh"] = False
            return

    def _at_mouth(self, b):
        """The ball's centre is on the mouth plane, going down. True when the flight ended here."""
        cups = self.target()
        if not cups:
            return False
        cup = min(cups, key=lambda c: abs(c[0] - b["x"]))
        d = b["x"] - cup[0]
        a = abs(d)
        r = self.r if self.thrower == ME else RIVALS["office"]   # your cups are plain red cups
        k = K_BOUNCE if b["bounces"] else 1.0
        in_r = r["in_r"] * k
        if not b["fresh"] and a <= in_r * FLUKE_IN:
            return self._take(cup, "fluke")
        if a <= in_r and b["fresh"]:
            if b["bounces"]:
                return self._take(cup, "bounce_in")
            return self._take(cup, "clean" if a <= self.clean_r() * k else "in")
        if a > r["rim_r"]:
            return False
        s = (a - in_r) / (r["rim_r"] - in_r)
        if not b["fresh"] or s > SPIN_S: # the lip's outer part, or a second touch: no spin, it skips off
            b["fresh"] = False
            if -b["vy"] < 25.0:          # too slow to hop: it rolls off the lip
                b["x"] = cup[0] + (r["rim_r"] + 0.05) * (1.0 if d > 0 else -1.0)
                return False
            b["vy"] = SKIP_UP * -b["vy"]
            b["vx"] *= SKIP_ON if d > 0 else SKIP_BACK
            b["y"] = RIM_Y + 0.01
            self._ev("rim_tick", side=1 if d > 0 else -1)
            return False
        p = P_RIM_0 - P_RIM_S * s / SPIN_S + (P_RIM_SIDE if d > 0 else -P_RIM_SIDE) - P_RIM_FLAT * (1.0 - k)
        p = min(0.95, max(0.05, p))
        drop = self.rng.random() < p
        secs = T_SPIN_0 + T_SPIN_S * s / SPIN_S
        flick = False
        if self.thrower == ME:           # the rival guards: decided now, shown at 60 % of the spin
            flick = self.rng.random() < self._cfg()["flick"] or cup is self.dare   # the dared cup is watched: only a drop takes it
        self.spin = dict(cup=cup, d=d, s=s, drop=drop, left=int(secs * HZ), age=0, flicked=flick, tapped=False,
                         vx=b["vx"], bounced=b["bounces"] > 0)
        self.phase = SPIN
        self._ev("rim", s=s, side=1 if d > 0 else -1)
        return True

    def _spin_tick(self, finger):
        sp = self.spin
        sp["age"] += 1
        if self.thrower == THEM and finger and not self.was_down and not sp["tapped"]:
            sp["tapped"] = True          # one tap: on the tick or wasted
            ts = sp["age"] * DT
            k = round((ts - FLICK_FIRST) / FLICK_LAP)
            if k >= 0 and abs(ts - (FLICK_FIRST + k * FLICK_LAP)) <= FLICK_HALF:
                sp["flicked"] = True
                sp["left"] = min(sp["left"], 2)
        self.was_down = finger
        sp["left"] -= 1
        if sp["left"] > 0:
            return
        self.spin = None
        self.was_down = False
        if sp["flicked"]:
            self._ev("flicked")
            return self._ball_done(False)
        if sp["drop"]:
            return self._take(sp["cup"], "rim_in")
        self._ev("rim_out")
        side = 1.0 if sp["d"] > 0 else -1.0
        b = self.ball
        b.update(x=sp["cup"][0] + side * (RIM_R + 0.3), y=RIM_Y + 0.5, vx=side * 45.0 + 0.15 * sp["vx"], vy=55.0, fresh=False)
        self.phase = FLIGHT

    def _take(self, cup, how):
        """A ball is in `cup`. how: clean, in, rim_in, bounce_in (worth the neighbour too), fluke."""
        side = 1 - self.thrower
        cups = self.cups[side]
        i = cups.index(cup)
        n = 1
        cups.pop(i)
        if how == "bounce_in" and cups:     # the cup tips into its neighbour: both go (the one behind, else the one in front)
            cups.pop(i if i < len(cups) else i - 1)
            n = 2
            self._ev("domino")
        self._ev(how if self.thrower == ME else "rival_cup", n=n)
        self.turn_takes += n
        if self.thrower == ME:
            self.took += n
            self.heat = min(HEAT_MAX, self.heat + n)
            if self.sudden:
                self.sudden_hit[ME] = True
            if cup is self.dare:
                self.dare = None
                self.karniak = True
                self.heat = HEAT_MAX
                self._ev("karniak")
                if not self.back_used and not self.sudden:
                    how = "clean"         # and the ball comes back, as for a clean hit
            if how == "clean" and not self.back_used and not self.sudden:
                self.back_used = True
                self.balls += 1
                self.lung += LUNG_BACK
                self._ev("back")
        else:
            self.lost += n
            self.drinks += n
            if self.sudden:
                self.sudden_hit[THEM] = True
        if not cups and not self.sudden:
            self.ball = None
            return self._over(self.thrower, "clear" if self.thrower == ME else "lost") or True
        if self.sudden and not cups:
            cups.append([2.0 * PITCH])   # sudden death is played on one cup each, put back if it falls
        if self.thrower == ME:
            if "late" in self.r and not self.awake and len(cups) <= self.r["wake_cups"]:
                self._wake()
            if self.r.get("reset_after_hit") and len(cups) > 1:
                pitch = 11.0 + 6.0 * self.rng.random()
                x0 = cups[0][0] - 4.0 + 10.0 * self.rng.random()
                x0 = min(x0, TABLE_HI - 10.0 - pitch * (len(cups) - 1))
                for j, c in enumerate(cups):
                    c[0] = x0 + j * pitch
                self.busy_until = self.t + int(self.r["reset_busy"] * HZ)
                self._ev("reset")
        extra = 0.0
        if len(cups) == RERACK_AT and not self.reracked[side] and not self.sudden:
            self.reracked[side] = True
            mid = 2.0 * PITCH
            cups[0][0], cups[1][0] = mid - PITCH * 0.5, mid + PITCH * 0.5
            extra = T_RERACK
            self._ev("rerack", side=side)
        self.ball = None
        self._pause((0.1 if n == 2 else T_HITSTOP) + T_BEAT + extra, self._next_ball)
        return True

    def _ball_done(self, _hit):
        if self.thrower == ME:
            self.heat = 0
            self._ev("miss")
        else:
            self._ev("rival_miss")
        self.ball = None
        self._pause(T_BEAT, self._next_ball)

    # ---- the one entry point ----
    def tick(self, finger=False, low=False):
        if self.phase == DONE:
            return
        self.t += 1
        if self.phase == WAIT:
            self.was_down = finger
            self.wait -= 1
            if self.wait <= 0:
                self.after()
        elif self.phase == AIM:
            self._aim_tick(finger, low)
        elif self.phase == FLIGHT:
            self._flight_tick()
        elif self.phase == SPIN:
            self._spin_tick(finger)


# ====================================================================================================
# The thumbs. Everything below is the prototype's player model; the game ships only `bot_finger`,
# a port of Bot.act with a fixed policy, for auto_play and the headless check.
# ====================================================================================================
READ_SWAT = 0.3       # a bot bounces at a table guarded less than this
THUMBS = {
    "novice": dict(sd=0.085, flick=0.35, blind=0.9, tells=False),
    "decent": dict(sd=0.048, flick=0.60, blind=0.6, tells=True),
    "expert": dict(sd=0.026, flick=0.85, blind=0.3, tells=True),
}


# What each thumb does when nobody tells it otherwise (the balance table's players).
HABITS = {
    "novice": dict(cup="mid", hold="deep", bounce="never"),
    "decent": dict(cup="far", hold="deep", bounce="read"),
    "expert": dict(cup="dare", hold="even", bounce="read"),
}


class Bot:
    """cup: far | near | mid | dare | smart.  hold: deep | even | none.  bounce: never | always | read."""

    def __init__(self, thumb, rng, cup="smart", hold="deep", bounce="read"):
        self.th = thumb
        self.rng = rng
        self.cup, self.hold, self.bounce = cup, hold, bounce
        self.ball_no = -1
        self.log = []                 # (cups standing, kind of cup, low, events before, ...) per throw

    def _plan(self, s):
        self.ball_no = s.ball_no
        cups = s.cups[THEM]
        n = len(cups)
        cfg = s._cfg()
        self.low = False
        self.read = False
        if self.bounce == "always":
            self.low = True
        elif self.bounce == "read" and n >= 2:
            # bounce when nobody is likely to swat it: an unguarded table, or (decided at the release) eyes off
            self.low = cfg["swat"] <= READ_SWAT
            self.read = not self.low and self.th["tells"]
        kind = "near" if self.read else self.cup
        if kind == "smart":
            kind = "dare" if (s.dare is not None and self.th["sd"] < 0.04 and not self.low) else "far"
        if self.low:
            self.cupref, self.kind = self._bounce_cup(s, cups), "bounce"
        elif kind == "dare" and s.dare is not None:
            self.cupref, self.kind = s.dare, "dare"
        elif kind == "near":
            self.cupref, self.kind = cups[0], "near"
        elif kind == "mid" and n >= 3:
            self.cupref, self.kind = cups[n // 2], "mid"
        else:
            self.cupref, self.kind = cups[-1], "far"
        lung = s.lung - 0.12
        if self.hold == "none" or lung < 0.15:
            self.h = 0.0
        elif self.hold == "even":
            self.h = min(lung / max(1, s.balls + 1), HOLD_RAMP + 0.1)
        else:
            self.h = min(lung, HOLD_RAMP + 0.1)
        self.noise = self.rng.gauss(0.0, self.th["sd"])
        self.goal = None              # the unwrapped swing phase to release at
        self.holding = False
        self.mash_at = None

    @staticmethod
    def _bounce_cup(s, cups):
        """The furthest cup a bounce can reach over the ones in front (the first two or three)."""
        best = cups[0]
        for c in cups[1:3]:
            vx = F_TABLE * (c[0] - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
            xb = c[0] - vx * BNC_T2
            tt = (cups[0][0] - s.r["half"] - BALL_R - xb) / vx
            if tt > 0 and BALL_R + E_TABLE * (G * BNC_T1 - BNC_VY) * tt - 0.5 * G * tt * tt > RIM_Y + BALL_R + 1.0:
                best = c
        return cups[0] if best is cups[0] else cups[min(1, len(cups) - 1)]

    def act(self, s):
        if s.phase == SPIN:
            sp = s.spin
            if s.thrower == THEM and not sp["tapped"]:
                if sp["age"] == 0:
                    self.will = self.rng.random() < self.th["flick"]
                return self.will and sp["age"] == int(FLICK_FIRST * HZ) - 1, False
            return False, False
        if s.phase != AIM:
            return False, False
        if s.ball_no != self.ball_no:
            self._plan(s)
        if self.th["tells"] and 0 <= s.nudge_at and s.aim_t >= s.nudge_at - int(NUDGE_WARN * HZ) and not self.holding:
            return False, self.low     # her hand is on the table: wait it out
        c, a, w = s.sweep
        want = self.cupref[0] - (1.0 - self.th["blind"]) * s.wobble()
        cosv = max(-1.0, min(1.0, (c - want) / a))
        p1 = math.acos(cosv)
        if self.h <= HOLD_RAMP:
            lead = w * (self.h - HOLD_SLOW * self.h * self.h / (2.0 * HOLD_RAMP))
        else:
            lead = w * (self.h * (1.0 - HOLD_SLOW) + HOLD_SLOW * HOLD_RAMP * 0.5)
        track = max(lead, 0.25 * w)
        if not self.holding:
            if not s.armed:
                return False, self.low
            # the next pass over the cup (either way) that is still at least `track` of swing away
            base = math.floor(s.phi / math.tau) * math.tau
            cands = [(base + k * math.tau + q, base + k * math.tau, sg) for k in range(4) for q, sg in ((p1, 1.0), (math.tau - p1, -1.0))]
            goal, self.gbase, self.gsign = min(g for g in cands if g[0] - s.phi >= track - w * DT)
            if goal - s.phi > track + w * DT * 0.5:
                return False, self.low
            self.holding = True       # from here the thumb follows this pass
        goal = self.gbase + (p1 if self.gsign > 0 else math.tau - p1)   # the wobble moves it a little
        t_go = (goal - s.phi) / (w * s.hold_factor())
        low = self.low or (self.read and s.rival_busy() and s.rival_busy(int(BNC_T1 * HZ) + 3))
        if self.h <= 0.0:             # a bare tap: down one tick, up the next
            if s.was_down:
                self.kind = "bounce" if low else self.kind
                return False, low
            return t_go - DT <= -self.noise, low
        if t_go <= -self.noise and s.was_down:   # let go `noise` seconds off the pass
            self.kind = "bounce" if low else self.kind
            return False, low
        return goal - s.phi <= lead + w * DT * 0.5 or s.was_down, low


class Masher(Bot):
    """No skill: taps at a random moment."""

    def act(self, s):
        if s.phase != AIM:
            return False, False
        if s.ball_no != self.ball_no:
            self.ball_no = s.ball_no
            self.mash_at = int((0.3 + 1.2 * self.rng.random()) * HZ)
        return s.aim_t == self.mash_at, False


class Idle(Bot):
    def act(self, s):
        return False, False


def play(rival, thumb, seed, start_drinks=0, **policy):
    rng = random.Random(seed * 7919 + 13)
    s = Sim(rival, seed, start_drinks)
    if thumb == "idle":
        bot = Idle(None, rng)
    elif thumb == "masher":
        bot = Masher(None, rng)
    else:
        bot = Bot(THUMBS[thumb], rng, **(policy or HABITS[thumb]))
    throws = []
    cur = None
    while s.phase != DONE and s.t < 400 * HZ:
        f, low = bot.act(s)
        before = s.ball_no if s.phase == AIM else -1
        n_ev = len(s.events)
        s.tick(f, low)
        for name, kw in s.events[n_ev:]:
            if name == "throw":
                cur = dict(kind=getattr(bot, "kind", "?"), low=kw["low"], n=len(s.cups[THEM]), took=0, how="miss")
                throws.append(cur)
            elif cur is not None and name in ("clean", "in", "rim_in", "bounce_in", "fluke"):
                cur["took"], cur["how"] = kw["n"], name
            elif cur is not None and name in ("swat", "flicked", "rim_out"):
                cur["how"] = name
            elif name in ("rival_throw", "round"):
                cur = None
    return dict(win=s.winner, end=s.end, secs=s.t * DT, took=s.took, lost=s.lost, rounds=s.round_no,
                throws=throws, stats=s.stats, stuck=s.phase != DONE)


def _cell(args):
    rival, thumb, n, seed0, drinks, policy = args
    out = dict(n=n, win=0, draw=0, secs=[], took=0, lost=0, ends={}, kinds={}, stats={}, stuck=0, rounds=0)
    for i in range(n):
        m = play(rival, thumb, seed0 + i, drinks, **policy)
        out["win"] += m["win"] == 0
        out["draw"] += m["win"] == 2
        out["stuck"] += m["stuck"]
        out["secs"].append(m["secs"])
        out["took"] += m["took"]
        out["lost"] += m["lost"]
        out["rounds"] += m["rounds"]
        out["ends"][m["end"]] = out["ends"].get(m["end"], 0) + 1
        for k, v in m["stats"].items():
            out["stats"][k] = out["stats"].get(k, 0) + v
        for t in m["throws"]:
            key = t["kind"]
            e = out["kinds"].setdefault(key, [0, 0, {}])
            e[0] += 1
            e[1] += t["took"]
            e[2][t["how"]] = e[2].get(t["how"], 0) + 1
    out["secs"].sort()
    return args, out


def run(cells):
    with Pool() as pool:
        return pool.map(_cell, cells)


def pct(a, b):
    return 100.0 * a / max(1, b)


def table(n):
    cells = [(r, th, n, 1000, 0, {}) for r in RIVALS for th in ("idle", "masher", "novice", "decent", "expert")]
    cells += [(r, "decent", n, 5000, d, {}) for r in RIVALS for d in (1, 2, 4)]
    res = dict(((a[0], a[1], a[4]), o) for a, o in run(cells))
    print("%-10s %-7s %5s %5s  %4s %4s %6s %5s %5s  %s" % ("rival", "thumb", "win%", "draw%", "took", "lost", "rounds", "sec", "p90", "ends % (clear lost bell sudden draw)"))
    for r in RIVALS:
        for th in ("idle", "masher", "novice", "decent", "expert"):
            o = res[(r, th, 0)]
            e = o["ends"]
            print("%-10s %-7s %5.1f %5.1f  %4.1f %4.1f %6.1f %5.1f %5.1f  %s" % (
                r, th, pct(o["win"], n), pct(o["draw"], n), o["took"] / n, o["lost"] / n, o["rounds"] / n,
                sum(o["secs"]) / n, o["secs"][int(n * 0.9)],
                " ".join("%2.0f" % pct(e.get(k, 0), n) for k in ("clear", "lost", "bell", "sudden", "draw"))))
    print("\ndecent thumb, win % after pints at the bar (0 / 1 / 2 / 4):")
    for r in RIVALS:
        print("  %-10s %s" % (r, " / ".join("%4.1f" % pct(res[(r, "decent", d)]["win"], n) for d in (0, 1, 2, 4))))
    print("\ndecent thumb, a match's moments (per match):")
    keys = ("clean", "in", "rim_in", "bounce_in", "fluke", "back", "karniak", "swat", "flicked", "rim", "body", "rerack", "nudge", "reset", "bonus", "gasp", "slip")
    print("  %-10s %s" % ("", " ".join("%7s" % k for k in keys)))
    for r in RIVALS:
        st = res[(r, "decent", 0)]["stats"]
        print("  %-10s %s" % (r, " ".join("%7.2f" % (st.get(k, 0) / n) for k in keys)))
    print("  stuck matches: %d; longest %.0f s" % (sum(o["stuck"] for o in res.values()), max(o["secs"][-1] for o in res.values())))


def choices(n):
    pols = [
        ("far cup, deep hold, no bounce", dict(cup="far", hold="deep", bounce="never")),
        ("near cup", dict(cup="near", hold="deep", bounce="never")),
        ("middle cup", dict(cup="mid", hold="deep", bounce="never")),
        ("the dared cup", dict(cup="dare", hold="deep", bounce="never")),
        ("far cup, breath split evenly", dict(cup="far", hold="even", bounce="never")),
        ("far cup, never holds", dict(cup="far", hold="none", bounce="never")),
        ("always bounces", dict(cup="far", hold="deep", bounce="always")),
        ("bounces when unguarded (the read)", dict(cup="far", hold="deep", bounce="read")),
        ("the read + dares (expert default)", dict(cup="dare", hold="deep", bounce="read")),
    ]
    for th in ("decent", "expert"):
        cells = [(r, th, n, 9000, 0, p) for r in RIVALS for _nm, p in pols]
        res = run(cells)
        print("\n%s thumb: win %% by policy            crew  Gienia  Hubert   takes/throw (crew)" % th)
        for nm, p in pols:
            row = [o for a, o in res if a[5] == p]
            k = row[0]["kinds"]
            tt = sum(v[0] for v in k.values())
            tk = sum(v[1] for v in k.values())
            print("  %-36s %5.1f  %5.1f  %5.1f    %.2f" % (nm, pct(row[0]["win"], n), pct(row[1]["win"], n), pct(row[2]["win"], n), tk / max(1, tt)))
        print("  per kind of throw (all policies pooled): throws, cups a throw, how they ended %")
        for ri, r in enumerate(RIVALS):
            pool = {}
            for a, o in res:
                if a[0] != r:
                    continue
                for kk, v in o["kinds"].items():
                    e = pool.setdefault(kk, [0, 0, {}])
                    e[0] += v[0]
                    e[1] += v[1]
                    for h, c in v[2].items():
                        e[2][h] = e[2].get(h, 0) + c
            for kk, v in sorted(pool.items()):
                print("    %-10s %-7s %6d  %.2f   %s" % (r, kk, v[0], v[1] / v[0], " ".join("%s %.0f" % (h, pct(c, v[0])) for h, c in sorted(v[2].items(), key=lambda x: -x[1]))))


def lab(n):
    """One throw alone, no rival: the take odds by where the ring was when the ball left."""
    print("a lob and a bounce let go with the ring d px off the first cup's centre (full rack), %d throws each:" % n)
    print("  d     lob: take  how                      bounce: cups  how")
    for d in (0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, -1.0, -2.5, -4.0, -6.0, -8.0):
        row = []
        for low in (False, True):
            took, how = 0, {}
            for i in range(n):
                s = Sim("office", i)
                s.thrower = ME
                s.phase = FLIGHT
                s.balls = 0
                s._launch(d, low)
                s.busy_until = 10 ** 9
                n_ev = len(s.events)
                while s.phase in (FLIGHT, SPIN):
                    s.tick()
                tk = CUPS - len(s.cups[THEM])
                took += tk
                h = [e[0] for e in s.events[n_ev:] if e[0] in ("clean", "in", "rim_in", "rim_out", "bounce_in", "fluke", "body")]
                h = h[-1] if h else "miss"
                how[h] = how.get(h, 0) + 1
            row.append("%.2f  %-24s" % (took / n, " ".join("%s %.0f" % (k, pct(v, n)) for k, v in sorted(how.items(), key=lambda x: -x[1])[:3])))
        print("  %4.1f  %s  %s" % (d, row[0], row[1]))


def trace():
    for low in (False, True):
        s = Sim("office", 1)
        s.thrower = ME
        s._launch(14.0, low)
        s.busy_until = 10 ** 9
        print("low=%s vx=%.1f vy=%.1f" % (low, s.ball["vx"], s.ball["vy"]))
        while s.phase == FLIGHT and s.ball:
            b = s.ball
            if b["age"] % 4 == 0:
                print("  t=%.3f x=%7.2f y=%6.2f" % (b["age"] * DT, b["x"], b["y"]))
            s.tick()
        print("  ->", [e[0] for e in s.events])


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 600
    mode = sys.argv[2] if len(sys.argv) > 2 else "table"
    if mode == "choices":
        choices(n)
    elif mode == "lab":
        lab(n)
    elif mode == "trace":
        trace()
    else:
        table(n)
