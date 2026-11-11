# Nocny spot: the Warsaw Night Racing Club (F, 2026-11-06)

F's ask (in Ukrainian, 2026-11-06): a quest about a Warsaw night racing club. Your BMW friend calls
and asks if you want to come to a street racers' meet on a big shopping-centre car park; someone
drifts a Porsche in the middle; the cops arrive, everybody runs, a pin comes with the next place and
you must get there first for bonus points; the cops come again; the next place is a drag, cars
launch before you, a START DRAG button teleports you to a long straight and you race and win
respect. All at night. Think about the police and rival AI, animations, dialogue, ideas from street
racing films and games (genre only: nothing copied).

F approved the proposal as posted in the thread; the voice-over comes later; test with Autopilot
after the build. Code: `game/scripts/street_meet.gd`, check `game/tools/check_street_meet.gd`
(verify step `meet`).

## Names (parodies only)

| Who / what | In game | Parody of |
| --- | --- | --- |
| The club | WARSAW NIGHT RACING CLUB (WNRC on TYGRAM) | generic, F's own words |
| Your friend | Darek „Bawarka", dark-blue Bawarka 3.2 saloon, two-part grille | a Bavarian saloon |
| The drifter | Lena „Bokiem" ("sideways"), silver Porszę 912, duck tail | a Stuttgart coupe |
| The drag boss | Tadek, matte black Nisan Skajlajner, tinted glass, tall wing | a Japanese GT |
| The messenger | TYGRAM (as in the Dżemini job) | a messenger app |
| The motto | „Ćwiartka nie kłamie." / "The quarter mile doesn't lie." | original |

No characters, quotes, catchphrases or memes from the films or games that inspired the genre
(`check_street_meet` rejects the obvious ones and every brand in `brand_denylist.json`).

## The flow

1. **The call** (night, 21:00-04:00, nothing else on; 4-8 minutes into a night, then 25-40 min
   apart). ODBIERZ / ODRZUĆ, then JADĘ! / NIE DZIŚ. The rescue calls pause.
2. **Meet 1, Plac Defilad** (the plaza east of the Palace). Six tuned cars in a ring (the traffic's
   pool cars in neon paints) with neon slabs under them, Darek's Bawarka, 16 people round the ring,
   and Lena spinning donuts in the middle: tyre smoke (22 puffs) and a circle of black marks. Stop in
   the ring's gap: six lines from Darek, Lena, Tadek and the crowd.
3. **Raid 1.** NALOT! `police.raid` brings two or three patrol cars in from the roads round the
   plaza, lights on, koguty 2 on you at once (no grace, no cooldown). The crowd runs off, every car
   glides off the plaza to the road and drives off fast. Get 220 m away (a meet off the road is no
   hiding place) and let the chase end (escape, end of shift or a caution: the night goes on). A
   raid's chase can't be shaken in its first 15 s and needs 160 m from every chaser (PT-34).
4. **The pin and the race.** TYGRAM: "📍 Parking pod Narodowym. Kto pierwszy, ten lepszy." Every
   racer races there from wherever it fled (racer mode, 0.86-0.97 of your top). The status shows
   your place live. Place pays 200 / 120 / 60 / 0 zł and 40 / 25 / 12 / 5 respect.
5. **Meet 2, the coach park south of the National Stadium.** The racers park in a new ring, Tadek's
   Skajlajner is there; four lines; **raid 2**; the pin: Zieleniecka, by Stadion station: the drag.
6. **The drag** (Aleja Zieleniecka, 904 m straight, two southbound lanes 3 m apart; the line 80 m
   from the north end, 402 m to the finish). Stop by the start: two exhibition pairs launch in front
   of you, then **START DRAG** puts you on the line next to Tadek. The tree: three ambers 0.5 s apart,
   green after up to 0.45 s more; moving before green is FALSTART. Darek's ECU map gives the car
   1.5× its top over four gears (34 / 57 / 79 / 100 %); at the top of each gear the button says
   BIEG! ⬆ TERAZ: within 0.35 s a perfect shift (×1.7 pull for 1.1 s), later a plain shift,
   before it a bog, and after 1 s the box shifts itself. NITRO works (a bottle on loan without the
   garage's). Tadek's run is the "ok" run of your own car (0.6 s late shifts) sped up to half the
   way to a clean run (0.35 s reaction, shifts 0.15 s after BIEG!): clean shifts or the nitro beat
   him, a lazy run doesn't (hatch: clean 11.36 s, Tadek 11.85 s, ok 12.35 s, lazy 13.06 s, clean +
   nitro 10.07 s). On the line and in the run the car holds the strip and any gas is full gas: a
   drag is the launch and the shifts (PT-33: the stick's aim and a part push lost 1.4 s on the
   Mac). `check_street_meet` drives the real car.gd too, its stick 20° off at 75 %.
   Win: RESPEKT!, 300 zł and 80 respect, the club card (`wnrc_member` in the save), the best time
   (`drag_402`). Lose: REWANŻ (again from the line) or KONIEC.

