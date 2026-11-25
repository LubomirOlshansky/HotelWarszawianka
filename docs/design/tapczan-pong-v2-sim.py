#!/usr/bin/env python3
"""Balance prototype for THE TAPCZAN's beer pong v2, "Rzut na raz" (docs/design/tapczan-pong-v2.md).

Design material, not game code: the reference the GDScript sim (game/scripts/pong_sim.gd, next
pass) is ported from and tuned against. It plays whole matches with a model of the thumb (a
release-time error in seconds, a share of rim flicks made) and prints win rates, cups, drinks
and the match length for each rival.

Usage:
    python3 -I docs/design/tapczan-pong-v2-sim.py            # the table in the brief (4000 matches a cell)
    python3 -I docs/design/tapczan-pong-v2-sim.py 20000      # more matches a cell

Units: canvas pixels of the 216-row pixel canvas (padel's scale) and seconds.
"""
import math
import random
import sys

# --- the rules (the brief's section 3; keep in step with the table of constants there) ---------
CUPS = 5              # a side, one row seen from the side
PITCH = 14.0          # px between cup centres (a cup is 9 px wide: 5 px of table between two)
IN_R = 2.5            # |landing - cup centre| <= IN_R: in
RIM_R = 4.5           # ... <= RIM_R: on the rim, the ball spins
CLEAN_R = 1.0         # ... <= CLEAN_R: CZYSTO, the ball comes back (once a turn)
SWEEP_LO = -24.0      # the ring swings like the arm, a sine between these, px from the first cup's centre
SWEEP_HI = 70.0       # (the table before the rack ... behind the last cup): fastest mid-rack, slowest at the far cup
PERIOD = 1.5          # s there and back, sober
HOLD_SLOW = 0.75      # finger down = a held breath: the swing this much slower (for BREATH s)
BREATH = 1.1          # s of held breath a throw; BREATH_DRINK less per drink, never under BREATH_MIN
BREATH_DRINK = 0.12
BREATH_MIN = 0.45
SWEEP_V_DRINK = 0.05  # each drink: the swing this much faster
WOB_0 = 0.4           # the ring's wobble, px, sober
WOB_DRINK = 0.9       # ... more per drink
WOB_MAX = 5.5
WOB_HZ = 1.1
RIM_DROP = 0.6        # an unflicked spinner drops in this often
BALLS = 2             # the player's balls a turn
ROUNDS = 8            # then OSTATNIE ZAMÓWIENIE: more cups taken wins
SUDDEN = 3            # a tie: this many one-ball rounds, then a draw (no pay)
RERACK_AT = 2         # cups left when a side closes up, once
SHOT_CLOCK = 5.0

# What differs between the rivals is behaviour, not one number (section 3.4).
RIVALS = {
    "office": dict(   # the open-space crew: three hasty balls, nobody guards the cups
        stake=80, balls=3, p_in=0.27, p_rim=0.13, flick=0.0, in_r=IN_R, rim_r=RIM_R),
    "first": dict(    # Pani Gienia: lobs until she is "warmed up", then flicks every spinner and nudges the table
        stake=150, balls=2, p_in=0.10, p_rim=0.12, flick=0.0, in_r=IN_R, rim_r=RIM_R,
        wake_cups=3, wake_round=4, late=dict(p_in=0.50, p_rim=0.12, flick=0.85, nudge=4.0)),
    "sommelier": dict(  # Pan Hubert: tasting glasses (narrow), re-sets his rack after your hit, a ball for your double miss
        stake=120, balls=2, p_in=0.45, p_rim=0.12, flick=0.0, in_r=2.0, rim_r=3.5,
        reset_after_hit=True, bonus_on_blank=True),
}

# The thumb: the release-time error's sd (s), the share of the rival's spinners flicked out, and
# how much of the wobble the player fails to read (0 = reads it all, 1 = ignores it).
PLAYERS = {
    "idle": None,
    "novice": dict(sd=0.085, flick=0.35, blind=0.9),
    "decent": dict(sd=0.048, flick=0.60, blind=0.6),
    "expert": dict(sd=0.026, flick=0.85, blind=0.3),
}

