# Warsaw parodies: design spec for loop 2d

Written 2026-10-28 by the game-designer for **loop 2d (Warsaw jokes and side jobs)**. The user
asked for lots of local Warsaw and Polish memes as **parodies**, never real names or logos: a
frog-green 24h corner-shop chain on every other corner, app-taxi drivers who follow the GPS
blindly and an app-taxi side job with star ratings, square-backpack delivery riders, dumped
e-scooters, more kebab. This file fixes the final invented names (after a web check, section 1),
each item's look at the default 80 m view, where it appears and how often, its gameplay hooks,
its lines, the app-taxi job end to end, the 2D art for PixelLab, and the cost against README
"Performance budgets". Numbers marked *guess* are first values with the way to tune them.

Rules that hold for everything here (warsaw-tone skill, art bible):
- **Affectionate, about the city's habits**, never about a real company, its workers' pay or
  conditions, or who drives or rides (no nationality or language jokes about app-taxi drivers or
  couriers: the joke is the **app and the GPS**, never the person).
- **Not mistakable for a real brand**: invented name, invented mark, and the colours never
  copy a real brand's set.
- **In the world**: Polish only, UPPERCASE, the 5×7 pixel font (`pixel_font.gd`: capitals,
  digits and `· → : , . ! ? - / ' „ ” ( ) + %`; **no ★**: stars appear only in the HUD font).
- **Reserved colours** (art bible): the player's car red-orange; jobs orange and teal; police
  blue and red light bars; collectibles gold; the car marker HUD yellow. Parody props stay less
  saturated than the police and the job beacons, and avoid saturated red or orange on traffic.

---

## 1. Final names and the name check

Checked on 2026-10-28 with web searches (Polish and English) and by opening the obvious
domains. A web search is not a trademark search; section 10 asks for a register check before
TestFlight.

| Joke | Candidate | What the check found | Decision |
| --- | --- | --- | --- |
| 24h corner shop | ~~Rechotka 24~~ → **Frogs** | Rechotka (2026-10-28): no shop, chain, retail brand or trademark named Rechotka found; `rechotka.pl` shows only the word "Rechotka" and a "PEGI 13" label. **"Frogs" is the user's pick (2026-10-30)**: it is an English word, not the real brand's name or logo (no frog figure, no lowercase wordmark, a lily-pad mark of our own) | **Frogs** (the user, 2026-10-30; ids stay `rechotka`, `easter_rechotka`) |
| App-taxi | **Łuber** | No taxi, ride-hailing app or transport company named Łuber found (results were iTaxi and other real apps, none with this name). `podwozka.pl` exists but refused the request (HTTP 403), content unknown | **Keep: Łuber** |
| Delivery riders | **Pędzik** | No courier, delivery app or brand named Pędzik found; `pedzik.pl` does not resolve | **Keep: Pędzik** |
| E-scooters | ~~Hulajka~~ | No brand "Hulajka" found, but **"Hulaj" (hulaj.eu, "HULAJnogi elektryczne na minuty") was a Polish per-minute e-scooter sharing service**; its domain now carries unrelated casino pages. One suffix away, same field. `hulajka.pl` exists (HTTP 403) | **Replace with Leżak** ("deckchair", from *leżeć*, to lie down: the scooters always lie down). No scooter or sharing brand named Leżak found; `lezak.pl` does not resolve |
| Kebab stand | ~~Nocny Marek~~ | One letter from **Nocny Market**, a real and well-known Warsaw night street-food market | **Drop** |
| Kebab stand | **U Zdzicha** | No kebab place by this name found | **Keep** |
| Kebab stand | **Na cienkim** | No venue by this name found; it is the everyday order phrase ("thin bread"), seen on menus | **Keep** |

---

## 2. Frogs: the frog-green corner shop

