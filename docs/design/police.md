# Police: design spec for loop 3g

Written 2026-10-28 by the game-designer for **loop 3g (Police)**, after the user's answers in
docs/DEMO.md section 8: **gentler police** (warnings and funny lines only, **no fines, no money
taken**), chases **short and always escapable**, **driving into the Old Town is allowed** and the
city guards react, the **helicopter is available from the start**. This file replaces DEMO.md
section 5 (5.1 to 5.8); DEMO.md should point here. Numbers marked *guess* are first values with
the way to tune them.

What 3g builds on: traffic drivers and MultiMeshes (`traffic.gd`), the rivals' lane-graph racing
(`traffic.race_to`, `lane_graph.distances_to`), bubbles and tags (`bubbles.gd`), lines
(`dialogue.gd`, `data/dialogue.json`), cards, pills, toasts and the wallet (`hud.gd`, `wallet.gd`),
the 4 m roof grid (line of sight), the pedestrians' MultiMesh, `make_sfx.py`. The three add-ons
the user approved for this loop (beehave, Dialogue Manager, Phantom Camera) are used as in
section 11.

---

## 0. In one screen

- **Who.** Patrol cars ("radiowóz") driving in traffic; a speed trap ("suszarka", the radar gun,
  literally "hair dryer") at 3 of 7 fixed spots a day, with an officer who waves the "lizak" (the
  round stop paddle); city guards ("Straż Miejska") on foot in the pedestrian zones and Łazienki,
  with one slow guard car. Three invented characters: **Sierżant Bogdan** (has seen everything),
  **Posterunkowy Kacper** (young, reads the rules aloud), **Strażnik Henio** (city guard, notebook).
- **What it costs you.** Seconds, never złoty or respect. Being stopped is a 6 to 8 second funny
  conversation that ends in a caution ("pouczenie") written in a joke notebook. Escaping pays a
  little respect. Nothing is ever taken from the wallet, nobody is arrested, nothing is rammed.
- **Escalation.** Warning (a megaphone line) → koguty 1 → 2 → 3, lost at 100 m or 4 s out of
  sight plus 8 s of searching. First-hour step 2 (F, 2026-11-15): no countdown on screen; the
  pill shows the gap to open instead, the chasers tire after 30 s so the gap always opens, the
  hiding spots blink on the minimap, Mirek's garage unseen ends a chase, and a hidden backstop
  ends any chase at 120 s ("Koniec zmiany!", end of shift). Before it each chase was capped at
  30 / 40 / 45 s by level, shown as "END OF SHIFT IN 0:27".
- **Ties.** On a rescue the police escort you to the hospital (+10 s on the clock). A race seen
  by police pulls in a chase; escaping it adds 20 % to the stake. Kebab, słoiki and (from loop 2d)
  the app-taxi each get their own pull-over joke.
- **Cost.** ≤ +3 draw calls (one police MultiMesh in the main and shadow passes; light-bar halos
  at night), scripts ≤ 0.15 ms on the Mac, ~1 MB.

---

## 1. The player's minute

**First contact (the 3:00 beat of DEMO 6.2).** Driving back from the first race, the player passes
a white-and-blue estate parked on the kerb with a figure in a lemon vest beside it. The figure
raises a round paddle; a pill says *ZATRZYMAJ SIĘ PRZY POLICJANCIE · PULL OVER BY THE OFFICER*.
The player stops (or not: see below). The view eases in on the two cars, a card opens with the
sergeant's face: *"Rutynowa kontrola. Spokojnie, nic pan nie zrobił. Jeszcze."* then *"Koguty na
dachu to my. Koguty w lusterku — też my."* A toast explains the rules in one line: *KOGUTY =
POLICJA. UCIEKNIJ ALBO STAŃ: NIC NIE TRACISZ · ROOSTERS = POLICE. ESCAPE OR STOP: YOU LOSE
NOTHING.* Eight seconds, two jokes, back to driving. If the player drives past the paddle
instead, the same patrol car switches its lights on and the first chase starts at koguty 1: the
same lesson, learnt by doing.

**A typical chase (after minute 3).** At 85 km/h down Wybrzeże Kościuszkowskie the player passes
a speed trap; the officer waves the paddle; the player keeps going. A two-tone siren, one rooster
lights up next to the wallet, a blue-red tint breathes at the screen edges, the camera eases back
to show the patrol car behind. A megaphone bubble: *"Kacper, włącz koguty. Nie, te drugie. Dobra,
jedziemy."* The pill says *UCIEKAJ · GET AWAY* over a gold bar that fills as the gap opens, and a
green ring blinks on the minimap under Most Poniatowskiego. The player cuts under the bridge (a
hiding spot), the patrol car loses sight, the rooster greys and blinks (*SZUKAJĄ CIĘ ·
SEARCHING*, the bar emptying), four seconds later *UCIECZKA! · ESCAPED!* and +15 respect.
Or the player stops at the kerb and gets the card and a caution. Either way, under a minute.

---

## 2. Who they are

| Unit | Count and where | Look (section 9) | Behaviour (beehave, section 11.1) |
| --- | --- | --- | --- |
| **Patrol car** (radiowóz) | In the traffic band: 1 at Low, 2 at Normal, 3 at Busy, 0 at Empty (*guess*). Main and secondary roads only. Never spawns within 200 m of the player while a chase is in cooldown | Estate, white upper body and roof, police-blue lower body, "POLICJA" on the doors, a two-lens light bar | Drives as traffic (obeys lights, `speed_factor` 0.95) and perceives; becomes a chaser, blocker or escort when the dispatcher (police.gd) assigns a role |
| **Speed trap** (suszarka) | 7 spots (table below), **3 active a day**, picked by the date like the roadworks (`--date`/`--barriers` style seed). Day and night | A patrol car parked on the shoulder, lights off; an officer 3 m upstream at the kerb, facing the traffic | Watches one direction; on a speeder the officer waves the lizak (section 5.2) |
| **City guards on foot** (Straż Miejska) | 2 at each pedestrian-zone entrance (Old Town: Plac Zamkowy, Nowomiejska by the Barbakan, Podwale, Krakowskie Przedmieście at Królewska), 2 on the Old Town Market Square, 2 in Łazienki, 1 on the Powiśle boulevards. Today's map: the boulevards and Krakowskie Przedmieście's south end only | Mustard jacket, dark red trousers, a notebook; part of the pedestrians' MultiMesh | Whistle, a line, a 3 s run after the car, give up panting; walk over to a car parked on the pavement (the clamp, 5.6) |
| **Guard car** | 1, in the sector of the Old Town or Łazienki when the player is there | The police estate's mesh at 0.88 scale, mustard, amber beacon, no lettering | Follows a car in a pedestrian zone at ≤ 25 km/h for 15 s, megaphone, then turns away |
| **Police helicopter** | Only at koguty 3, only at night, only for the chase | Never in frame: a searchlight pool sweeping round the player (a glow instance) and the rotor sound overhead | Sweeps; while the player is inside the pool the police keep sight |

**Speed traps.** Each sits on a straight run of the named road ≥ 250 m long with no junction node
within 80 m, the car parked off the lane on the kerb side (lane edge + 1.5 m), facing the traffic it
measures. The radar covers 40 m of that road ahead of the officer, one direction. Polish and English
phrases are for the radio host's line (`radio_host` "traps", section 6).

