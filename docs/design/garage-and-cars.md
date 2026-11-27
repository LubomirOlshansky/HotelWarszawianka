# Garage, cars, tuning and nitro: the plan (2026-11-22)

F (2026-11-22, the thread "Plan garage, car buying, upgrades and nitro"): Mirek's garage should
look like a real car service with cool cars around it, in a place with space; parts to change like
in Need for Speed (engine, steering, handling...) but easy to understand; a few cheap cars to buy
that you can see and turn round in the garage (look-alikes of an Audi TT, an A6 allroad, a Daewoo
Lanos, a Lamborghini, a Polonez, a BMW "bavara", a cabrio and an electric car); a menu somewhere on
the map with your car, what you bought and a way to switch cars; and a normal nitro, because today
you have to take your thumb off the gas to use it. **This is a plan for F's approval. Nothing is
built yet.**

## 0. The revised plan (2026-11-22, after the Opus review; F: "critique it with Opus, revise, implement")

**This section wins over everything below it.** The sections below are kept as the first draft and
the reasons. What the review found and what changed:

1. **Rivals stop copying the player's car** (the review's #1): today rivals race at the player's
   top speed (`rivals.gd` `player_top`, the pack race in `street_meet.gd`), so a better car wins
   nothing. They get a fixed top, the stock hatch's 30 m/s: a stock hatch races exactly as today,
   a better car gains. Done **before any car is sold** (phase R1, race bench before and after).
   The drag and the police chase stay as they are for now.
