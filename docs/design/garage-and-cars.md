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
| **P1a** | Cars and tuning data: `upgrades.gd` roster, per-car parts, class, `turn_mult`/`brake_mult`, perks, save migration (copy the old levels, TT refund 600 zł with Mirek's line) | Opus | 1 PR, ~1 day | `check_garage` grows; lanedrive and steering stay on the hatch |
| **P1b** | The 8 bodies in `models.gd` (cabrio part), Level-3 parts on the body | Sonnet object-modeler, Opus accepts | 1 PR, ~1-2 days | turntable sheet per car, shots, bench |
| **P2** | Car viewer + the garage card's three tabs | Sonnet with this spec | 1 PR, ~1-2 days | card shots at phone size, gamepad |
| **P3** | MOJE AUTO from the full map and Settings | Sonnet | 1 PR, ~1 day | shots, check the switch rule |
| **P4** | The workshop and the komis lot at Twarda × Emilii Plater | Sonnet modeler, Opus directs | 1-2 PRs, ~2 days (Mac shots, bench) | turntable, prebuilt and runtime city, bench |
| **P5** | Races value the car: a rival level per race (F's call, question 4) | Opus | 1 PR | race bench before/after (`tools/race_bench.sh`), the racer rules |
| later | Looks: rims, spoilers, underglow (BACKLOG), plates; selling cars | Sonnet | | |

P0 goes first (F's pain today, touches nothing else). P1a → P1b → P2 → P3 in order; P4 can run
beside them in the map lane. About 8-11 thread-days in all. Any change to `traffic.gd`,
`race_session.gd`, `race_planner.gd` or `rivals.gd` reruns the race bench. Merges: the audit
thread's go and a green `gate`.

## 10. What only the phone can show

The nitro thumb (slide up from GAS), the burst's feel, the turning car in the viewer at 60 fps,
the class badges' readability, and the lot's draw calls on the iPhone.
