# Beer pong v2, physics and fun: the second pass (addendum, 2026-11-25)

F: "take from Fable once more a critique of how to make the physics and the game interesting, and
then do everything to the end." This is that critique and the improved design. Design only, no
game code. **Where this differs from `tapczan-pong-v2.md`, this wins** (its section 3 rules, its
constants, its sim API, its check). The look, the palette, the room UI, the tap list and the
wiring of that brief stand as they are.

| File | What |
| --- | --- |
| `tapczan-pong-v2-physics-sim.py` | the reference sim: a deterministic 60 Hz `Sim` with real ball flight, the bots, every table below. `game/scripts/pong_sim.gd` is ported from it |
| `tapczan-pong-v2-sim.py` | the first pass's balance prototype, kept as the record the critique measured |

No new mocks: mocks 2 and 3 still show the screen. The new things to draw are listed in 5.3.

## 1. The critique of the first design

Measured on the first prototype (`tapczan-pong-v2-sim.py`, 20 000 throws or 6 000 matches a cell,
the "decent" 48 ms thumb) and by reading its own model.

| What I claimed | What the numbers say |
| --- | --- |
| "Which cup: the far cup is the slow one" | A throw takes a cup 0.49 / 0.53 / 0.53 / 0.53 / 0.54 of the time for cups 1 to 5. **The choice is worth nothing.** A 48 ms thumb lands 5 to 7 px off, a cup is 5 px wide and 14 px from the next, so the neighbours catch the errors of a middle aim. One strategy, and it barely beats any other |
| "Breath: hold for a steadier hand" | Holding lifts the take from 0.47 to 0.54 on the far cup and **by nothing on the three middle cups**. And it costs nothing, so it is not a decision: always hold. The breath bar is a bar the player has no reason to read |
| "A clean hit feels earned" | CZYSTO (within 1 px) comes on 14 to 16 % of throws whatever the aim. It is a lottery prize |
| "Timing is the skill" | A thumb that taps at a random moment takes a cup on **0.29** of throws at a full rack, against 0.53 for the careful one. Half the result is where the cups happen to be |
| "Eight rounds, then last orders, then sudden death" | **0 to 2 %** of matches reach the bell. Two rules that never happen |
| The end of a match | It gets harder as you win: 0.46 a throw at the re-racked pair, 0.40 at the last cup (they sit mid-swing, where the ring is fastest). The finish drags; the rival's dice decide it |
| "Idle wins 0 %" | Only because the prototype hard-coded an idle throw as a miss. The shot clock throws the ball wherever the ring is: an idle phone would have taken cups |
| The rival's turn | Dice: `p_in`, `p_rim`. Nothing flies, so nothing can be read, and a rim is a number, not a ball on a lip |
| Gienia's nudge, the flick | Rolled as chances in the prototype, so the numbers never tested whether a player can see them coming |

And what no number shows, from playing it in my head with one thumb:

- **Floaty.** The ball "lands where the ring was" along a drawn arc. No weight, no bounce, no rim:
  the result is a lookup of one distance. The eye sees a ball, the hand feels a slot machine.
- **Dull by the third round.** Every throw is the same throw. Nothing to choose, nothing to risk,
  no way to come back from two cups down except to wait for luck.
- **Unfair in feel.** Losing a cup to a number you cannot see reads as cheating. So does a spinner
  that is "flicked 85 %".
- **Exploit.** None that wins, but one that bores: wait at the far end of every swing. The shot
  clock is the only thing that ever hurries the player.

What was right and stays: one finger, hold and let go; the side view; rivals that differ in what
they do; drinks that cost aim; the pixel look; 55 seconds.

## 2. The physics

A hand-written 2D integrator and five analytic collisions. No rigid bodies, no engine physics.
Pure, deterministic, a fixed 60 Hz step, driven by two booleans a tick: `finger` (down) and `low`
(dragged down, section 3.3).

### 2.1 One rule above the rest: the ring is the truth

**The gold ring's offset from a cup's centre at the moment of release is the only aim error.**
The sim solves the launch so that the ball comes down through the mouth plane exactly at the
ring. From there everything is physics the player can watch. If the ring was on the cup, the ball
goes in, every time.

### 2.2 The table, in the thrower's frame

Units: canvas px and seconds. `x` runs along the table towards the rack being thrown at, 0 at the
first cup's centre in a full rack; `y` is up from the table top. Every throw (yours and the
rival's) is computed in this frame; the view mirrors the rival's.

```
  y
 64 |             . ' ' ' ' .                 a lob: apex 64, 0.73 s in the air
 44 |      . ' ' ' .          ' .             a bounce throw: apex 44, flatter, 0.56 s to the table
 34 |  o hand (-150, 34)  ' .     ' .
    |                        ' .    '.             mouth plane, y = 13
 13 |- - - - - - - - - - - - - -'.- - -\- - +---+ - +---+ - +---+ - +---+ - +---+
    |                             '. /'\ \  |   |   |   |   |   |   |   |   |   |   cup: body +-4.5,
  0 +------------------------------'X'----\-+---+---+---+---+---+---+---+---+---+-- lips +-4, tall 13
   -190            hand -150      bounce   \  0      14      28      42      56          table to 93
                                  point x_b
```

```
 the mouth plane of one cup, d = ball centre - cup centre (a lob; the in-zone is x0.85 for a bounce)

   -5.5       -3.75      -2.0   -0.8   0   +0.8   +2.0      +3.75       +5.5
     |   tick   |   spin   |  in  |  CZYSTO  |  in  |   spin   |   tick   |    beyond: the cup's
     | skips    | drops    |      | ball back|      | drops    | skips on |    side, or the table
     | back     | .67-.05  |      |          |      | .83-.18  |          |
```

### 2.3 Constants