2. **One handling slider instead of the Cruise/Sport modes** (F 22:43: "the default steering is too
   dull, I set Sport at once; we have sensitivity, so why the modes; make it better by default, a
   slider from Cruise to sharper, maybe slides, maybe not, it must get on with the car tuning"):
   Settings → Jazda gets one slider **„Charakter jazdy": Spokojny ↔ Sportowy** that blends the Cruise
   and Sport numbers (grip, turn, steering speed, gas bite) and folds the old sensitivity in. The
   default sits at about two thirds, close to Sport. Slides only open on the last third (so the
   left end keeps F's G4 rule "a city, not a racer"); Realnie stays a separate switch. Each car's
   feel multiplies whatever the slider gives, so cars and the slider get on. Saves move over: Sport
   → 1.0, Cruise → the new default 0.65 (built: Cruise was the default nobody chose, since the modes
   sat on the DEV page; 0.35 is still Cruise's exact numbers), Grounded → Realnie, a moved
   sensitivity shifts the slider by half its offset. (Phase H1, built 2026-11-22: car.gd
   `set_character`, 0..0.35 calmer than Cruise, 0.35 Cruise, 0.35..0.8 the steering to Sport's,
   0.7..1 the tail's grip to Sport's, 1 Sport.)
3. **Only knobs a player can see from the 80 m camera** (#2, #3): top speed, the pull curve (bite
   and fade), the turning circle, steering speed in three bands, the tail slide (only on the slider's
   sporty end), and **the engine sound per car** (the strongest cue). Cut: brakes as a part, body
   lean per car, weight per car, grip on the calm end.
4. **Nitro** (#4): tap fires a 2.5 s bottle; the kit stays **350 zł with 2 bottles**, each refills in
   12 s, a 3rd bottle 300 zł; owners keep what they paid for (they get 2 bottles). In Classic the disc
   moves **above GAS** and a swipe up from GAS (40 pt or more) fires it; in Point and Fixed it stays
   where it is. The drag: a tap before the green waits for the green (no false start), and the BIEG
   shift keeps its place. Pad LB/RB tap, Shift tap. Near-miss refills are deferred (no detector yet).
5. **Tuning stays shared by every car** (#8; no save migration): Silnik (engine) and "Zawieszenie i
   opony" (the tyres, now grip +8 % and turn +4 % a level) at today's prices; Turbo later. Per-car
   tuning, class badges, the test drive and most perks are deferred; two cheap perks stay (the
   Ałroud shrugs off kerbs, the electric car's quiet hum).
6. **Cars and prices** (the review's numbers; speed ceiling kept at today's ~190 km/h with nitro):

| Car | Price | Top | Pull | Turn | Slide (sporty end) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Hatchback z paskami | free | 1.00 | 1.00 | 1.00 | 1.0 |
| Dejwu Łanos | 200 zł | 1.00 | 0.85 | 1.12 | 1.0 |
| FSŁ Bolonez Karo | 300 zł | 1.03 | 0.85 | 0.88 | more |
| Mazgaj Kabrio | 550 zł | 1.02 | 1.05 | 1.20 | 1.0 |
| Ołdi Ałroud | 700 zł | 1.08 | 1.00 | 0.90 | 1.0 |
| Ołdi TT | 1,000 zł (was 1,500: owners get 500 back) | 1.12 | 1.20 | 1.05 | less |
| Bawarka 325 | 1,200 zł | 1.15 | 1.25 | 1.05 | more |
| Prąd-Pol Cichobieg (electric) | 1,400 zł | 1.08 | 1.50, instant, fades | 1.00 | 1.0 |
| Łamborgini Kurakan | 2,800 zł | 1.22 | 1.50 | 1.00 | 1.0 |

   Names lost their real model codes (M3, MX-5, A6) and the electric car is no longer a near-copy of
   a state EV project. Stripes are per car (a Bolonez has none).
7. **Screens**: the garage card gets the turning car (a SubViewport with its own small world) and
   tabs AUTA / TUNING / LAKIER; MOJE AUTO is a 44 pt chip on the full map (not a second big button);
   switch cars only when stopped with nothing on. One language at a time through `Lang.pick` (not
   Polish over English).
8. **The lot**: a `Places.TABLE` row beside today's ring on Twarda (no ring move, no re-bake); the
   workshop and Komis u Mirka modelled after the screens.

**Order (one PR each; PRs touching car.gd go one after another):** N1 nitro → H1 handling slider →
R1 rivals' fixed top → C1a cars' feel, roster, sound, Car lab, `check_car_feel` → C1b the bodies
(turntable sheets) → G1 garage card with the viewer → G2 MOJE AUTO → Autopilot P21-P23 → the lot →
the drift (docs/design/drift-narodowy.md section 0). The estimates below are optimistic: about 1.5×.

**C1a + C1b built (2026-11-27, F: "a few meme cars at Mirek's, each driving its own way", "the
TT must be there", "nice models"; the Bawarka as the night meet's prize, story fix-plan-v2):**
upgrades.gd CARS has the hatch, Dejwu Łanos 200 zł (D), FSŁ Bolonez Karo 300 zł (D), Paszat B5 TDI
600 zł (C), Madża Mjata 800 zł (C, the roof-down roadster with its pop-up lamps up, F 2026-11-27), Tojota Szupra 1,100 zł (B), the Ołdi TT 1,500 zł (A, unchanged numbers, rounder body)
and Bawarka Darka 2,500 zł (A; gold in the night meet's drag gives it, a loss opens it for sale:
`meet_prize`). Each car's `feel` (car.gd `set_feel`: turn, steering lag, tail slide on the sporty
end only, the gas's bite, the pull's fade, the engine note in sfx.gd); bodies in models.gd
`player_meshes` / `_player_kit` (+0 draw calls), sheet `game/tools/car_sheet.gd`. Not built: the
Mazgaj, Ałroud and Cichobieg, per-car paint, weight in crashes.

**Defaults built unless F says otherwise:** race classes (section 0a; the fixed rival top is cut);
tuning shared; you can buy a road Bawarka 325 and the drift prize is its drift setup in Darek's
colours; in the calm half of the slider cars differ only by speed, pull, turning and sound.

## 0a. Balance: race classes (F 2026-11-23 00:29 Warsaw, after the revised plan)

F: "the chases, the police and so on need balancing: if you buy a fast car it mustn't stop being
fun to race; the rivals should adapt somehow, because if you buy and tune you overtake everyone
easily; maybe some races you can win with the starter car and some only once you tune it."

**The Opus critique of both ways we have:**
- *Today* (rivals.gd `player_top`, street_meet.gd `_player_top`, police.gd `chase_top`): every rival
  and patrol races at a share of **your** car's top. Races never get boring, but a bought car or an
  engine level buys nothing in a race, so the garage is cosmetics; and Mike (share 1.0) can never
  be faster than you, so a "hard" race is impossible to make.
- *Section 0 #1 (R1, a fixed 30 m/s)*: upgrades finally count, but after the first engine level
  every ladder race is a walk, so F's worry is right. Cut.
- What arcade racers do: a car rating and **race classes** (Need for Speed's performance rating,
  Forza's D-C-B-A-S classes, Asphalt's car tiers, Midnight Club's class-locked tournaments): each
  race has its own class and its rivals bring cars of that class; your upgrades open the next
  classes, and the old races stay winnable easily but pay little. The rubber band (our catch-up,
  #948) keeps any race close at the end, it does not decide who is faster.

**Built from this (replaces R1):**
1. **Your car's class** from one number, *Moc* = top × engine + 0.15 × (pull × engine − 1):
   **D** below 1.05, **C** below 1.13, **B** below 1.22, **A** below 1.34, **S** from 1.34. Shown as
   a letter badge on the garage card, MOJE AUTO and the race card ("Klasa C"). Examples with
   today's numbers: the hatch D; hatch + engine 1 C; hatch + engine 3 B; Ołdi TT B, with engine 3 A;
   Łamborgini Kurakan A, with engine 2 or 3 S.
2. **Each race has a class** and its rivals drive at that class's top, not yours: D 30, C 32.5,
   B 35, A 37.5, S 40 m/s, times the rival's own `share` (Halina 0.775 ... Mike 1.0), so the ladder
   keeps its order. The catch-up stays (CATCH_TOP 42 m/s).
   - Ladder: Halina **D**, Słoik **D**, Bartek **C**, Seba **C**, Zbyszek **B**, Mike **A**, the
     final **A**. The first two are the starter car's races (F 2026-11-10: the first race stays a
     real race you can lose); Bartek and Seba want an engine level; Mike wants a real car.
   - The race meets (pack race) climb a class a night; Trzy mosty A; free duels at your class.
3. **Racing below your class**: allowed, never locked. The rivals answer one class up ("Halina też
   coś podkręciła", a line on the card) and the pay drops by a third for each class you are above
   the race (respect for a first win stays whole). One class over: an even race again, two or more:
   an easy win that pays little. So a tuned car is a reason to go up, not a way to farm.
4. **Racing above your class**: allowed too; the card says "Twoje auto: C · wyścig: B" in amber and
   Mirek says it'd be quicker with a better engine. Catch-up never helps the player (it is only for
   rivals), so it is honestly hard.
5. **The police**: a patrol already matches your car (`chase_top` = 0.8 × your top, 0.7 once they
   tire). That stays: the police are not a race to win with top speed. A better car still helps a
   chase through pull, turning and the nitro (the burn is left out of the patrols' top on purpose).
   New: from class A the chase calls one fast unit after 20 s, so a supercar can't simply hold the
   throttle and vanish; nothing changes below A.
6. **The drag**: Tadek and the drag rivals get a class too (D now, the meet's later nights C and
   B), with times scaled by class, instead of fixed times a tuned car always beats.
7. **Rewards scale up with the class** (D 1×, C 1.3×, B 1.7×, A 2.2×, S 3× the race's pay), so a
   new car pays itself back in its own class, and the prices in section 0 #6 stay.

**Tests:** `check_race_class` (the class of every car and tune from the numbers above; a race's
rival top by class; the over-class step and pay); `tools/race_bench.sh` with a player in each class
against each rung (marks: the starter car beats Halina and Słoik in a clean run, loses to Mike by
more than 5 s; a class-A car beats Mike on a clean run; a car two classes over wins by more than
10 s); Autopilot P21-P23 get a class column; the phone check (does a tuned car feel worth it, is the
old race still fun one class over).

**Built in R1 (2026-11-23, F chose "rivals one class up" on the card):** points 1-4 (ladder.gd
`car_class`, `race_class`, `class_top`, `over_pay`, `club_class`; rivals.gd and street_meet.gd use
them; the race prompt shows "KL. C (TY D)"). Still to come: the police fast unit (5), the drag
classes (6), the pay rising with the class (7, with C1a when cars are sold), the badge on the
garage card and MOJE AUTO (G1, G2).

**Order:** N1 → H1 → **R1 classes** (the badge, the race class, the over-class step, the bench) →
C1a ... as in section 0. The police fast unit and the drag classes come with R1 if small, else
right after it.

## 0b. MOJE AUTO and the garage card: the night-garage look (F 2026-11-23 01:04 Warsaw)

F: "MOJE AUTO should have that street-racing underground vibe, with the garage and the tuning;
critique it with Opus and make it nice and stylish." The mood of the 2000s night-tuning racers
(a car under coloured light in a dark garage, readable part levels, the car turning while you
choose), made in our own look: the UI kit's dark cards (F 2026-11-19), our neon pink and cyan,
Warsaw's own details. No layout, font, logo or art from any existing game.

**One screen, three doors** (F 00:04: "the same for Mirek's garage and the car showroom, make it
stylish"). One `car_screen.gd` (a Control with a small 3D stage) in three modes: WARSZTAT at Mirek's
(G1: tune and paint, the workshop's work lamps and tool wall behind the car), KOMIS u Mirka on the
lot next door (buy cars: the car on a raised plate under a price banner, the next car a swipe
away, the lot's string of bulbs overhead) and MOJE AUTO from the full map (G2: look, switch owned
cars when stopped, see class and stats; the shop's buttons say "U Mirka na Twardej", so there is
still a reason to drive there). Same stage, same panel, a different back wall and buttons. The
game pauses under it, as the garage card does today.

**The stage (left 60 %, the car big):**
- A night box: dark concrete floor with a soft wet sheen (the car's body drawn once more upside
  down under a 70 % dark floor, the cheap mirror; no reflection probe), the back wall a roller door
  with a faded "TWARDA 24h" stencil and a parody sticker or two (Mirek's, original art), a work
  lamp and a tyre stack as silhouettes.
- Light: two neon tubes (unshaded emissive strips, pink above, cyan along the floor; additive halo
  quads, no glow pass), one warm key light; the paint you pick lights the floor's sheen.
- The car on a slow turntable (8 s a turn); a swipe turns it, a release lets it drift on; a tap on
  a part makes the camera ease to it (engine: the bonnet, tyres: the wheel, nitro: the boot).
- Changing a car: a 0.4 s fade through black with the engine's own rev (car.gd's engine sound).

**The panel (right 40 %, the dark card):**
- Head: the car's name big, the class badge (a neon letter D C B A S in a hexagon, its colour by
  class), the wallet.
- Tabs: AUTA (the owned and the buyable cars as a strip of cards: a side silhouette, the price or
  "masz"), TUNING (Silnik, Opony i zawieszenie, Nitro: three level pips each, the next level's
  price), LAKIER (today's swatches).
- Four stat bars that anyone reads at a glance: Prędkość, Przyspieszenie, Skręt, Nitro. The bar
  now in white, what a buy adds in cyan, what a switch loses in pink; the class letter beside them
  steps when a buy crosses an edge ("C → B" pulses once).
- One big gold action (KUP · 120 zł / ZAŁÓŻ / JEDŹ) and WYJAZD.

**The Opus critique, and the answers built into the spec above:**
1. *A 3D viewport on the phone costs frames.* The game is paused under the screen; the stage is a
   SubViewport with its own World3D, at 0.75 of the screen's scale, about 12 draw calls (car 3,
   mirror 3, floor, wall, two tubes, two halos), no shadows (a baked blob under the car), and it
   stops rendering the moment the screen closes. Bench row "car screen open" before G1 ships.
2. *Neon needs glow, and glow is a full-screen pass.* Halo quads (a soft radial texture, additive)
   give the look without the pass; the Mobile renderer's glow stays off.
3. *Too dark reads as muddy on a phone outdoors.* The car is lit warm and bright; only the room is
   dark. The panel's text keeps the kit's contrast (INK on CARD). Screenshot check by day outside
   is a PHONE-CHECK row.
4. *Two screens drift apart.* One script, one layout, the mode decides which buttons work.
5. *"Underground" can slide into copying.* Our own stencil, stickers and Mirek's lines; the kit's
   fonts and colours; no named game's HUD shapes.
6. *Thumb reach.* The tabs and the action sit at the panel's bottom half; nothing under 44 pt.
7. *Small phones (iPhone SE-class 16:9).* The panel takes 45 % and the car shrinks; the stats move
   under the action.

**Order change:** G1 (this screen at the garage) and G2 (the chip on the full map) come right after
R1, with today's two cars (the hatch and the Ołdi TT); the new cars of C1a/C1b join the same AUTA
strip as they are made.

## 1. What is there today (main 04e52e9)

- **Warsztat u Mirka** (`garage.gd`, card `garage_card.gd`): until 2026-11-24 a dashed ring on Twarda
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
| 6 | **Bawarka M3** (F's "bavara"; the game already calls Darek's car Bawarka) | BMW M3 E36 | 1,100 zł | 1.22 | 1.25 | 0.95 | 1.10 | 1.05 | B | Rear-drive: easy drifts, drifts fill nitro ×2 |
| 7 | **Iżera** ("Polski elektryk. Zapowiadany od lat. Przyjechał.") | Izera EV | 1,300 zł | 1.12 | 1.45 | 1.05 | 1.00 | 1.10 | B | Instant pull, a quiet hum; braking refills nitro (regen) |
| 8 | **Łamborgini Kurakan** | Lamborghini Huracán | 2,400 zł | 1.40 | 1.45 | 1.20 | 1.10 | 1.20 | A | Loud: pedestrians turn their heads, police notice sooner |

- **Time to buy** at ~20 zł a minute: Łanos 10 min, Bolonez 15, Mazgaj 30, Ałroud 35, TT 45,
  Bawarka 55, Iżera 65, Kurakan about 2 hours. A full main line buys any one of the first seven.
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
the profile's numbers, so a Bawarka in Cruise is still a calm city car, only with its own
character, and in Sport it really slides. Nothing a car does may break the city rules (lane
assist, the stop assist, kerbs, collisions, the tow): the collision box stays one size for all.

**The knobs** (car.gd has most of them already, per profile; today one car shares them all):

| Knob | car.gd today | What the player feels |
| --- | --- | --- |
| Steering response | `steer_time` | how fast the car answers the thumb (go-kart vs bus) |
| Turn at low / high speed | `turn_cap`, `turn_pull`, `turn_floor` | tight in the streets vs calm on the avenues |
| Grip and slide | `grip`, `drift_grip` | holds the line vs the tail steps out when braking in a bend |
| Power slide (new) | – | rear-drive: full gas in a slow bend kicks the tail out (Bawarka, Bolonez) |
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
| Bawarka M3 | 0.9 | 1.1 | 0.95, slides on brakes and power | strong mid | 1.05 | medium / leans 0.9 | "Tylny napęd. Gaz w zakręcie = bokiem." |
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
   (Bawarka, Bolonez, Iżera perks above). A full bottle pops with a short "pling" and a buzz.
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

## 7. The place: Warsztat u Mirka on Grzybowska

F, 2026-11-24 (Play 15 shots of the dashed ring on Twarda): "the garage is a dumb circle on the
street; there must be a real garage on Grzybowska, on an empty plot, really cool, pimp-my-ride
style, supercars and stripped cars beside it, something meme-y, lit up; drive up, press enter and
buy upgrades there; and it must always be on the map". Built that way (site `warsztat_mirka`,
`landmarks/mirek.gd`, spec `docs/landmarks/specs/warsztat_mirka.md`), in place of the earlier plan for the corner
of Twarda and Emilii Plater.

- **Where**: the empty plot on Grzybowska's south side between Q22 and the slab at number 61
  (OpenStreetMap: grass and a dozen trees, no building), about 230 m north-west of the old ring.
  The forecourt (garage.gd SPOT) is off the eastbound carriageway, so waiting there never blocks
  traffic; the mapped service stub is its driveway.
- **What**: a graphite hall with three roller doors in hazard frames (one shut and tagged, one
  open and lit with a hatchback up on a lift, one half up), WARSZTAT U MIRKA in pink neon on a
  black fascia with blue LED edges, a chequered parapet, TUNING on the west wall; in the yard
  two lowered supercars with underglow and a stripped car on axle stands, tyres and drums; on the
  roof the meme: a little cream hatchback and ZROBI SIĘ! in yellow neon. All of it the city's
  building surface (+0 draw calls), every light M_LAMP, the words the landmark neon.
- **Drive in**: roll onto the forecourt's blue bay and a side card asks WJEŻDŻAM / NIE TERAZ
  (Enter on a keyboard); WJEŻDŻAM opens the car screen. No ring on the street any more.
- **Always on the map**: the diamond is on the minimap and the full map from the first minute;
  the first earnings still bring the toast that says where.
- **MOJE AUTO** (from the full map) lists only what is owned: the cars bought and the paints
  owned, to switch between; the tab says AUTA. Parts, nitro and new cars: at Mirek's.
- **The lot (KOMIS)**: later, beside the hall on the same plot (the yard has room west of it).

## 8. Questions for F (each has a default that gets built if nobody answers)

1. **Names**: Dejwu Łanos, FSŁ Bolonez Karo, Mazgaj MX-5 Kabrio, Ołdi A6 Ałroud, Ołdi TT, Bawarka M3,
   Iżera, Łamborgini Kurakan. *Default: these.*
2. **Parts per car or shared?** *Default: per car (NFS).*
3. **Buy only at Mirek's, or also from MOJE AUTO anywhere?** *Default: buy at Mirek's (the place
   matters), look, switch and route from anywhere.*
4. **Should a better car win races more easily?** Today rivals drive at your car's top speed, so
   upgrades don't help in races. NFS gives each race a fixed rival level, so upgrades matter.
   *Default: keep today's rule until F decides; phase 5 is the change.*
5. **The place**: Grzybowska's empty plot by Q22 (F chose, 2026-11-24).
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
| **P4** | The workshop on Grzybowska (done 2026-11-24, `warsztat_mirka`); the komis lot beside it later | Opus | 1-2 PRs | turntable, prebuilt and runtime city, bench |
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
   slalom of the cheap cars, the TT slides least, the Bawarka and Bolonez most, the Iżera first to
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
