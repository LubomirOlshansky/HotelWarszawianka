# Testing backlog

F's ask (2026-11-06): a separate backlog for testing, built from the comment history, worked
through until every test is done. This file is the queue; `docs/PLAYTEST.md` keeps the plan rows,
the case lists and the PT-n bug log. A run takes one line here: tick it, name the run, link the PT
ids. Bugs are reported, not fixed here; each one gets its own fix thread.

Each row is one Autopilot run of under 6 minutes on the Mac (`.claude/skills/autopilot-playtest`).
Order: fixes waiting for proof, then what F asked about, then the plan rows never run.

## 1. Fixes waiting for proof

- [x] T1 PT-23 and PT-24 (#460): the offer over the ride app at `-735,1722`, backing off at `-680,725` · 2026-11-06 run -100916: offer in 10.8 s at the yard, 8.05 s at the barrier, tow taken at both: PT-23, PT-24 verified
- [ ] T2 PT-25 crazy drivers' lines: with `--crazy-log`, why 5 cut-ins gave no line · fix built 2026-11-07 (a refused line waits 6 s instead of being spent): re-run near the Patelnia, expect lines > 0
- [ ] T3 PT-19: the map teleport hold at `-700,900` leaves the car in place · 2026-11-07: the teleport lands there headless (`--teleport-test`); the map's refusal was unwired in play and is fixed; re-run the hold, and a hold mid-job must say "Nie teraz"
- [ ] T4 The P2 re-checks: PT-11 (first race), PT-15 (two offers at once), PT-16 (order result card)
- [ ] T5 PT-18 ramp stop on Solec and PT-20 toast, on the next P11 and P13 runs

## 2. What F asked for

- [ ] T6 Roadworks block every road end ("make sure there are the block roads on the end of the map", 11-05): P7, north, east and west closures, and traffic queued at them · run -101542: Grójecka held; Grochowska has a gap on the tram strip (PT-28; collider and barriers built 2026-11-07, re-run `--at=2174,-1448`); Andersa, Okopowa and Jana Pawła II still to reach by road
- [ ] T7 Objects that are invisible but solid ("check for more objects with such bug", 11-05): log every stop with nothing on screen · runs -104826, -105503: dead stops at -755,691, -743,730 and -775,653 looked invisible at first; frames at -775,653 show a dark traffic car, so no invisible object found yet
- [ ] T8 Collisions with cars ("car stuck each time it collides", 10-29): ram traffic at 15, 40 and 80 km/h, time to drive off · runs -102831, -104826: a hard hit on a traffic car costs 6-12 s, with the tow offer at 8 s; no permanent pin
- [x] T9 Tiny objects on the road ("driving is heavy", 10-29): after smooth roads (#447), one steered street per run · run -103535: Emilii Plater, Bracka, Krucza at 45-55 km/h with no stop from a small object
- [ ] T10 Police and racers ("make them smarter, then test", 11-04): P10 and P17, can the chase be escaped by a fast agent · run -104826: no chase at 108 km/h for 140 s, even with --police-now (phase stayed Calm): the harness needs another way to start one
- [ ] T11 Radio ("make sure the new radio interface and songs are there", 11-05): station change, from the #454 branch
- [ ] T12 Złote Tarasy corner screen and Skwer Linearny (11-05): drive and look, from the #456 branch
- [ ] T13 Crazy drivers in thick traffic: Marszałkowska south, at speed, how close they come
- [ ] T14 Button driving, the default (#425): the on-screen GAS, BRAKE and slider, not keys
- [ ] T15 Patelnia from the west by Kokota, and the Rotunda stair once more after #452 merges · run -092040: north-east side and the stair done (P18); west still open
- [ ] T16 The look of the starting street shops and Świętokrzyska tents (#449): frames, day and night

## 3. Plan rows never run or left open

- [ ] T17 P1 the other start streets (only Marszałkowska driven) · run -103535: Emilii Plater, Bracka, Krucza clean; Chmielna, Mokotowska still open · run -110225: Mokotowska clean bar one stop at -111,612; Chmielna open
- [ ] T18 P4 Krakowskie Przedmieście, Plac Zamkowy, Old Town · run -102201: Krakowskie Przedmieście and Nowy Świat clean at 50-60 km/h; the Old Town core still open
- [ ] T19 P5 bridges and ramps, W-Z tunnel, Wisłostrada · run -102831: Most Śląsko-Dąbrowski and Most Świętokrzyski clean at 70 km/h; Poniatowskiego and Tunel Wisłostrady not reached · run -105503: Poniatowskiego landing was under the viaduct, deck still undriven
- [ ] T20 P6 Powiśle and the river edge, water tow
- [ ] T21 P8 helicopter landings, rescue roofs
- [ ] T22 P9 menus: pause card, map, garage, settings, POMOC DROGOWA · run -104211: gear, Escape, HELI and CAR, radio, ✕ all work, no trap; pause tabs, full map, garage still open
- [ ] T23 P11 the tunnels driven through (C11.1, C11.3, C11.4) · run -105503: Armii Ludowej and the Wisłostrada approach clean; the tunnel itself cut off by the time limit
- [ ] T24 P14 narrow streets, steered · run -110225: Hoża steered to -530,995 clean; Frascati, Ordynacka, Sienna open
- [ ] T25 P15 the helicopter to Varso and the map edge
- [ ] T26 P16 Trzy mosty frames at race speed

## 4. Only the phone can show

Parked until F allows a device run: touch feel, frame time and heat, the button ranks' look (#460),
PT-27 on a real screen.
