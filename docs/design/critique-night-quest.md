# Critique: the whole night quest "Nocny spot" (2026-11-25)

F: "critique with Fable the same way ... the whole night quest". **Which chain:** "the night quest"
is taken as Darek's Warsaw Night Racing Club (`street_meet.gd`): the call, meet 1, raid 1, the
race, meet 2, raid 2, the drag. It is the one chain the repo calls the night meet and the one the
drag belongs to. Mati's nights (the secret rave, Smoła, `rave.gd`, `club.gd`) are a different
questline and are not covered. The drag itself has its own document (critique-drag-race.md); here
it is one beat.

Design only, no game code. Read: `street_meet.gd` (stages, raid, cordon, race, watch),
`ladder.gd` `CLUB`, `night-meet.md`, `quest-map.md`, `race-ai-tuning.md` (the club rows),
`pacing.json` "meet", BACKLOG "Night racing club", PLAYTEST P20, R11, PT-33, PT-34, PT-48 to
PT-52. No sim: the chain's questions are about structure, and the drag's numbers are in its own
document.

## 1. What it is now

| # | Beat | What the player does | About | Can it go wrong? |
| --- | --- | --- | --- | --- |
| 0 | Darek's call (21:00-4:00) or WCHODZĘ! at Parkingowa (the clock jumps to 21:00) | two taps | 10 s | no |
| 1 | Drive to Plac Defilad, stop in the ring's gap | drives 400 m | 40 s | no |
| 2 | Meet 1: four lines, Lena's donuts | stands still | 9 s | no |
| 3 | Raid 1: NALOT!, four cordon cars stop 9.5 m round you, the chase at koguty 2 | drives out through a gap | the pin comes after 4.5 s whatever happens | no: caught, cautioned or clear, "the night goes on" |
| 4 | The race to the stadium, 2.9 km, eight club racers with every shortcut | races | 135 to 155 s | a place: 200 / 120 / 60 / 0 zł |
| 5 | Meet 2: four lines, Lena and Darek's tandem | stands still | 12 s | no |
| 6 | Raid 2: the same again | drives out | 5 to 20 s | no |
| 7 | Drive to Aleja Zieleniecka, watch two pairs launch | drives 500 m, watches | 30 s + up to 25 s | no (START DRAG skips the watching) |
| 8 | The drag against Tadek | a hold and three taps | 12 s | REWANŻ, free |

About 6 to 7 minutes. Pay at most 500 zł and 120 respect, and the club card. Darek calls again 25
to 40 minutes later: the same night, with the race one class faster (D to A over four nights).

## 2. The critique

- **One beat in nine is played.** The race is about 2.4 minutes of real driving against real AI
  and is the best thing here. Around it: 21 s of standing, two raids that end by a timer, a
  watched tutorial and a 12 s finale that today cannot really be lost (its own document: mashing
  at the first yellow beats Tadek by 1.2 s).
- **Nothing carries.** Coming first or last to the stadium changes one toast. Being caught in a
  raid changes nothing. The drag has no stake. Each beat pays and forgets, so the night is five
  small jobs in a row, not a story that tightens.
- **The raids are a picture, not a chase.** The four cordon cars are props (`scene_car`: parked,
  solid, never chasers); they leave after 25 s wherever you are (a fix for a 200 s stuck, playtest
  2026-11-16). The real chase was lost in 8 s at 108 km/h (PT-34), then given a 15 s floor: a
  timer. And the pin lands 4.5 s in, so the race starts under it. Nothing the player does in a
  raid is better or worse than anything else.
- **Raid 2 is raid 1.** Same cordon, same three lines, three minutes later. The second time it is
  a delay.
- **The meets are waited through.** Lena's donuts and the tandem are the look of the whole quest,
  and the player's part in them is to park.
- **The race's result depends on a setting.** In Busy traffic a club racer far from the player
  loses up to 170 s on the 2.9 km (race-ai-tuning.md): a walkover on one traffic level, a fight
  on another. And nobody says who is ahead by how much: a place badge only.
- **No reason for night two.** The same 18 lines, places and order. `wnrc_member` and `wnrc_wins`
  are written and never read.
- **You never know where you are in the night.** No beat counter. The pin's "next place" could be
  the last or the third.
- **Rough edges on record.** Driving north out of meet 2's square lands on the railway bed at 6
  km/h (BACKLOG, open). PT-49: the first-10 note over the rev counter (suspect, open).
- **Never played through by a hand.** P20 reached the race and the drag by teleport; the Autopilot
  re-run after PT-33/PT-34 and the phone check (smoke, the cordon, the rev counter, a bench at the
  meet) are still open lines in BACKLOG.

