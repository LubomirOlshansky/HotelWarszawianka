# The main line: one story thread through the demo

F's ask (2026-10-31): tell the main line apart from the side quests on the minimap and the full
map, and shape the main line so the first 10 minutes come first and the whole of it fits in about
an hour. This page is the design; `game/scripts/main_line.gd` is the code (its `step` says what
the main line wants now), `game/tools/check_main_line.gd` the check.

The demo already had the pieces (docs/DEMO.md 6.2 "The first 10 minutes", 6.3 "The first hour":
the guide, the rival ladder, the final "Trzy mosty", the end card). What it lacked was one thread
that says "this is the story, the rest is the city": every target looked the same (a dot in the
job's colour), and between the guide and the final nothing on the map said where to go next.

## 0. For now: only the first kebab (F, 2026-11-08)

F: after the first task the star confused them while they were on a quest they had taken. Until
the main line is reworked, `main_line.gd` FIRST_JOB_ONLY gates it (`now`): the star, the goal card
under the full map's title and the nudge on the driving screen show only while the guide runs and
no job is done yet, that is for the first kebab order. After it the main line is "done" and the
guide's later targets (Pani Halina's race and the rest) are ordinary pins. The chapters below stay
written; FIRST_JOB_ONLY false brings them back. The quest the player took is the marked one now:
a glowing, pulsing pin in its colour (hud.gd `active_pin`) on the minimap and the full map, with a
dotted line from the car on the full map, and the full map's quest card has a quit button (two
taps) that gives the quest up as its status ✕ does.

## 1. The three chapters

| Chapter | Time | What the player does | Where the marker points |
| --- | --- | --- | --- |
| **1. Pierwsze kroki · First steps** | 0:00-10:00 | The guide (first10.gd): the first kebab, Pani Halina's race, the first speed trap, the first rescue, the helicopter, the boulevard cassette, Powiśle, Mirek's garage | Whatever the guide points at: its arrow, or the target of the beat on now (the order's door, the race finish, the hospital) |
| **2. Drabinka · The ladder** | 10:00-~45:00 | The five rivals after Halina, in order of stake: Słoik z Radomia, Bulwar Bartek, Seba z Pragi, Taksiarz Zbyszek, Mordor Mike. Each is a cruising car: find it, sit on its bumper, flash | The next rung's rival, live, pinned to the minimap's rim at any distance; during that race, the finish |
| **3. Trzy mosty · Three bridges** | ~45:00-~60:00 | The final against Seba at night, from Rondo Daszyńskiego over three bridges to the stadium; then jobs up to ten for the end card | Seba's start at night; during the race the next bridge, then the stadium |

When a rung needs more respect than the player has, the main line has no place to point: the goal
line says "Zdobądź szacunek: 180/220, potem Bulwar Bartek · Earn respect: 180/220, then Bulwar
Bartek" and the side quests are the way. By day, once the final is open, it says the final is at
night (the clock, or the Night look in Settings). After the end card the main line is done and
only side quests show.

### What counts as the main line

- During the guide (chapter 1), **everything** it pushes is the main line, the first kebab order and
  the first rescue included: the first ten minutes teach the game through those.
- After the guide, a race is the main line only when it is the **next rung's** (or the final). A
  beaten rival re-raced for the stake is a side race.
- Everything else is a side quest: kebab and słoiki, Podwózka, the courier race, Na czasie, the
  scooter round-up, rescues after the first, the notebook, the Syrenki, the eggs, the cassettes.

## 2. Pacing: the final inside the first hour

A rung's first race win gives +100 respect (a rematch +20 since the designer pass of 2026-11-01,
docs/design/pay-tables.md, so re-racing Halina is no shortcut). Before this change the gates were 0/100/250/400/600/850 and 1100
for the final: six wins give 600, so the side quests had to bring about **500** respect. A side
quest gives 10 (a hot kebab), 15 (Na czasie, a cassette, an escape), 30 (słoiki, a courier race),
40 (a rescue, the round-up): about 10 respect a minute for a player who mixes them, so ~50 minutes
of side quests on top of ~25 of races and the guide's 10: **~85 minutes**, over the hour.

The gates now are **0/100/220/340/480/640 and 850**. The side quests bring **250** in all (the
check holds it between 150 and 300), and about 80 of that comes inside the guide (the first
kebab, the first rescue, the cassette, Powiśle and the other districts on the way, a few notebook
places). What is left, rung by rung:

| Rung | Gate | Respect after the wins before it | From side quests here |
| --- | --- | --- | --- |
| Halina | 0 | 0 | 0 (the guide's race) |
| Słoik z Radomia | 100 | 100 | 0 |
| Bulwar Bartek | 220 | 200 | 20 (already met by the guide's extras) |
| Seba z Pragi | 340 | 300 | 40 |
| Taksiarz Zbyszek | 480 | 400 | 80 |
| Mordor Mike | 640 | 500 | 140 |
| Trzy mosty | 850 | 600 | 250 |

Estimate for an ordinary player: 10 min guide, ~3 min a rung (finding the rival, the race), ~17
minutes of side quests between rungs 3 and 6 and the final, ~5 min the final: **~50-60 minutes**.
Race wins alone still stop at the third rung (`check_ladder`, `check_main_line`), so the side
quests stay part of the way, they just no longer double its length. The stakes, the paces and the
final's pay (500 zł, +250 respect) are unchanged. Old saves keep their respect, so a rung may open
for them at once (the "New rival" toast says so).

*The minutes are estimates from the pay tables, not a played hour.* A timed playthrough on the
phone is the real gate (QUESTIONS.md).

## 3. The markers

| | Minimap | Full map |
| --- | --- | --- |
| **Main line** | A gold five-point star with a dark rim in a pulsing gold ring, pinned to the rim at **any** distance (the one thing that is always findable) | The same star, bigger; off the screen it waits at the screen's edge, smaller, on the way to it. Under the title a gold goal card: "★ Znajdź i mrugnij: Słoik z Radomia" / "Find and flash: Słoik z Radomia" |
| **Side quest, active** | A dot in the job's colour (kebab orange, Podwózka teal, rescue red, race) inside a white ring, pinned to the rim | The same ringed dot, bigger |
| **Side quest, places to start one** | Small blinking squares in the job's colour, up to 700 m (kebab stands, the station, the scooters) | Squares in the job's colour, all of them |
| Not found yet | The gold "?" | The gold "?" |
| Garage | The diamond (Mirek's) | The diamond |

A legend bottom left on the full map names the four shapes (Polish · English); it gives way to the
hold-to-jump hint on a narrow screen. The final's start diamond is gone: at night the main line's
star stands there. Gold stays the main line's; the side quests keep their jobs' colours, so a star
and a dot never look alike even in the corner of the eye.

Cost: the star is 20 triangles and its ring 64, in the minimap overlay's one triangle batch (+0
draw calls); the step is looked at four times a second (a dictionary of facts, no scans); the full
map's legend is one card.

## 4. Open (parked in QUESTIONS.md)

- The new gates (0/100/220/340/480/640/850) and the hour: F to time a fresh save on the phone.
- ~~The main line's star on the screen's edge arrow too~~ and ~~a short goal line on the driving
  screen~~: built 2026-11-03 as a nudge (`main_nudge.gd`): the goal line is a toast 4 s after the
  step changes; the edge arrow in gold with "★ N m" shows for 25 s then and again after every
  150 s of free driving, only while nothing else is on, so the first screen stays clean. The
  timings wait for F's run on the phone.