**Frogs** (the user's pick, 2026-10-30; it was Rechotka 24). An English word a Warsaw local reads
at once as the frog-green shop on every corner. In Polish it declines as a masculine noun: *Frogs,
do Frogsa, przy Frogsie, pod Frogsem, dwa / trzy Frogsy, pięć Frogsów*. The joke is density and
the frog's hop: there is always one a hop away, often two, and they multiply like frogs in spring.
The ids stay `rechotka` (the quirk, `--ride-quirk=rechotka`, the dialogue group) and
`easter_rechotka`, so saves and flags keep working; only the shown words changed.

### 2.1 Look at the default view

A **shop front** attached to a building's ground floor (not a kiosk), one mesh with vertex
colours, ≤ 600 triangles (README: a shop front ≤ 1,500), Models.material():

| Part | Size | Colour | At 80 m (≈ 6 image px per metre) |
| --- | --- | --- | --- |
| Fascia over the window | 5.0 × 0.9 m, 0.25 m deep, at 3.2–4.1 m | frog green `#4fae3b` (LIT_SIGN at night) | a 30 × 5 px green bar |
| "FROGS" on the fascia | pixel font, letter pixel 0.12 m: 5 letters × 6 px − 1 = 29 × 7 px = 3.48 × 0.84 m (at RECHOTKA's 0.09 m it would be only 2.6 m of the 4.2 m; 0.84 m fits the 0.9 m fascia) | cream `#fbf7ee` (LIT_SIGN) | a pale streak; reads as text from a ~45 m view |
| Blade sign, sticking out sideways | a 0.9 m disc (octagon prism), 0.12 m thick, on a bracket at 3.6 m | lily-pad green `#2f6b2a` disc with a notch, "24" in cream on both faces | a dark green dot off the wall, visible down the street |
| Shop window and door | 4.4 × 2.4 m glass, a 1.0 m door with a dark frame | glass `#cfe8c6` (LIT_WINDOW, bright cool-white at night) | a light panel |
| Floor strip | 5.0 × 0.12 m | dark `#1f3a22` | — |

**The mark is a lily pad, not a frog.** No frog face, no mascot, no lowercase wordmark: the name
carries the frog. Sound: stopping in front plays a two-note croak chime ("kum-kum", the Polish frog's call) instead of a
door bell. At night the fascia and window are among the brightest things on a corner (neon rung of
the art bible's value ladder), which is the 3 a.m. joke by itself.

### 2.2 Where and how often

Placement is a bake step (map-engineer) writing `pois` kind `corner_shop`: position on the facade,
facade normal, facade width, district.

1. **Anchors**: OSM `shop=convenience` nodes and ways, by position only, never their names (like
   the kebab places); plus **junction corners**: lane-graph nodes with three or more approaches
   where a building corner lies within 14 m of the junction box.
2. Snap to the street-facing facade of that building with ≥ 5.5 m of straight wall and no
   other shop-front or landmark there; the fascia faces the street.
3. **Density** *guess*: **24 per km²** in the hero districts (DEMO 2.3), **10 per km²** elsewhere,
   minimum **70 m** between two (except the triple corners). That is about one Frogs in every
   second default-view screen in the centre. The centre's OSM shows ~20 convenience shops per km²
   (read from the demo download, tile r1c1), so this is the real city, slightly exaggerated.
4. **Triple corners** (an egg, id `easter_rechotka`): three Frogs on three corners of one
   junction, spacing rule waived: **Marszałkowska × Świętokrzyska** (today's map, on the route of
   the first kebab order) and **Plac Zbawiciela** (demo area). At most one per district.
5. **Never** on a tier-A landmark footprint (DEMO 2.2), on the Old Town Market Square frontage,
   on a bridge or in a park; at most 2 in the Old Town's side streets.

Expected counts: today's map (6.3 km², about half hero) ~100; the demo (31 km²) ~450. Each is
one instance in a MultiMesh per 512 m tile (section 8).

### 2.3 Gameplay hooks

- **Stamp card ("Karta stałego klienta")**: stop within 6 m of any Frogs shop's door at < 2 m/s for
  2 s → croak chime, a `rechotka` line from the till ("Frogs" as the speaker, tag `stamp`),
  +1 stamp. One stamp per shop per in-game day, max 10 a day. The **10th stamp**: a card *HOT DOG
  GRATIS! · FREE HOT DOG!* with the `free` line and +10 respect. Saved. (A discoverable loop that
  costs nothing and teaches that they are everywhere.)
- **Łuber's GPS uses them as landmarks** (section 3.4): "turn at the Frogs", at a triple
  corner.
- **Passenger detour**: some app-taxi passengers ask to stop at one (+0.5 ★, section 3.3).
- **Radio ads**: two `radio_host` lines (the host reads parody ads among the others).
- **Billboard and column poster** (section 6).
- **Night**: no change in rules; the lit fascias make the city's 3 a.m. map.

---

## 3. Łuber: the app-taxi, in traffic and as a side job

*"Łuber"* is colloquial for "a lift". The joke is the app: a pin that is a bit off, a GPS that
is very sure of itself, star ratings, a "multiplier".

### 3.1 Look in traffic

- A new traffic kind **APP_TAXI** (pool 12; about 10 % of cars at Normal *guess*): the traffic
  car mesh plus a **phone-shaped roof sign**: an upright dark bezel 0.32 × 0.5 × 0.08 m
  (`#1f1f22`) with a white screen inset (`#e8f4ff`, LIT_SIGN, cool white at night) showing a row
  of five dark pixels (the star bar). At 80 m: a 2 × 3 px white tile standing on the roof, next
  to the city taxis' yellow block sign and chequers. ≤ 330 triangles.
- Paint from `APP_PAINT = ["#2b2c2f", "#6f7378", "#b8bcc0", "#e9e9e6", "#24324a"]` (greys, black,
  white, navy: never red or orange, which the player's car owns).

### 3.2 "GPS moments" in traffic

One app-taxi in view does one of these every 45 to 90 s *guess* (never two at once, only within
80 m of the camera's focus, so it is seen):

| Moment | What it does | Line (`podwozka_driver`) |
| --- | --- | --- |
| "You have arrived" | stops in its lane 4 s, then goes; cars behind wait (they may shout a `traffic` line) | untagged |
| Recalculating | takes the reverse edge at the next junction where a U-turn is allowed | untagged |
| The river | on a boulevard road, pulls up at the granite edge (loop 10a), waits 3 s, turns away | `river` |

### 3.3 The side job, end to end

**Start.** In the car, with no other activity (one activity at a time, like the kebab and słoiki
jobs), not in the first 2 minutes of a session *guess*. Two ways:
- a **request card** at the bottom of the screen every 75 to 120 s while idle (not modal, gone
  after 10 s, never during a race, rescue or chase);
- or the top row's **context button** shows **ŁUBER** when the player is idle in the car;
  tapping it brings a request within 2 s.

The card (HUD card recipe, Polish above English):

```
ŁUBER · NOWY KURS / NEW RIDE
Kasia · 350 m · kurs 1,8 km · ★ 4,9
Uwagi: „stoję pod Frogsem”.            ← a podwozka_request line
MNOŻNIK ×1,5 · NOC / NIGHT              ← only at night or in rain
Twoja ocena / Your rating: 4,87
[ PRZYJMIJ · ACCEPT ]   [ POMIŃ · SKIP ]
```

**Pickup.** A real address door point (`address` pois) **150 to 600 m** by road. The app's pin
(teal ring + minimap pin, the passengers' job colour, as słoiki) sits at the door. Half the time
*guess* the passenger actually waits **30 to 60 m away** (across the street, round the corner):
a teal "!" over them, waving, and a `podwozka_pickup` bubble. Pull in within 7 m of the
passenger at < 2.5 m/s and hold 1 s.

**Passenger types** *guess*: normal 65 %, **GPS believer** 25 % (tag `believer`), **in a hurry**
10 % (tag `hurry`: ETA × 0.8, tip × 1.2). First names from the jobs' `CUSTOMERS` list; their
lines are written gender-neutral.

**Destination.** A real address **600 to 2,500 m** by road, or (30 %) a named place from the
race finishes (Złote Tarasy, Dworzec Centralny, Stadion Narodowy, Plac Trzech Krzyży, Varso…;
in the demo also the Old Town and Łazienki). The beacon and the edge arrow always point at the
real destination: the player is never lost.

**The app's route.** A dotted teal line on the minimap: the shortest lane-graph path, except
that **35 %** *guess* of rides get one **quirk**, shown on the line and said by "Nawigacja"
(speaker; a phone avatar) when the player is 200 m from it:

| Quirk | The app's route… | GPS line tag |
| --- | --- | --- |
| `river` | runs to the river's edge on a boulevard road (a waypoint on dry land ≥ 3 m from the granite edge), then on | `river` |
| `oldtown` / `zone` | cuts across the Old Town Market Square or a park's paths (the player's car is capped at 20 km/h there and the city guards react: docs/design/police.md 5.6) | `oldtown` / `zone` |
| `rechotka` | tells you to turn "at the Frogs" at a triple corner | `rechotka` |
| `reroute` | recalculates once mid-ride and draws a new line | `reroute` |

On arrival the GPS says the `arrive` line. Ignoring the app is always allowed.

**Star rating** (shown live in the status panel in the HUD font: ★★★★½ 4,5). Starts at 5.0:

| Event | Change |
| --- | --- |
| A hard bump (closing speed > 4 m/s), braking > 18 m/s², cornering > 15 m/s² | −0.5 each, 2 s apart, at most −2.0 in all (milder than the słoiki: 16 / 14 m/s²) |
| Late: ETA = road distance / 9 m/s + 20 s | −0.5 per 15 s over, at most −1.5 |
| A police pull-over during the ride (police.md 8.3) | −1.0 (escaping a chase: no change) |
| Arriving at ≤ 0.8 × ETA | +0.5 |
| A `detour` passenger asks for a Frogs and you stop at one (stamp rules, any shop) | +0.5 |
| A **believer**, and you drive the app's quirk leg (reach the river waypoint within 15 m, or cross the zone) | +0.5 ("No widzisz, aplikacja wie") |
| A believer, and you ignore the app | no change, only grumbling lines |

Final rating: rounded to the nearest half, 1.0 to 5.0.

**Pay** *guess* (złoty; compare kebab 30–110, słoiki 50–260):
- fare = **15 zł + 9 zł per km** of road from pickup to destination;
- × **1.5 at night** (Night, or Live after dusk), × **1.2 in rain** (shown as the "MNOŻNIK" on
  the card; both together × 1.8);
- tip = fare × **0.40** at 5 ★, **0.25** at 4.5, **0.10** at 4, nothing below;
- **5-star streak**: each consecutive 5 ★ ride adds **+10 zł × streak** (at most +50); a ride
  below 4.5 or a cancel ends the streak;
- respect **+25** at 5 ★, **+10** at 4 or 4.5.

A 1.8 km day ride at 5 ★: 15 + 16.2 = 31 zł, + 12 zł tip = 43 zł, +25 respect.

**Your rating.** The average of the last 20 rides, saved, shown on the request card. A new save
starts at **4,87** (nobody has a 5.0).

**Ending.** At the destination, stop within 7 m at < 2.5 m/s: a result card with the stars, a
`podwozka_rating` comment (tag `5`, `4`, `low` for < 4, `police` if pulled over), and the pay
breakdown (fare, multiplier, tip, streak). **Cancel**: ✕ on the status panel any time, or the
passenger cancels after 3 × ETA (`cancel` line): no pay, no penalty, the streak ends. Not from the
helicopter (the passenger rides in the car).

**Chatter** on the way: a line every 25 to 40 s from `podwozka_passenger` (believers prefer
`believer`, hurry `hurry`), mixed with the existing `passenger` group.

### 3.4 Flags and checks for the job

`--ride=N` (put the car by ride N's passenger; the same N gives the same ride), `--ride-quirk=
river|oldtown|zone|rechotka|reroute`, `--passenger=normal|believer|hurry`, `--stars=X` (start
the live rating, for card shots), `--autopilot` drives the app's route (or the shortest one with
`--ignore-app`), `--parody-log` prints `ride: pickup`, `ride: quirk river reached`, `ride: stars
4.5 (bump −0.5)`, `ride: pay 43 zł (fare 31, tip 12, streak 0)`.

---

## 4. Pędzik: the square-backpack riders

*"Pędzik"*, from *pędzić*, to rush. The joke: a backpack the size of a studio flat, and riders who
go where cars can't.

### 4.1 Look

- **Rider on a bike**, ≤ 300 triangles (README: a person or rider): bike frame and wheels as
  boxes (dark `#3a3b3f`), rider (white helmet, magenta jacket `#c23a7e`, dark trousers), and a
  **0.45 m cube backpack** in magenta `#c23a7e` with a cream band `#fbf7ee` round its middle and
  our own mark on the sides (a wheel with three speed lines, as vertex-coloured pixels).
- At 80 m: a 3 × 3 px magenta square with a pale line, moving along the kerb or through a park.
  Magenta was DEMO's choice; it is a step less saturated than the race pink `#ff4fd8` and the
  neon pink, and the cream band keeps it from being one solid brand colour.

### 4.2 Where and how often

- **One MultiMesh for the whole city** (moving things, pool 16), written once a frame near the
  view like `pedestrians.gd`. In the band round the view: 3 to 6 at Normal *guess*, × 1.5 at
  night; 1 to 2 waiting by each kebab stand at night (bike parked, standing).
- They ride on the road's kerb edge (lane 0 + 0.6 m) at 5 to 7 m/s and **through parks and
  pedestrian zones on the footway network** (the pedestrians' paths). They never touch the
  player's car: within 4 m of its path they swerve onto the footway, or hop (a 0.3 s cartoon jump)
  if there is no room, with a `pedzik` bubble on a near miss (once per 30 s).

### 4.3 Hook: the courier race

At a kebab stand, when the player takes an order, **1 time in 4** *guess* (night only; a rider
must be waiting there) the rider challenges: a `pedzik` / `challenge` bubble and a button
**ŚCIGAJ · RACE** (the FLASH LIGHTS slot) for 6 s. Accept and both go to the **same door**.

- The rider follows a path on the footway network (parks and squares included) found by A* from
  the stand to the door; no challenge if that path is longer than 1.6 × the straight line.
- Rider speed 6.5 m/s (23 km/h) *guess*: on a typical 900 m order the rider's path is ~25 %
  shorter than the road, so a clean drive wins by a few seconds.
- The race UI is the rivals' (beacon, edge arrow, 1ST / 2ND). Win: the kebab pays as usual
  **+30 zł +30 respect**, the rider's `lose` line. Lose: the kebab pays as usual, the rider's
  `win` line. The kebab's heat rules are unchanged.

---

## 5. Leżak: the dumped e-scooters

*"Leżak"* is a deckchair, from *leżeć*, to lie down. The joke: they are never standing.

### 5.1 Look

- **Scooter**, ≤ 120 triangles: deck 1.1 × 0.06 × 0.18 m violet `#8e44d9`, stem 0.95 m and
  handlebar dark `#3a3b3f`, two small wheels, a white front lamp pixel. Violet is not used by the
  scooter-sharing operators active in Warsaw (their colours are green, light blue, teal and red),
  and sits apart from Seba's purple `#b45cff` (a car) by size and place.
- **Lying** on its side at a random yaw (one transform: the same mesh rotated 90° about its
  length). At 80 m: a 7 × 1 px violet dash on the pavement. Upright it is 0.95 m tall: **no sun
  shadow**, and it joins `fine_detail` (hidden in views wider than 170 m).

### 5.2 Where and how often

Baked (map-engineer) as `pois` kind `scooter` (position, yaw, pose):
- **Density** *guess*: 30 per km² in hero districts, 12 elsewhere; on footways near junctions,
  bus and tram stops, metro exits, the boulevards, park edges; never on a carriageway, a kerb ramp
  or a crossing.
- **Odd places** (1 in 15): on the grass, across a bench's front, at a Frogs shop's door, half in a
  hedge; **1 in 40 on a bus-shelter roof** (`shelters` data; seen from the helicopter).
- **Parking zones** (`scooter_zone`, a painted white rectangle 3 × 1.5 m on the pavement), one
  per ~400 m of hero-district street: the joke is that the zone is **empty** and the scooters lie
  round it. One zone in the whole map holds **one scooter standing properly**: an egg
  (`easter_lezak`).

### 5.3 Hooks

- **Knock-about**: the car within 1.2 m pushes a lying scooter 1 to 3 m (a distance check like the
  roadworks barriers, not physics), with a plastic-and-metal clatter (`make_sfx.py`) and a `lezak`
  / `knock` bubble at most once per 60 s. No damage, no pay effect, no shout from traffic.
- **The round-up** (DEMO 6.3), night only: pull into the **Leżak depot** ring (one depot per hero
  district at a parking zone; teal ring, a passenger-and-goods job colour) → card *ZBIERZ 10
  LEŻAKÓW · ROUND UP 10 LEŻAKS* and the `start` line. The 10 nearest lying scooters within 600 m
  get violet pins on the minimap. Drive within 4 m at < 15 km/h: clatter, +1 in the boot (it
  holds **5**), back to the depot to unload, then the other 5. Pay **8 zł a scooter**, **+40 zł**
  if all 10 come back within 6 minutes, **+40 respect**; the `done` line. Collected scooters
  reappear by the next in-game morning. One activity at a time; ✕ gives up.

---

## 6. More kebab, billboards and posters

### 6.1 Kebab

- **14 stands** (DEMO 6.3): the 7 of today plus Praga (Ząbkowska), Muranów, Hala Mirowska, the
  Old Town's edge (Podwale, outside the pedestrian zone), Plac Zbawiciela, Arkadia's car park, and
  the stadium's north side. Never on a bridge, never inside a pedestrian zone.
- **Two named stands** get a second, smaller board under KEBAB in the pixel font: **U ZDZICHA**
  (Hala Mirowska) and **NA CIENKIM** (Plac Zbawiciela). The rest say KEBAB.
- Draw: the 12 generic stands become one MultiMesh per 512 m tile (they are 7 nodes today);
  the two named stands keep their own mesh each (the text differs).
- New `only` tags for the vendor and order lines: `stadium`, `zdzich`, `cienkim`, `hala` (by
  stand), `oldtown`, `mall` (by the address's district from the demo bake; today's `powisle`,
  `praga`, `office` unchanged).
- Pędzik riders wait at stands at night (4.2).

### 6.2 Billboards and posters

Four new billboards (`signs`, DEMO's 5 → 10 billboards; their picture comes from PixelLab, the
words from the pixel font) and three new column posters (`column_posters`, four lines of eight
letters), all below in section 7.

---

## 7. Lines (to merge into game/data/dialogue.json)

61 original lines (one added with the Frogs rename, 2026-10-30), Polish then English. New groups: `rechotka`, `easter_rechotka`,
`podwozka_request`, `podwozka_pickup`, `podwozka_gps`, `podwozka_passenger`, `podwozka_rating`,
`podwozka_driver`, `pedzik`, `lezak`, `easter_lezak`; additions to `radio_host`, `kebab_vendor`,
`kebab_order`, `signs`, `column_posters`. Speakers: **"Frogs"** (the till, with the lily-pad
icon), **"Nawigacja"** (the app, a phone avatar), the passenger's first name, **"Łuber"** for
app-taxi drivers in traffic, **"Pędzik"** for riders, **"Leżak"** for the round-up card (the
knock line is the game's own aside, no speaker). Polish bubbles ≤ 70 characters. Checked
against today's file for repeats (grep: pierwszeństwo, kawalerka, zaginął, za rogiem, GPS, 3:00):
the callbacks are deliberate (the tram's *pierwszeństwo* becomes the backpack's; *ZAGINĄŁ GOŁĄB*
becomes *ZAGINĄŁ SYGNAŁ GPS*) and each has a new punchline.

```json
{
  "rechotka": [
    ["Hot dog, kawa i ładowarka. Zestaw przetrwania do rana.", "A hot dog, a coffee and a charger. The survive-till-morning combo."],
    ["Chleb, bilety, paczki, kawa. Nadzieję trzymamy na zapleczu.", "Bread, tickets, parcels, coffee. We keep hope in the back room."],
    ["Drugi Frogs jest naprzeciwko. Konkurujemy sami ze sobą.", "The other Frogs is across the street. We compete with ourselves."],
    ["Między jednym Frogsem a drugim jest dokładnie jeden Frogs.", "Between one Frogs and the next, there's exactly one Frogs."],
    ["Do następnego Frogsa? Jeden skok. Jesteśmy żabami, nie liczymy metrów.", "The next Frogs? One hop. We're frogs, we don't count metres."],
    ["Otwarte całą dobę. Nawet jak nikt nie wie, która jest godzina.", "Open around the clock. Even when nobody knows what time it is."],
    ["Pieczątka jest. Do darmowego hot doga coraz bliżej.", "Stamped. One step closer to a free hot dog.", {"only": "stamp"}],
    ["Dziesiąta pieczątka! Hot dog gratis. Musztarda też, spokojnie.", "Tenth stamp! A free hot dog. Mustard too, relax.", {"only": "free"}]
  ],
  "easter_rechotka": [
    ["Trzy Frogsy na jednym skrzyżowaniu. Żaby, wiadomo: się mnożą.", "Three Frogs on one junction. Frogs, you know: they multiply."]
  ],
  "radio_host": [
    ["Frogs. Otwarte dziś, jutro i na wszelki wypadek pojutrze.", "Frogs: open today, tomorrow, and the day after, just in case."],
    ["Łuber: przyjedziemy tam, gdzie pokaże pinezka. Mniej więcej.", "Łuber: we'll come wherever the pin says. More or less."]
  ],
  "podwozka_request": [
    ["Uwagi: „stoję pod Frogsem”.", "Note: \"I'm outside the Frogs.\""],
    ["Uwagi: „jestem tam, gdzie pinezka, tylko po drugiej stronie”.", "Note: \"I'm where the pin is, just on the other side.\""],
    ["Uwagi: „mam walizkę i optymizm”.", "Note: \"I've got a suitcase and optimism.\""],
    ["Uwagi: „proszę nie dzwonić, machnę”.", "Note: \"please don't call, I'll wave.\""]
  ],
  "podwozka_pickup": [
    ["Dzień dobry! Pinezka trochę się pomyliła, ja nie.", "Hi! The pin was a bit off. I wasn't."],
    ["Pięć gwiazdek, jeśli zdążymy. Sześć, jeśli bez trąbienia.", "Five stars if we make it. Six if there's no honking."],
    ["To pan od Łubera? Bo tu czeka jeszcze trzech.", "Are you my Łuber? Because three more are waiting here."]
  ],
  "podwozka_gps": [
    ["Za dwieście metrów skręć w prawo. W Wisłę.", "In two hundred metres, turn right. Into the Vistula.", {"only": "river"}],
    ["Skręć przy Frogsie. Nie tym. Tym drugim. Nie, tym.", "Turn at the Frogs. Not that one. The other one. No, that one.", {"only": "rechotka"}],
    ["Przeliczam trasę… Gotowe. Zawróć, gdzie możesz. I gdzie nie możesz.", "Recalculating… Done. Make a U-turn where you can. And where you can't.", {"only": "reroute"}],
    ["Jedź prosto przez Rynek. Dorożki jakoś dają radę.", "Go straight across the Market Square. The horse carriages seem to manage.", {"only": "oldtown"}],
    ["Skrót przez park. Mapa twierdzi, że ścieżka to droga.", "Shortcut through the park. The map insists the path is a road.", {"only": "zone"}],
    ["Jesteś na miejscu. Cel znajduje się po lewej. Albo nad tobą.", "You have arrived. Your destination is on the left. Or above you.", {"only": "arrive"}]
  ],
  "podwozka_passenger": [
    ["Ale aplikacja mówi w lewo! Aplikacja się nie myli. Prawie.", "But the app says left! The app is never wrong. Almost.", {"only": "believer"}],
    ["GPS mówi przez Wisłę. Może jest prom? Nie ma promu?", "The GPS says across the Vistula. Maybe there's a ferry? No ferry?", {"only": "believer"}],
    ["Możemy stanąć przy Frogsie? Wybór jest, delikatnie mówiąc, duży.", "Can we stop at one of the Frogs? The choice is, to put it mildly, wide.", {"only": "detour"}],
    ["Może pan ściszyć radio? Żartuję, proszę podgłośnić.", "Could you turn the radio down? Kidding, turn it up."],
    ["Pan zna skróty? Bo aplikacja zna tylko proste.", "Do you know the shortcuts? The app only knows straight lines."],
    ["Spieszę się na pociąg. Pociąg też się spieszy.", "I'm rushing for a train. The train's rushing too.", {"only": "hurry"}]
  ],
  "podwozka_rating": [
    ["Pięć gwiazdek. W komentarzu: „lepszy niż GPS”.", "Five stars. Comment: \"better than the GPS\".", {"only": "5"}],
    ["Pięć gwiazdek i serduszko. Serduszko jest rzadkie.", "Five stars and a heart. The heart is rare.", {"only": "5"}],
    ["Cztery gwiazdki. Piąta za mniej hamowania.", "Four stars. The fifth would need less braking.", {"only": "4"}],
    ["Gwiazdek mało, ale radio było super.", "Not many stars, but the radio was great.", {"only": "low"}],
    ["Policja w trakcie kursu? Gwiazdkę zabieram, anegdotę zostawiam.", "Police mid-ride? I'm taking a star, but keeping the anecdote.", {"only": "police"}],
    ["Anulowane. Wysiadam przy Frogsie, i tak tu jest jeden.", "Cancelled. I'll get out at the Frogs, there's one right here anyway.", {"only": "cancel"}]
  ],
  "podwozka_driver": [
    ["GPS kazał tu stanąć. Kim jestem, żeby się kłócić?", "The GPS said to stop here. Who am I to argue?"],
    ["Przeliczam! Proszę nie trąbić, przeliczam!", "Recalculating! Please don't honk, I'm recalculating!"],
    ["Mapa pokazuje most. Most chyba nie wie.", "The map shows a bridge. The bridge doesn't seem to know.", {"only": "river"}]
  ],
  "pedzik": [
    ["Uwaga, plecak! Plecak ma pierwszeństwo.", "Mind the backpack! The backpack has right of way."],
    ["Skrót przez park! Wy macie ulice, my mamy całą resztę.", "Shortcut through the park! You've got the streets, we've got everything else."],
    ["Ścigamy się do drzwi? Ja mam rower, ty masz korki.", "Race you to the door? I've got a bike, you've got traffic.", {"only": "challenge"}],
    ["Dowiezione. Zupa nawet się nie rozlała.", "Delivered. The soup didn't even spill.", {"only": "win"}],
    ["Auto szybsze od roweru? W centrum? Zapiszę to w kalendarzu.", "A car faster than a bike? In the centre? That's going in my diary.", {"only": "lose"}]
  ],
  "lezak": [
    ["Leżak się nie przewrócił. Leżak zawsze tak leży.", "The Leżak didn't fall over. Leżaks always lie like that.", {"only": "knock"}],
    ["Dziesięć Leżaków do zebrania. Podobno jeden stoi. Nie wierzę.", "Ten Leżaks to round up. Rumour says one of them is standing. I don't believe it.", {"only": "start"}],
    ["Wszystkie zebrane. Jutro rano znowu będą leżeć. Krąg życia.", "All collected. By morning they'll be lying around again. The circle of life.", {"only": "done"}]
  ],
  "easter_lezak": [
    ["Leżak, który stoi. W swojej strefie. Ktoś powinien to zgłosić.", "A Leżak standing up. In its own parking zone. Somebody should report this."]
  ],
  "kebab_vendor": [
    ["Kebab dla kibica spod Narodowego. Wygrali czy przegrali, sos ten sam.", "A kebab for a fan by the National Stadium. Won or lost, same sauce.", {"only": "stadium"}],
    ["U Zdzicha od zawsze: sos czosnkowy, ostry i sos „nie pytaj”.", "Zdzich's, since forever: garlic sauce, hot sauce and \"don't ask\" sauce.", {"only": "zdzich"}],
    ["Na cienkim, jak sama nazwa wskazuje. Grube są tylko korki.", "On thin bread, as the name says. The only thick thing round here is the traffic.", {"only": "cienkim"}],
    ["Tu był targ i dalej jest targ. Ja tu nowy, od dwudziestu lat.", "There was a market here, and there still is. I'm the new guy: twenty years now.", {"only": "hala"}]
  ],
  "kebab_order": [
    ["Zamówienie na Starówkę: „pod pomnikiem, tym z mieczem”.", "Order to the Old Town: \"by the statue, the one with the sword\".", {"only": "oldtown"}],
    ["Na parking pod galerią: poziom −2, sektor „gdzie ja stałem”.", "To the mall car park: level −2, zone \"where did I park\".", {"only": "mall"}]
  ],
  "signs": [
    ["FROGS · TU TEŻ", "FROGS · HERE TOO"],
    ["ŁUBER · GPS WIE LEPIEJ", "ŁUBER · THE GPS KNOWS BEST"],
    ["PĘDZIK · PLECAK WIĘKSZY NIŻ KAWALERKA", "PĘDZIK · A BACKPACK BIGGER THAN A STUDIO FLAT"],
    ["LEŻAK · PARKING? JAKI PARKING?", "LEŻAK · PARKING? WHAT PARKING?"]
  ],
  "column_posters": [
    ["FROGS: ZAWSZE O JEDEN SKOK", "Frogs: always one hop away", {"poster": ["FROGS:", "ZAWSZE", "O JEDEN", "SKOK"]}],
    ["LEŻAK. LEŻY. PRAWIE WSZĘDZIE.", "Leżak. Lying around. Almost everywhere.", {"poster": ["LEŻAK.", "LEŻY.", "PRAWIE", "WSZĘDZIE"]}],
    ["ZAGINĄŁ SYGNAŁ GPS. ŁUBER.", "Missing: one GPS signal. Łuber.", {"poster": ["ZAGINĄŁ", "SYGNAŁ", "GPS.", "ŁUBER"]}]
  ]
}
```

For `radio_host`, `kebab_vendor`, `kebab_order`, `signs`, `column_posters` (groups that already
exist), append these lines to the existing arrays. Every sign and poster character is in the pixel
font (Ę, Ó, Ż, Ł and `?` `·` included). Vendor lines for the stand tags are picked with
`prefer = true`.

---

## 8. Cost on the phone (README "Performance budgets")

Rule 1 (one MultiMesh per kind per 512 m tile for static things, one per kind for the city for
moving things), rule 2 (vertex colours, glow only through the shared material), rule 3 (≤ 300
triangles a prop or rider, ≤ 1,500 a shop front, ≤ 800 a traffic car), rule 4 (no shadow under a
metre), rule 5 (no new shader).

| Kind | MultiMesh | Triangles each | Shadow | Draw calls: default / zoomed out / helicopter |
| --- | --- | --- | --- | --- |
| Frogs shop front | per 512 m tile (static) | ≤ 600 (~430 planned: 8 boxes, the blade disc, ~150 letter quads) | **off** (flat on a wall that already casts) | +1–4 / +4–9 / +6–12 |
| Leżak scooter (lying or upright) | per tile (static; a knocked one rewrites its tile's buffer once) | ≤ 120 | off (< 1 m), `fine_detail` | +1–4 / 0 / 0 |
| Łuber car | traffic kind APP_TAXI (pool 12) + its night headlight beams, like the other kinds | ≤ 330 | small_casters | +2 (+1 at night) at every view |
| Pędzik rider | one for the city (pool 16) | ≤ 300 | small_casters | +2 at every view |
| Kebab stands, 12 generic | per tile (replaces 7 nodes) | ≤ 1,500 (today's stand) | as today | ≈ ±0 (fewer nodes, more stands) |
| Two named kebab stands | own mesh each (never both in view) | ≤ 1,500 | as today | +0–1 |
| Billboard and poster art | the existing poster atlas (one material) | — | — | +0 |
| **Total** | | | | **≤ +15 / ≤ +17 / ≤ +20** |

Within 2d's allowance (~65–90 draw calls; ceilings 200 / 300 / 360 at the default / zoomed-out /
helicopter views). Triangles at the default view < +5 k (≤ +20 k zoomed out), against 130 k
allowed. Scripts ≤ 0.15 ms on the Mac (riders ~0.05, app-taxi moments ~0.02, scooter knock checks
through the tile grid ~0.02, the ride job ~0.03, stamp checks ~0.01), against 0.3 ms allowed.
Memory ≤ +3 MB. Report the four views' `draw calls` / `main pass` lines, the bench medians and a
phone TEST · BENCH card before and after (rule 9); `--no-parodies` hides all of it for an A/B.

---

## 9. 2D art from PixelLab (loop 2d, ≤ 50 generations)

Follow `.claude/skills/pixellab/SKILL.md`: `get_balance` first, explore with the 1-generation
tool, no text or brand in any image, described by function and colour, `view: "high top-down"`
for things in the city, front-on for portraits and UI, saved with provenance JSON under
`game/art/<kind>/`. **Base palette in every call**: `#fbf7ee`, `#c9c2d8`, `#ffd23f`, `#3a3b3f`,
`#34404e`, `#a8cde6`; plus the item's colours below. Outline single dark, shading basic, detail
medium, `max_colors` 8–16 for icons, ≤ 32 for billboards.

| Asset | Tool, size | Prompt | Item colours | Gens |
| --- | --- | --- | --- | --- |
| Frogs minimap icon | `create_image_pixen`, 16 px, no background | "tiny round lily pad icon with a small notch, flat, bold outline" | `#4fae3b`, `#2f6b2a` | 2 |
| Łuber pickup icon | same | "tiny smartphone icon with a small star on the screen, flat, bold outline" | `#1f1f22`, `#e8f4ff` | 2 |
| Pędzik icon | same | "tiny cube delivery backpack icon with a pale band round the middle, flat" | `#c23a7e` | 2 |
| Leżak icon | same | "tiny electric kick scooter lying on its side, flat icon" | `#8e44d9` | 2 |
| "Nawigacja" avatar | `create_image_pixen`, 32 px | "a cheerful smartphone with a map pin for a face, simple, front view" | `#1f1f22`, `#e8f4ff`, `#4fd8c4` | 2 |
| Billboard art: Frogs | `create_image_pixen`, 128 × 64 | "billboard illustration of a bright corner shop at night on a city street, green shop front, warm light from the window, a lily pad symbol, no text, no people" | `#4fae3b`, `#2f6b2a`, `#cfe8c6` | 2 |
| Billboard art: Łuber | same | "billboard illustration of a small dark car with an upright glowing phone sign on its roof, a curvy dotted route line leading into a river, no text" | `#1f1f22`, `#e8f4ff`, `#4fd8c4` | 2 |
| Billboard art: Pędzik | same | "billboard illustration of a bicycle courier with an enormous cube backpack bigger than a doorway, speed lines, no text, no logos" | `#c23a7e` | 2 |
| Billboard art: Leżak | same | "billboard illustration of violet electric kick scooters lying on a pavement around an empty painted parking rectangle, no text" | `#8e44d9` | 2 |
| Portrait: passenger, GPS believer | `create_portrait_character`, 64 px | "young office worker staring at a smartphone, lanyard, confident smile, invented character, front view" | `#4fd8c4` | 10 |
| Portrait: passenger, student | same | "student with big headphones and a tote bag, relaxed grin, invented character, front view" | `#4fd8c4` | 10 |
| Portrait: Pędzik rider | same | "bicycle courier with a white helmet and a huge cube backpack strap over the shoulder, energetic, invented character, front view" | `#c23a7e` | 10 |
| **Total** | | | | **48** |

The world signs (fascia, blade sign, phone roof sign, kebab name boards) are built in code with
pixel-font quads, not textures. If a billboard explore wins, its final can be redone with
`create_image_pro` (10–25) only with the user's yes (it would pass 50).

---

## 10. What to build (task list with checks)

**map-engineer** (bake; can ride with loop 3d's demo bake, or run on today's map first):
1. `pois` `corner_shop` (2.2 rules), with the two triple corners flagged; `scooter` and
   `scooter_zone` (5.2); 7 more `kebab` (6.1) with their stand tags; the address district tags
   `oldtown`, `mall`. Counts recorded in `check_map_data.py` and README together.
   *Check:* today's map gets 85–115 Frogs shops, each fascia within 0.3 m of a building edge, none
   on a landmark footprint, minimum spacing 70 m outside the triple corners.

**gameplay-dev:**
2. Shop-front, scooter and rider meshes (`props.gd` / `models.gd`), their MultiMeshes per tile /
   per city; APP_TAXI traffic kind with the phone sign; generic kebab stands into a per-tile
   MultiMesh. *Check:* the section 8 table at the four README views, `--no-parodies` A/B.
3. Frogs stamps (2.3), the croak chime, the triple-corner egg. *Check:* `--rechotka`
   (car at the nearest door) logs `rechotka: stamp 1`; `--stamps=9` then one stop shows the free
   hot dog card and +10 respect.
4. App-taxi GPS moments in traffic (3.2). *Check:* in a 5-minute `--traffic=busy` run at least 3
   moments log, never two at once.
5. **The Łuber job** (3.3) with its flags (3.4). *Check:* `--ride=1 --autopilot --parody-log`
   logs pickup, quirk (with `--ride-quirk=river`: the waypoint is on dry land), arrival, stars,
   pay; a headless `check_rides.gd` feeds synthetic events and asserts the star and pay tables,
   the streak and the cancel rules; the police pull-over takes exactly one star.
6. Pędzik riders (4.2) and the courier race (4.3). *Check:* `--courier=N --autopilot` logs the
   rider's path length vs the road's and a result; in a 10-minute soak no rider overlaps the
   player's car (minimum distance logged ≥ 1.0 m).
7. Leżak knock-about and the round-up (5.3). *Check:* `--roundup --time=night --autopilot`
   collects 10 in two trips and logs the pay; knocked scooters never end on a carriageway lane.
8. Kebab stands to 14, the two name boards, the stand and district tags (6.1).
9. Lines merged (section 7); billboards and posters wired; PixelLab assets (section 9).
   *Check:* `check_parodies.gd` (headless): every group and tag the code uses exists with ≥ 1
   line, PL + EN present, bubbles ≤ 70 characters, posters ≤ 4 × 8, every world-text character is
   in `pixel_font.gd`.
10. Shots at 2868×1320 by day and night at 80 m: a Frogs corner, the triple corner, scooter
    litter and an empty zone, a rider, an app-taxi with its sign, the ride card and result card.
    art-director: nothing reads as a real brand; parody colours less saturated than the police
    and the job beacons; C1 (the player's car found in < 1 s) still holds with the extra props.
11. README (a Parodies and Łuber section, flags), ROADMAP row, BACKLOG; CREDITS: nothing new
    from outside (the PixelLab art is the game's own).

Flags: `--rechotka`, `--stamps=K`, `--ride=N`, `--ride-quirk=…`, `--passenger=…`, `--stars=X`,
`--ignore-app`, `--courier=N`, `--roundup`, `--no-parodies`, `--parody-log`.

What only the phone can show: whether the green corners feel like "every other corner" or like
clutter, whether the phone sign reads, the croak chime's charm, and how long a ride feels.

---

## 11. Open questions (each with the default this spec uses)

1. **Hulajka → Leżak** (because of the real e-scooter service "Hulaj"). Options: *Drzemka*
   ("nap"; no scooter brand found either), or keep Hulajka. *Default: Leżak.*
2. **Nocny Marek dropped** (too close to the real Nocny Market). *Default: U Zdzicha and Na
   cienkim, the other stands plain KEBAB.*
3. **No frog figure** for Frogs: a lily pad and a croak chime carry it, so the parody never
   looks like the real chain's frog. Option: an invented frog on posters only. *Default: no frog.*
4. **Pędzik's magenta** (DEMO's colour) with a cream band. Option: another colour if magenta
   feels too close to a delivery brand the user knows. *Default: magenta `#c23a7e`.*
5. **Density**: Frogs 24 per km² in hero districts, scooters 30 per km². *Default: these;
   tune after the first phone look.*
6. **The "MNOŻNIK" (surge multiplier) joke** on the ride card. Option: drop it as too close to a
   real app's feature. *Default: keep, night × 1.5 and rain × 1.2 only.*
7. **GPS believers** never cost stars, they only grumble, and following the app's silly leg
   earns +0.5. *Default: yes.*
8. **Pay** for rides (15 zł + 9 zł/km, tip by stars, streak) sits between kebab and słoiki.
   *Default: these, tuned with the economy in loop 3h.*
9. **The courier race** only at night and only from a kebab order (1 in 4). Option: also by day,
   or as a standalone challenge. *Default: as written.*
10. **Name check depth**: web search and domains only. `podwozka.pl` and `hulajka.pl` exist with
    content we could not see (HTTP 403) and `rechotka.pl` shows only "Rechotka · PEGI 13". A
    search of the Polish Patent Office (UPRP) and EUIPO registers before TestFlight (loop 3k's
    brand audit) would settle it; it covers **Frogs** (the user's pick, 2026-10-30, a plain
    English word) too. *Default: proceed; re-check in 3k.*

## Sources read (for the checks; no content copied)

- hulaj.eu (the former per-minute e-scooter service's page), rechotka.pl, podwozka.pl and
  hulajka.pl (HTTP 403), pedzik.pl and lezak.pl (do not resolve).
- Searches for each name with "sklep", "aplikacja", "taxi", "kurier", "hulajnogi", "marka",
  "znak towarowy" (2026-10-28): results were other, real companies (iTaxi, Number One Taxi, Lime,
  Dott, Bolt, Blinkee, Tier and others), none with these names.
- warsawinsider.pl and inyourpocket.com listings for Nocny Market (Warsaw's night street-food
  market), found while checking "Nocny Marek".
- eurobuildcee.com on Warsaw's e-scooter operators' agreement (Bolt, Dott, Lime, Blinkee, Tier),
  for the colours to avoid.
- OpenStreetMap (the demo download on disk, tile r1c1): convenience-shop and kebab counts used for
  density only.
