#!/usr/bin/env python3
"""Critique sim for docs/design/drift-narodowy.md section 0b.2 and 0b.5 (the numbers as written).

Usage: python3 -I docs/design/critique-drift-sim.py

A 1-D model: in JEDEN KCIUK the car steers itself along Osemka's ideal line, so the state is
s (m along the line), v, the slip angle and the scorer. It answers:
  1. does a fixed rhythm hold the drift and pass Q_LINE 4,500 (0b.6 attack 1)?
  2. what bank-spam, kick-and-hold and no-kick score (attacks 2 and 3);
  3. what skipping both transitions costs (the spec does not say: both readings are printed);
  4. closed forms: the sticky band's attractor, check M3 against the table, how one true angle
     reads on the 40-degree isometric camera, BLISKO against KONTAKT, smoke cover, the marks.

NOT RUN by its author: the critique thread had no shell. The numbers in critique-drift.md are
hand sums from the same rates; the "hand" column repeats them, so a gap of more than about
20 % means this file or the hand sum is wrong. Guesses where 0b gives no number: both
crossovers 45 m and straight, the zones' places and lengths, a 4.0 x 1.8 m car box.
"""
import math

DT = 1.0 / 60.0
Q_LINE = 4500
# (length m, curvature 1/m, + left): south straight, west loop r 24 m 300 deg, crossover, east
# loop r 18 m 300 deg the other way, crossover, half the west loop, north straight: 465 m.
SEGS = [(40.0, 0.0), (125.7, 1 / 24), (45.0, 0.0), (94.2, -1 / 18), (45.0, 0.0), (75.4, 1 / 24), (39.7, 0.0)]
LENGTH = sum(seg[0] for seg in SEGS)
FLIPS = [188.2, 327.4]  # the middle of each crossover: where the line's curvature changes sign
# (from m, to m, least angle deg, side). ZONA is 35, not 30: 2.6 m - 2 m x sin(angle) <= 1.5 m.
ZONES = [(64, 76, 35, 1), (120, 128, 30, 1), (196, 204, 30, -1), (250, 262, 35, -1), (285, 293, 30, -1)]


def kappa(s):
    for length, k in SEGS:
        if s < length:
            return k
        s -= length
    return 0.0


def bend_ahead(s):
    """The side (+1 or -1) of the first bend within 30 m, 0 if none (the kick's rule)."""
    x = s
    while x <= s + 30.0:
        k = kappa(x)
        if abs(k) >= 1 / 60:
            return 1 if k > 0 else -1
        x += 1.0
    return 0


def angle_score(b):
    """A(beta) of 0b.2: 0 under 15, 1 from 25 to 50, 0.5 from 65."""
    if b < 15.0:
        return 0.0
    if b < 25.0:
        return (b - 15.0) / 10.0
    if b <= 50.0:
        return 1.0
    return max(0.5, 1.0 - 0.5 * (b - 50.0) / 15.0)


