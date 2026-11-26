# Beta values: deliveries, races and steering (F, 2026-11-04)

F (2026-11-04): before the next round of city work, test the gameplay and improve its two main
beta values: **the delivery mechanic**, and **the racing mechanics with the steering**. Roads,
objects and buildings have their own plan (`docs/design/road-objects.md`). This page is the review
of the three, what was built straight away (the safe changes), and the A/B list for F's phone:
the feel calls that only F can make. Every A/B item is also parked in docs/QUESTIONS.md "Waiting",
so it shows on the dev console's Approvals tab (`tools/console.py`).

## 1. Deliveries (kebab, słoiki)

### 1.1 How it works today

- **Pick-up**: pull into a stand's ring (7 m, under 29 km/h). The order card counts down
  ("JEDZIEMY! · 9") and the job goes by itself, or on GO, or when the car drives off. 48 stands
  on the map (5 of them the Zagłębie's by Kino Femina); the słoiki at Centralny and Gdański.
- **The trip**: an address 400-1500 m by road (3.6 km across the river, 30 % of orders), a beacon
  on the door, an edge arrow, the distance.
- **The clock**: the heat falls in a straight line, `1 - 0.6 t / fair`, with
  `fair = 25 s + road / 8 m/s` (× the Zagłębie shop's factor). Hot (70 % and up) lasts half of
  `fair`, warm (40 %) all of it. A 1.2 km order: hot for 87 s, about 50 km/h door to door.
- **Pay**: fare `12 + 0.015 × road` zł, tip `heat × (10 + 0.02 × road)` only while warm, × 1.5 at
  night, × the shop's factor; +10 respect when warm. Słoiki: 40 zł + 30 a whole jar.
- **The end**: stop in the door's 9 m ring under 16 km/h (the stop assist brakes the car in). The
  result card goes by itself after 12 s or 25 m.

### 1.2 What the review found

| # | Finding | Effect on the player |
| --- | --- | --- |
| D-1 | The only guidance was the edge arrow, straight at the door. | In a grid of one-way streets the arrow points through blocks: the player turns into the wrong street, or the wrong way. Łuber already drew its route on the minimap; the kebab didn't. |
| D-2 | The order's road length counted the **off-map links** (the lane graph's portals). | The edge roadworks close every road out, so the player can't drive them. About 1 order in 30 (2 of 60 sampled) was a "1,053 m" trip that was much longer on the map's own roads, with a heat clock for the short one: cold however well you drove. The same pick serves Łuber and "Na czasie". |
| D-3 | The heat showed as "GORĄCY 85 %" and a bar. | No idea how long is left: the tip band (hot / warm / no tip) is the whole game, and it was hidden. |
| D-4 | After a delivery, nothing points anywhere. | The dead time of the loop: find a stand on the minimap, drive back, pull in, wait out the card. Crazy Taxi's rule is that the next fare is always in sight. |
| D-5 | The tip drops to 0 at 40 % heat (a cliff), and 50 km/h door to door is needed for "hot". | Most city trips with traffic arrive warm; a cliff at 40 % feels like a fail, not a smaller tip. A feel call (A/B 1, 2). |
| D-6 | The order card waits 9 s (14 s for the craft kebab) unless you drive off or press GO. | Fine for the first order (it teaches); slow on the tenth. A feel call (A/B 4). |
| D-7 | The test autopilot drives orders at ~6 m/s (order 0: 1,266 m in 212 s, cold). | Only the headless run; it says nothing about the balance. |

### 1.3 Built (2026-11-04)

- **The route on the minimap** (D-1): kebab and słoiki deliveries draw the way to the door as
  Łuber's dotted route, in the job's colour; it is walked again from the car every second
  (`scripts/route_line.gd`, one search per order, then a 0.13 ms walk), so a wrong turn re-routes.
- **Honest road lengths** (D-2): order, ride and "Na czasie" picks and the job autopilot measure
  without the off-map links (`LaneGraph.distances_from/to(…, portals = false)`).
- **The heat's clock in words** (D-3): "Gorący jeszcze 34 s", then "Ciepły jeszcze 20 s, potem bez
  napiwku", then "Zimny: bez napiwku, kurs się liczy" (`jobs.gd heat_hint`).
- **NASTĘPNE** (D-4): the delivered card has a second button. It points at the stand nearest by
  road: its ring, the edge arrow, the route and a toast "Następne zamówienie: Kebab 24h, 330 m".
  The pointer goes when the car pulls in or anything else starts. OK (or nothing) leaves things as
  they were.
- Check: `game/tools/check_delivery.gd` (verify step `delivery`, in CI).

## 2. Street races

### 2.1 Where they stand

R1 (racer driving), R2 (the band) and R4's numbers were built and measured on 2026-11-04
(`street-races.md` sections 6-7): an average autopilot driver beats Halina and Słoik and loses to
the rest; a skilled one beats all six, Zbyszek by only 25 m. The leaderboard is designed (L1-L5).

### 2.2 What the review found

| # | Finding | Effect |
| --- | --- | --- |
| R-1 | The police runs P3 and R1 (`verify.sh --only=police-runs`) failed on main since #426. | The test's escaping car rode a town-car ghost (every corner at ~20 km/h, stops for reds); once the chasers raced, they never lost it. Not a game bug: a real player corners faster. |
| R-2 | The race showed the gap in metres, and nothing marked a lead change or how close the finish was (R5 unbuilt). | A race is a story of being caught and passing; metres at 80 km/h mean little, and a 0.4 s finish looked like any win. |
| R-3 | Only the edge arrow pointed at the finish, straight. | The same as D-1: in Trzy mosty especially, where the next bridge is the goal. |
| R-4 | Rivals still route with the off-map links (`rivals.gd _distances`). | A finish near the map's edge could send a rival off the map and back in through a portal the player can't use. Not seen in the sampled races (central finishes); left as is because the race tuning was measured on these routes. Fix with R3 (routes by time). |
| R-5 | A flat-out escape now gets away in 16 s (P3, the racer-mode test car). | Is that too easy? A feel call (A/B 6). |

### 2.3 Built (2026-11-04)

- **Police checks green again** (R-1): the escape test car drives in racer mode like the race
  tests' skilled ghost (`police.gd` ESCAPE_ACCEL 12, ESCAPE_LAT 8.5). P1-P7 and part two PASS.
- **R5, the race shown better** (R-2, R-3):
  - the route to the finish on the minimap in the race's pink (in Trzy mosty to the next bridge,
    again at each checkpoint);
  - the gap in seconds: "Pani Halina 2,4 s za tobą", "łeb w łeb!" side by side (the metres
    between them over the trailing car's speed, at least 8 m/s);
  - a lead change says itself once: "PROWADZISZ! Pani Halina za tobą" or "Pani Halina cię
    wyprzedza!" with a short tick, at most once in 6 s and not in the first 3 s;
  - the finish card gives the margin: "Pani Halina za tobą (o 2,4 s)", "Zabrakło ci 40 m (o 1,8 s)",
    and the same in Trzy mosty.
- Checks: `check_ladder` (the gap's numbers and words), the verify runs `race`, `trzy-mosty`,
  `first10-run`, `police-runs`.
- Not built from R5: the rival's own screen-edge arrow (the minimap dot shows it) and the slipstream
  (A/B 9).

## 3. Steering

### 3.1 Where it stands

Classic (steering strip + GAS / BRAKE) has been the default since #425. The strip's curve is gentle
in the middle (`drive_controls.gd`: `u × (0.4 + 0.6 u)`), the Cruise profile holds the road (grip
16, turn pull 10, steering 0.14 s), the sensitivity slider scales it 0.6-1.4. Walls: #430 brings
Point's wall follow to Classic (head-on hits turn along the wall); the speed kept on a graze (97 /
90 / 80 % presets) is the collision v2 work in `road-objects.md` 4.2.

### 3.2 What the review found

| # | Finding | Effect |
| --- | --- | --- |
| S-1 | Nothing holds the car in its lane. On a touch strip every small correction is a thumb movement. | Long avenues and gentle curves (Wisłostrada, Trasa Łazienkowska, the bridges) need constant small inputs; the car drifts into the kerb or the oncoming lane. GAMEPLAY_PLAN 1.5's lane assist ("Asysta pasa") is not built. |
| S-2 | The strip's centre is a dead zone of 8 %, then the gentle curve. | Fine on a pad; on the phone it decides how twitchy the car feels. Part of F's feel test, no change. |
| S-3 | F: "97 % of speed kept on a graze is too arcade". | The road-objects thread's collision v2 (A/B from 90 %). Listed here only so the console shows it next to the steering items. |

### 3.3 Built (2026-11-04): the lane assist "Asysta pasa" (S-1), off by default

- Settings → Jazda → **Asysta pasa** (Wył. / Wł., `settings.gd lane_assist`, saved), and
  `--lane-assist=on|off` for a run. **Off by default** until F has felt it (A/B 10).
- Classic only. 10 times a second `main.gd` finds the lane the car drives in (within 3.5 m, its
  direction within 35° of the car's) and aims at the lane's middle 0.9 s ahead (8-30 m, pure
  pursuit), so it holds the lane's middle and goes round curves; `car.gd` adds `1.5 × the heading
  error` (rad/s) to the yaw while the strip is within 15 % of the middle (fading to nothing at 15 %),
  above 15 km/h (full from 22), under 20° off, not braking, not touching anything.
- `game/tools/check_lane_assist.gd` (verify step `laneassist`, in CI), the real car on flat
  ground at 50 km/h, steering in the middle:

  | Case | Assist on | Off (before) |
  | --- | --- | --- |
  | a straight lane, starting 6° off | on the lane in 0.7 s, 0.0 m across after 6 s | 8.7 m across |
  | a 300 m curve, 10 s | 0.2 m off the curve at worst | 31 m off |
  | the strip at 0.6 for 1 s | 30° turned | 30° turned |

  Plus: no pull under 15 km/h, braking, 25° off the lane, the strip at 0.15 or more, in Point, or
  switched off; on the map the lane's direction is found on 84 of 85 sampled lanes, nothing 10 m off
  the road, and turned the wrong way only the other lane's own direction.
- Not built from GAMEPLAY_PLAN 1.5: the wall look-ahead (2), the junction pick (3), the camera lead
  at junctions (5). A real-map drive with the assist (Wisłostrada, Trasa Łazienkowska) is the next
  check (`check_lane_drive` with a Classic, hands-off driver).

## 4. The A/B list for F (phone)

Each is parked in QUESTIONS "Waiting" with the default that is built.

| # | Question | Built default | Alternatives |
| --- | --- | --- | --- |
| 1 | The heat clock: is "hot" (half of the fair time, ~50 km/h door to door) reachable in real traffic? | as is | B: hot for 60 % of fair; C: the heat stops falling while held at a red light |
| 2 | The tip cliff at 40 % heat | no tip below 40 % | B: the tip shrinks smoothly to 0 |
| 3 | A delivery streak ("Seria") | none | B: × 1.1 for each hot delivery in a row, up to × 1.5; a cold one or 90 s idle ends it |
| 4 | The order card's wait | 9 s (craft 14 s) | B: 9 s for the first order, then 4 s |
| 5 | NASTĘPNE | a button on the delivered card | B: always point at the nearest stand after a delivery, no button |
| 6 | Police escape | a flat-out run escapes in ~16 s (chasers 0.8 of your top, 6.5 m/s² in corners) | B: chasers 0.85 of your top |
| 7 | The race gap | seconds | B: metres (as before) |
| 8 | Lead-change toast and tick | on | B: off; C: a rival's bubble line instead of a toast |
| 9 | Slipstream (not built) | none | B: right behind the rival at speed for 1.5 s, +5 % pull and wind lines |
| 10 | Lane assist (built, Settings → Jazda → Asysta pasa) | off | B: on in Cruise, off in Sport; C: on for everyone |
| 11 | Wall graze speed kept (road-objects thread) | that thread's A/B | 97 / 90 / 80 % |

How to test on the phone: one kebab order from the Marszałkowska stand (route, heat words, NASTĘPNE),
Halina's race and one mid-ladder race (gap, lead change, margin), a police escape on Marszałkowska.

## 5. Order of the next work

1. A real-map hands-off drive with the lane assist (Wisłostrada, Trasa Łazienkowska, the bridges).
2. F's phone answers to A/B 1-10; build the picked ones.
3. R3 routes by time (fixes R-4), R4 part 2 (aggression, mistakes), the leaderboard L1-L4.
