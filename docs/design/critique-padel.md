# Critique: the padel match "Padel na Desce" (2026-11-25)

F: "critique with Fable the same way ... and the padel mini-game too". Design only, no game code.
Read: `padel_sim.gd` (rules, ball, AI), `padel_match.gd` (touch, callouts), `check_padel.gd`,
`padel.md`, BACKLOG "Padel call at WTS DESKA", PLAYTEST PT-30 to PT-32 (padel). No sim was written:
the findings below follow from the sim's own formulas, quoted. The match has no Autopilot row and
no phone row yet, so nothing here is measured on a hand.

## 1. What it is now

Kuba calls: a fourth is missing at DESKA. On time at the gate, a 2v2 pixel-art match in a 3/4 side
view: you and Kuba (orange) against Prezes z Mokotowa and Pan Zbyszek (cyan). First to two games,
0/15/30/40 with a golden point at 40:40. Left thumb: a stick (let go for 0.7 s and you run to the
ball by yourself). Right thumb: UDERZ (a drive; a volley near the net; a smash on a high ball) and
LOB. Real rules, simplified: one bounce, then the glass plays.

| Thing | Value (`padel_sim.gd`) |
| --- | --- |
| Reach | 1.3 m, +0.35 m at a run; contact up to 2.2 m, 3.2 m for a smash |
| A tap | opens a 0.34 s swing; **the first frame the ball is in reach, it is hit**; then 0.2 s cool |
| Quality | `q = 1 - 0.55 × (distance / reach) - 0.6 × (height off 1.05 m) / 1.4`; from 0.9 it is IDEALNIE! |
| Where the ball goes | `_open_y`: the spot furthest from both rivals, plus a scatter of `(1 - q) × 1.2 to 2.3 m` |
| Whether they return it | a hidden roll: `1 - (PRESSURE × q + pace + how little time he has) × (1.7 - skill)`, never under 0.4. PRESSURE: drive 0.10, lob 0.03, volley 0.18, smash 0.42 |
| Skills, speeds | you 0.75 and 5.4 m/s, Kuba 0.70, the rivals 0.66 and 0.72, all three about 4.7 m/s |
| Pauses | point 1.9 s, game 3.2 s, your serve waits 4 s, intro 3 s, end 4 s |
| Pay | 2:0 full, 2:1 two thirds, 1:2 one third, 0:2 or ✕ nothing |

`check_padel`: 24 matches on autopilot, the pair wins 16; an idle human loses 0:2; about 6 to 7
hits a rally.

## 2. The critique

| What the design says | What the code does |
| --- | --- |
| "Timing sets the quality" | The swing hits on the **first** frame the ball enters the reach circle. A tap before the ball arrives (the natural one) connects at the circle's rim: distance / reach is 1, so `q` is at most **0.45**, whatever the timing. Only a tap made while the ball is already inside can score higher, and a drive crosses the circle in about 0.2 to 0.3 s. IDEALNIE! needs the ball within 0.3 m of your middle at chest height: a slice about 45 ms long that most balls never pass through |
| "HIT WHEN THE BALL GLOWS" (the hint) | The glow is "in reach". Tapping when it lights is the rim again: the hint teaches the 0.45 hit |
| "The left thumb is a stick" | The auto-run reads every ball perfectly (`read` is always true for the human) and runs at 4.86 m/s, faster than the other three players. Touching the stick switches that off for 0.7 s. The stick can only make you worse: a second thumb for nothing |
| "A player who reads the situation wins" | There is no aim. The sim picks the open spot; you pick when, and UDERZ or LOB. A drive at q 0.45 to a rival with time to reach it is returned about 90 % of the time; only a good smash (0.42) or a ball he barely reaches forces an error. One plan: wait for a high ball, press UDERZ |
| The rivals' mistakes | A roll decides that a rival "misreads": he then runs the wrong way or hits the net. Nothing on screen says your shot caused it |
| 2v2 | Four players share 6 to 7 hits: you swing about 1.6 times a rally of about 7 s, then wait 1.9 s. Most of the match is watched |
| The serve | A tap; the target is random |

And:

- **Floaty.** The ball's flight is real (gravity 9, bounce, glass), but your hand is not in it:
  the racket has no swing time, no direction and no sweet moment you can see. It reads as "tap
  somewhere around now".
- **Unfair in feel.** Points end on dice in both directions. Your out balls come from the scatter
  of a quality you could not have raised.
