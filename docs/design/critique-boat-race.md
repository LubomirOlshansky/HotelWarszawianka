# Critique: the boat race "Wiślana Szprotka" (2026-11-25)

F: "critique with Fable the same way the quest 'Wiślana szprotka' with the boats". Design only, no
game code. Read: `boat_race.gd`, `boat.gd`, `game/data/boat_race.json`, `boat-race.md`,
`quest-map.md`, PLAYTEST P19, R11, PT-31, PT-32, PT-53. Measured with
`docs/design/critique-boat-sim.py` (a port of `boat.gd` `step()` for the runabout, driven through
the baked rings; no banks, waves or rivals).

## 1. What it is now

Szymek calls by day (or waves at the pontoon at Port Czerniakowski). Four boats race 3.5 km down
the Vistula under four bridges: 30 orange rings 24 m wide (a median 87 m apart, the line turning
4 to 40° at each), 3 gold rings 9 m wide, 10 floating ramps, the sand barge coming up the right
bank, a 60 m finish arch. The car's own controls drive the boat. Three missed rings and you are out
(JESZCZE RAZ from the grid, or WYJDŹ).

| Thing | Value (`boat_race.gd`, `boat.gd`) |
| --- | --- |
| Runabout | top 39.9 m/s (145 km/h), pull 12.4 m/s², turn 2.0 rad/s, grip 1.1 → 3.2 /s, the rudder 30 % weaker from 24 to 44 m/s |
| Rhythm | +3 % top a ring in a row, to +15 % at five; any miss resets it |
| Gold ring / ramp / slipstream | +18 % for 2.5 s / +12 % for 1.8 s / +9 % behind a boat (3 to 28 m, within 3.4 m of its line) |
| Rivals | Szymek 0.975 pace, Pan Zdzisiek's tub, Kamil's jet ski 0.96 with a show-off; mistakes 0 to 3.5 % a ring; rubber band ±8 % past 45 m, off screen only |
| Pay | 150 / 60 / 25 / 0 zł, 40 / 15 / 5 / 0 respect. No best time is kept |
| Length | about 88 s on the rivals' driver (`check_boat_race` allows 60 to 150 s) |

## 2. The critique

| What the design says | What the numbers say |
| --- | --- |
| "Rings you must go through, miss three and you lose" | Full gas from the grid to the arch, aiming at each ring's middle, never braking: **0 misses, the worst pass 3.2 m off centre in an opening 11.6 m to each side**. With the top speed ×1.5 (a 215 km/h top): still 0 misses, 4.7 m off. The rule that names the game never bites a player who can steer, and the brake has no use |
| "The rhythm: rings in a row raise top speed, a miss resets it" | With no misses the meter is full at ring 5 and stays full: a constant +15 %; with the three gold rings it is worth 8.6 s (97.0 → 88.4 s). Not a meter, a number |
| "Gold rings off the slalom" | They sit on the line, right past each crossing's ramp: no detour, no risk |
| "Ramps, slipstream" | Mac Autopilot never took a ramp and never saw the slipstream toast in two full races (R11, PT-53). The juice is there for the rivals' driver, not for a hand |
| "A close pack" | Close for the rivals' driver (all four within about a second). Autopilot was **4th of 4 both times** (248.6 s and 207 s at the old speed). Past 45 m the rubber band gives ±8 % out of sight: a 300 m gap closes at 3 m/s, so never. A beginner races alone for a minute and finishes for 0 zł |
| The only skill left | A 0.15 s late thumb costs 4.3 s (92.7 s) through the turn's speed bleed. Smoothness wins, and nothing on screen shows it |

And from the code and the playtest rows:

- **Floaty.** Sideways slip fades at 3.2 /s (0.3 s), up to 10 m/s of slide in the sim, the yaw
  follows the thumb with a 0.17 s lag, the rudder weakens at speed. At 145 km/h the hull answers
  the same as at 60: nothing marks the speed but the banks going by.
- **Unfair.** `_hit` multiplies the speed by 0.92 on every frame of contact: half a second along a
  bank at 60 fps leaves 8 % of the speed. A brush is a dead stop. And the third miss throws away
  the whole 88 s.