| # | Road (`e_name` in the graph) | Where (map metres, today's origin) | Direction measured | In the map | Radio phrase PL / EN |
| --- | --- | --- | --- | --- | --- |
| 1 | Aleje Jerozolimskie, by the National Museum | x 0 to 300, z ≈ 120 | eastbound (towards the bridge) | today | „w Alejach Jerozolimskich” / "on Aleje Jerozolimskie" |
| 2 | Wybrzeże Kościuszkowskie (the Wisłostrada) | x 400 to 650, z ≈ −560 | northbound | today | „na Wisłostradzie” / "on the Wisłostrada" |
| 3 | Aleja Jana Pawła II (south of Rondo ONZ today; by Arkadia in the demo) | x ≈ −1,614, z ≈ 417; demo ≈ −2,690, −2,400 | southbound | today | „na Jana Pawła” / "on Jana Pawła II" |
| 4 | Wybrzeże Szczecińskie (Praga bank) | x ≈ 1,240, z ≈ −560 | southbound | today | „na Wybrzeżu Szczecińskim” / "on Wybrzeże Szczecińskie" |
| 5 | Aleja „Solidarności” | demo, between Plac Bankowy and the W-Z bridge | eastbound | demo (3d) | „na Solidarności” / "on Solidarności" |
| 6 | Trasa Łazienkowska (OSM name to confirm: the ways may be named Trasa Łazienkowska or Aleja Armii Ludowej) | demo, west of Most Łazienkowski | eastbound | demo (3d) | „na Trasie Łazienkowskiej” / "on Trasa Łazienkowska" |
| 7 | Aleje Ujazdowskie | demo, between Plac Na Rozdrożu and Plac Trzech Krzyży | northbound | demo (3d) | „w Alejach Ujazdowskich” / "on Aleje Ujazdowskie" |

A spot whose road is not in the loaded map is skipped (the log says so); the day's three are then
drawn from those present. Speed limits come from the lane graph (`e_speed`, from OSM `maxspeed`;
all four of today's trap roads are 50 km/h, parts of Wybrzeże Szczecińskie 60).

---

## 3. What they react to

Perception runs **5 times a second** in police.gd for all units at once (no per-unit physics
queries): distance, a 180° cone in front of a patrol car (360° for guards), and line of sight by a
short walk through the helicopter's 4 m roof grid. The player's helicopter is never perceived as an
offender (it can't be chased), except landing in a pedestrian zone (guards only).

| Offence | Seen when | Result |
| --- | --- | --- |
| Speeding at a trap | > limit + 20 km/h inside the trap's 40 m | **Lizak** (5.2): stop by the officer → pull-over; drive on → koguty 1 |
| Speeding past a patrol car | > limit + 25 km/h within 40 m of a patrol car, in its cone | Warning |
| Red light | Crossing a stop line on red within 60 m of a patrol car with line of sight | Warning |
| Wrong way on a one-way street | > 3 s, within sight | Warning (a whoop and a pill, no line) |
| Bumping a police car | Contact 2 to 6 m/s | Warning ("bump" line); < 2 m/s nothing |
| Ramming a police car | Contact > 6 m/s | A strike that counts double (koguty 1 at once; +1 level in a chase, at most once per 10 s) |
| Racing | A street race within 60 m of a patrol car or an active trap, in sight | Koguty 1 at once (the chaser follows the player only) |
| Driving in a pedestrian zone (Old Town, Market Square, Krakowskie Przedmieście's car-free part, the boulevards, Łazienki's paths) | Entering the zone with a guard within 60 m | City guards only (5.6); **never the police, never a chase** |
| Parking on the pavement | Stopped on a footway > 20 s with a guard within 30 m | The clamp joke (5.6) |
| Landing the helicopter in a pedestrian zone | Within 60 m of a guard | Guard zone line, nothing else |
| The river | Not an offence: loop 10a's tow handles it | — |

**Warnings and strikes.** A warning is a megaphone bubble from the unit that saw it, a short
"whoop", and the first rooster blinking as an outline for 2 s. It adds one **strike**; strikes fade
one every 45 s. **Two strikes within 45 s start koguty 1.** So a single slip is always just a joke.

**When the police never start a chase:**
- in the first **180 s** of a session (warnings only, and only after 60 s), except the scripted
  first contact;
- within **180 s** after the last chase ended (cooldown), unless the player rams a police car;
- while a rescue is in PICKUP or DROPOFF (they escort instead, section 8.1);
- while the player is in the helicopter.

Megaphone lines: at most one every 8 s in the whole city, and 20 s per unit.

---

## 4. Escalation: states, timings, distances

```
             offence seen            2nd strike in 45 s / lizak ignored / race seen / ram > 6 m/s
  CALM ───────────────────► WARNED ───────────────────────────────────────────► KOGUTY 1
   ▲   (strike fades 45 s)    │                                                    │ ram > 6 m/s, or seen by a 2nd unit
   │                          └─ trap: LIZAK ─ stop by officer ─► PULL-OVER         ▼
   │                                    └─ drive on ─────────────► KOGUTY 1      KOGUTY 2 ── same again ──► KOGUTY 3
   │                                                                   │               │                       │
   │                 100 m from every chaser, or no chaser sees you 4 s│               │                       │
   │                                                                   ▼               ▼                       ▼
   │                                                    SEARCH (8 s; 4 s in a hiding spot) ── seen again within 50 m ──► back to the same level
   │                                                         │
   │       ESCAPED (+15 respect) ◄───────────────────────────┘
   │       END OF SHIFT (the hidden backstop: 120 s from the chase's start, at any level)
   │       PULL-OVER (stopped within 15 m of a chaser for 1.5 s) → caution
   └──── COOLDOWN 180 s (warnings still possible) ◄──────── any of the three
```

| State | Enter | Leave | Numbers |
| --- | --- | --- | --- |
| CALM | start, end of cooldown | an offence | — |
| WARNED | an offence seen (strike +1) | strikes back to 0 (one fades per 45 s), or koguty 1 | outline rooster blinks 2 s |
| LIZAK | speeding inside a trap's 40 m | stop within 20 m of the officer at < 8 km/h → PULL-OVER; more than 30 m past the officer → KOGUTY 1 (the trap car starts it); 6 s pass with the player stopped elsewhere → CALM | the officer waves for ≤ 6 s; trap re-arms after 60 s |
| KOGUTY 1 | see the diagram | escape, backstop, pull-over; +1 level on a trigger | 1 chaser |
| KOGUTY 2 | in koguty 1: ram > 6 m/s, or a second unit sees the player within 60 m | as above | + 1 blocker |
| KOGUTY 3 | in koguty 2: the same triggers | as above | + a two-car roadblock; at night the searchlight |
| SEARCH | distance > 100 m from every chaser, or no chaser with sight for 4 s | 8 s pass (4 s if the player is in a hiding spot) → ESCAPED; any unit sees the player within 50 m → back to the level it was | chasers drive to the last-seen point, then wander within 150 m at 30 km/h |
| ESCAPED | search ran out; or the car stops in Mirek's garage ring while no unit sees it (in the search: none within 50 m) | — | +15 respect (once per chase); bubble "escaped" (the garage: "garage", toast *NOWY LAKIER, KTO PYTA? · NEW PAINT, WHO'S ASKING?*); a race in progress is marked for +20 % |
| END OF SHIFT | the hidden backstop: 120 s from the chase's start, in any chase state | — | bubble "shift"; no respect bonus, nothing lost |
| PULL-OVER | player speed < 1 m/s within 15 m of a chaser for 1.5 s; or the lizak stop | the conversation ends | ≤ 8 s (section 7); job clocks and the kebab's heat frozen during it |
| COOLDOWN | after ESCAPED, END OF SHIFT or PULL-OVER | 180 s | warnings still happen; a ram > 6 m/s starts koguty 1 anyway |

Rules that hold in every state:
- **No level rises in the backstop's last 10 s.**
- **The chasers tire** (first-hour step 2): after 30 s of a chase their top speed drops from 0.8
  to 0.7 of the player's, so the gap opens for any player (police.gd `TIRE_AT`, police_unit.gd
  `TIRED_SHARE`; first guesses for the phone).