| Name | Value | What |
| --- | --- | --- |
| `HZ` | 60 | the step. Positions use the exact parabola inside a step, so 60 is enough |
| `G` | 600 px/s² | a lob lasts 0.73 s. True gravity at this scale (1 px is about 0.9 cm) would be 0.5 s: too fast to read on a phone |
| `BALL_R` | 1.5 | the 3x3 ball |
| `HAND_X`, `HAND_Y` | -150, 34 | where the ball leaves the hand |
| `TABLE_LO`, `TABLE_HI` | -190, 93 | the table top (283 px) |
| `CUPS`, `PITCH` | 5, 14 | a row seen from the side |
| `RIM_Y` | 13 | the mouth plane |
| `CUP_HALF` | 4.5 (tasting glass 3.5) | the body's half width |
| `IN_R` | 2.0 (glass 1.2) | a drop: the lips are at ±4, less the ball's 1.5, less half a pixel of lip |
| `RIM_R` | 5.5 (glass 4.0) | the ball touches a lip |
| `SPIN_S` | 0.5 | the inner half of the lip zone catches the ball (a spin); the outer half skips it off |
| `CLEAN_R`, `CLEAN_HEAT` | 0.8, +0.3 a heat point | CZYSTO: the ball comes back, once a turn |
| `K_BOUNCE` | 0.85 | a ball coming in flat off the table sees a mouth this much smaller |
| `A_LOB`, `A_BOUNCE` | 64, 44 | the apex of the two throws |
| `E_TABLE`, `F_TABLE` | 0.62, 0.80 | the table's bounce: vertical speed kept, forward speed kept |
| `E_SPENT` | 0.30 | the table's bounce for a ball that has touched a cup: it dies in one or two tocks |
| `E_CUP` | 0.35 | off a cup's side |
| `SKIP_UP`, `SKIP_ON`, `SKIP_BACK` | 0.35, 0.45, -0.25 | a skip off a lip: the hop, and the forward speed kept off the far lip / the near lip |
| `FLUKE_IN` | 0.6 | a ball that has already touched something sees a mouth this much smaller |
| `P_RIM_0`, `P_RIM_S`, `P_RIM_SIDE`, `P_RIM_FLAT` | 0.75, 0.65, 0.08, 0.25 | the spin's odds (2.5) |
| `T_SPIN_0`, `T_SPIN_S` | 0.50, 0.45 s | a spin lasts 0.5 s plus up to 0.45 s by how far out it caught |
| `SLIDE_PER_V`, min, max | 1/110, 0.5, 2.5 px | a ball on a cup's side shoves the cup |
| `MIN_GAP` | 9 | two cups never closer than touching |
| `V_REST`, `MAX_BOUNCES`, `MAX_FLIGHT` | 35 px/s, 3, 3 s | when a ball is dead |

Derived once at load: `LOB_VY` 189.7, `LOB_T` 0.729 s; `BNC_VY` 109.5, `BNC_T1` 0.559 s (hand to
table), `BNC_T2` 0.360 s (table to mouth).

### 2.4 Flight

```
launch(x_t, low):                      # x_t = the ring at release (or the rival's aim point)
    if low:  vx = (x_t - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2);  vy = BNC_VY
    else:    vx = (x_t - HAND_X) / LOB_T;                         vy = LOB_VY
    ball = {x: HAND_X, y: HAND_Y, vx, vy, low, fresh: true, bounces: 0, age: 0}

flight_tick():                         # one 1/60 s
    rem = 1/60
    repeat at most 8 times:
        t_rim = time until y comes DOWN through RIM_Y     # (vy + sqrt(vy² + 2G(y - RIM_Y))) / G, none if the root is < 0
        t_tab = time until y comes DOWN through BALL_R    # the same with BALL_R
        t = min(t_rim, t_tab, rem)
        x += vx*t;  y += vy*t - G*t²/2;  vy -= G*t;  rem -= t          # exact, not Euler
        if t == t_rim:  if at_mouth(): return                          # 2.5: in, spin, skip, or nothing
        elif t == t_tab: if on_table(): return                         # 2.6
        walls()                                                        # 2.7
        if rem == 0: break
    if y < -30 or age > MAX_FLIGHT*HZ: ball is dead (a miss)
```

The exact parabola matters: plain Euler at 60 Hz lands 3 to 4 px off the ring, which would break
2.1. With it, the mouth-plane crossing equals `x_t` to a thousandth of a pixel (the check tests
this).

### 2.5 At the mouth

When the ball's centre crosses `RIM_Y` going down, take the nearest cup; `d` = ball − centre,
`a = |d|`, `k = K_BOUNCE` if the ball has bounced off the table, else 1.

| Case | Condition | Result |
| --- | --- | --- |
| **Clean drop** | fresh ball, `a <= IN_R * k` | in. CZYSTO if `a <= (CLEAN_R + CLEAN_HEAT*heat) * k` on a lob: the ball comes back once a turn, with 0.4 s of breath |
| **Bounce-in** | the same, and the ball came off the table first | in, **and the cup tips into its neighbour, which goes too** (the one behind, else the one in front): Z ODBICIA, two cups. No ball back |
| **Spin** | fresh ball, `s = (a - IN_R*k) / (RIM_R - IN_R*k) <= SPIN_S` | the ball leaves the integrator and rides the rim for `T_SPIN_0 + T_SPIN_S * s/SPIN_S` s. It drops in with `p = P_RIM_0 - P_RIM_S * s/SPIN_S ± P_RIM_SIDE (far lip +, near lip −) - P_RIM_FLAT * (1 - k)`, clamped to 0.05..0.95, rolled **now** from the sim's seeded generator. So a lip kissed from inside drops 3 in 4, one caught at the edge 1 in 10; the far lip is kinder than the near one. If not: it tips off on the side it caught (`vx = ±45 + 0.15 * vx_in`, `vy = 55`) and is a live, spent ball again. A rim-in is one cup, also for a bounce throw |
| **Tick** | `s > SPIN_S`, or any second touch | no spin: the ball skips off the lip (`vy = SKIP_UP * fall speed`, `vx *= SKIP_ON` far lip or `SKIP_BACK` near lip), spent. Slower than 25 px/s it just rolls off |
| **Fluke** | a spent ball with `a <= IN_R * k * FLUKE_IN` | in: FUKS, one cup. About 1 in 14 matches |
| Nothing | further out | the ball falls on: a cup's side or the table |

