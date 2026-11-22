# Garage, cars, tuning and nitro: the plan (2026-11-22)

F (2026-11-22, the thread "Plan garage, car buying, upgrades and nitro"): Mirek's garage should
look like a real car service with cool cars around it, in a place with space; parts to change like
in Need for Speed (engine, steering, handling...) but easy to understand; a few cheap cars to buy
that you can see and turn round in the garage (look-alikes of an Audi TT, an A6 allroad, a Daewoo
Lanos, a Lamborghini, a Polonez, a BMW "bavara", a cabrio and an electric car); a menu somewhere on
the map with your car, what you bought and a way to switch cars; and a normal nitro, because today
you have to take your thumb off the gas to use it. **This is a plan for F's approval. Nothing is
built yet.**

## 1. What is there today (main 04e52e9)

- **Warsztat u Mirka** (`garage.gd`, card `garage_card.gd`): a dashed ring on Twarda
  (SPOT -1505, -135; PR #1009). Stop in it and a card opens with two tabs: LAKIER (10 paints,
  50-150 zł, three unlocked by eggs and Syrenki) and CZĘŚCI I AUTA (`upgrades.gd`).
- **Cars**: the striped hatch (free) and the Ołdi TT (1,500 zł; top ×1.2, pull ×1.2, grip ×1.1).
- **Parts**: tyres and engine, levels 1-3 (100-320 zł), shared by every car.
- **Nitro "Kebab Boost"** (350 zł): a 52 pt disc *left of BRAKE*. Held, it burns 3.5 s of a tank
  that refills in 20 s. It already opens the gas fully, but the right thumb lives on GAS, so the
  player lifts it off the gas, moves past the brake and holds the disc. That is F's complaint.
- **Money**: the pay tables (`docs/design/pay-tables.md`) give 12-40 zł a minute, about
  **1,200 zł an hour** of ordinary jobs; the main line pays ~1,400 zł by itself.
- **Races**: rivals race at *the player's car's top speed* × their pace (`rivals.gd player_top`,
  `race_session.gd`), so a faster car does not make races easier today (see 8, question 4).

## 2. How the arcade racers do it (what we take)

| Game | Idea | What we take |
| --- | --- | --- |
| Need for Speed Underground 2 / Heat | Parts in a few categories (engine, turbo, suspension, brakes, nitrous), each in packages Street → Sport → Race; a performance number on the car | 4 parts × 3 levels named ULICA / SPORT / WYŚCIG, and one class letter per car |
| Forza Horizon | Class letter D, C, B, A, S from the car's numbers; upgrades push it up a class | The class badge (D-S) on every car and in every list |
| Mario Kart, Asphalt | Stats as a few bars; the upgrade shows its gain as a coloured part of the bar before you buy | 4 bars, green "after" segment on the bar |
| Burnout 3 | Boost is earned by driving well: near misses, drifts, oncoming lane, air | Nitro bottles refill faster from near misses, drifts and jumps |
| Asphalt 8/9 | Nitro is a **tap**: one tap, one burst; no holding while you steer | Tap = one bottle burns for 2.5 s |
| NFS showrooms, Gran Turismo | The car on a turntable, swipe to turn it | One 3D car viewer, used by the garage and the new car menu |