- **Confusing.** The next ring sits behind the race panel as the boat runs up the screen (PT-31);
  after a miss no ring is on screen for 1.5 s and there is no edge arrow on the water (PT-32).
- **Nothing to come back for.** No record, no target time, the same rivals at the same pace, the
  same 150 zł. REWANŻ is the same race.
- **Exploit.** None that pays; the dull one is the honest one: hold the gas, point at the next ring.

Right and staying: the car's controls, the river's own line under the real bridges, three rivals
with a temper each, the barge, rubber band only out of sight, the length.

## 3. Physics and feel fixes

### 3.1 Every ring gets an inside buoy (the risk on each gate)

A ring is two buoys. The one on the side of the next ring is the **inside buoy** (gold cap, the
other stays orange). Width `RING_W` 24 → 20 m.

```
across = signed offset from the ring's centre, positive towards the inside buoy
half   = RING_W / 2 - 0.4                      # 9.6
across >  half                 -> PUDŁO (a miss, as now)
across >= half - INSIDE_R      -> "PO BOI!" / "BUOY LINE!": rhythm +2, INSIDE_BOOST 1.06 for 1.5 s
otherwise                      -> a pass: rhythm +1
INSIDE_R = 3.5 m
```

The fast line and the miss now sit 3.5 m apart on every gate. Szymek aims for it (`line` 0.15 →
0.55 on the inside) and misses 4 % of rings; Pan Zdzisiek never tries; Kamil's line stays wide.

### 3.2 The rhythm becomes a meter

| Name | Now | New |
| --- | --- | --- |
| `RHYTHM_MAX` | 5 | 8 |
| `RHYTHM_STEP` | 0.03 | 0.025 (full: +20 %) |
| A miss | resets to 0 | -4 |
| A bank or pier hit over 4 m/s, a hard landing | nothing | -2 |
| Braking over 0.6 s | nothing | -1 |

Drawn as eight pips by the place badge, the last three gold. A clean line through plain rings
fills it by ring 8; buoy lines fill it by ring 4. It is now something to lose and to win back.

### 3.3 Four hard gates and a slide to take them

`tools/boat_course.py`: before each of the three crossings and before the finish, one pair of
rings 55 m apart with the line turning 65 to 75° (`HARD_GATES`, eased rule skipped for them, marked
with a red chevron board on the outside buoy). Target, checked in the sim after the bake: **full
gas with centre aim misses at least two of the four; a lift or a slide clears all four**.

The slide (brake tapped while steering over 60 % and over 18 m/s):

```
sliding (while the brake is held, at most SLIDE_MAX 0.9 s):
    grip      = 1.0            # was 3.2 on the plane: the stern steps out
    turn      *= 1.45
    BRAKE     = 3.0            # instead of 9.0: it scrubs, it doesn't stop
    bleed     *= 2.0
on release, if the heading is within 20° of the next ring's bearing:
    "ŚLIZG!" / "SLIDE!": SLIDE_BOOST 1.05 for 1.0 s, rhythm +1
```

The rivals' driver slides at a hard gate when its `turn` there is over 1.0 rad (Kamil always,
Szymek 70 %, Pan Zdzisiek lifts instead).

### 3.4 Banks scrub, they don't stop

```
first frame of a contact (_contact was 0):  vel -= n * into * (1 + PUSH);  vel *= 0.90
every later frame of the same contact:      vel *= exp(-BANK_SCRUB * dt)      # BANK_SCRUB 0.9 /s
```

Half a second on a bank now leaves 57 % of the speed (was 8 %). Piers keep the hard first hit.

### 3.5 Speed you can feel (view only)

- From 85 % of the top: the camera pulls back 10 % and looks 14 m further ahead (eased over 0.5 s),
  white streaks in the foam layer (the same draw call), the hull's bow drops 2° and chatters
  (pitch noise 0.6° at 9 Hz), a light buzz every 0.25 s.
- Any boost: the spray plume doubles, the engine pitch +12 %, the pips flash.
- PT-31: the race panel shrinks to one line while racing (place, clock, pips, misses). PT-32: an
  edge arrow to the next ring whenever it is off screen, in the ring's orange.

### 3.6 The third miss