The defender can take a spinner out (the flick, as in the first brief): the rival by their `flick`
chance, shown as a puff at 60 % of the spin; you by one tap while the ball passes the gold tick
(at 0.25 s and every 0.40 s after, ±0.085 s; one tap, on the tick or wasted).

The spin is an animation over a result already decided: the ball circles the mouth (x = centre +
3.5·cos, 0.4 s a lap, the far half drawn behind the lip), a `pong_rim` tick each half lap, the
laps slowing. It reads as physics because the contact chose the odds and the side it leaves by.

### 2.6 The table

A ball reaching `y = BALL_R` between `TABLE_LO` and `TABLE_HI`: `vy = E_TABLE * |vy|` (`E_SPENT`
for a spent ball), `vx *= F_TABLE`, one `pong_bounce`. Dead after `MAX_BOUNCES`, or when the hop
would be slower than `V_REST`. Past the table's end it falls to the floor.

**The bounce shot** is this rule and nothing else: a `low` throw is solved to hit the table at
`x_b = x_t - F_TABLE * vx * BNC_T2` and come down through the ring after one hop of 50 to 70 px
that tops out 3 px over the lips. It reaches the first two or three standing cups; aimed further,
the hop runs into the front cup's side (the preview shows it, 5.3). On that first bounce the
rival may swat it (3.4).

### 2.7 Cups: sides, shoves, the domino, the re-rack

- **A cup's side.** A ball below the mouth plane within `CUP_HALF + BALL_R` of a centre is put
  back on the side it came from, `vx *= -E_CUP`, spent. The cup is **shoved** the ball's way by
  `clamp(|vx| * SLIDE_PER_V, 0.5, 2.5)` px, stopped by the next cup (`MIN_GAP`, a `glass_clink`)
  or the table's end. It rocks one pixel for 0.3 s and throws foam. Cups never fall to a ball:
  I measured a counted knock-over and its target band came out wider than the mouth, which turns
  the game into "aim short". Shoved cups bunch up and change the swing's rhythm; that is the
  point of them.
- **Cup to cup.** A bounce-in tips the cup into its neighbour and both are taken (2.5): the one
  place a cup knocks a cup over.
- **Re-rack.** At two cups a side closes up once to x = 21 and 35 (PRZESTAWIAMY KUBKI, 0.7 s).
- A ball that falls between two cups rattles between their sides (2 px of room) and dies:
  `pong_bounce` twice, quick.

### 2.8 Cost

- State: 4 floats and 3 small ints for the ball, 5 floats a rack, about 20 scalars of match
  state. Nothing allocated in a tick.
- A throw: 57 flight ticks on average, 105 at most seen (the cap is 180). A tick: at most 8
  sub-steps, each two square roots and up to five compares against cups. A whole match is about
  3 100 ticks.
- On the phone: one `tick` a rendered frame at 60 Hz, a few microseconds of GDScript, against a
  16.6 ms frame. The prototype's Python runs it at 1.4 µs a tick. At 120 Hz the view ticks every
  second frame and draws the ball between two states.
- The aim preview is not simulated: its dots are the launch's one or two parabolas, 12 points.

## 3. Making it fun

### 3.1 The list

| # | Improvement | What it does to the sim | Cost | v1 |
| --- | --- | --- | --- | --- |
| 1 | **The ring is the truth, the rest is physics** (section 2) | timing still decides, but the ball has weight: tocks, lip skips, rattles, cups shoved, flukes | the sim, about 350 lines | **in** |
| 2 | **Breath is a lung per turn, and a hold deepens** (3.2) | holding is worth 18 points of win rate against the crew, and there is not enough for two full holds | 3 constants | **in** |
| 3 | **The bounce shot: a smaller mouth for two cups** (3.3) | 0.48 cups a throw against 0.40 for a lob, but swattable; "always bounce" loses 7 to 31 points, "bounce when they look away" is level to 3 up | one gesture, one solver line | **in** |
| 4 | **Rival tells** (3.4): eyes off the table, Gienia's hand, Hubert's ritual | a second rhythm to line up with the swing; the swat and the nudge can be seen coming | poses, an eye pip, 4 numbers a rival | **in** |
| 5 | **The dare: TEGO NIE TRAFISZ** (3.5), the called shot turned round | a reason to aim at a middle cup; the same win rate as the safe cup, with wider swings | 20 lines | **in** |
| 6 | **Heat** (3.6): consecutive cups widen the ball-back core | a streak pays in balls, and is visible in the ring | 5 lines, 3 flame pips | **in** |
| 7 | **Juice** (3.7): hit-stop, shake, foam, trail, rock, chatter | the hit-stop is inside the sim's clock (0.07 s, 0.10 s on a bounce-in); the rest is the view | view only | **in** |
| 8 | **Last orders that happens**: six rounds, then cups are counted | 6 to 13 % of a decent thumb's matches now end at the bell or in sudden death (was 0 to 2 %) | 1 constant | **in** |
| 9 | **The regulars react** and **each rival has six lines of story** (3.8) | none | 4 poses, 30 lines of text | **in** |
| 10 | **Sound on every contact**, from the sounds the game already has (3.9) | none | a table | **in** |
| 11 | **REWANŻ** with a memory of the last result this visit (3.8) | none | a variable in the room | **in** |
| 12 | The shot clock drops the ball (WYPADŁA Z RĘKI) instead of throwing it | idle wins 0 for a real reason | 2 lines | **in** |
| 13 | Behind-the-back throw (pull another way) | a second gesture for a cosmetic throw; the drag is spent on the bounce | medium | out |
| 14 | Drink or pay when a cup is lost | touches the wallet and the tipsy drive outside the pub; stops the flow each cup | medium | out (question 3) |
| 15 | Rivals bounce and you swat | a second defence action; good, later | medium | out, v1.1 |
| 16 | A saved record per rival (stars on the card) | needs a row in the save owner | small | out, v1.1 |
| 17 | Cups knocked over by a ball | measured: degenerate (2.7) | | out |