Traffic is cleared off the strip at the line and while the run lasts; the police are gentle during
the drag (no chase starts).

## Cost

Idle: one 0.25 s look. At a meet: marks, smoke, the neon slabs and the crowd (one draw call each),
Darek's and Lena's cars and their lights (four); the ring's cars are traffic pool cars (no new draw
calls). At the drag: Tadek's car and two exhibition cars at a time (two draw calls each with the
lights). Bench by the meet still to do on the phone.

## Add-ons check

Beehave: not used. The racers drive in traffic.gd's racer mode and the police use their own
beehave trees as before (only a new entry point, `police.raid`). Dialogue Manager: not used; the
lines are short bubbles, no branching talk.

## Left (BACKLOG "Night racing club")

- Voice for Darek, Lena and Tadek (ElevenLabs, F said later).
- Autopilot run on the Mac (F asked): call, meet, raid, race, drag.
- Phone check: the drift's smoke and marks, the tree's size, the BIEG! button's place under a thumb.
- Pay to enter the drag (a stake)? Parked for F; built without.
- A club card in the notebook, weekly meets at other places (Browary's meet, Wał Miedzeszyński),
  spectators filming with phone lights, underglow paint in Mirek's garage after a win.

## F's pass (2026-11-08)

F played it and found it weak. Changed in `street_meet.gd`:

- **Start spot** (F 2026-11-11). Darek waits on the kerb of Parkingowa by Rondo Dmowskiego (about
  380 m south of the spawn, out of the first view), not by the plaza; after WCHODZĘ! the beacon
  sends you up Marszałkowska to the ring on Plac Defilad.
- **Night.** Accepting at the start ring jumps the clock to 21:00 (PR #582's WAIT TILL 21:00 card, the
  questline start's own thread).
- **Meet 2** moved from the plaza south of the stadium (two fences through the ring) to the paved
  square at the stadium's north foot, under its facade (about 15 m from any fence, road, tree or the
  car park's parked cars; the open apron off Zieleniecka was tried first and was full of parked cars). Lena and Darek drift a tandem there (Darek on her bumper, 0.8 rad behind, 0.9 m wider).
  `check_street_meet` now fails if a fence, wall, guard rail or building comes within 17 m of a ring.
- **Meet 1** talks 9 s (4 lines), not 15 s.
- **Raids.** Four patrol cars (police.gd `scene_car`, lights on, solid, never chasers) drive in
  across the plaza from 34 m out and stop 9.5 m round you, noses in, with the gaps between them as
  the way out; the road chasers still come. They leave out of sight once you are 90 m away.
- **Minimap.** The racers show as neon dots (hud.gd `set_quest_dots`, pinned to the rim when far)
  during the raids and the race.
- **Racers** race at 1.0-1.06 of your top speed, 6-8 m/s² and 7.6 m/s² in corners, with every
  shortcut in race_cuts.json.
- **Drag.** A start gate over both lanes (chequered line, lit club-red banner, a small tree of
  lights); stop on the line under it to stage (START DRAG still works). The count is a big 3, 2, 1,
  START! on a 0.8 s beat. A rev counter at the bottom middle (0-9 thousand; yellow get ready, green
  shift now, red the limiter; gear and km/h in the middle): tap it (a second finger) or the ⬆ BIEG
  button to shift. No auto-shift on time any more: only 2.5 s on the limiter makes the box shift
  late for you.
- **Launch and grades (F 2026-11-09, "look how arcade games do it", CSR-style drag games)**: on the
  line the gas only revs the engine and the car stays put; at green the needle in the blue launch
  zone (0.55-0.78 of the range) is a perfect launch (a burst), over it wheelspin (accel × 0.55 for
  0.9 s), under it a bog. Holding the gas from the first amber overshoots: a tap-and-hold at "1"
  lands it. Shifts: yellow = good, green = perfect (a burst), before the yellow = early (a bog),
  0.8 s past the green on the limiter = late. No false start by gas any more.
- **Less on screen during the drag** (F: "lots of dialogs one over another"): the bubbles clear on
  the line, Tadek speaks while you watch instead, and the radio ticker, info notes and flavour toasts
  wait until the result (`hud.set_hush`).