def step(st, pressed, kick, strict):
    st["gas"] = min(1.0, st["gas"] + DT / 0.15) if pressed else 0.0
    gas, v = st["gas"], st["v"]
    if st["mode"] == "SPIN":
        st["spin_t"] -= DT
        st["v"] = max(0.0, v - st["spin_v"] / 1.5 * DT)
        st["s"] += st["v"] * DT
        if st["spin_t"] <= 0.0:
            st["mode"], st["v"] = "GRIP", 0.0
        return
    if kick and st["mode"] == "GRIP":
        side = bend_ahead(st["s"])
        if v >= 30.0 / 3.6 and side != 0:
            st.update(mode="DRIFT", side=side, open=True, chain=1, chain_t=0.0, low_t=0.0)
    elif kick and st["mode"] == "DRIFT" and st["flip_t"] <= 0.0:
        flip = next((f for f in FLIPS if f not in st["flips"] and f - 0.8 * v <= st["s"] <= f + 0.4 * v), None)
        if flip is None:
            st["b"] = max(0.0, st["b"] - 5.0)  # outside the window: -5 degrees, nothing else
        else:
            st["flips"].append(flip)
            st.update(flip_t=0.6, flip_from=st["side"] * st["b"], flip_to=-st["side"] * 30.0, open=False)
            st["chain"] = min(5, st["chain"] + 1)
    if st["mode"] == "DRIFT":
        if st["flip_t"] > 0.0:
            st["flip_t"] -= DT
            frac = 1.0 - max(st["flip_t"], 0.0) / 0.6
            signed = st["flip_from"] + (st["flip_to"] - st["flip_from"]) * frac
            st["b"] = abs(signed)
            if signed != 0.0:
                st["side"] = 1 if signed > 0.0 else -1
        elif st["open"]:
            st["b"] += (30.0 - st["b"]) * (1.0 - math.exp(-DT / 0.10))
            st["open"] = st["b"] < 28.5
        elif pressed:
            rate = 25.0 * (1.0 + 15.0 * abs(kappa(st["s"])))
            st["b"] += rate * (0.35 if 25.0 <= st["b"] <= 50.0 else 1.0) * DT
        else:
            st["b"] = max(0.0, st["b"] - 40.0 * DT)
        if st["b"] > 75.0 or (v < 6.0 and st["b"] > 45.0):
            st.update(mode="SPIN", spin_t=1.5, spin_v=v, pile=0.0, chain=1, b=0.0, open=False, flip_t=0.0)
            st["spins"] += 1
            return
        if st["b"] < 8.0 and not st["open"] and st["flip_t"] <= 0.0:
            st["low_t"] += DT
            if st["low_t"] >= 0.4:  # GRIP: the chain banks
                st["total"] += st["pile"]
                st.update(mode="GRIP", pile=0.0, chain=1, b=0.0)
                st["banks"] += 1
        else:
            st["low_t"] = 0.0
    drag = 0.3 * v * math.sin(math.radians(st["b"])) if st["mode"] == "DRIFT" else 0.0
    st["v"] = max(0.0, v + (9.0 * gas * (1.0 - v / 28.0) - drag - 1.5 * (1.0 - gas)) * DT)
    st["s"] += st["v"] * DT
    if st["mode"] != "DRIFT":
        return
    st["drift_t"] += DT
    st["drift_m"] += st["v"] * DT
    st["chain_t"] += DT
    if st["chain_t"] >= 2.5:
        st["chain_t"] -= 2.5
        st["chain"] = min(5, st["chain"] + 1)
    k = kappa(st["s"])
    wrong = abs(k) >= 1 / 60 and (k > 0.0) != (st["side"] > 0)
    if st["v"] >= 8.0 and not (strict and wrong):
        st["pile"] += st["v"] * 3.6 * angle_score(st["b"]) * st["chain"] * DT
    for i, (z0, z1, least, side) in enumerate(ZONES):
        if i not in st["zones"] and z0 <= st["s"] <= z1 and st["b"] >= least and st["side"] == side:
            st["zones"].add(i)
            st["pile"] += 300.0 * st["chain"]


def run(bot, strict=False):
    """One run. bot(t, st) -> (pressed, kick). strict: a slip on the wrong side of the bend scores 0."""
    st = {"s": 0.0, "v": 0.0, "b": 0.0, "side": 0, "mode": "GRIP", "gas": 0.0, "chain": 1, "chain_t": 0.0,
          "pile": 0.0, "total": 0.0, "low_t": 0.0, "spin_t": 0.0, "spin_v": 0.0, "open": False, "flip_t": 0.0,
          "flips": [], "zones": set(), "banks": 0, "spins": 0, "drift_t": 0.0, "drift_m": 0.0}
    t = 0.0
    while st["s"] < LENGTH and t < 45.0:
        pressed, kick = bot(t, st)
        step(st, pressed, kick, strict)
        t += DT
    if st["mode"] == "DRIFT":
        st["total"] += st["pile"]  # the run's end while drifting banks
    st["time"] = t
    return st


def can_kick(st):
    return st["mode"] == "GRIP" and st["v"] >= 30.0 / 3.6 and bend_ahead(st["s"]) != 0


def metronome(hold, lift):
    """Open loop: gas held in grip, a kick when the game allows it, then a fixed pulse for ever."""
    def bot(t, st):
        if st["mode"] != "DRIFT":
            return True, can_kick(st)
        return (t % (hold + lift)) < hold, False
    return bot


def needle(target, late, flick=True, bank_at_flips=False):
    """Closed loop: hold under `target` degrees (seen `late` s ago), lift over it."""
    seen, banked, lifting = [], set(), [None]

    def bot(_t, st):
        seen.append(st["b"])
        if st["mode"] != "DRIFT":
            if lifting[0] is not None:
                banked.add(lifting[0])
                lifting[0] = None
            return True, can_kick(st)
        v = st["v"]
        for f in FLIPS:
            if bank_at_flips and f not in banked and f - 1.6 * v <= st["s"] <= f:
                lifting[0] = f
                return False, False
            if flick and f not in st["flips"] and f - 0.2 * v <= st["s"] <= f + 0.4 * v:
                return True, True
        return seen[max(0, len(seen) - 1 - int(late / DT))] < target, False
    return bot


def bank_spam(every):
    since = [0.0]

    def bot(_t, st):
        if st["mode"] != "DRIFT":
            since[0] = 0.0
            return True, can_kick(st)
        since[0] += DT
        return (since[0] <= every and st["b"] < 40.0), False
    return bot


def hold_only(_t, st):
    return True, st["spins"] == 0 and st["banks"] == 0 and can_kick(st)