Right and staying: the cast (Darek, Lena, Tadek) and the motto, the look of the ring (neon, smoke,
marks), the cordon driving in, the COTAM pin, the racers on the minimap, the club's pack with its
own profiles and the class a night, the gate, the route across the river to the stadium.

## 3. Rules and feel fixes

### 3.1 The pot: one number that the whole night feeds

`pula` (the night's pot, zł), shown in the night bar (3.2). Nothing is paid until the end.

| Beat | Into the pot |
| --- | --- |
| Arriving at meet 1 within 60 s of WCHODZĘ! | +40 |
| Raid: out of the cordon before it closes (3.3) | +60 ("CZYSTO") |
| Raid: the chase shaken without a touch | +40 |
| The race | 1st +200, 2nd +120, 3rd +60, the rest +20 |
| Caught or cautioned in a raid | the pot halved ("mandat") |
| The drag | win: the pot ×2 and +80 respect; lose: the pot ×0.5 and +10 respect |

Paid on the result card with its sums in one line („Pula 320 zł × 2 = 640 zł”). A clean night
with a win is about 680 zł (500 today); a sloppy one with a loss 10 to 60. REWANŻ after a loss
costs half of what is left, once. This also answers BACKLOG's parked "a stake to enter the drag?":
the stake is the night, never the wallet.

### 3.2 The night bar

Five pips over the status line: SPOT · NALOT · WYŚCIG · SPOT 2 · DRAG, the current one lit in the
club's red, the pot beside them. It replaces the per-beat titles. Cost: one HUD row.

### 3.3 A raid you can win or lose

```
t = 0.0   a siren from one side and blue light on the facades there, 2.0 s BEFORE "NALOT!"   # the tell
t = 2.0   NALOT!; the cordon cars start in from CORDON_FROM 34 m, CORDON_T 2.4 -> 3.2 s
          the gap opposite the siren is WIDE (6.5 m); the others are 3.2 m (a car is 1.8 m wide)
out of the ring (CORDON_R + 4 m) before the cars stop  -> CZYSTO, +60
still inside when they stop                             -> boxed: the narrow gaps only
t = 5.2   two of the four cordon cars become chasers (BACKLOG's "later" item), koguty 2
the chase: no 15 s floor; it ends by the usual rules (160 m from every chaser)
the pin comes at t = 4.5 as now: the first 500 m of the race are the escape
```

A player who heard the siren and was already rolling is out clean and leads the race. One who
watched the smoke fights out through a 3.2 m gap with two cars on his bumper.

### 3.4 Raid 2 is a different beat

No second cordon. At meet 2, after Tadek's challenge, a searchlight sweeps the square from the
road above (one light on one patrol car): 8 s to leave by either of two exits before it finds
you. The short way to the strip is the lit one for the first 4 s; the longer one is dark (the
coder takes both from the lane graph round the square and names them in the PR). Found: koguty 2
and the pot's "mandat" rule. A fence closes the way north onto the railway bed.

### 3.5 The race tells you about itself and pays into the drag

- The gap to the car ahead and behind, by name, under the place badge („LENA +1.8 s”, „DAREK -0.6
  s”), refreshed each 0.5 s.
- One COTAM hint a night from Darek at the first split („Przez Solec szybciej. Nie mów Lenie.” /
  "Solec is quicker. Don't tell Lena."): one of `race_cuts.json`'s cuts on the player's own route,
  drawn on the minimap for 6 s.
- The club's pack always plans for "Normal" traffic density whatever the setting (the town's cars
  stay as set): the race is the same fight on every level.
- First or second at the stadium: "rozgrzane opony" / "warm tyres" in the drag (the launch's blue
  zone 0.04 wider) and the left lane. Fifth or worse: Tadek's line is „Długo cię nie było.” / "You
  took your time." and the zone is the night's own.

### 3.6 The meets take part of you

- Meet 1: the gap in the ring is at the far side, so you drive a half lap round Lena's smoke to
  park; the crowd's phones turn to you by your arrival bonus. Four lines become three (7 s).
- Meet 2: the lines play while the racers still arrive in race order: the ring fills as they
  come, your place decides how full it is when you stop. First: an empty ring and Lena's „No
  proszę. Nowy pierwszy.” / "Well, well. The new guy's first."
- The watched pairs: one pair (12 s) on night 1, with Darek's line; none from night 2.

### 3.7 Four nights, then open nights