### 3.2 The swing and the breath

- The ring swings as a sine from **16 px before the first standing cup to 12 px behind the
  last** (it follows the rack, latched at the start of each ball). So the two end cups are the
  slow ones and the middle is fast, at every stage of the match.
- The period shrinks with the rack: `1.20 * sqrt(span / 84)` s, between 0.80 and 1.45. Five
  cups: 1.20 s, the ring passing the end cups at 154 to 173 px/s and the middle at 220. Two
  cups: 0.85 s. The last cup: 0.80 s and 109 px/s. The end of a match is quicker and a little
  easier, where the first design dragged.
- Each ball starts the swing at the near end. The rhythm is learnable; Hubert's re-set and
  Gienia's nudge are attacks on exactly that.
- **Finger down = you hold your breath.** The swing slows smoothly to **60 %** over 0.6 s of
  holding and stays there. A 48 ms thumb lands 7 px off on a tap and 4.4 px off on a full hold.
- **The lung is 1.3 s for the whole turn**, not a ball (0.1 s less a drink, never under 0.7).
  A full hold needs 0.7 s, so two do not fit: spend it on the first ball, split it, or save it
  for the ball that comes back. A clean hit gives 0.4 s back.
- Out of breath while holding (BRAK TCHU): the swing jumps to 115 % and the ring wobbles 0.8 px
  wider until you let go.
- The finger must come up once before a new ball's hold counts (no carrying a press over).
- Five seconds without a throw: the ball slips out of the hand. No throw.
- Tipsy, as before but in the ring's own motion: +0.8 px of wobble a drink (0.3 sober, 5 at
  most), the swing 5 % quicker a drink. The ring's faint double shows the wobble's size.

**How it reads.** The cyan bar under the table's lip is the lung: it drains while you hold and
does **not** refill between your two balls, with a notch at "one full hold". The ring is drawn in
two parts: the gold outline is the mouth, the bright core is the ball-back window. The outline
tightens by a pixel as the hold deepens, so "steady" is something you see.

### 3.3 The bounce shot

- **Drag the held finger down** by 28 pt or more: the throw is aimed at the table. Back up
  past 16 pt: a lob again. (Mac: hold S or the down arrow.) `low` is read at the release.
- The screen: the ring over the cup shrinks to 7x3; a gold cross sits on the table at the bounce
  point; the dotted arc shows both hops. If the hop would hit the front cup, the arc stops there
  and the ring dims.
- In clean: **two cups**. On the rim: the usual spin, one cup, worse odds (`P_RIM_FLAT`).
- **The rival may swat it** on the bounce (a real beer pong rule): chance `swat`, only while
  their eyes are on the table (3.4).
- A hint, once, at the start of your second turn: PALEC W DÓŁ: ODBICIE ×2.

Why it is a choice and not the new best throw (decent thumb, crew / Gienia / Hubert win %):
lob only 60 / 45 / 28, **always bounce 53 / 14 / 10**, bounce when unguarded 62 / 48 / 27. It is
also the one way to take two cups with one ball when the bell is a turn away.

### 3.4 Tells

Every rival has `swat` and moments when their eyes are off the table. The pose shows it, and a
5x3 eye pip on the rival's name tab (open, closed) says the same thing at phone size.

| | Open-space crew | Pani Gienia | Pan Hubert |
| --- | --- | --- | --- |
| Throws | three hasty balls, aim error 7.1 px | two lobs, 9.0 px; awake 2.55 px | two measured balls, 4.5 px |
| Their cups | red cups | red cups | tasting glasses: drop within 1.2, lip to 4.0, body 3.5 |
| Swat | 0.60 when watching | none asleep; **0.85 awake** | 0.75 |
| Eyes off | on their phones 1.4 s in every 2.6 | asleep: always. Awake: only while she nudges | nose in the glass 1.0 s in every 3.4, and **2.2 s after every re-set** |
| Guards spinners | never | awake: flicks 55 % | never (beneath him) |
| Trick | none: here you learn the bounce | **wakes** at three cups or round 4. On half your balls she nudges the table: her hand goes to its edge 0.4 s before, then her cups jump 4 px. Thrown before the hand moves: no nudge. Thrown after: the cups move under the ball | **re-sets** his glasses after each of your hits (a new pitch of 11 to 17 px, shifted up to 6): your rhythm is gone, but his nose is in the glass. If you blank a turn he takes a third ball |
| How to beat them | bounce when the phones are out | bounce her early, two cups at a time, before she wakes; then clean lobs, and throw before her hand or after the jump | never blank a turn; after a hit, a quick bounce while he decants |

The rivals' balls fly through the same physics as yours (an aim error in px, a lob), so their
rims spin on your cups and their short balls shove your rack.

### 3.5 The dare

At the start of each of your turns, while three or more of their cups stand, the rival points at
one **middle** cup: a gold chalk mark over it and, the first time, the bubble TEGO NIE TRAFISZ.

- Take it this turn with a drop (they watch that cup: a spin on it is always flicked out):
  **KARNIAK**. The rival drinks a penalty and throws **one ball fewer** next turn, your heat goes
  to the top, and the ball comes back.
- Aim at it and miss: the neighbours still catch some errors, but fewer cups come of it (0.31 a
  throw against 0.40).

Measured (decent thumb): always the dare 59 / 46 / 28 against always the safe far cup 60 / 45 /
28. The same on average, wider swings: the throw for the turn when their next ball would finish
you.

### 3.6 Heat