- **Chasers never ram.** They brake to keep ≥ 10 m behind the player and stop if the player stops.
- **Chaser speed:** the player's top speed × 0.8 (30 m/s × 0.8 = 24 m/s ≈ 86 km/h; 2026-11-02: at 0.92 the gap opened 2.4 m/s, so 120 m was out of reach inside the 30-45 s cap and only a lost line of sight ever escaped), acceleration × 1.2 of
  traffic; through a junction on red and round roundabouts they slow to 30 km/h with the siren
  (always a moment to gain). They stay on the lane graph: pavements, parks and the pedestrian
  zones are always a way out.
- **Traffic gives way** to a car with its lights on: cars within 30 m ahead in the same direction
  shift to the kerb lane and slow to 5 m/s for 3 s.
- **Hiding spots:** under a bridge deck (`decks`), in a tunnel (the tunnel edges from loops 3b/3e),
  inside a multi-storey car park (bake POI `hide`, from OSM `parking=multi-storey`).
- **Helicopter:** taking off during a chase is allowed (the user's choice: the helicopter is
  always there). The chase ends at once as END OF SHIFT with the "heli" line, no respect bonus.
  When the player lands and returns, nothing waits for them.
- **One chase at a time.** A new offence during a chase only counts towards its level.

**Pursuit on the lane graph.** A chaser races (`traffic.race_to`) to the player's nearest graph
node, re-planned once a second (one unit per frame, round-robin). `distances_to` gets an optional
`max_cost` so the search stops at 800 m (a few hundred nodes, instead of the whole demo graph's
~10k); beyond it the chaser picks, at each junction, the way whose end lies nearest the player.
**Blocker (koguty 2):** spawned out of sight on the player's predicted route (the edge chain the
player is on, 250 to 400 m ahead), it drives to the junction there and parks across the **far**
lane only, leaving ≥ 3.5 m clear. **Roadblock (koguty 3):** two patrol cars parked in a V at the
next junction ahead on the predicted route, ≥ 4 m gap in the middle (passable at ≤ 40 km/h);
if the player turns off, they stay 10 s, then leave.

---

## 5. What happens at each state

### 5.1 On screen, in sound, in lines

| State | World | HUD | Sound | Line (group / tag, speaker) |
| --- | --- | --- | --- | --- |
| WARNED | the unit's bubble over its car | first rooster outline blinks 2 s | whoop + megaphone chirp | `police_warn` speed / red / bump, "Policja" (megaphone) |
| LIZAK | the officer raises the paddle; a 2D lizak icon bobs over the officer | pill *ZATRZYMAJ SIĘ PRZY POLICJANCIE · PULL OVER BY THE OFFICER* | two whistle blasts | — |
| KOGUTY 1 | the chaser's light bar flashes blue and red; halos on the road at night | 1 rooster lit; blue-red edge breath (≤ 10 % opacity, 1 Hz); pill *UCIEKAJ · GET AWAY* over a gold bar that fills with the escape made (the gap to the nearest unit against the 100 m, or the time out of sight against 4 s, the larger), no clock; off-screen chasers as a rooster at the screen edge; minimap: chasers blink blue/red with a white outline, and the 4 nearest hiding spots (tunnels, roads under a deck, within 600 m) as blinking green rings pinned to the rim | siren on the chaser (one positional voice) | `police_chase` start, then the generic ones every 10 to 12 s |
| KOGUTY 2 | the blocker's lights flash at its junction | 2 roosters | whoop when the blocker joins | `police_chase` backup |
| KOGUTY 3 | the roadblock; at night the searchlight pool (9 m) sweeps round the player | 3 roosters | rotor overhead at night | `police_chase` roadblock |
| SEARCH | chasers slow, lights stay on | roosters grey and blink; pill *SZUKAJĄ CIĘ · SEARCHING* over a grey-blue bar that empties as the search runs out | siren off, lights on | — |
| ESCAPED | chasers switch lights off and rejoin traffic | toast *UCIECZKA! · ESCAPED!* and "+15" on the respect star | a short rising chord (`make_ui_sounds.py` style) | `police_lost` escaped (bubble from the last chaser, or on the radio ticker if off screen) |
| END OF SHIFT | as escaped | toast *KONIEC ZMIANY · END OF SHIFT* (it comes without warning: nothing counts down) | siren winds down | `police_lost` shift (or heli) |
| PULL-OVER | the chaser parks 6 m behind; the camera eases in (11.3) | the conversation card (section 7); toast after it *POUCZENIE · CAUTION · W ZESZYCIE: 3 DZIŚ · IN THE NOTEBOOK: 3 TODAY* | the radio ducks −6 dB; a stamp thump at the end | `police_stop`, `police_reply`, `police_caution` |
| ESCORT | the escort ahead with lights on, traffic shifting aside | pill *ESKORTA · ESCORT · +10 S* | siren on the escort | `police_escort` |