def no_kick(_t, _st):
    return True, False


BOTS = [
    ("metronome 0.40 / 0.20 s, no flick", lambda: metronome(0.40, 0.20), "5,000-6,300, passes, parked at 21-30 deg"),
    ("metronome 1.50 / 0.55 s (Lena's tip)", lambda: metronome(1.50, 0.55), "passes, 12-44 deg"),
    ("needle 42 deg, 0.20 s late, flicks", lambda: needle(42.0, 0.20), "11,000-13,000"),
    ("needle 27 deg (shallow), flicks", lambda: needle(27.0, 0.20), "more km/h than 42 deg, no ZONA"),
    ("needle 42 deg, banks at both crossovers", lambda: needle(42.0, 0.20, False, True), "4,500-5,500: Q_LINE"),
    ("needle 42 deg, never flicks", lambda: needle(42.0, 0.20, False), "as written the wrong side pays"),
    ("bank-spam every 2.5 s", lambda: bank_spam(2.5), "about 2,000"),
    ("one kick, then hold", lambda: hold_only, "spin near 2 s, total 0"),
    ("no kick", lambda: no_kick, "0"),
]


def apparent(beta, heading, pitch=40.0):
    """The on-screen angle between the travel direction and the body (orthographic, `pitch` down)."""
    sp = math.sin(math.radians(pitch))
    a0, a1 = math.radians(heading), math.radians(heading + beta)
    d = math.atan2(math.sin(a1) * sp, math.cos(a1)) - math.atan2(math.sin(a0) * sp, math.cos(a0))
    return abs(math.degrees((d + math.pi) % (2.0 * math.pi) - math.pi))


def contact_gap(beta, length=4.0, width=1.8):
    """The centre-to-centre gap along the line under which two cars at one angle overlap."""
    b = math.radians(beta)
    return min(length / math.cos(b), width / math.sin(b))


def main():
    print("Bots on Osemka (%.0f m), Q_LINE %d. Columns: total as written | total if the wrong side "
          "scores 0 | zones | banks | spins | km/h sideways | hand sum" % (LENGTH, Q_LINE))
    for name, make, hand in BOTS:
        a, b = run(make()), run(make(), True)
        kmh = a["drift_m"] / a["drift_t"] * 3.6 if a["drift_t"] > 0.0 else 0.0
        print("  %-40s %6d %-4s | %6d %-4s | %d/5 | %d | %d | %3.0f | %s" % (
            name, a["total"], "PASS" if a["total"] >= Q_LINE else "fail", b["total"],
            "PASS" if b["total"] >= Q_LINE else "fail", len(a["zones"]), a["banks"], a["spins"], kmh, hand))
    print("\nThe sticky band's attractor (PELNA): a fixed duty between the two parks the needle at 25 deg")
    lo, hi = 0.0, 1.0
    for name, k in (("crossover", 0.0), ("sweeper r 24", 1 / 24), ("hairpin r 18", 1 / 18)):
        r = 25.0 * (1.0 + 15.0 * k)
        under, inside = 40.0 / (40.0 + r), 40.0 / (40.0 + 0.35 * r)
        lo, hi = max(lo, under), min(hi, inside)
        t50 = 20.0 / (0.35 * r)
        print("  %-13s duty %.3f to %.3f | gas held from 30 deg: 50 deg at %.2f s, spin at %.2f s "
              "(M3 wants >= 1.5 s and >= 3.0 s)" % (name, under, inside, t50, t50 + 25.0 / r))
    print("  every part of the track: %.3f to %.3f (hand: 0.615 to 0.714)" % (lo, hi))
    print("\nOne true angle on the isometric camera (pitch 40), by the way the car is heading on screen")
    for beta in (20, 40, 60):
        seen = [apparent(beta, h) for h in range(0, 180, 5)]
        print("  true %d deg reads as %.0f to %.0f deg (hand: 20: 13-30, 40: 28-53, 60: 48-70)"
              % (beta, min(seen), max(seen)))
    print("\nBLISKO 1-5 m against KONTAKT (same line, same angle, 4.0 x 1.8 m boxes, centre to centre)")
    for beta in (25, 40, 50):
        print("  %d deg: boxes overlap under %.2f m (hand: 4.26, 2.80, 2.35)" % (beta, contact_gap(beta)))
    view = 34.0 * 34.0 * 2532.0 / 1170.0
    print("\nSmoke: 64 puffs, mean 3.75 m across: %.2f screens (5 m across: %.2f); the gate is 1.5"
          % (64 * math.pi * 1.875 ** 2 / view, 64 * math.pi * 2.5 ** 2 / view))
    print("Marks: 6,144 at 0.45 m on two wheels = %.0f m of path (0b.4 says about 1,800)" % (6144 * 0.45 / 2))


if __name__ == "__main__":
    main()
