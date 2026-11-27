# Critique: the drag on Aleja Zieleniecka (2026-11-25)

F: "critique with Fable the same way ... the drag race". Design only, no game code. Read:
`street_meet.gd` (the drag half: `_stage`, `hold_car`, `_drag_frame`, `_launch`, `_shift`,
`sim_run`, `rival_run`), `check_street_meet.gd`, `car.gd` `_pull` and the nitro, `night-meet.md`,
CHANGELOG, PLAYTEST P20, R11, PT-33, PT-48, PT-49, PT-50. Measured with
`docs/design/critique-drag-sim.py` (part 1 ports `sim_run` and the launch grades; parts 2 and 3
are the proposal below).

## 1. What it is now

The end of Darek's night: 402 m against Tadek's Skajlajner under a start gate. A 3, 2, 1, START!
on a fixed 0.8 s beat. On the line the gas only revs the engine (the needle climbs 0.9 a second);
at START! the needle in the blue (0.55 to 0.78) is IDEALNY START (pull ×1.7 for 1.1 s), over it
BUKSOWANIE, under it ZA MAŁO OBROTÓW. Four gears (34 / 57 / 79 / 100 % of 1.5× the car's top);
tap the rev counter or ⬆ BIEG: in the green for up to 0.35 s IDEALNIE! (×1.7 for 1.1 s), from the
yellow (82 %) DOBRZE, before it ZA WCZEŚNIE (a bog). The car steers itself. Two nitro bottles on
loan. Tadek drives a recorded profile: the "ok" run of your own car, sped up halfway to a clean
one. Win: 300 zł, 80 respect, the club card. Lose: REWANŻ, free, as often as you like.

## 2. The critique

Tadek's time for the starter car is 11.85 s.

| The run (today's rules) | Time | Against Tadek |
| --- | --- | --- |
| Perfect launch, three IDEALNIE | 10.43 s | wins by 1.43 s |
| Perfect launch, **a tap the moment the yellow shows**, three times | 10.65 s | wins by 1.20 s |
| Perfect launch, three shifts 0.6 s late | 11.59 s | wins by 0.26 s |
| Bogged launch, three IDEALNIE | 11.15 s | wins by 0.70 s |
| Bogged launch, three shifts 0.9 s late, the bottles from 1 s | 10.13 s | wins by 1.73 s |
| Three IDEALNIE, the bottles from START! | 7.98 s | wins by 3.88 s |
| No taps at all | 14.06 s | loses by 2.20 s |

- **Tadek is not a rival.** His time was built for a player with a 0.3 s reaction and no launch
  bonus. Since the launch rework (2026-11-09) the car leaves on START! by itself with a burst, and
  Tadek never got one. To lose you need a bad launch and late shifts together.
- **Timing is worth 0.22 s.** The pull fades as the needle nears the gear's top
  (`1 - 0.6 × speed / cap`), so shifting early loses nothing, and DOBRZE has no bog. Mashing at the
  first yellow is as fast as three perfect shifts. The green band is decoration.
- **The launch is solved on the second run.** A fixed beat and a fixed climb: press at "1", the
  needle stops at 0.72, blue every time. Nothing to read.
- **All the play is in the first 2.5 s.** The shifts come at 0.9, 1.7 and 2.5 s. Then about 8 s in
  fourth with nothing to do, the last of it flat at 162 km/h (PT-33 saw 5 s flat): three quarters
  of the run.
- **The nitro is the win button.** Two bottles are 5 s of ×2.2 pull in an 11 s run. The check asks
  that nitro beats Tadek; nothing asks that it doesn't beat him asleep.
- **He is a ghost on rails.** The same run every time, no mistake, no tell, no answer to you. And
  no gap on screen: you learn who won at the line.
- **The card lies a little.** "reakcja" is the time to roll 0.5 m, not a reaction.
- **No stake, no ladder.** A win ends the story; `wnrc_wins` is counted and never read. A loss
  costs nothing and REWANŻ is free, so the only tension is the first run.
- **Unverified.** PT-48 and PT-50 were fixed in code and never re-run in Autopilot; PT-49 (the
  first-10 note over the rev counter) is a suspect; the phone check of the rev counter under a
  thumb is still open in BACKLOG.

Right and staying: the gate and the count, the car holding the strip, one big button where the gas
is, the hush on the HUD, the launch word in the count's place, 12 seconds.

## 3. Physics and feel fixes

### 3.1 Five gears that fill the run

Taller gears pull less, so the shifts spread over the whole strip and the car is still
accelerating at the line.

| Name | Now | New |
| --- | --- | --- |
| `DRAG_TOP` | 1.5 | 1.87 (top 56 m/s for the starter car) |
| `GEARS` | 0.34, 0.57, 0.79, 1.0 | 0.26, 0.44, 0.62, 0.81, 1.0 |
| `GEAR_PULL` (new, × the car's pull) | 1 in every gear | 1.0, 0.60, 0.40, 0.29, 0.22 |
| Shifts in a perfect run | 0.9, 1.7, 2.5 s | 0.9, 2.1, 4.5, 8.5 s |
| A perfect run, the speed at the line | 10.43 s, 162 km/h flat | 11.51 s, 179 km/h and rising |

`sim_run` and the real car take the same two arrays (the check already holds them within 0.3 s).

### 3.2 The shift: a green band that is worth hitting

```
k = speed / the gear's cap;  w = seconds since k reached SHIFT_AT (0.96)
k <  0.82            ZA WCZEŚNIE  pull x0.55 for 0.9 s
0.82 <= k < 0.96     KRÓTKO / SHORT  pull x(0.55 + 0.45 * (k - 0.82) / 0.14) for 0.7 s   # new: the yellow costs
w <= PERFECT 0.12    IDEALNIE!    pull x1.7 for 1.1 s          # was 0.35 s
w <= GOOD 0.35       DOBRZE       nothing
w >  0.35            ZA PÓŹNO     pull x0.8 for 0.5 s, on top of the time lost on the limiter
```

The needle sweeps the last 4 % in about 0.1 s in first gear and 1 s in fourth, so the dial draws
each gear's green as the stretch the needle covers in the 0.12 s after 0.96 (then a white DOBRZE
stretch to 0.35 s, then red): what is green is always IDEALNIE. Three perfect in a row light the
dial's rim ("SERIA ×3"), and the fourth then gives ×1.9.

| The run (new rules, no bottle) | Time |
| --- | --- |
| Perfect launch, four IDEALNIE | 11.51 s |
| Perfect launch, two IDEALNIE and two DOBRZE | 11.91 s |
| Perfect launch, four DOBRZE | 12.67 s |
| Perfect launch, a tap at the first yellow, four times | 13.27 s |
| Bogged launch, four DOBRZE | 13.39 s |
| No taps | 15.64 s |

Timing is now worth 1.8 s between the masher and the clean hand, where it was 0.2 s.

### 3.3 The launch: a needle you have to catch

The beat stays (F: an arcade count, no random hold). `REV_UP` 0.9 → 1.3, `REV_DOWN` 1.4 stays, and
over 0.85 the needle bounces off the limiter (falls to 0.70, climbs again). Pressing at "1" now
overshoots into BUKSOWANIE; the launch is a press about half a second before START! or a feathered
gas, in a window 0.18 s wide. The blue zone narrows by night: 0.55-0.78, 0.58-0.77, 0.61-0.76,
0.64-0.75. The card shows the launch's word, not a "reaction".

### 3.4 One bottle, and where it bites

- One bottle (2.5 s), not two. In the drag the nitro is pull ×1.6 and top ×1.15 (the strip only;
  the city's ×2.2 and ×1.3 stay).
- In first or second gear the tyres can't take it: BUKSOWANIE, the bottle is gone.
- Fired within 0.4 s after an IDEALNIE: "STRZAŁ!" / "SHOT!", the burn lasts 3.2 s.
- Night 1 has no bottle on either car (Darek: „Butla jest na drugą noc.” / "The bottle's for night
  two.").

| Four IDEALNIE and the bottle | Time |
| --- | --- |
| In first gear (wheelspin) | 11.95 s (slower than no bottle) |
| Into third | 10.47 s (10.34 s as a STRZAŁ) |
| Into fourth | 10.91 s |
| Into fifth | 11.37 s |

Early is strongest, but it needs the IDEALNIE into third at 2.1 s, the hardest window of the run.
Miss it and the choice is real: burn it plain now, or wait for the shift into fourth.

### 3.5 Tadek drives the same car by the same rules

`rival_run` stops scaling a recording. Tadek's run is `sim_run` with his own inputs, rolled once
at the line from the night's row and a seed, and **shown**: his launch (smoke for wheelspin), his
shifts (the nose dips, the exhaust pops; a late one coughs a puff of black), his bottle (a blue
flame). His profile is still a 30 Hz distance table, so the frame cost is unchanged.

| Night | His launch | His shifts (s after the green) | His bottle | His time | What beats him |
| --- | --- | --- | --- | --- | --- |
| 1 | plain, 0.15 s late | about +0.22 each | none | about 13.2 s | four DOBRZE (12.67 s); the masher (13.27 s) loses |
| 2 | plain, 0.10 s late | +0.15 | into third | 12.50 s | four DOBRZE and the bottle into third or fourth (11.97 / 12.29 s); the masher with a bottle (12.66 s) loses |
| 3 | perfect | perfect, +0.2, perfect, +0.2 | into fourth | 11.41 s | two IDEALNIE and the bottle into third (11.09 s); one is not enough (11.50 s) |
| 4 and on | perfect | three perfect, one +0.2 | into third | 10.81 s | four IDEALNIE and the bottle into third (10.47 s); three tie him |

His mistake: on nights 1 to 3, a 25 % chance of one shift 0.9 s late (the black puff; worth about
0.1 to 0.4 s by the gear), 40 % if you are ahead at that shift. On night 4 he makes none. The
check pins the four times (±0.1 s) and the "what beats him" column, for the starter car and the
best garage car.

### 3.6 The gap on screen

A thin bar over the rev counter: your car and his as two marks, the gap in car lengths ("+1.5"
green, "-0.5" red), from 60 m on. It replaces nothing and keeps the hush.

## 4. The fun set

| # | What | Next version | Cost |
| --- | --- | --- | --- |
| 1 | Tadek on the same model with the four nights' table (3.5), read from `wnrc_wins` | in | M |
| 2 | Five gears with a pull each (3.1) and the new grades with KRÓTKO (3.2) | in | S (two arrays, one grade, the tacho's fifth mark) |
| 3 | The launch needle (3.3) | in | S |
| 4 | One bottle, wheelspin in low gears, STRZAŁ! (3.4) | in | S |
| 5 | His tells: launch smoke, the shift's nose dip, the black puff, the blue flame | in | S (his node's pitch, two particle bursts on the existing smoke) |
| 6 | The gap bar (3.6) and SERIA ×3 on the dial | in | S |
| 7 | Juice: a 50 ms hit-stop and a 3 % zoom kick on IDEALNIE, the gate's lights strobing in the mirror, the street lamps as a rhythm at 180 km/h, the crowd's phones along the first 60 m flashing at START! and running to the kerb on a win | in (the hit-stop and zoom), out (the crowd run) | S / M |
| 8 | The stake: the night's pot, doubled on a win, halved on a loss (critique-night-quest.md 3.1). REWANŻ after a loss costs half of what is left | in, with the night quest's pot | S |
| 9 | The photo finish: under 0.15 s apart the last 20 m run at half speed and the card says "O ZDERZAK!" / "BY A BUMPER!" | in | S |
| 10 | Other lanes: Lena on night 3 in a pink Porszę (launches perfectly every time, shifts late), Darek's Bawarka as the easy rematch any night | out | M |

On-screen words (new): KRÓTKO / SHORT, SERIA ×3 / STREAK ×3, STRZAŁ! / SHOT!, O ZDERZAK! / BY A
BUMPER!, Tadek on night 2: „Dziś mam butlę. Ty też. Zobaczymy, kto umie.” / "Tonight I've got a
bottle. So do you. Let's see who can use it."

## 5. Build plan and what only the phone shows

1. Items 2, 3, 4: constants and grades in `street_meet.gd`, mirrored in `sim_run`; the tacho's
   fifth gear. `check_street_meet`: the table of 3.2 within 0.15 s, "a tap at the first yellow
   loses to four DOBRZE by over 0.4 s", "a bottle in first is slower than none".
2. Item 1 and 5: `rival_run(night, seed)`, the tells, the check's four nights.
3. Items 6, 7, 9, then 8 with the night quest.
4. Re-run PLAYTEST P20's drag in Autopilot (PT-48, PT-49, PT-50 are still to confirm) and run
   `python3 -I docs/design/critique-drag-sim.py` against the check's printed times.

Full definition of done (per-frame gameplay): verify, shots of the line and the card, bench at the
gate.

Only the phone shows: whether a 0.12 s green can be hit with a thumb in first gear at 60 fps (if
not, widen first gear's alone to 0.18 s); the feathered launch with the gas under the same thumb
as BIEG; whether the gap bar is readable over the dial; the hit-stop (a kick or a stutter?); the
tells on a car 3 m away at the iso scale.

## Open questions (parked; the default is what this specifies)

- Night 1 with no bottle changes "NITRO works (a bottle on loan)". Default: no bottle on night 1,
  one from night 2.
- A player who already won on today's rules holds the club card. Default: the card stays, and the
  ladder starts them at night 2.