Colour is never the only cue: the rooster count, the pill text, the siren and the edge rooster
carry every state (DEMO bar J2, ROADMAP's colour-blind note). Reduce Motion (loop 3i) switches the
edge breath off; the light bar keeps flashing at 2.5 Hz (under the 3 flashes a second limit).

### 5.2 The speed trap and the lizak

- The officer's radar watches the 40 m in front of them. A speeder triggers the lizak: the officer
  turns to the car, the paddle (a 24 px 2D icon pinned over the officer, bobbing 2 px at 2 Hz) and
  the pill appear, two whistle blasts.
- **Stop:** within 20 m of the officer at < 8 km/h (no ring on the road; the pill says where) →
  PULL-OVER with opener tag `trap`. No chase, nothing lost.
- **Drive on:** more than 30 m past the officer → koguty 1; the trap's own car is the chaser
  (it pulls off the shoulder).
- A trap re-arms 60 s after it triggered. Traps never trigger in the first 180 s, except the
  scripted first contact (`routine`, section 1), which is the trap nearest the route back from the
  first race and fires even without speeding.

### 5.3 Pull-over

The player's car is held (brake on, controls ignored) for the conversation; the chaser parks 6 m
behind with its lights on; traffic flows round. Every beat can be tapped through. Section 7 has
the flow. At the end: the caution count goes +1 in the **"Zeszyt pouczeń"** (the cautions
notebook, a joke counter in the save that resets each in-game day; the fifth of a day gets its own
line), the chaser turns its lights off and drives away, COOLDOWN starts. **The wallet is never
touched and respect never drops.**

### 5.4 Escape and end of shift

Escape rewards: +15 respect (once per chase); during a race the race is flagged and a win pays
the stake × 1.2; during an app-taxi ride (loop 2d) the passenger's rating is untouched. End of
shift rewards nothing and costs nothing.

### 5.5 What never happens

No fines, no money, no respect lost, no arrests, no handcuffs, no weapons, no crashes on purpose,
no police in the player's path at > 30 km/h, no chase longer than 120 s, no chase in the first 3
minutes, no police reaction to the helicopter except the guards' landing line.

### 5.6 City guards

- **Entering a pedestrian zone.** The player's car is capped at **20 km/h** inside a zone polygon
  (pill *STREFA PIESZA · 20 KM/H · PEDESTRIAN ZONE*; pedestrians within 6 m of the car's path step
  aside). The nearest guard within 60 m whistles and says a `guard` line (tag `oldtown` on the Old
  Town's square and lanes, none elsewhere), at most once per zone per 60 s. The guard runs after
  the car at 5 m/s for 3 s, stops, and says `guard` / `run`. If the guard car is in the sector it
  follows at ≤ 25 km/h with its amber beacon for 15 s, then turns away.
- **Stopping by a guard** (within 10 m, < 1 m/s, 1.5 s) opens the guard conversation (7.2): a zone
  line and a caution. Guards never call the police and never chase.
- **The clamp ("blokada").** A car stopped on a footway > 20 s with a guard within 30 m: the guard
  walks over, says `guard` / `clamp` (a 10 s countdown pill *BLOKADA ZA 0:10 · CLAMP IN 0:10*), a
  scribble sound while they write. Drive off and nothing happens. Still parked at 0: a clamp
  (a yellow box on the front wheel, part of the guard's MultiMesh pose) and a card with one button
  **Przepraszam · Sorry**: tap it and the clamp comes off at once; or it comes off by itself after
  10 s. It exists to catch a player who put the phone down, and costs nothing.

---

## 6. Lines (to merge into game/data/dialogue.json)

30 original lines, Polish then English, grouped by situation. `dialogue.line(group, tag, prefer)`
picks them; a line without `only` fits every tag, so each call names its tag and passes
`prefer = true` where a tagged line must win. Speakers are set by the code: **"Policja"** for the
megaphone groups (`police_warn`, `police_chase`, `police_lost`, bubbles over the car),
**"Sierżant Bogdan"** for `police_stop`, `police_caution`, `police_escort` (except `police_stop`
`trap`: **"Posterunkowy Kacper"**), **"Strażnik Henio"** for `guard`, the player for
`police_reply` (buttons, ≤ 28 characters). The `radio_host` line is read only when police.gd asks
with tag `traps` and fills `{pl}` / `{en}` with the day's three radio phrases (section 2 table),
e.g. *„na Wisłostradzie, w Alejach Jerozolimskich i na Wybrzeżu Szczecińskim”*. Checked against
the file (grep for suszarka, koguty, pouczenie, blokada, Syrenka, myjni, krawężnik, zeszyt): no
repeated joke. The nearest is the egg line *„Syrenka z mieczem pilnuje miasta. Ograniczenia
prędkości też.”*; the guard's Old Town line has the Mermaid disapproving instead, a different
punchline.

```json
{
  "police_warn": [
    ["Pan w małym aucie! Wolniej, bo suszarka się przegrzeje.", "You in the little car! Slow down, the radar gun (the \"hair dryer\") is overheating.", {"only": "speed"}],
    ["Czerwone to nie jest „prawie zielone”.", "Red is not \"almost green\".", {"only": "red"}],
    ["Proszę nie dotykać radiowozu. Dopiero co był w myjni.", "Please don't touch the patrol car. It's just been through the car wash.", {"only": "bump"}]
  ],
  "police_chase": [
    ["Kacper, włącz koguty. Nie, te drugie. Dobra, jedziemy.", "Kacper, lights on. No, the other switch. Right, off we go.", {"only": "start"}],
    ["Proszę się zatrzymać! Albo chociaż zwolnić, będzie miło.", "Please stop! Or at least slow down, that would be nice."],
    ["Proszę zjechać do krawężnika. Któregokolwiek.", "Please pull over to the kerb. Any kerb."],
    ["Centrala, prosimy o wsparcie. I o kawę.", "Control, requesting backup. And coffee.", {"only": "backup"}],
    ["Blokada ustawiona. Pachołki pożyczone od remontu.", "Roadblock set. Cones borrowed from the roadworks.", {"only": "roadblock"}]
  ],
  "police_lost": [
    ["Zgubiliśmy cel. Kacper, zapisz: „szybki, ale kulturalny”.", "Target lost. Kacper, write this down: \"fast, but polite\".", {"only": "escaped"}],
    ["Koniec zmiany! Pościg dokończymy jutro o ósmej.", "End of shift! We'll finish the chase tomorrow at eight.", {"only": "shift"}],
    ["Auto zostało, kierowca odleciał. Tego nie ma w regulaminie.", "The car stayed, the driver flew off. That's not in the rulebook.", {"only": "heli"}]
  ],
  "police_stop": [
    ["Rutynowa kontrola. Spokojnie, nic pan nie zrobił. Jeszcze.", "Routine check. Relax, you haven't done anything. Yet.", {"only": "routine"}],
    ["Koguty na dachu to my. Koguty w lusterku — też my.", "\"Roosters\" (the light bar) on a roof: that's us. Roosters in your mirror: also us.", {"only": "roosters"}],
    ["Kontrola drogowa. Wie pan, czemu pana zatrzymałem? Ja tak średnio.", "Traffic check. Do you know why I stopped you? I'm not entirely sure myself."],
    ["Wie pan, ile pan jechał? Ja też nie. Suszarka się zawiesiła.", "Do you know how fast you were going? Me neither. The hair dryer froze.", {"only": "trap"}],
    ["Czuję czosnkowy. Kontrola potrwa krócej niż stygnięcie.", "I can smell garlic sauce. This check will take less time than the cooling.", {"only": "kebab"}],
    ["Kontrola słoików. Ogórki w normie, bigos podejrzanie ciężki.", "Jar inspection. Pickles within limits; the bigos is suspiciously heavy.", {"only": "sloik"}]
  ],
  "police_reply": [
    ["Przepraszam, już nie będę.", "Sorry, won't happen again."],
    ["Suszarka? Mam krótkie włosy.", "Hair dryer? But I've got short hair.", {"only": "trap"}],
    ["Kebab stygnie, panie władzo!", "The kebab's getting cold, officer!", {"only": "kebab"}]
  ],
  "police_caution": [
    ["Pouczenie. Następnym razem mandat. Albo znowu pouczenie, zobaczymy.", "A caution. Next time, a fine. Or another caution, we'll see."],
    ["Pouczam pana. Kacper, zapisz w zeszycie. Ładnie, nie jak ostatnio.", "Consider yourself cautioned. Kacper, put it in the notebook. Neatly, not like last time.", {"only": "police"}],
    ["Piąte pouczenie dzisiaj. Jeszcze jedno i dostaje pan kubek.", "Fifth caution today. One more and you get a mug.", {"only": "fifth"}]
  ],
  "police_escort": [
    ["Jedziemy na sygnale, proszę się trzymać!", "Lights and siren on, hold on tight!"],
    ["Do szpitala? Za nami! Korek się rozstąpi. Prawie zawsze.", "To the hospital? Follow us! The traffic will part. Almost always."]
  ],
  "guard": [
    ["Panie, tu jest deptak, a nie Wisłostrada!", "Sir, this is a promenade, not the Wisłostrada!"],
    ["Na Rynek autem? Syrenka patrzy i nie jest zachwycona.", "Into the Market Square by car? The Mermaid is watching, and she's not impressed.", {"only": "oldtown"}],
    ["Proszę stanąć! Ja dłużej nie pobiegnę.", "Please stop! I can't run any further.", {"only": "run"}],
    ["Za dziesięć sekund blokada. Liczę: jeden… dwa… gdzie ja byłem?", "Wheel clamp in ten seconds. Counting: one… two… where was I?", {"only": "clamp"}]
  ],
  "radio_host": [
    ["Suszarki dziś: {pl}. Na pozostałych ulicach jedźcie grzecznie z przyzwyczajenia.", "Speed traps today: {en}. Everywhere else, drive nicely out of habit.", {"only": "traps"}]
  ]
}
```

`radio_host` already exists: append that one line to it. Calls, for the builder:

| Moment | Call |
| --- | --- |
| Warning | `line("police_warn", "speed" / "red" / "bump", true)`; one-way: no line |
| Chase start / blocker / roadblock | `line("police_chase", "start" / "backup" / "roadblock", true)` |
| Chase, every 10 to 12 s | `line("police_chase", "")` (the two untagged lines alternate) |
| Escaped / end of shift / helicopter | `line("police_lost", "escaped" / "shift" / "heli", true)` |
| Pull-over opener | tag = `routine` (first contact), else the job running (`kebab`, `sloik`), else the reason (`trap`), else `""` (the generic line); `prefer = true` |
| Replies | `line("police_reply", "")` always; plus `line("police_reply", tag, true)` when that tag has a reply (`trap`, `kebab`) |
| Caution | 5th of the day: `line("police_caution", "fifth", true)`; police otherwise `line("police_caution", "police")` (both untagged and police lines); guards `line("police_caution", "")` |
| Escort joins | `line("police_escort", "")` |
| Guards | `line("guard", "oldtown", true)` in the Old Town, `line("guard", "")` elsewhere; `"run"`, `"clamp"` with `prefer = true` |
| Radio, once per station change after the first 120 s, at most once per in-game hour | `line("radio_host", "traps", true)`, filled |

Speech-bubble rule (warsaw-tone): every Polish line above is ≤ 70 characters except the radio
ticker line, which runs on the ticker like the other host lines.

---

## 7. Conversations (Dialogue Manager)

### 7.1 The pull-over

Three beats, ≤ 8 s, every beat tappable: the opener (with the roosters line on first contact),
the player's reply (one or two buttons, the first auto-picked after 5 s), the caution. A first
contact ends after the opener: no reply, no caution, the rules toast instead.

`game/dialogue/police.dialogue` (Dialogue Manager 4 syntax; `talk` is the state object passed as
`extra_game_states`, 11.2):

```
~ pull_over
Sierżant Bogdan: {{talk.say("police_stop", talk.opener)}}
if talk.first_contact
	Sierżant Bogdan: {{talk.say("police_stop", "roosters")}}
	$> talk.done_routine()
	=> END
- {{talk.say("police_reply", "")}} => caution
- {{talk.say("police_reply", talk.opener)}} [if talk.has_reply /] => caution

~ caution
Sierżant Bogdan: {{talk.say("police_caution", talk.caution_tag)}}
$> talk.done_caution()
=> END

~ guard_stop
Strażnik Henio: {{talk.say("guard", talk.zone)}}
- {{talk.say("police_reply", "")}} => guard_caution

~ guard_caution
Strażnik Henio: {{talk.say("police_caution", "")}}
$> talk.done_caution()
=> END
```

The `police_stop` `trap` opener is spoken by Kacper: the balloon reads `talk.speaker_override`
(set by `say` for that tag) before the line's own character name.

### 7.2 Text stays in dialogue.json

All words live in `dialogue.json`; the `.dialogue` file holds only the flow. `talk.say(group, tag)`
picks a line through `dialogue.line()`, remembers `{polish: english}` for this conversation and
returns the Polish; the custom balloon shows `line.text` (Polish, ink `#fbf7ee`) with
`talk.english_of(line.text)` under it (sub-text `#c9c2d8`, smaller), the speaker's portrait on
the left, reply buttons ≥ 44 pt. Dialogue Manager's `translation_source` is **None** (we handle
both languages). If the installed version does not evaluate method calls inside `{{ }}`, use a
mutation before each line instead: `$> talk.pick("police_stop", talk.opener)` and then
`Sierżant Bogdan: {{talk.pl}}`; responses likewise with `talk.r0`, `talk.r1`.

---

## 8. How it ties in

### 8.1 Rescues: the escort

- While a rescue is in PICKUP or DROPOFF the police perceive nothing and start nothing.
  **Accepting a rescue call during a chase ends the chase** (toast *POLICJA ODPUSZCZA: RATUJESZ
  KOGOŚ · THE POLICE BACK OFF: YOU'RE ON A RESCUE*), straight to COOLDOWN.
- **Escort.** When the person is aboard (DROPOFF, in the car), the nearest patrol car within 200 m
  joins within 2 s; if none, one is spawned out of sight 150 m ahead on the route (guaranteed on
  the first rescue). It drives the route to the hospital (distances to the two hospital nodes are
  computed once and cached, like the rivals' finishes), 15 to 25 m ahead of the player, slows when
  the player falls > 60 m behind, and drops behind if the player overtakes it. Traffic ahead of it
  shifts aside (section 4). The rescue clock gets **+10 s** when it joins (pill). At the hospital it
  turns its lights off and leaves. Not in the helicopter.
- Lines: `police_escort` when it joins; the crew's existing `rescue_done` line at the hospital.

### 8.2 Races

A race seen by police (section 3) pulls in koguty 1 on the player. The rival keeps racing (rivals
do not perceive police). Escaping before the finish marks the race: a win pays the stake × 1.2
(shown on the result card as *+20 % ZA UCIECZKĘ · +20 % FOR THE ESCAPE*). A pull-over during a
race costs only the seconds. Rivals' own lines stay as they are; *Taksiarz Zbyszek knows every
hiding spot* is a hint the radio host or a later rival line can carry (not in 3g).

### 8.3 Side jobs

| Job | During a chase | Pull-over |
| --- | --- | --- |
| Kebab | the heat fades as on any drive | opener `kebab`, reply `kebab`; **the heat is frozen** while the card is open |
| Słoiki | jars stress as on any drive (hard driving in a chase is its own risk) | opener `sloik`; jars untouched |
| App-taxi (loop 2d) | no rating change | the passenger takes one star off (`podwozka_rating` / `police` in docs/design/parodies.md); escaping changes nothing |

### 8.4 Wallet, save, radio, eggs

- **Wallet:** nothing in this spec takes złoty or respect. Escapes add +15 respect.
- **Save:** `cautions_today` and the date it belongs to; `escapes_total` (for a later
  achievement). Save version bump as loop 3h plans.
- **Radio:** the host reads the day's traps (section 6) and the minimap then shows those traps
  as a hair-dryer icon; a trap the player has seen shows too.
- **Egg (DEMO 6.3):** "a police car stuck in its own roadworks": a police instance parked inside
  the day's roadworks fence with its lights on, a `police_chase` `roadblock` bubble on approach
  (the cone joke lands twice). Loop 2d/3h owns the egg; 3g supplies the parked instance.

---

## 9. Art at the default 80 m view

At the default view in the Sharp style (480-line pixel image) one metre is about **6 image
pixels**; a car is ~25 px long. What reads there is **silhouette, two-tone and the light bar**;
the word POLICJA reads only when zoomed in.

| Thing | Spec | What reads at 80 m |
| --- | --- | --- |
| **Patrol car** (loop 2c makes the mesh; 3g needs these parts) | Estate 4.7 × 1.85 × 1.55 m, ≤ 800 triangles. Roof, pillars and the upper doors white `#f2f2ee` (FIXED); lower body PAINT, instance colour police blue `#1f4fd8`; trims as traffic. **Light bar** 1.5 × 0.14 × 0.32 m on the roof: left lens blue, right lens red, dark centre. **"POLICJA"** in the 5×7 pixel font (`pixel_font.gd add_quads`), white, letter pixel 0.06 m, 2.34 × 0.42 m, on both lower doors (~170 triangles a side); no crest, badge, number or real emblem | A white roof (≥ 6:1 against asphalt) longer than the traffic cars, a two-tone side, and a blue/red 9 × 2 px bar that blinks. The lettering is a 2 px white streak; it reads as text from a ~30 m view |
| Light bar, lit | New actor-shader part **SIREN** (value 8.0, next free code after BLINK): when the instance's custom data `a` says lights on, the left lens shows `#3d7bff` and the right `#ff3b3b` alternately, 0.2 s each (2.5 Hz), glowing like LIT_SIGN; off, they show dim `#34407a` / `#7a3434` so the bar still reads as two-tone | A blinking blue/red dot pair by day; a glow at night |
| Light bar halos at night | Two soft quads per car with lights on (blue left, red right, 4 m), alternating with the lens; one glow MultiMesh for every police light (`Props.halo` + `glow_material`) | Blue and red pools on the road |
| **Guard car** | The same mesh and MultiMesh at scale 0.88, paint mustard `#e3b33a` (3.5:1 against asphalt); custom data selects the guard livery: the lettering pixels take the paint colour (invisible, no discard), both lenses amber `#ffb21e`, blinking 1.5 Hz | A small mustard estate with an amber dot: never mistaken for police (different hue, different blink, no blue) |
| **Officer** at a trap | A pedestrian instance (pedestrians' MultiMesh): shirt lemon hi-vis `#e8f23a`, trousers navy `#24324a`, standing, facing the road | A bright lemon figure beside a parked patrol car |
| **Lizak** | A 24 px PixelLab icon (white disc, red rim, short dark handle) drawn by the HUD over the officer's head while waving, bobbing 2 px at 2 Hz | A round red-and-white sign over the officer |
| **City guard** on foot | Pedestrian instance: shirt mustard `#e3b33a`, trousers dark red `#7a2430`; standing or walking; the clamp is a 0.3 m yellow box added to the car's front wheel as a guard-livery pose | Mustard figures at the zone gates |
| **Searchlight** (koguty 3, night) | A 9 m soft white pool instance in the same glow MultiMesh, sweeping a figure-eight round the player at 0.25 Hz | A moving spotlight |
| **HUD** | Rooster icons (24 px PixelLab, two states: lit blue-red, empty outline) ×3 left of the coin; the edge breath; the edge rooster; minimap: chasers as blinking blue/red dots with a white outline, known traps as a 16 px hair-dryer icon | — |
| **Portraits** for the card | 64 px PixelLab, shown at 2–3×: Sierżant Bogdan, Posterunkowy Kacper, Strażnik Henio (prompts below) | — |

Reserved colours (art bible "Reserved colours", DEMO bar C2): the blue and red light bars are
the police's alone; police blue is the most saturated thing near it by day, like the job beacons
and the player's car. The player's car is red-orange with white roof stripes, the patrol car blue
with a whole white roof: different hue, different roof. The guards' mustard and amber stay off the
police and are not the jobs' saturated orange. Check the C1/C2 tests on the shot set (section 15).

**PixelLab** (loop 3g, ≤ 50 generations; follow `.claude/skills/pixellab/SKILL.md`; no text,
no insignia, no real badge; palette always includes `#fbf7ee`, `#c9c2d8`, `#ffd23f`, `#3a3b3f`,
`#34404e` plus the colours named):

| Asset | Tool, size | Prompt | Extra palette | Generations |
| --- | --- | --- | --- | --- |
| Portrait: Sierżant Bogdan | `create_portrait_character`, 64 px | "friendly older police sergeant, grey moustache, peaked cap, plain dark blue uniform with no badges or insignia, tired kind eyes, slight smile, front view" | `#1f4fd8`, `#24324a` | 10 |
| Portrait: Posterunkowy Kacper | same | "young earnest police officer, short hair, plain dark blue uniform with no badges, holding a small tablet, eager expression, front view" | `#1f4fd8`, `#24324a` | 10 |
| Portrait: Strażnik Henio | same | "older city warden, round glasses, mustard yellow jacket, dark red collar, small notebook and pencil, patient expression, front view" | `#e3b33a`, `#7a2430` | 10 |
| Rooster icon, lit + outline | `create_image_pixen`, 24 px, `no_background` | "small cartoon rooster head icon, side view, bold shapes" then an outline-only variant | `#3d7bff`, `#ff3b3b` | 2 + 2 |
| Lizak icon | `create_image_pixen`, 24 px | "round traffic stop paddle, white disc with thick red rim, short dark handle, flat icon" | `#ff3b3b` | 2 |
| Hair-dryer minimap icon | `create_image_pixen`, 16 px | "tiny hair dryer silhouette icon, flat, high contrast" | `#1f4fd8` | 2 |

Total 38. Save under `game/art/portraits/`, `game/art/icons/` with provenance JSON.

---

## 10. Sound and haptics

All synthesised in `tools/make_sfx.py` (no samples), checked by `check_sfx.gd`.

| Sound | Recipe (*guess*, tune by ear) | Playback |
| --- | --- | --- |
| Siren | Two-tone 590 / 790 Hz, 0.5 s each, soft square through a 3 kHz low-pass, 1 s loop | One positional voice of the six, on the nearest chaser only; ducked 3 dB under the radio; stolen from the oldest ambience voice if needed (D2: ≤ 6 voices) |
| Whoop | 0.35 s sweep 400 → 1,100 Hz | When a unit warns or joins |
| Megaphone chirp | 0.12 s band-passed noise burst and a 1 kHz click | Before each megaphone bubble |
| Whistle | Two 0.15 s blasts at 2.9 kHz with a 20 Hz trill | Lizak, guards |
| Scribble | 0.8 s of filtered noise strokes | The clamp countdown, the caution |
| Stamp | 120 Hz thud and a paper slap, 0.25 s | End of a caution |
| Clamp clank | Partials 600 / 1,700 Hz, 0.3 s decay | Clamp on and off |
| Rotor | The helicopter's rotor loop at −6 dB, positioned 40 m above the player | Koguty 3 at night |

Haptics (once the iOS haptics plugin lands, ROADMAP): light tap on a whoop, medium on the
pull-over stop, a double light tap on ESCAPED.

---

## 11. The approved add-ons and how 3g uses them

Install each from the Godot Asset Library into `game/addons/<name>/` with its licence file, a
CREDITS.md line (name, author, licence, URL, version), and a phone check before relying on it
(CLAUDE.md "Godot add-ons"). All three are MIT and GDScript (Phantom Camera also ships optional C#
files: don't enable C#). Versions to record at install: beehave 2.10+ (Godot 4.5+), Dialogue
Manager 4 (Godot 4.6+), Phantom Camera (Godot 4.4+); the project runs Godot 4.7.2.

### 11.1 beehave: each unit's behaviour

- One `PoliceUnit` node per active unit (patrol, trap, guard car; at most 6 at once) wraps its
  traffic `Driver` and carries a `BeehaveTree` with `process_thread = MANUAL`; police.gd ticks the
  trees **5 times a second** right after perception (`tree.tick()`), never per frame. Guards on
  foot share one tree per guard, max 6 ticking (the ones within 150 m of the player).
- **Escalation is not in the trees.** The global state machine of section 4 lives in police.gd;
  it writes the blackboard (`level`, `role`, `sees_player`, `last_seen`, `target_node`,
  `cutoff_node`, `pullover`, `escort_route`); trees only move their unit.
- Patrol unit tree:

```
BeehaveTree (MANUAL, ticked at 5 Hz)
└ SelectorReactive
  ├ Sequence  Escort      : IsRole(escort) → DriveRoute(hospital) → KeepGap(15..25 m) → ClearTrafficAhead
  ├ Sequence  PullOver    : IsPullOver → ParkBehindPlayer(6 m) → LightsOn
  ├ Sequence  Roadblock   : IsRole(roadblock) → DriveTo(cutoff) → ParkV(gap ≥ 4 m) → HoldOrLeave(10 s)
  ├ Sequence  Blocker     : IsRole(blocker) → DriveTo(cutoff) → ParkAcrossFarLane(clear ≥ 3.5 m)
  ├ Sequence  Search      : IsState(search) → DriveTo(last_seen) → Wander(150 m, 30 km/h)
  ├ Sequence  Chase       : IsRole(chaser) → Pursue(replan 1 Hz, gap ≥ 10 m, slow 30 km/h on red)
  ├ Sequence  Trap        : IsRole(trap) → Parked → WaveLizakIfFlagged
  └ Patrol                : DriveAsTraffic
```

- Guard tree: `Selector[ Clamp: CarParkedOnFootway(20 s) → WalkTo → Countdown(10 s) → PlaceClamp,
  Chase: SawCarInZone → Whistle → RunAfter(3 s, 5 m/s) → GiveUp(line "run"),
  Talk: PlayerStoppedNear(10 m, 1.5 s) → OpenGuardTalk, Post: StandOrStroll ]`.
- Leaves are small GDScript classes under `game/scripts/police/bt/`; each action returns RUNNING
  while it moves the Driver through the traffic API (`race_to`, `stop_racing`, `teleport` for
  out-of-sight spawns, `held`), never touching transforms itself.
- `custom_monitor = true` in debug builds so the bench and Godot's monitors show the trees' time.

### 11.2 Dialogue Manager: the conversations

- Used only for the two conversations of section 7 (pull-over and guard stop). Barks (warnings,
  chase lines, escort, lost) stay on `dialogue.gd` bubbles: one-liners need no flow.
- Files: `game/dialogue/police.dialogue`; a custom balloon scene drawn like the HUD cards (dark
  translucent violet, ~94 %, ink `#fbf7ee`, sub-text `#c9c2d8`, accent per speaker: police blue
  `#1f4fd8`, guards mustard `#e3b33a`), sized in points (loop 2e), Polish above English.
- `talk` (a `RefCounted` with `say`, `pick`, `english_of`, `opener`, `caution_tag`, `has_reply`,
  `first_contact`, `zone`, `done_caution`, `done_routine`) is passed as `extra_game_states`.
  `translation_source = None`. The game stays running (traffic moves); only the player's car is
  held; the radio ducks −6 dB.

### 11.3 Phantom Camera: chase framing

The game camera has invariants Phantom Camera must not break: the yaw comes from the control
scheme (never turned faster than ~64°/s), the focus is snapped to the pixel grid, `cam.far` is
sized by `_camera_far`, the car never sits within 20 % of a screen edge (DEMO bar B4). So:

- A `PhantomCameraHost` under `cam` with **`interpolation_mode = MANUAL`**: main.gd calls
  `host.process(dt)` inside `_update_camera`, then applies the pixel snap and `cam.far` itself,
  as today. The host only blends positions and the orthographic size.
- `PCam Drive` (priority 10, no follow): every frame main.gd writes into it the transform and
  `camera_3d_resource.size` the existing code computes now. With nothing else active the picture
  is exactly today's.
- `PCam Chase` (priority 20 while koguty ≥ 1 and the player is in the car): follow mode **Group**
  on [the player's car, a proxy node at the nearest chaser], `follow_damping` on (0.2). Its basis
  is copied from Drive every frame (no rotation of its own). Its size is set by police.gd:
  `clamp(on-screen gap × 1.3 + 20 m, drive size, drive size × 1.25)` (Phantom Camera's auto
  distance does not change an orthographic size). The proxy is clamped to ≤ 0.3 × the view from
  the player, so the group centre never moves more than 15 % of the view off the car.
- `PCam Stop` (priority 30 during a pull-over): Group on [car, the stopping patrol car], size
  drive × 0.8.
- `PCam Escort` (priority 20 during an escort): Group on [car, escort], size drive × 1.1.
- Tweens: into Chase 0.6 s SINE / EASE_OUT; back to Drive 0.8 s; into Stop 0.5 s. No shakes.
  Reduce Motion keeps the tweens (they are slow) and drops nothing else.

---

## 12. Cost on the phone

| | Budget | How |
| --- | --- | --- |
| Draw calls | **≤ +3** at any view (DEMO row 11) | One new traffic kind **POLICE** (pool 8: patrols, trap cars, blockers, escort, the guard car) = +1 main, +1 shadow (small_casters, off on Medium); one glow MultiMesh for light-bar halos and the searchlight = +1 at night only. The POLICE kind gets **no** headlight-pool MultiMesh of its own (the other kinds have one at night): its lamps still glow on the car, and the halos light the road instead, so the night total stays +3. Officers and guards ride in the pedestrians' MultiMesh (+0). The roadblock is two POLICE instances (+0, no cones). The lizak, roosters and portraits are 2D (≤ +4 2D draw calls while shown; the 2D pass stays < 80) |
| Triangles | ≤ +8 k at the default view | ≤ 800 a car, ≤ 4 cars in view in a chase |
| Scripts | ≤ 0.15 ms on the Mac (≤ 0.5 ms on the phone) in a koguty 3 chase | Perception at 5 Hz in one pass; beehave trees ticked manually at 5 Hz; one bounded re-plan per frame at most (`max_cost` 800 m); no raycasts; the siren on one voice |
| Memory | ≤ +2 MB | add-ons, portraits, the dialogue resource |
| First-sight hitch | none new | the SIREN part lives in the existing actor shader; no new shader |

Report before and after at README's four views (`--probe`) and the bench, plus a phone TEST ·
BENCH card, as README "Performance budgets" rule 9 asks.

---

## 13. Map data 3g needs (map-engineer, can come with loop 3d or 3e)

- `pois` kind `trap`: one per row of the section 2 table found in the map: the shoulder point,
  heading, measured direction, the officer's spot, the two radio phrases.
- `pois` kind `guard_post`: the posts of section 2 (position, heading, zone id).
- `areas` kind `ped_zone`: the pedestrian-zone polygons (Old Town, the Market Square, Krakowskie
  Przedmieście's car-free part, the boulevards, Łazienki's paths; from OSM `highway=pedestrian`
  areas and ways, `place=square` inside the Old Town); traffic stays out of them (loop 3e).
- `pois` kind `hide`: multi-storey car parks (`parking=multi-storey`, centre + radius); under-deck
  and tunnel tests use the deck and tunnel data that already exist.
- `check_map_data.py` gets the new counts, recorded with README in the same change.

---

## 14. Tuning (first guesses) and flags

| Value | First guess | Tune by |
| --- | --- | --- |
| Patrol cars in the band | 0 / 1 / 2 / 3 at Empty / Low / Normal / Busy | A 10-minute drive should meet ~2 to 4 patrol cars and trigger ≤ 1 chase without trying |
| Trap threshold / radar reach | limit + 20 km/h / 40 m | Most players at full throttle on a trap road trigger it; cruising at 60 in a 50 never does |
| Patrol-car speeding threshold | limit + 25 km/h within 40 m | — |
| Strikes to koguty 1 / fade | 2 within 45 s / one per 45 s | — |
| Chaser speed | player top × 0.8; × 1.2 traffic acceleration; 30 km/h through reds and roundabouts | A straight escape at full speed should open 120 m in ≤ 15 s |
| Escape | 100 m, or 4 s without sight; search 8 s (hiding 4 s) | Median chase ≤ 25 s in playtests |
| Backstop (hidden) / chasers tire | 120 s at any level / after 30 s, 0.8 → 0.7 of the player's top (first-hour step 2; before it the caps were 30 / 40 / 45 s by level) | the gap always opens; nobody waits a chase out |
| Cooldown / start grace | 180 s / 180 s (warnings from 60 s) | ≤ 1 chase in 3 minutes |
| Escape reward | +15 respect; race stake × 1.2 | — |
| Escort | joins ≤ 2 s, 15 to 25 m ahead, +10 s on the clock | — |
| Pedestrian-zone speed cap | 20 km/h | — |
| Clamp | 20 s parked, 10 s countdown, 10 s or a tap to remove | — |

Flags (parsed in `main.gd`, listed in README's flags table):

| Flag | Does |
| --- | --- |
| `--no-police` | no police, traps or guards |
| `--police=1\|2\|3` | start a chase at that level at frame 60, the chaser 40 m behind on the same lane (and the blocker / roadblock for 2 / 3) |
| `--trap=N` | put the car 150 m before trap N (1–7), heading into it; with `--pedal=gas` it speeds into the radar |
| `--pullover=routine\|trap\|kebab\|sloik\|guard\|generic` | open that conversation at frame 60 with a patrol car (or guard) behind (screenshots, `--clicks` for the replies) |
| `--police-auto=escape\|stop\|hold` | in a chase the autopilot drives away flat out on the lane graph / stops at once (and, when a lizak waves, brakes to stop within 20 m of the officer, overriding `--pedal`) / keeps driving nearby without escaping (cap tests) |
| `--police-now` | no start grace and no cooldown (tests only) |
| `--guards` | start at the Plac Zamkowy gate (today's map: the Krakowskie Przedmieście end) driving into the zone at 30 km/h |
| `--clamp` | park the car on the pavement by a guard; the clamp countdown starts at frame 60 |
| `--escort` | with `--mission=N`: the person is already aboard and the escort joins |
| `--police-log` | print every state change with its frame: `police: warn speed (unit 2)`, `police: L1 (lizak ignored)`, `police: escaped after 18.4 s`, `police: caution n=2 today`, `police: wallet 120 zł → 120 zł` |

---

## 15. Acceptance tests loop 3g can script

Every run: `--nosave`, a quit flag, `--police-log`; the wallet line must show the same złoty before
and after in every test.

| # | Run | Pass when |
| --- | --- | --- |
| P1 Lizak | `--trap=2 --pedal=gas --police-now --notitle` | `police: lizak` within 0.4 s of entering the 40 m; with the pedal held, `police: L1 (lizak ignored)` ≤ 1.0 s after passing the officer by 30 m |
| P2 Trap stop | `--trap=2 --pedal=gas --police-auto=stop --police-now` | `police: lizak`, the car stops within 20 m of the officer, `police: pull-over trap`, then `police: caution n=1` ≤ 10 s later; no `L1` |
| P3 Escape | `--police=1 --police-auto=escape` | `police: escaped` ≤ 30 s after start; respect +15; złoty unchanged |
| P4 Caught | `--police=1 --police-auto=stop` | `police: pull-over` ≤ 2.5 s after the stop; card shown (screenshot); `police: caution` ≤ 10 s |
| P5 Backstop | `--police=1/3 --police-auto=hold` | `police: end of shift` at 120 s ± 0.5 s at both levels |
| P6 Grace | `--trap=2 --pedal=gas` without `--police-now`, within 180 s of start | only `police: warn` or nothing; no `L1` |
| P7 Cooldown | two offences after a chase, 60 s apart | the second logs `warn (cooldown)`; a ram > 6 m/s logs `L1 (ram)` |
| P8 Escort | `--mission=1 --escort --autopilot` | `police: escort joined` ≤ 2 s; clock +10 s; `police: escort left` at the hospital; no chase even if the route passes a trap |
| P9 Guards | `--guards` | `guard: whistle` ≤ 2 s after entering; the car's speed ≤ 20 km/h in the zone; no `L1`; `guard: gave up` |
| P10 Clamp | `--clamp` then `--clicks` on Przepraszam | `guard: clamp on` at 10 s; `guard: clamp off` ≤ 0.5 s after the tap |
| P11 Lines and flow | `game/tools/check_police.gd` (headless) | every group and tag used by police.gd and `police.dialogue` exists with ≥ 1 line; every line has Polish and English; Polish bubbles ≤ 70 characters, replies ≤ 28; the `.dialogue` file parses |
| P12 State machine | `check_police.gd` with synthetic inputs (no rendering) | the timings of sections 4 and 14 hold; no level rises in the last 10 s; the wallet is never written by any path; starts = ends |
| P13 Soak | `--autopilot --traffic=busy --police-now`, 10 minutes | no script errors; police cars stay within 1.5 m of a lane; every chase ends; B4: the player's car never within 20 % of a screen edge during a chase (logged each second) |
| P14 Look | shots at 2868×1320: a patrol car at 80 m by day and night, koguty 2 HUD, the pull-over card, a guard in the zone, the escort | art-director: car found < 1 s; light bar visible (≥ 6 blue pixels in its box by day); C2 contrast holds |
| P15 Cost | `--probe` at the four README views with `--police=3` | draw calls ≤ baseline + 3; scripts ≤ +0.15 ms (Mac); bench within README |

`check_police.gd` joins `tools/verify.sh` in the same change. What only the phone can show: the
siren's level against the radio, how the chase feels at 60 fps, whether the edge breath is too
much, the haptics.

---

## 16. Build list for gameplay-dev (loop 3g)

1. Install beehave, Dialogue Manager, Phantom Camera (approved), CREDITS lines, phone check.
2. POLICE traffic kind (pool 8, custom data for livery and lights), SIREN shader part, halo
   MultiMesh; patrol spawning in the band; traffic giving way to lights.
3. `police.gd`: perception (5 Hz), strikes, the section 4 state machine, caps, cooldown, grace,
   hiding spots, wallet-free outcomes, save fields, radio hook, minimap and HUD (roosters, pill,
   edge breath, edge rooster).
4. Traps and lizak; guards (pedestrian instances, guard tree, zone speed cap, clamp); the guard car.
5. beehave trees and leaves (11.1); `distances_to(…, max_cost)`.
6. Dialogue Manager balloon and `police.dialogue` (section 7); lines merged into `dialogue.json`
   (section 6).
7. Phantom Camera host in MANUAL mode with the four PCams (11.3), B4 kept.
8. Escort for rescues; race and job ties (section 8).
9. Sounds in `make_sfx.py`; PixelLab assets (≤ 38 generations).
10. Flags, `check_police.gd`, README (flags, a Police section, budgets), ROADMAP row, BACKLOG.

---

## 17. Open questions (each with the default this spec uses)

1. **Pull-over cost.** Default: seconds only, nothing taken (the user's rule). Option: escaping
   gives nothing either (pure flavour). *Default: +15 respect for an escape.*
2. **Helicopter mid-chase.** Default: allowed, ends the chase at once with the "heli" line and no
   bonus. Options: the HELI button waits until the chase ends (like races), or the police
   helicopter follows you up. *Default: allowed.*
3. **Pedestrian-zone speed cap** of 20 km/h for the player's car (so nobody can be hit at speed in
   the Old Town). Option: no cap, pedestrians jump aside. *Default: the cap.*
4. **The clamp** stays as a joke that costs a tap. Option: cut it. *Default: keep.*
5. **Guard colours** mustard and dark red (invented; real municipal guard cars are mostly silver).
   *Default: yes.*
6. **"POLICJA" reads only zoomed in**; at 80 m the police read by the white roof, two-tone side
   and light bar. Option: a larger, non-realistic roof marking (a big white "P" panel).
   *Default: no roof marking.*
7. **Escort bonus** +10 s on the rescue clock. *Default: yes.*
8. **Police helicopter** only as a night searchlight at koguty 3, never in frame. *Default: yes.*
9. **Seven trap spots** (DEMO's six plus Wybrzeże Szczecińskie, so today's map has four).
   *Default: yes.*

## Sources read

- beehave: github.com/bitbrain/beehave (README; `addons/beehave/nodes/beehave_tree.gd`:
  `tick_rate`, `process_thread` IDLE/PHYSICS/MANUAL, `tick()`, `custom_monitor`).
- Dialogue Manager: github.com/nathanhoad/godot_dialogue_manager docs (Basic_Dialogue,
  Conditions_Mutations: `$>` mutations, `[if … /]` responses, `extra_game_states`; State: `{{ }}`;
  Translations: `translation_source`; API: `DialogueLine`, `show_dialogue_balloon_scene`).
- Phantom Camera: phantom-camera.dev (PhantomCameraHost `interpolation_mode` MANUAL and
  `process()`; Group follow and auto distance; v0.7.2 notes on orthographic size tweening).
- Real-world details used as flavour only: the "suszarka" and "lizak" slang, municipal guard
  fleets being mostly silver (tender documents found while checking colours).