Out stays F's rule. Two changes: ten rings in a row with no miss give one miss back
("ODZYSKANE!" / "MISS BACK!"), and ODPADASZ! offers **OD PRZEPRAWY** / FROM THE CROSSING first:
the state of all four boats, the barge and the clock is saved at each crossing's mid-river ring and
restored with +5 s on the player's clock and the misses at 1. JESZCZE RAZ and WYJDŹ stay.

### 3.7 The pack stays with a slow player (out of sight only)

`RUBBER` 0.08 → 0.14 for a rival **ahead** of the player by more than 90 m and off screen (0.08
stays behind the player and from 45 to 90 m). `DRAFT_AHEAD` 28 → 40 m, `DRAFT` 0.09 → 0.11, and
the slipstream draws two faint lines in the foam behind every boat ahead, so the player sees where
to sit.

## 4. The fun set

| # | What | Next version | Cost |
| --- | --- | --- | --- |
| 1 | The inside buoy (3.1): PO BOI! on every gate | in | S |
| 2 | The rhythm meter with pips (3.2) | in | S |
| 3 | Banks scrub (3.4), the edge arrow and the slim panel (3.5) | in | S |
| 4 | A record: `wallet.record("boat_szprotka", time)`, Szymek's time to beat on the card, the gap to the record at each crossing ("-1.2 s" green, "+0.8 s" red) | in | S |
| 5 | Rival tells. Szymek looks back and his wake lines bend 0.6 s before he blocks; Kamil lifts his phone (a white square over his head) 0.5 s before the show-off; Pan Zdzisiek's tub throws a 0.5 m wake that is a free hop for whoever follows him | in | S |
| 6 | Hard gates and the slide (3.3) | in | M (a re-bake of the course, the rivals' driver, the check's seeds) |
| 7 | FROM THE CROSSING (3.6) and the pack that waits (3.7) | in | M |
| 8 | A span to choose under Most Poniatowskiego: two rings side by side, the narrow span's 9 m wide and 1.2 s shorter, either counts | out (after 6: the bake again) | M |
| 9 | The boulevards watch: on the Powiśle bank run within 25 m of the bank, a crowd cheer and phone flashes, louder with the meter (sound and the existing crowd, no new people) | out (needs a bench on the phone first) | S |
| 10 | Szymek's ladder: after each win he comes back a step quicker (pace 0.975 → 1.0 → 1.02, then the "Szprotka II" paint), the loser buys the ice cream, Kamil posts your misses on TYGRAM | in (words and three numbers) | S |

Cost: S is up to half a day for a coder, M one to two days, L three or more.

On-screen words (new): PO BOI! / BUOY LINE!, ŚLIZG! / SLIDE!, ODZYSKANE! / MISS BACK!, OD
PRZEPRAWY / FROM THE CROSSING, REKORD / RECORD, Szymek: „Po boi, nie po mnie!” / "Round the buoy,
not over me!".

## 5. Build plan and what only the phone shows

1. S items 1 to 5 and 10 in one PR (no re-bake): `boat_race.gd`, `boat.gd` `_hit`, the panel, words.
   `check_boat_race` gains: a buoy-line pass raises the rhythm by 2; half a second on a bank keeps
   over half the speed; the record is written; the autopilot still finishes with 0 misses.
2. The hard gates and the slide (6): re-bake `boat_race.json`, run
   `python3 -I docs/design/critique-boat-sim.py game/data/boat_race.json` (it must show misses at
   full gas), then the check with 12 seeds.
3. The restart and the pack (7). Then 8 and 9.

Full definition of done (per-frame code, geometry): verify, shots, bench at the pontoon and mid-race.

Only the phone shows: whether a 3.5 m buoy band can be hit with a thumb at 145 km/h at the iso
scale; whether the slide's brake tap is reachable while steering; the camera pull-back (sick or
fast?); the edge arrow against the HUD; the buzzes; the frame with ten ramps and the streaks.

## Open questions (parked; the default is what this specifies)

- The rhythm losing a pip for braking: a fair nudge to stay on the gas, or a punishment for
  careful players? Default: built, -1 after 0.6 s.
- OD PRZEPRAWY softens F's "miss three and you lose". Default: built, with +5 s and one miss kept.