A cup taken adds a point (a bounce-in two, a karniak fills it), a ball that takes nothing empties
it. Three flame pips in the top strip. Each point widens the ring's bright core by 0.3 px a side
(0.8 sober, 1.7 at three): more balls come back. At two: NA FALI, the regulars lean in. At three:
OGIEŃ, a 2 px shake on every drop and the rival's sour line.

### 3.7 Juice (the view; all cheap)

| Moment | What happens |
| --- | --- |
| Release | the arm snaps through, the ball leaves with a 4-dot fading trail |
| A table bounce | `pong_bounce`, a 1 px dust tick, the ball one frame squashed (3x2) |
| A lip tick | `pong_rim`, a white spark pixel, the cup's rim flashes for a frame |
| A cup's side | the cup slides and rocks, 3 foam pixels, `pong_bounce` low; a `glass_clink` if it meets its neighbour |
| A spin | half-lap ticks slowing; the regulars' heads follow; your tick mark and STUKNIJ on your cups |
| A drop | **hit-stop 4 frames** (the sim's own 0.07 s), `pong_cup`, 6 foam pixels up, a 1 px shake, the callout at 2x, the cup lifted away over 0.3 s |
| CZYSTO | the same, the core of the ring flashes white, the ball arcs back to your hand |
| A bounce-in | hit-stop 6 frames, the cup tips onto its neighbour over 3 frames, both carried off, a 2 px shake, the regulars up |
| A swat | the rival's hand cuts the arc, `thump_soft`, ODBITA ŁAPĄ |
| You lose a cup | your figure drinks (0.4 s), the ring's double grows a little |
| Out of breath | the lung bar flashes, your figure exhales, the ring jitters |

The shake moves the whole 216-row canvas by whole canvas pixels, 0.15 s, never during an aim.

### 3.8 Regulars, story, rematch

- **The regulars** (four at the back table): sit, lean in (a spin, heat 2), up with arms (a
  bounce-in, CZYSTO, heat 3, the last cup), heads down (you lose a cup). One of eight short
  bubbles on the big moments, at most one every 6 s.
- **Six lines a rival**: the intro, you lead by two, they lead by two, their last cup, your
  win, your loss; and one for a rematch after each result. In `tapczan.json`, Polish and
  English, picked by events (the sim's `over`, the cup counts). The crew: a retro that will not
  end. Gienia: "pierwszy raz", then the glasses come down. Hubert: tasting notes on your throws.
- **REWANŻ** on the receipt starts the same rival at once; the room remembers the last result
  against each rival for this visit, and the rival's first line says so. Nothing is saved.

### 3.9 Sound hooks (no new audio)

| Event | Sound (`sfx.gd` name) |
| --- | --- |
| a table bounce, a cup's side | `pong_bounce` (the side at -4 dB, pitched down) |
| a lip tick, each half lap of a spin | `pong_rim` |
| a ball in a cup | `pong_cup` |
| a cup meets a cup, a tasting glass taken, the karniak | `glass_clink` |
| the re-rack, Hubert's re-set | `glass_clink` twice, quiet |
| a swat, Gienia's nudge | `thump_soft` |
| the lung's last 0.3 s, the shot clock's last 2 s | `tick` |
| last orders | `cafe_bell` |
| the regulars (a low bed while playing; up on a bounce-in and the win) | `crowd_murmur`, `fan_chant` |
| the payout | `coin` |

Names that turn out not to be in `sfx.gd`'s tables get a row there, not a private player.

## 4. The numbers

`python3 -I docs/design/tapczan-pong-v2-physics-sim.py 3000`. The thumbs are the first brief's:
a release-time error of 85 / 48 / 26 ms; "masher" taps at a random moment; "idle" never touches.

| Rival | Idle | Masher | Novice | **Decent** | Expert | Cups you lose (decent) | Mean length | 9 in 10 under | Ends at the bell or in sudden death |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Crew | 0 % | 6 % | 32 % | **63 %** | 93 % | 3.3 | 54 s | 81 s | 9 % |
| Pani Gienia | 0 % | 3 % | 20 % | **48 %** | 81 % | 3.7 | 46 s | 68 s | 6 % |
| Pan Hubert | 0 % | 1 % | 14 % | **30 %** | 69 % | 4.1 | 56 s | 77 s | 13 % |

Draws are under 1 %. No match stuck; the longest of 72 000 was 121 s (an idle phone).

After 0 / 1 / 2 / 4 pints at the bar, decent thumb: crew 63 / 60 / 57 / 54 %, Gienia 48 / 45 /
41 / 35 %, Hubert 30 / 26 / 23 / 21 %.

**Which choice wins** (`... 1000 choices`; decent thumb, win % against crew / Gienia / Hubert;
±3 at this sample):

| Policy | Decent | Expert |
| --- | --- | --- |
| far cup, full hold then what is left, no bounce | 60 / 45 / 28 | 93 / 80 / 72 |
| near cup | 57 / 40 / 23 | 90 / 73 / 68 |
| middle cup | 55 / 40 / 23 | 88 / 77 / 59 |
| the dared cup whenever there is one | 59 / 46 / 28 | 93 / 84 / 61 |
| far cup, the breath split evenly | 62 / 43 / 32 | 93 / 78 / 75 |
| far cup, never holds | 41 / 26 / 13 | 77 / 60 / 48 |
| always bounces | 53 / 14 / 10 | 84 / 23 / 26 |
| bounces when the rival's eyes are off | 62 / 48 / 27 | 92 / 80 / 68 |

Cups a throw against the crew, decent thumb: far 0.40, near 0.40, middle 0.34, the dare 0.31,
a bounce 0.48. A decent match against the crew holds about 1.0 clean drops, 1.1 plain drops,
0.8 rim-ins, 0.55 bounce-ins, 1.0 balls back, 0.3 karniaks, 4.7 rim touches, 12 cups shoved.

What this says, plainly:

- **No dominant line.** The safe end cup, the dare and the read bounce are within three points
  of each other; which is best changes with the rival (the dare against Gienia, an even breath
  against Hubert). Two lines are clearly wrong and the game shows why at once: never holding,
  always bouncing.
- **The breath is worth 18 points** against the crew. How it is split is worth little, about
  three. That is a weak second layer: honest, and fine for a pub game.
- The far cup still edges the near cup by 2 to 5 points. Not a problem; a habit.
- A read bounce is on par for a decent thumb, not better. Its value is the two-cup swing, and
  Gienia's sleepy start.
- The skill gradient is real now: masher 6 %, novice 32 %, decent 63 %, expert 93 % against the
  crew (the first design's masher took a cup on 0.29 of throws against the careful thumb's 0.53).

These are models of a thumb, not thumbs. PHONE-CHECK 15zzr replaces the 48 ms with a measure.

## 5. Build plan (replaces the first brief's 5.1 step 3, 5.3 and 5.5; the rest of its section 5 stands)

Opus builds all of it in one go, full definition of done.

### 5.1 Order

1. Confirm the 2x cause (first brief 5.1 step 1). Bench before.
2. `game/scripts/pixel_kit.gd` (first brief, step 2), with the additions of 5.3.
3. **`game/scripts/pong_sim.gd`**: port `tapczan-pong-v2-physics-sim.py`'s `Sim` method for
   method (5.2). Delete `beer_pong_sim.gd`.
4. **`game/tools/check_tapczan.gd`**: the pong half becomes 5.4. Run it before any drawing
   exists; the bands are the acceptance of step 3.
5. `game/scripts/pong_match.gd` (first brief, step 5): the view, the input (finger, and `low`
   from the drag), 3.7's juice, 3.8's regulars and bubbles, 3.9's sounds. Delete `beer_pong.gd`.
6. `game/scripts/tapczan_ui.gd` and the slimmed `tapczan_room.gd` (first brief, step 6), plus
   the room's detail: the action tiles' objects tappable, the bill chip's flash, the rival
   card's eye-catching "how" line, the last result this visit for REWANŻ.
7. `game/data/tapczan.json` (5.5), the lines (5.6).
8. Sounds: 3.9, through the room's `_sound`.
9. Docs: `systems.md` rows (`pong_sim.gd`, `pong_match.gd`, `tapczan_ui.gd`, `pixel_kit.gd`),
   the `tech-debt.md` row for padel onto `pixel_kit`, `tapczan-pub.md` sections 2 and 3, the
   archive's flags table (no new flags), PHONE-CHECK rows (5.7), one change note.
10. `tools/verify.sh` (the `tapczan` and `tapczan-run` steps, then the full set and `--ios`),
    shots (`--tapczan=in`, `taps`, `pong:first` at 2532x1170 and 2868x1320), bench after, the
    frame time inside the room and inside pong.

### 5.2 `pong_sim.gd`

- `class_name`-less `RefCounted`, pure: no nodes, no engine time, no `Vector2` (32-bit; the
  ring-is-the-truth rule needs 64-bit `float` scalars). One `RandomNumberGenerator` seeded in
  `_init`. The Python generator's stream is not reproduced: the check uses bands.
- `_init(seed: int, rival: Dictionary, start_drinks := 0)`
- `tick(finger: bool, low: bool) -> void`, called at a fixed 60 Hz by the view (an accumulator;
  at most 4 ticks a frame).
- Read by the view: `phase` (`AIM, FLIGHT, SPIN, WAIT, DONE`), `thrower`, `ring_x()`,
  `hold_factor()`, `lung`, `gasp`, `clean_r()`, `heat`, `cups_me` / `cups_them`
  (`PackedFloat64Array`, with a parallel id array so the dare and the view's cup sprites follow
  a cup when its neighbours go), `dare_id`, `ball` (x, y, low, fresh), `spin` (cup, side, age,
  left), `rival_busy()`, `nudge_warned()`, `round_no`, `balls`, `sudden`, `lost`, `took`,
  `winner` (-1, 0 you, 1 rival, 2 draw), `end`.
- `preview(x_t: float, low: bool) -> PackedFloat64Array`: 12 points of the launch's parabolas
  and whether the hop is blocked by the front cup (`Bot._bounce_cup`'s test).
- `events: Array[Dictionary]`, drained by the view each frame: `round`, `dare`, `throw`,
  `rival_throw`, `tock`, `body`, `rim`, `rim_tick`, `rim_out`, `flicked`, `clean`, `in`,
  `rim_in`, `bounce_in`, `domino`, `fluke`, `back`, `karniak`, `swat`, `miss`, `slip`, `gasp`,
  `rival_cup`, `rival_miss`, `nudge_warn`, `nudge`, `reset`, `bonus`, `wake`, `rerack`,
  `last_orders`, `sudden`, `over`.
- `bot_finger(thumb: Dictionary) -> Array` (`[finger, low]`): a port of `Bot.act` with the
  "decent" habit (far cup, full hold, bounce on the read), its own seeded generator. Thumbs:
  decent `{sd 0.048, flick 0.60, blind 0.6, tells true}`, expert `{0.026, 0.85, 0.3, true}`.
  For `auto_play` and the check.
- Constants: section 2.3, plus the swing and the match:

| Name | Value | Name | Value |
| --- | --- | --- | --- |
| `M_LO`, `M_HI` | 16, 12 | `BALLS` | 2 |
| `P_REF`, `A_REF` | 1.20 s, 42 | `ROUNDS` | 6 |
| `P_MIN`, `P_MAX` | 0.80, 1.45 s | `SUDDEN` | 3 |
| `HOLD_SLOW`, `HOLD_RAMP` | 0.40, 0.60 s | `RERACK_AT` | 2 |
| `LUNG`, `LUNG_DRINK`, `LUNG_MIN`, `LUNG_BACK` | 1.30, 0.10, 0.70, 0.40 s | `HEAT_MAX` | 3 |
| `GASP_V`, `GASP_WOB` | 1.15, 0.8 px | `DARE_MIN_CUPS` | 3 |
| `SWEEP_V_DRINK` | 0.05 | `SHOT_CLOCK` | 5 s |
| `WOB_0`, `WOB_DRINK`, `WOB_MAX` | 0.3, 0.8, 5.0 px | `T_INTRO`, `T_BANNER`, `T_BEAT` | 2.0, 0.6, 0.45 s |
| wobble | `amp * (0.7 sin(6.912 t) + 0.3 sin(16.96 t + 1))` | `T_RIVAL_WIND`, `T_RERACK` | 0.5, 0.7 s |
| `FLICK_FIRST`, `FLICK_LAP`, `FLICK_HALF` | 0.25, 0.40, 0.085 s | `T_HITSTOP` | 0.07 s (0.10 on a bounce-in) |
| `NUDGE_WARN`, `NUDGE_BUSY` | 0.4, 0.6 s | nudge time | 0.6 to 1.4 s into the aim |

- Sudden death: on the cups still standing (a side's last cup, if it falls, is put back at
  x = 28), one ball each, no dare, no ball back, up to three rounds; one hits and the other
  does not: over; still level: a draw, `pong_over(false, 0, lost)`.

### 5.3 Sprites and drawing (all code, through `pixel_kit`; no texture)

The first brief's list (5.2 there) plus:

| Sprite | Size (canvas px) | Frames or states |
| --- | --- | --- |
| The ring | 9x4 outline (7x3 in bounce), core 2 to 4 px wide by heat | outline one px tighter at a full hold; dim when the hop is blocked; a faint double at the wobble's size |
| The bounce cross and the two-hop arc | 5x3; 2x2 dots | computed from `preview` |
| The lung bar | 94x3, a notch at 0.6 s | drains, flashes on a gasp; replaces the breath bar |
| Heat | three 5x7 flames in the top strip | off, lit; all three pulse at heat 3 |
| The eye pip | 5x3 on the rival's name tab | open, closed |
| The dare mark | 3x5 gold chalk "!" over a cup | bobs 1 px |
| Rival poses | the figure | guard (hand over the cups), away (crew: heads to phones; Gienia: glasses up, dozing; Hubert: nose in the glass), wind-up, throw, swat, nudge-reach (Gienia), re-set (Hubert), cheer, slump |
| Your poses | the figure | swing (the arm's angle is the swing's phase), hold (shoulders up), throw, exhale, drink, cheer, slump |
| A cup | 9x13, glass 7x13 | upright, rock left and right (1 px), tipped (3 frames, for the domino), lifted away |
| Foam, sparks, dust | 1 px each, 3 to 6 at a time | a fixed pool of 24, no allocation |
| The ball | 3x3, 3x2 squashed for one frame on a tock | a 4-dot trail |
| The regulars | four chibis at the back table | sit, lean in, arms up, heads down |
| The flick tick | 1x3 gold on the near lip of your cup | while a rival's ball spins |

### 5.4 The headless check (`check_tapczan.gd`, the pong half)

Bots and bands, 300 seeded matches a cell at a fixed step, `bot_finger`:

- Win rates, decent: crew 55 to 71 %, Gienia 40 to 56 %, Hubert 22 to 38 %, and crew > Gienia >
  Hubert. The expert beats the decent by 10 points or more against each.
- A finger that never touches wins none (every ball is a `slip`). A finger that taps at a random
  moment wins under 15 % against the crew.
- Length: the decent mean is 40 to 65 s for each rival; no match over 150 s; every match reaches
  `DONE`.
- Determinism: the same seed and the same input script give the same event list twice.
- The ring is the truth: for 50 seeded `x_t`, a lob and a bounce cross the mouth plane within
  0.01 px of it (no cups in the way).
- One forced case each (launch at a set offset from the first cup, the generator's roll forced
  where one is used): d 0: `clean` and `back`, once a turn only; d 1.5: `in`; d 2.5: a `rim`,
  dropping or not by the roll, and a flicked one never drops; d 4.5: a `rim_tick`, no cup; d -8:
  a `body`, the cup shoved 0.5 to 2.5 px and never nearer than 9 to its neighbour; a bounce at d
  0: `bounce_in`, `domino`, two cups, no `back`; a bounce with `swat` 1 and eyes on: `swat`; with
  eyes off: none; a spent ball takes a cup only inside 0.6 of the mouth.
- The turn: the lung is shared by the turn's balls and never refills between them; a gasp at
  zero; a press carried over from the last ball does not hold; a `slip` at 5 s.
- The match: the dare is a middle cup, only a drop takes it, the karniak removes one rival ball
  next turn (never the last); heat rises, empties on a miss and widens `clean_r()`; the re-rack
  at two, once a side; Gienia wakes at three cups and at round 4, her nudge is cancelled by a
  throw before the warning and lands after one; Hubert's re-set and his third ball after a blank
  turn; last orders after six rounds counts cups; sudden death; a draw pays nothing.
- `lost` equals the cups the rival took; `start_drinks` widens the wobble and shortens the lung
  and is not reported.
- `tapczan.json`: every rival has 5.5's fields, every line both languages, no `skill`, `p_in`
  or `p_rim` left.
- The view: `pong_match.gd` loads; `start` then `auto_play` reaches `finished` and `closed`.
  `tapczan-run` still expects `tapczan: out: won`: `auto_play` uses the expert thumb against the
  crew with a seed the check has found to win.

### 5.5 `tapczan.json`, per rival

Drop `skill`, `late_skill`. Add (values: the prototype's `RIVALS`):

| Field | Crew | Gienia | Hubert |
| --- | --- | --- | --- |
| `balls` | 3 | 2 | 2 |
| `sd` (px) | 7.1 | 9.0 | 4.5 |
| `flick` | 0 | 0 | 0 |
| `swat` | 0.60 | 0 | 0.75 |
| `away_every`, `away_len` (s) | 2.6, 1.4 | | 3.4, 1.0 |
| `glass`, `half`, `in_r`, `rim_r` | cup, 4.5, 2.0, 5.5 | cup, 4.5, 2.0, 5.5 | tulip, 3.5, 1.2, 4.0 |
| `wake_cups`, `wake_round` | | 3, 4 | |
| `late` | | `sd` 2.55, `flick` 0.55, `swat` 0.85, `nudge` 4, `nudge_p` 0.5 | |
| `reset_after_hit`, `reset_busy` | | | true, 2.2 |
| `bonus_on_blank` | | | true |
| `how`, `story` | the card's line; the six lines of 3.8 | | |

### 5.6 Words (new or changed `ui` lines; the first brief's table stands otherwise)

| Key | Polish | English |
| --- | --- | --- |
| `hint_low` | PALEC W DÓŁ: ODBICIE ×2 | DRAG DOWN: BOUNCE ×2 |
| `bounce_in` | Z ODBICIA! DWA KUBKI | OFF THE TABLE! TWO CUPS |
| `swat` | ODBITA ŁAPĄ! | SWATTED! |
| `dare` | TEGO NIE TRAFISZ | YOU WON'T HIT THAT ONE |
| `karniak` | KARNIAK! RYWAL PIJE | PENALTY! THE RIVAL DRINKS |
| `heat2` / `heat3` | NA FALI / OGIEŃ! | ON A ROLL / ON FIRE! |
| `rim_out` | WYKRĘCIŁA SIĘ | SPUN OUT |
| `fluke` | FUKS! | FLUKE! |
| `gasp` | BRAK TCHU | OUT OF BREATH |
| `slip` | WYPADŁA Z RĘKI | IT SLIPPED |
| `too_far` | ZA DALEKO NA ODBICIE | TOO FAR FOR A BOUNCE |
| `round` | RUNDA %d/6 | ROUND %d/6 |
| Hubert `how` | Wąskie kieliszki. Pilnuje stołu, póki nie wącha. | Narrow glasses. Guards the table, until he sniffs. |
| Gienia `how` | „Pierwszy raz.” Póki śpi, bij z odbicia. | "First time." While she dozes, bounce it. |
| crew `how` | Trzy piłki na turę. Połowę czasu w telefonach. | Three balls a turn. Half the time on their phones. |
| regulars (eight, one at a time) | No ładnie! · Uuu... · Jeszcze raz to samo! · Barman, on oszukuje! · Z odbicia, widziałeś? · Pij, pij. · Cisza, kręci się! · Ostatnie zamówienie! | Nice! · Ooh... · Same again! · Barman, he's cheating! · Off the table, did you see? · Drink up. · Quiet, it's spinning! · Last orders! |

The rivals' six story lines each are written in the build pass with the warsaw-tone skill.
`clean`, `flick_hint`, `flicked`, `last_orders`, `sudden`, `draw`, `rematch`, `total`: unchanged.
`breath` stays as the lung bar's label.

**Add-ons check.** Beehave: not used, because a rival is a table of numbers, a timer for where
the eyes are and at most two flags; nothing chooses between behaviours. Dialogue Manager: not
used, because every line is a one-liner picked by an event, with no branch.

### 5.7 PHONE-CHECK rows (replace the first brief's three)

| Id | Do | Look for |
| --- | --- | --- |
| 15zzq | Go into THE TAPCZAN; look, tap PIWKO, a row, the cross; tap GRAJ, a rival; tap WYJDŹ | the UI is small and sharp, pixels match padel's size; every tile and row is easy to hit and nothing is hit by mistake; the bubble points at whoever speaks |
| 15zzr | Play each rival twice, sober, without reading the hints | the hold and release feel natural within three throws; the ball lands where the ring was, every time; a held throw is plainly steadier than a tap and the lung bar is noticed by the second turn; matches take about a minute; wins roughly crew > Gienia > Hubert. Note the wins out of six and how late or early the releases feel |
| 15zzs | Against the crew: drag down for a bounce, three times with their phones out and three with one looking up | the drag is found from the hint and does not fire by accident on a plain hold; the cross and the two-hop arc read; the eye pip and the pose say when it is safe; a swat feels deserved; a bounce-in is the best moment of the match |
| 15zzt | Two pints, then Gienia; then Hubert | the wobble and the double read as tipsy, harder but fair; her hand is seen before the nudge and waiting it out works; his re-set is seen and the quick bounce after it is possible; flicking a spinner works on the first or second try; the dare mark is understood; hit-stop and shake feel like weight, not lag |

### 5.8 What only the phone can show

- Whether 48 ms is a real thumb. The whole balance rests on it; if the phone says 60 ms, `P_REF`
  goes to 1.35 and nothing else moves.
- Whether the release should be read at the touch's own time. The sim reads it at a 60 Hz tick:
  up to 16 ms and 1.5 px of ring late. If throws feel late, the view passes the tick the finger
  left on, not the next one.
- The drag threshold (28 pt down, 16 pt back) under a real thumb, and that the thumb does not
  cover the lung bar.
- Whether a 9x4 ring with a 2 px core reads at arm's length.
- The flick's ±85 ms window by feel; hit-stop of 4 and 6 frames at 60 and 120 Hz.
- Heat and frame rate inside the pub.

## Open questions (parked; the default is what this builds)

1. **Stakes against difficulty**, unchanged: Hubert is the hardest and pays 120 zł, Gienia 150.
   Default: left.
2. **The dare's prize.** Default: the rival loses a ball, and your ball comes back. Alternative:
   10 zł on the receipt, which would touch the payout.
3. **Drink or pay** when you lose. Default: out of v1; drinks are the cups you lost, as now.
4. **Six rounds.** Default: six, so the bell rings in about one match in ten. Seven makes it one
   in thirty and the long matches 10 s longer.