# Clock model for the session length (s): what the view shows, not what the rules need.
T_AIM, T_FLY, T_BEAT, T_RIVAL_BALL, T_BANNER, T_SPIN, T_INTRO, T_END = 1.9, 0.75, 0.5, 1.35, 0.7, 0.9, 2.0, 0.0


def ring_speed(x):
    """px/s of the unheld ring at x (a sine swing between SWEEP_LO and SWEEP_HI)."""
    c, a = (SWEEP_LO + SWEEP_HI) * 0.5, (SWEEP_HI - SWEEP_LO) * 0.5
    return math.tau / PERIOD * math.sqrt(max(a * a - (x - c) * (x - c), 1.0))


def rack(n):
    """Cup centres, px from the first cup of a full rack; RERACK_AT cups close up in the middle."""
    return [i * PITCH for i in range(n)]


class Match:
    def __init__(self, rival_id, player, rng, start_drinks=0):
        self.r = dict(RIVALS[rival_id])
        self.id = rival_id
        self.p = player
        self.rng = rng
        self.theirs = rack(CUPS)      # the cups the player aims at
        self.mine = CUPS              # the player's cups left (the rival's throws are rolled, not flown)
        self.drinks = start_drinks    # pints at the bar before the game count too
        self.took = 0
        self.reracked = False
        self.awake = False
        self.shaken = False           # Hubert just re-set his rack / Gienia nudged: the next throw is harder
        self.clock = T_INTRO
        self.throws = 0

    # the player's one throw: returns "clean", "in", "rim_in", "rim_out", "miss"
    def throw(self):
        self.throws += 1
        self.clock += T_AIM + T_FLY + T_BEAT
        if self.p is None:
            return "miss"             # the shot clock throws it: the ring is wherever it is
        target = self.theirs[-1] if self.p["sd"] < 0.06 else self.rng.choice(self.theirs)  # a decent thumb takes the far, slow cup first
        v = ring_speed(target) * HOLD_SLOW * (1.0 + SWEEP_V_DRINK * self.drinks)
        breath = max(BREATH_MIN, BREATH - BREATH_DRINK * self.drinks)
        if self.rng.random() > min(1.0, breath / (self.p["sd"] * 14.0)):
            v /= HOLD_SLOW        # the breath ran out before the cup: thrown at the full swing
        wob = min(WOB_MAX, WOB_0 + WOB_DRINK * self.drinks)
        sd = self.p["sd"]
        nudge = 0.0
        if self.shaken:
            sd *= 1.25                # a new rack to read
            self.shaken = False
        if self.awake and "late" in self.r and self.rng.random() < 0.5:
            # Gienia's nudge lands mid-sweep on half the throws; a patient player waits it out.
            if self.rng.random() > (0.7 if self.p["sd"] < 0.06 else 0.3):
                nudge = self.rng.choice([-1.0, 1.0]) * self.r["late"]["nudge"]
        err = self.rng.gauss(0.0, sd) * v
        err += self.p["blind"] * wob * math.sin(self.rng.random() * math.tau)
        land = target + err + nudge
        d = min(abs(land - c) for c in self.theirs)
        hit = min(self.theirs, key=lambda c: abs(land - c))
        if d <= CLEAN_R:
            self._take(hit)
            return "clean"
        if d <= self.r["in_r"]:
            self._take(hit)
            return "in"
        if d <= self.r["rim_r"]:
            self.clock += T_SPIN
            flick = self.r["late"]["flick"] if self.awake and "late" in self.r else self.r["flick"]
            if self.rng.random() >= flick and self.rng.random() < RIM_DROP:
                self._take(hit)
                return "rim_in"
            return "rim_out"
        return "miss"

    def _take(self, c):
        self.theirs.remove(c)
        self.took += 1
        if self.r.get("reset_after_hit"):
            self.shaken = True
        if len(self.theirs) == RERACK_AT and not self.reracked:
            self.reracked = True
            mid = 2.0 * PITCH
            self.theirs = [mid - PITCH * 0.5, mid + PITCH * 0.5]
        if "late" in self.r and not self.awake and len(self.theirs) <= self.r["wake_cups"]:
            self.awake = True

    # one ball of the rival's: True when it takes a cup
    def rival_ball(self):
        self.clock += T_RIVAL_BALL
        cfg = self.r["late"] if self.awake and "late" in self.r else self.r
        x = self.rng.random()
        if x < cfg["p_in"]:
            return True
        if x < cfg["p_in"] + cfg["p_rim"]:
            self.clock += T_SPIN
            if self.p is not None and self.rng.random() < self.p["flick"]:
                return False
            return self.rng.random() < RIM_DROP
        return False

    def play(self):
        """Returns (result, cups taken, drinks, seconds): result 1 won, 0 lost, 2 draw."""
        for rnd in range(1, ROUNDS + 1):
            if "late" in self.r and not self.awake and rnd >= self.r["wake_round"]:
                self.awake = True
            self.clock += T_BANNER
            balls, back, hits = BALLS, False, 0
            while balls > 0:
                balls -= 1
                res = self.throw()
                if res in ("clean", "in", "rim_in"):
                    hits += 1
                if res == "clean" and not back:
                    back = True
                    balls += 1
                if not self.theirs:
                    return 1, self.took, self.drinks, self.clock
            self.clock += T_BANNER
            n = self.r["balls"] + (1 if self.r.get("bonus_on_blank") and hits == 0 else 0)
            for _ in range(n):
                if self.rival_ball():
                    self.mine -= 1
                    self.drinks += 1
                    if self.mine == 0:
                        return 0, self.took, self.drinks, self.clock
        left_theirs, left_mine = len(self.theirs), self.mine
        if left_theirs != left_mine:
            return (1 if left_theirs < left_mine else 0), self.took, self.drinks, self.clock
        for _ in range(SUDDEN):
            mine_hit = self.throw() in ("clean", "in", "rim_in") if self.theirs else True
            their_hit = self.rival_ball()
            if their_hit:
                self.drinks += 1
            if mine_hit != their_hit:
                return (1 if mine_hit else 0), self.took, self.drinks, self.clock
        return 2, self.took, self.drinks, self.clock