- **Too long for what you do.** By the constants a match is 8 to 21 points of roughly 10 s: about
  1.5 to 3.5 minutes, with 20 to 35 taps in it (not measured; the check prints the range, no run
  here). A 0:2 pays nothing after two minutes.
- **Exploit.** None that wins: tap-spam hits at the rim and scatters. The dull truth is the plan
  above.
- **Unverified.** 16 of 24 is autopilot against autopilot; "a real hand is weaker" (padel.md) has
  no number.

Right and staying: the court from F's photos, the rules and the glass, the crowd, the flip-card
score, Trener Dominik, the chiptune, shot choice by height (a smash is a high ball), the golden point.

## 3. Physics and feel fixes

### 3.1 The swing commits to the best contact, and the tap's timing is the quality

```
on tap:
    scan the ball's flight for the next SWING_S (0.34 s), 60 Hz, a copy of the ball (the AI's read does this already)
    t* = the reachable moment where the ball is nearest the sweet point
         (the player's middle + 0.45 m towards the net, 1.05 m up; 2.6 m up for a smash)
    none -> the swing runs out: PUDŁO, as now
    else -> the hit happens AT t* (not now); the player's arm winds up until then
    err  = (t* - LEAD) - t_tap            # LEAD 0.14 s: the ideal tap is 0.14 s before contact
    |err| <= 0.045  -> CZYSTO!   q = 1.0
    |err| <= 0.100  -> DOBRZE    q = 0.8
    |err| <= 0.170  -> q = 0.6   ("ZA WCZEŚNIE" / "ZA PÓŹNO" in small grey)
    else            -> q = 0.4   (a late tap with t* already past: the frame's ball, as now)
```

The cue: the ball's shadow carries a ring that shrinks onto it and closes at `t* - LEAD` (white
flash, one frame of 2 px). The hint becomes „UDERZ, GDY KÓŁKO SIĘ ZAMKNIE” / "HIT WHEN THE RING
CLOSES". The 0.09 s CZYSTO window is five frames: rhythm-game size, and the same for every ball.

### 3.2 Aim: timing pulls the ball, the stick places it

- No stick (one thumb): early pulls cross-court, late goes down the line.
  `to.y = lerp(cross corner, line corner, clamp((err + 0.10) / 0.20, 0, 1))`, corners 1.3 m from
  the side fence. CZYSTO with no lean keeps today's open spot.
- With the stick held at contact: up or down picks the side (corner 1.0 m from the fence),
  towards the net is deep (8.4 m), away is short (a drop at 2.6 m, only from q 0.8).
- The scatter stays `(1 - q) × SCATTER`: a corner with a poor tap goes into the fence. That is the
  risk.

### 3.3 The stick stops being a trap

The auto-run stays on always. The stick only aims (3.2), and the left half of the screen gets one
more use: a swipe up is DO SIATKI / TO THE NET, a swipe down is DO TYŁU / BACK, for the pair
(`_home` takes the flag; Kuba follows; it lasts until the point ends). The net wins points and
loses lobs: a decision the player can see.

### 3.4 Pressure you can watch

Drop the hidden `read` roll. Instead:

```
diff  = PRESSURE[shot] * q + the pace and slack terms (as now) + 0.15 if the ball lands within 1.2 m of a corner
react = REACT * (1.4 - skill) + 0.30 * diff          # the rival starts late: a visible stumble frame
a ball reached only inside the lunge band (distance > REACH): botch chance 0.25 + 0.5 * diff
a ball not reached: it bounces twice (a clean winner)
```

Errors now come from late feet and stretched arms, after your pace, corner or smash. The rivals'
skill row gains `late` (Prezes 0.30, Pan Zbyszek 0.24) in place of the roll.

### 3.5 More of the ball, less of the wait

- The rivals aim at your lane: in `_open_y` for their shots Kuba counts as covering 1.4× his
  reach. Target for the check: you play 45 to 55 % of the pair's balls (about 25 % now).
- Kuba leaves a ball between you when you are nearer by 0.5 m („TWOJA!” / "YOURS!").
- `POINT_PAUSE` 1.9 → 1.3, `GAME_PAUSE` 3.2 → 2.2, `HUMAN_SERVE_WAIT` 4.0 → 2.5, intro 3 → 2 s.
- At 1:1 the third game is a short decider: first to three points, the golden point at 2:2.
- Target: 75 to 120 s a match, 30 to 45 taps.