| Night | Race class | Tadek (critique-drag-race.md 3.5) | The card | What changes |
| --- | --- | --- | --- | --- |
| 1 | D | night 1, no bottles | KANDYDAT / CANDIDATE | the lines as now |
| 2 | C | night 2 | CZŁONEK / MEMBER | new lines (set B); the raid's siren side changes |
| 3 | B | night 3 | STARSZYZNA / ELDER | set C; Lena races flat out (her profile's `share` +0.02) |
| 4 | A | night 4 | LEGENDA NOCY / LEGEND OF THE NIGHT | set C; the underglow colour of your choice (BACKLOG's idea) |
| 5 and on | A | night 3 or 4 by a roll | the best drag time on the card | Darek calls once a night at most; the pot's record |

A night counts when the drag is won. The card is a notebook page: the level, the nights, the best
402 m, the biggest pot.

## 4. The fun set

| # | What | Next version | Cost |
| --- | --- | --- | --- |
| 1 | The pot (3.1) and the night bar (3.2) | in | S |
| 2 | The race's gaps by name and the warm tyres into the drag (3.5) | in | S |
| 3 | The raid with a siren tell, a wide gap, CZYSTO, two cordon cars that chase (3.3) | in | M (police.gd hands two scene cars to the chase; the check's raid) |
| 4 | Four nights: Tadek's tiers, the card's levels, two more line sets (24 lines, Polish with English) (3.7) | in | S + the drag's rework |
| 5 | Meet 2 fills in race order; one watched pair, then none (3.6) | in | S |
| 6 | Raid 2 as the searchlight with two exits, and the fence by the railway (3.4) | in | M (a light, an exit test, one fence in the map lane) |
| 7 | Darek's shortcut hint on COTAM (3.5) | in | S |
| 8 | The crowd reacts to you: phones up for a first place, a flat „Aha.” for the last; after the drag the ring runs to the winner's car (the existing crowd, new targets) | in (phones and lines), out (the run) | S / M |
| 9 | Racers get caught: a ring car the cordon boxes is out of the race, with a COTAM line („Golfa zwinęli. Znowu.” / "They got the hatchback. Again.") | out | M |
| 10 | Show off at meet 1: your own donut in the ring for the pot. Waits for the drift quest (drift-narodowy.md, planned): there is no drift scoring in the game yet | out | M after that |
| 11 | Meets that move (Browary, Wał Miedzeszyński from night-meet.md's list) | out | L (each ring needs clear ground, the check's 17 m rule, a race course) |

On-screen words (new): PULA / POT, CZYSTO / CLEAN, MANDAT: pula ÷ 2 / FINE: pot ÷ 2, ROZGRZANE
OPONY / WARM TYRES, the pips SPOT · NALOT · WYŚCIG · SPOT 2 · DRAG (English: MEET · RAID · RACE ·
MEET 2 · DRAG), the card's four levels above.

## 5. Build plan and what only the phone shows

1. The drag's own steps 1 and 2 (critique-drag-race.md 5): without a real Tadek the pot's ×2 is
   free money.
2. Items 1, 2, 5, 7 here: one PR in `street_meet.gd` and the HUD row. `check_street_meet`: the
   pot's sums for a clean night, a caught night and a lost drag; nothing is paid before the card;
   quitting (the ✕, PT-52's paths) pays nothing and gives the tune back.
3. Item 3 (the raid), with `check_street_meet`'s cordon rows: the wide gap faces away from the
   siren, a car that leaves in the first 3 s is CZYSTO, two chasers exist after 5.2 s.
4. Item 4 (the nights) and 6 (raid 2; the fence goes to the map lane).
5. An Autopilot run of the whole chain without teleports (P20 has never had one), then the phone.

Add-ons check: Beehave not used (the chasers keep the police's own trees; the cordon hand-over is
one entry point). Dialogue Manager not used (short bubbles, no choices).

Full definition of done (gameplay, lights): verify, shots of both meets and both raids, bench at
meet 1 with the cordon in and at the searchlight.

Only the phone shows: whether the siren's side can be heard on the phone's speaker (the blue
light is the backup; test with the sound off); a 3.2 m gap under a thumb; the night bar and the
pot beside the police pill; the smoke, 16 people, four patrol lights and the neon slabs in one
frame (the bench at the meet was never run on a device); whether 5 to 6 minutes holds a player on
a phone, or the chain should save after the race.

## Open questions (parked; the default is what this specifies)

- **Raid 2 as a searchlight** changes F's "the cops come again" from a second cordon to a
  different beat. Default: built as the searchlight. The stronger option, if F agrees: move it to
  **after** the drag, as the night's ending (escape to bank the pot); it changes the order F asked
  for, so it is not the default.
- **The pot halved when caught** is the first real loss in the chain. Default: built; never to zero.
- **Mid-night save** (after the race) if the phone round finds 6 minutes too long. Default: none.
- Should Mati's nights (the rave, Smoła) get the same critique? Not covered here.