def table(n, seed=7):
    rng = random.Random(seed)
    print("%-10s %-8s %5s %5s %5s  %5s %6s %6s %6s" % ("rival", "thumb", "win%", "draw%", "lose%", "cups", "drinks", "sec", "p90 s"))
    for rid in ("office", "first", "sommelier"):
        for pname, p in PLAYERS.items():
            res = [Match(rid, p, rng).play() for _ in range(n)]
            win = sum(1 for r in res if r[0] == 1) * 100.0 / n
            draw = sum(1 for r in res if r[0] == 2) * 100.0 / n
            secs = sorted(r[3] for r in res)
            print("%-10s %-8s %5.1f %5.1f %5.1f  %5.2f %6.2f %6.1f %6.1f" % (
                rid, pname, win, draw, 100.0 - win - draw,
                sum(r[1] for r in res) / n, sum(r[2] for r in res) / n,
                sum(secs) / n, secs[int(n * 0.9)]))
    print("\ndecent thumb, win % after pints at the bar (start_drinks 0 / 1 / 2 / 4):")
    for rid in ("office", "first", "sommelier"):
        row = []
        for d in (0, 1, 2, 4):
            res = [Match(rid, PLAYERS["decent"], rng, d).play() for _ in range(n)]
            row.append("%4.1f" % (sum(1 for r in res if r[0] == 1) * 100.0 / n))
        print("  %-10s %s" % (rid, " / ".join(row)))

if __name__ == "__main__":
    table(int(sys.argv[1]) if len(sys.argv) > 1 else 4000)