### 3.6 The serve

A marker slides across the service box (0.9 s there and back, twice). Tap: the middle third is
safe (as now); the outer sixths are a wide serve (the receiver's `react` +0.15 s); past the line
is a fault. One fault („DRUGI SERWIS” / "SECOND SERVE": slow, safe, automatic), no double faults.

## 4. The fun set

| # | What | Next version | Cost |
| --- | --- | --- | --- |
| 1 | The committed swing, the closing ring, CZYSTO (3.1) | in | M (the scan, the scheduled hit, the cue, the hint) |
| 2 | Aim by timing and by stick (3.2) | in | S on top of 1 |
| 3 | Visible pressure in place of the roll (3.4) | in | M (the AI's plan, 24 seeds re-tuned) |
| 4 | Your lane gets the ball, shorter pauses, the short decider (3.5) | in | S |
| 5 | Rival tells. Prezes shouts „MOJA!” and plants his feet 0.3 s before every smash (step back or lob him next); Pan Zbyszek looks up before he lobs; a tired rival (a rally over 10 hits) drops his racket hand: his `late` +0.1 for that ball | in | S |
| 6 | Juice: 60 ms hit-stop on CZYSTO and on a smash; the glass rings lower the harder it is hit and the frame shakes 1 px; a rally counter from 6 („WYMIANA ×8”), +1 zł a hit over 8; the crowd's gasp grows with it; slow motion (×0.5 for 0.3 s) on a ball that comes back off the glass at a golden point | in | S |
| 7 | NA FALI / ON A ROLL: three points in a row and your next CZYSTO smash is the fire smash (PRESSURE +0.15, the trail the game already draws). They get one too: after three lost in a row Prezes says „Teraz na poważnie.” and his `late` drops 0.06 for the next point | in | S |
| 8 | DO SIATKI / DO TYŁU for the pair (3.3) | in | S |
| 9 | The aimed serve (3.6) | out (after a phone round of 1 to 4) | S |
| 10 | The story: Prezes changes racket after each game he loses („RAKIETA NR 2”, „NR 3”, then he blames the strings); a 2:0 opens the rematch ladder (rivals' skill +0.03 a win, three steps; BACKLOG already asks for it), then a new pair on the rooftop court "Ściana Płaczu" | in (the rackets and the ladder), out (the new court) | S / L |

On-screen words (new): CZYSTO! / CLEAN!, UDERZ, GDY KÓŁKO SIĘ ZAMKNIE / HIT WHEN THE RING CLOSES,
TWOJA! / YOURS!, DO SIATKI / TO THE NET, DO TYŁU / BACK, WYMIANA ×8 / RALLY ×8, NA FALI / ON A
ROLL, DRUGI SERWIS / SECOND SERVE, Trener Dominik: „Nie machaj. Czekaj na kółko.” / "Don't flail.
Wait for the ring."

## 5. Build plan and what only the phone shows

1. Item 1 with 2 (`padel_sim.gd` `press`, `_human_hit`, a scheduled contact; `padel_match.gd` the
   ring and the hint). `check_padel` gains a timed bot: taps at `t* - LEAD` plus a normal error of
   45 ms ("decent") and of 110 ms ("clumsy"). Targets: decent wins 55 to 70 % of 24 matches,
   clumsy 20 to 35 %, a tap the moment the ball enters reach under 15 %, idle still 0:2.
2. Item 4 (constants) and 3 (the roll out, the late feet in); re-tune the two rivals to step 1's
   targets. The check asserts the human's share of the pair's hits (45 to 55 %) and the match time.
3. Items 5 to 8, then 10's words. 9 after the phone round.

Full definition of done (gameplay): verify, shots of the court with the ring, the bench is the
match's own frame time (a 2D canvas: one number, before and after the scan).

Only the phone shows: whether a 5-frame CZYSTO is hittable with the audio's latency (if not, 0.06
s); whether the ring reads on a 216 px tall court on a small screen; swipes on the left half
against the stick's dead zone; the hit-stop; whether 75 to 120 s is the right length (ask F after
three matches); the first Autopilot row for the match (it has none).

## Open questions (parked; the default is what this specifies)

- The short decider at 1:1 bends "real padel rules". Default: built; the cards still flip 15/30/40
  in games one and two.
- Dropping the stick as movement removes a control F asked for ("the left thumb is a stick").
  Default: the stick aims and the swipe sets the line; free running goes.