Sources read: [Asphalt upgrades](https://asphalt.fandom.com/wiki/Upgrade),
[NFS No Limits and mobile racing design](https://www.deconstructoroffun.com/blog//2016/01/need-for-speed-no-limits-and-why-racing.html).
The rest is the well-known design of those games.

## 3. The cars (parody names only; prices low, as F asked)

Every car is a lofted body from `models.gd spec()` like the hatch and the TT (one mesh, one draw
call on the road). Numbers are multipliers on the hatch (top 108 km/h in Cruise). **Perk** = the
one thing that makes the car feel different, shown as an icon on its card.

| # | Name (pl) | Look-alike of | Price | Top | Pull | Grip | Steer | Brake | Class | Perk |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | :-: | --- |
| 0 | Hatchback z paskami | the start car | free | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | D | none (honest) |
| 1 | **Dejwu Łanos** | Daewoo Lanos | 200 zł | 0.95 | 0.95 | 1.00 | 1.08 | 0.95 | D | "Niezniszczalny": the first bump of each job costs no star and no jar |
| 2 | **FSŁ Bolonez Karo** | FSO Polonez Caro | 300 zł | 1.05 | 0.95 | 0.90 | 0.92 | 0.90 | D | Long slides: drifts fill nitro ×1.5 |
| 3 | **Mazgaj MX-5 Kabrio** | Mazda MX-5 (cabrio) | 550 zł | 1.05 | 1.05 | 1.15 | 1.15 | 1.05 | C | Roof down: the driver shows; respect +10 % on rides by day (roof goes up in rain) |
| 4 | **Ołdi A6 Ałroud** | Audi A6 allroad | 700 zł | 1.12 | 1.05 | 1.00 | 0.95 | 1.00 | C | High body: grass, cobbles and kerbs slow it half as much |
| 5 | **Ołdi TT** | Audi TT (exists) | 900 zł (was 1,500) | 1.20 | 1.20 | 1.10 | 1.05 | 1.05 | B | none |
| 6 | **Bawara M3** (F's own name) | BMW M3 E36 | 1,100 zł | 1.22 | 1.25 | 0.95 | 1.10 | 1.05 | B | Rear-drive: easy drifts, drifts fill nitro ×2 |
| 7 | **Iżera** ("Polski elektryk. Zapowiadany od lat. Przyjechał.") | Izera EV | 1,300 zł | 1.12 | 1.45 | 1.05 | 1.00 | 1.10 | B | Instant pull, a quiet hum; braking refills nitro (regen) |
| 8 | **Łamborgini Kurakan** | Lamborghini Huracán | 2,400 zł | 1.40 | 1.45 | 1.20 | 1.10 | 1.20 | A | Loud: pedestrians turn their heads, police notice sooner |

- **Time to buy** at ~20 zł a minute: Łanos 10 min, Bolonez 15, Mazgaj 30, Ałroud 35, TT 45,
  Bawara 55, Iżera 65, Kurakan about 2 hours. A full main line buys any one of the first seven.
- **Class** is a letter from the car's numbers *with its parts*: D, C, B, A, S (only a fully
  tuned Kurakan, or a tuned B car, reaches S). Shown as a badge everywhere.
- **Owned cars stay owned**; switching is free. No selling in v1 (it adds a menu and a way to
  lose money). Paints apply to any car (the paint is the player's, not the car's).
- **The cabrio** is a new Shape option: no roof and side panes, a windscreen frame, two seats and
  a driver's head (one more part in the same mesh, no extra draw call).
- **Reserved colours** (art bible): the factory paints of the new cars avoid the police blue; red
  and orange stay the player's, so every new car comes in red by default like today.
- Mirek's lines for each car (warsaw-tone skill: Polish with English, affectionate).

## 4. Tuning (per car, four parts, three levels)

| Part | Each level adds | L1 ULICA | L2 SPORT | L3 WYŚCIG |
| --- | --- | ---: | ---: | ---: |
| Silnik (engine) | top +4 %, pull +4 % | 50 zł | 100 zł | 150 zł |
| Turbo | pull +8 % | 50 zł | 100 zł | 150 zł |
| Zawieszenie i opony (suspension and tyres) | grip +7 %, steer +4 % | 50 zł | 100 zł | 150 zł |
| Hamulce (brakes) | brake +10 % | 50 zł | 100 zł | 150 zł |

- A car fully tuned costs **1,200 zł** of parts. A maxed Łanos is about a stock TT; a maxed TT is
  near a stock Kurakan. Upgrading the cheap car you like is a real choice, as in NFS.
- **Per car** (NFS's rule, F's "develop the car"): each car keeps its own levels. Today's shared
  tyres and engine levels are copied to every car the player owns when the save loads (nobody
  loses anything), and the old "tyres" become Zawieszenie i opony.
- Level 3 shows on the car where it is cheap to show: Turbo L3 a bonnet scoop, Zawieszenie L3 the
  body 3 cm lower, Silnik L3 a twin exhaust. Same mesh, no new draw call.
- `car.gd` gets two more multipliers next to `top_mult`, `accel_mult`, `grip_mult`: `turn_mult`
  (turn cap and pull) and `brake_mult` (the brake decel). They apply on top of the handling profile
  (Cruise, Sport, Grounded) exactly like the others.
- Existing paint prices stay (50-150 zł).

## 4b. How each car drives (F 2026-11-22: "work the car control out well, so different cars feel different")

**The rule.** The player's handling profile (Settings → Jazda: Cruise, Sport, Realnie) stays the
base: it says *how arcade* the driving is. A car is a **feel preset on top of it**: multipliers on
the profile's numbers, so a Bawara in Cruise is still a calm city car, only with its own
character, and in Sport it really slides. Nothing a car does may break the city rules (lane
assist, the stop assist, kerbs, collisions, the tow): the collision box stays one size for all.

**The knobs** (car.gd has most of them already, per profile; today one car shares them all):

| Knob | car.gd today | What the player feels |
| --- | --- | --- |
| Steering response | `steer_time` | how fast the car answers the thumb (go-kart vs bus) |
| Turn at low / high speed | `turn_cap`, `turn_pull`, `turn_floor` | tight in the streets vs calm on the avenues |
| Grip and slide | `grip`, `drift_grip` | holds the line vs the tail steps out when braking in a bend |
| Power slide (new) | – | rear-drive: full gas in a slow bend kicks the tail out (Bawara, Bolonez) |
| Pull curve (new) | `accel`, `onset`, one fade with speed | EV: everything at once, then fades; turbo: kicks in mid-range; old engine: slow build |
| Brakes | `brake_decel` (Realnie: `GR_BRAKE`) | stopping distance |
| Weight | yaw lag (`YAW_LAG`), load transfer (Realnie only) | heavy cars turn in a beat late and lean |
| Body lean (all profiles) | body spring, Realnie only today | the body rolls in bends and dips under braking: the strongest cue from the iso camera |
| Rough ground | kerb and grass drag (`KERB_*`) | Ałroud shrugs off kerbs, grass and cobbles |
| Sound and camera | engine pitch, tyre squeal, camera lead at speed | the Kurakan screams and the view pulls back; the Iżera hums |

**The cars' feel** (multipliers on the profile; 1 = the hatch; the one-line "feel" is what the
garage card says, in Polish with English):

| Car | Steer response | Turn | Grip / slide | Pull curve | Brake | Weight / lean | Feel line |
| --- | ---: | ---: | --- | --- | ---: | --- | --- |
| Hatchback | 1.0 | 1.0 | 1.0 | even | 1.0 | 1.0 / 1.0 | "Uczciwy. Jedzie tam, gdzie patrzysz." |
| Dejwu Łanos | 0.85 (quick) | 1.08 | 1.0, soft | weak, even | 0.95 | light / leans 1.4 | "Lekki i nerwowy, ale wybacza." |
| FSŁ Bolonez Karo | 1.25 (slow) | 0.92 | 0.9, tail out on brakes | slow build | 0.9 | heavy, lag 1.4 / leans 1.6 | "Płynie jak statek. Tył ma własne zdanie." |
| Mazgaj MX-5 | 0.7 (go-kart) | 1.2 | 1.15, flat | light, even | 1.05 | very light / leans 0.6 | "Gokart z dachem w bagażniku." |
| Ołdi A6 Ałroud | 1.1 | 0.95 | 1.0 | strong low down | 1.0 | heavy, lag 1.3 / leans 1.3 | "Krawężnik? Jaki krawężnik?" |
| Ołdi TT | 0.9 | 1.05 | 1.1, never slides (quattro) | even | 1.05 | planted / leans 0.7 | "Przyklejony do asfaltu." |
| Bawara M3 | 0.9 | 1.1 | 0.95, slides on brakes and power | strong mid | 1.05 | medium / leans 0.9 | "Tylny napęd. Gaz w zakręcie = bokiem." |
| Iżera | 1.0 | 1.0 | 1.05 | instant, fades past 100 km/h; strong regen off the gas | 1.1 | heavy but low, lag 1.2 / leans 0.6 | "Cicho, szybko, od zera." |
| Łamborgini Kurakan | 0.75 (sharp) | 1.1 | 1.2, nervous at top speed | violent | 1.2 | low / leans 0.5 | "Dużo konia. Uważaj na tramwaje." |

**Tuning changes the feel too**, not only the numbers: Zawieszenie levels cut lean and yaw lag
(-15 % a level) and add grip; Turbo moves the pull curve's kick earlier; Hamulce shorten the stop.
A maxed Bolonez still floats, only less.

**Readable for the player**: the card shows the 4 bars, the class and the one feel line; and
**JAZDA PRÓBNA** (test drive, as in the NFS showrooms): from the garage, 60 s in any car round
the nearby blocks, then back to the lot. You buy what you have felt.

**Tuning on the phone (DEV)**: a "Car lab" card in the DEV settings (F keeps DEV visible): the
car's knobs as sliders, live, with the numbers written to the log, so F can tune the feel on the
iPhone and the thread copies the numbers into `upgrades.gd`.

## 5. Nitro: tap, bottles, earned by driving

1. **A tap fires one bottle**: 2.5 s of boost (top ×1.3, pull ×2.2 as today). While a bottle burns
   the gas is held for you, so the thumb can do anything. BRAKE ends the burn.
2. **The disc moves to sit right above GAS** (60 pt, same side as the thumb). Slide the thumb up
   from GAS onto it, or tap it: both fire. The thumb never crosses the brake.
3. **Bottles, not a held tank**: the kit (250 zł, once, for every car) gives 1 bottle; "Druga
   butla" 200 zł and "Trzecia butla" 300 zł give 2 and 3. Shown as 1-3 segments round the disc.
4. **Refill**: an empty bottle fills in 20 s of driving, faster when you drive like an arcade
   hero: a near miss +15 %, a second of drift +10 %, a jump +20 %, a clean overtake in a race +10 %
   (Bawara, Bolonez, Iżera perks above). A full bottle pops with a short "pling" and a buzz.
5. **Feel**: the camera pulls back a little and widens, short speed lines, the flames and whoosh we
   have, a short buzz.
6. **Pad and keyboard**: LB/RB tap and Shift tap fire one bottle (the same rule).
7. **Night meet drag** (`street_meet.gd`): the "nitro on loan" becomes one bottle; `sim_run` keeps
   its numbers with a 2.5 s burn.
8. Rivals still never use nitro (as today); nitro for rivals belongs to question 4.

## 6. Screens

**One car viewer** (new, small): a SubViewport with its own tiny world (a turntable disc, one key
light, one rim light), the car mesh from `models.gd` in its paint and parts. Drag to turn it, it
spins slowly by itself, pinch to zoom. The game is paused under it; closed it costs nothing.

**The garage card** (Warsztat u Mirka), three tabs:
- **AUTA**: the viewer on the left, the cars on the right (name, class badge, price or "masz" /
  "jeździsz"), the 4 bars for the one picked, its perk; one big button: KUP 550 zł / WSIADAJ.
- **TUNING**: the 4 parts and the nitro bottles for the car on the road; the bars show the green
  "after" segment for the part picked; KUP 100 zł · SPORT.
- **LAKIER**: today's paints, now shown on the turning car.

**MOJE AUTO** (new, F's "menu somewhere on the map"): a second big button next to QUESTS on the
full map (and a row in Settings). The viewer, the car's name, class and bars, then:
- **GARAŻ**: the cars you own; tap one and WSIADAJ swaps it right there (only when stopped and no
  job, race or chase is on: "Mirek podstawił auto").
- **TUNING**: what is fitted and what the next level costs.
- **KATALOG**: every car with its price and class; for one you don't own, TRASA DO MIRKA sets the
  route to the garage. Buying happens at Mirek's (question 3).

All in the UI kit (`ui_kit.gd`, dark cards, gold titles in caps), Polish over English, every
touch target 44 pt or more, the gamepad works on every row.

## 7. The place: Warsztat u Mirka on the corner of Twarda and Emilii Plater

- **Where**: the garage stays on Twarda (PR #1009) and grows into the corner by the real
  filling station at **Emilii Plater 55** (it is on the map today as a low retail box at about
  -1541, -86, 60 m from the ring), under the 160 m Cosmopolitan tower (Twarda 4). A scruffy
  workshop under a luxury tower is a very Warsaw picture.
- **What**: a single-storey workshop with two roll-up doors (one open and lit, a car up on a
  lift), a hand-painted sign "WARSZTAT U MIRKA · MECHANIKA · WULKANIZACJA · TUNING", stacks of
  tyres, an oil drum, Mirek in overalls by the door; beside it **"KOMIS U MIRKA"**, a lot with the
  cars for sale in a row, price cards behind the windscreens ("OKAZJA! 200 zł"), a string of
  flags, a neon at night. Cars you own park on the lot when you are not in them.
- **Drive in**: the ring moves off Twarda into the lot, so stopping there never blocks traffic.
- **Cost**: the lot's cars are one merged mesh in the shared material (1-2 draw calls), the
  workshop and props a handful more; target ≤ +5 draw calls in view, bench before/after.
- **How**: photos first (Mapillary, Panoramax, fotopolska.eu for that corner), the plot measured
  on the orthophoto on the Mac; turntable sheet before the PR (`tools/turntable.sh`). If the plot
  is too tight, the lot takes the forecourt side and only the workshop front faces Twarda.
- F lifted the modelling stop for the garage in this ask.

## 8. Questions for F (each has a default that gets built if nobody answers)

1. **Names**: Dejwu Łanos, FSŁ Bolonez Karo, Mazgaj MX-5 Kabrio, Ołdi A6 Ałroud, Ołdi TT, Bawara M3,
   Iżera, Łamborgini Kurakan. *Default: these.*
2. **Parts per car or shared?** *Default: per car (NFS).*
3. **Buy only at Mirek's, or also from MOJE AUTO anywhere?** *Default: buy at Mirek's (the place
   matters), look, switch and route from anywhere.*
4. **Should a better car win races more easily?** Today rivals drive at your car's top speed, so
   upgrades don't help in races. NFS gives each race a fixed rival level, so upgrades matter.
   *Default: keep today's rule until F decides; phase 5 is the change.*
5. **The place**: the corner of Twarda and Emilii Plater by the filling station. *Default: yes.*
6. **Keep the old hold-to-burn nitro as a setting?** *Default: no, tap only.*

## 9. Phases

| Phase | What | Model | Size | Checks |
| --- | --- | --- | --- | --- |
| **P0** | Nitro: tap, bottles, disc above GAS, refill from near misses/drift/air, pad and keys, the drag | Opus (feel) | 1 PR, ~1 day | new `check_nitro`, `check_gamepad`, street meet drag check; full DoD, bench (per-frame), phone feel |
| **P1a** | Cars, feel and tuning: `upgrades.gd` roster, per-car feel presets on the profile (4b), the power slide, pull curves, body lean in every profile, per-car parts, class, perks, `--car`/`--tune`/`--car-log`, the Car lab (DEV), save migration (copy the old levels, TT refund 600 zł with Mirek's line) | Opus | 1-2 PRs, ~2-3 days | new `check_car_feel`, `check_garage`, lanedrive/steering/grounded per car, race bench, police chase pace (9b) |
| **P1b** | The 8 bodies in `models.gd` (cabrio part), Level-3 parts on the body | Sonnet object-modeler, Opus accepts | 1 PR, ~1-2 days | turntable sheet per car, shots, bench |
| **P2** | Car viewer + the garage card's three tabs + JAZDA PRÓBNA | Sonnet with this spec | 1 PR, ~1-2 days | card shots at phone size, gamepad |
| **AP** | Autopilot rows P21-P23 on F's Mac after P0-P3 land (9b.4) | Opus thread on the Mac | ~1 evening | PT-n rows, fix threads |
| **P3** | MOJE AUTO from the full map and Settings | Sonnet | 1 PR, ~1 day | shots, check the switch rule |
| **P4** | The workshop and the komis lot at Twarda × Emilii Plater | Sonnet modeler, Opus directs | 1-2 PRs, ~2 days (Mac shots, bench) | turntable, prebuilt and runtime city, bench |
| **P5** | Races value the car: a rival level per race (F's call, question 4) | Opus | 1 PR | race bench before/after (`tools/race_bench.sh`), the racer rules |
| later | Looks: rims, spoilers, underglow (BACKLOG), plates; selling cars | Sonnet | | |

P0 goes first (F's pain today, touches nothing else). P1a → P1b → P2 → P3 in order; P4 can run
beside them in the map lane. About 10-14 thread-days in all, plus an Autopilot evening. Any change to `traffic.gd`,
`race_session.gd`, `race_planner.gd` or `rivals.gd` reruns the race bench. Merges: the audit
thread's go and a green `gate`.

## 9b. Testing the feel (headless, then Autopilot, then the phone)

1. **`check_car_feel.gd`** (new, joins `tools/verify.sh`): the real car script on the flat test
   ground, every car × every profile, the same manoeuvres a car magazine runs: 0-100 km/h, top
   speed, 100-0 braking distance, the turning circle at 30 km/h, the most sideways pull at 60, a
   lane change at 50 (peak slip, settle time), a 6-cone slalom 18 m apart, a 90° corner at full
   lock at 25 km/h, full gas in a slow bend (the power slide). It prints one "feel card" table
   and fails when a car leaves its band or the **order** breaks (the Mazgaj fastest through the
   slalom of the cheap cars, the TT slides least, the Bawara and Bolonez most, the Iżera first to
   50 km/h, the Kurakan fastest overall). Cruise keeps F's G4 rule: no car slides more than
   CRUISE_SLIP in a lane change at 50 km/h unless the player asks for it (brake or power in a bend).
2. **Every car drives the city**: `check_lane_drive` (13 routes, the real car steered along the
   lanes), `check_steering` and `check_grounded` run for each car (`--car=<id>`, new flag, with
   `--tune=0..3`): no stall, no unstick, no sink, lane assist holds.
3. **Races and the police**: `tools/race_bench.sh` with the slowest and the fastest car (rivals
   take the player's top today), and `check_police` "chase pace" with the Kurakan.
4. **Autopilot on F's Mac** (F asked for it, 2026-11-22; docs/PLAYTEST.md, new rows; one car per
   run to stay under the Mac's ~6 min limit; the decision model bills F's Aura account):
   - **P21 Car feel tour**: each car (`--car=`, stock and `--tune=3`) drives the same ~3 min loop
     Twarda → Emilii Plater → Świętokrzyska → Marszałkowska → Rondo Dmowskiego → Jerozolimskie →
     back, Classic controls. The log gives speed, slip, kerb hits, contacts and stops (`--car-log`);
     Autopilot says which car was hardest and where it got stuck.
   - **P22 Nitro**: taps on Wisłostrada and in a race, bottles and refills, any fire by mistake.
   - **P23 Garage and MOJE AUTO**: buy, switch, test drive, turn the car, every button, leave.
   - **P17 again** with the Łanos and the Kurakan: is the race still close?
   Autopilot gives the place and the symptom; any stop a player could make goes to a cloud fix
   thread with a headless repro (the 2026-11-08 lesson).
5. **The phone**: PHONE-CHECK rows, one per car, F's word on each feel line; the Car lab numbers
   go back into the code.

## 10. What only the phone can show

The nitro thumb (slide up from GAS), the burst's feel, the turning car in the viewer at 60 fps,
the class badges' readability, and the lot's draw calls on the iPhone.
