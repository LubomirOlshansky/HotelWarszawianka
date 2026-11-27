# Isometric Warsaw and Around Warsaw: what we learn (2026-10-29)

The user asked to study Bedirhan Yıldırım's "Isometric Warsaw" (an article and its screenshots,
bedirhanyildirim.com/pixel-art-map-of-warsaw/, online 22 October 2026) against our plan and to
say what can be improved. It is the nearest project to ours: an isometric pixel-art Warsaw from
the same open data (OpenStreetMap; GUGiK LoD2 buildings, terrain, orthophoto, 3D trees), built by
Claude Code agents in parallel git worktrees. It is a map, not a game, and its code is private;
nothing here is copied from it: these are lessons and ideas to do in our own way.

## What it is, in numbers

- The whole city, 517 km², in 659 squares of 1 km streamed into a three.js page; 197,000
  buildings, 1.93 M trees, 46,873 street lamps lit at night at their real places.
- About 240 landmarks hand-built from photos, each with a history card and a pixel pin; 380+
  churches with walls, arched windows and towers; schools, hospitals, stations drawn by their
  OSM use; 6,300 stops with poles, shelters and platforms; metro entrances; advertising columns
  with blank faces (no brands).
- A living city from timetables: all 26 tram lines on their real routes and hourly frequency
  (three tram types), 1,600+ trains a day, ~370 flights at Chopin with the day's runway; the real
  sun by date and time; live weather (Open-Meteo); seasons (leaves in October, snow, frozen
  ponds); the Vistula's level by date (old bridge piles at low water); calendar days
  (11 November in white and red, a Christmas market and Ferris wheel on Plac Defilad).
- A flight game on top (four aircraft, rings, three difficulty levels, a cockpit minimap).
- English and Polish; a feedback form that carries the exact view; save a picture; install as a
  web app; "show my location".
- Built in about a week: 258 commits, 6–8 agents at a time, 20,700 visitors from 94 countries in
  the first week, ~3.5 minutes a visit.

## The look, from its screenshots

- **Daytime:** a dense, saturated, toy-like city: LoD2 roofs everywhere (pitched red roofs in
  the Old Town, the double walls, the Castle), very many trees, a top-lit "SimCity 2000" read, a
  steep isometric angle. Pixels are half-resolution with dark outlines where depth jumps and a
  limited palette.
- **Night:** near black, read almost only by thousands of small warm points (lamps, windows):
  very atmospheric from far, little to read up close.
- **Dusk on the river:** the boulevards' lamps in their real rows, bar barges on the water, the
  bank's paths: exactly our "schodki" scene.

## Where we already match or lead

- **The same data and method** (OSM + GUGiK LoD2 + terrain + trees, agents in worktrees, a check
  before every merge); our verification set (32 steps, both city paths, road rules C1–C11,
  streets S1–S4, streaming identity, the police and ride runs) is deeper than what the article
  describes.
- **A game, not a map**: a car and a helicopter you drive, traffic with lanes and signals, the
  police, jobs, Łuber, races, the radio, the jokes: their author turned down "moving cars and
  a life simulator" for scale reasons; at our street-level zoom they are the point.
- **Roads as structures**: bridges, flyovers, tunnels, ramps, kerbs you feel, markings and lamps
  checked rule by rule; a map seen from above can skip most of that.
- **A phone-first budget** measured on a real iPhone 11 (60 fps, sharp ×1, 20-minute soaks).
- **The "Moja Warszawa" voice** (vision.md): memes, parodies, the night scene, the user's own
  ten years. Isometric Warsaw is documentary; ours is personal and funny.

## What to take from it (ranked, each with where it goes)

1. **Landmarks are what people open.** They had 8,000+ landmark cards opened in a week and built
   ~240 landmarks by hand. Our demo has 7 sites plus 10 tier-A ones planned. → Raise the demo's
   landmark target: tier A 10 hand-built, **tier B ~30** in a cheaper kit way (LoD2 shape +
   a hand-placed detail or two + a card), every church in the box with a tower and arched
   windows by OSM tags (a rule, like their 380 churches), each with a card and a **pin** that
   shows on a wide view. Loops 3f and MW-1 (the notebook) share the cards.
2. **Real trams on real routes and timetables.** Today our trams run the lane graph's tracks on
   their own. → Read ZTM's GTFS (free, the same feed they used) for the lines inside the box:
   the right line numbers on the right tracks at the right frequency by hour, tram stops with
   shelters and platforms by rule, a tap on a tram shows its line card. Fits Moja Warszawa's
   "metro and buses" theme; needs a download approval (the GTFS feed, a few MB). Loop MW-4.
3. **The calendar and the river level.** → 11 November, Christmas on Plac Defilad, the leaves in
   October, and the Vistula's level by month (low water shows the sandbars and old bridge piles
   by Bednarska; this fits our river work and the river steps). Our time of day already has the
   real sun (`--time=live`). Loop 3i / MW-6.
4. **Live weather, optional.** Open-Meteo (free, no key) for "Live" mode. A network call on the
   phone needs the user's yes and a privacy line (the game collects nothing today). Later.
5. **Churches, schools, hospitals and stations drawn by their use** (OSM tags → facade kit):
   cheap variety everywhere, not only at landmarks. Our building shader has the codes for it.
   Loop 3f-2.
6. **Night read.** Their night is beautiful from far but hard to read up close; ours keeps the
   value ladder (the art bible) so the car and streets read. Keep ours; borrow their density of
   lit windows and real lamp rows for the far view (the helicopter at night). Loop 3i.
7. **Save a picture + share the view.** Their right-click "save a picture" and feedback with the
   exact view are what made people post it. → Our Fotka (vision.md 4.2) should export a clean
   picture (no HUD, a small credit line) to Photos, and a "report this spot" with the place in it
   for the TestFlight build (loop 3j).
8. **Polish and English UI with a switch.** We show both at once today (Polish above English).
   → A language setting (Polski / English / both), the default by the device's language. Loop 3j.
9. **Ship early to Warsaw.** Their best fixes came from locals in the first week (a missing
   flagpole, a cemetery, a hidden mall). → The demo goes to TestFlight testers in Warsaw as soon
   as 3d–3f land, with the feedback-with-the-view button. Loop 3j.
10. **Agents say "done" too early; isolate them.** Same lesson as ours (the beach regression, the
    bake that printed OK in 49 ms). Keep: look at every before/after pair, a full verify per
    merge, one writer per worktree.

## What not to copy

- **The whole city at once.** Our demo stays the 18.6 km² box at street-level quality; their
  517 km² works because a map at their zoom needs no lanes, collisions or traffic.
- **Generated filler presented as data** (their graves); if we fill, it is labelled in code and
  docs (they do label theirs).
- **A near-black night**: the player must see the road.
- **Their names, art or code**: we build our own; the project is credited here only as an
  inspiration.

## Changes this makes to the plan

- DEMO 2.2 / loop 3f: tier B grows to ~30 landmarks, plus churches by rule, cards and pins.
- vision.md: the tram GTFS (MW-4), the calendar and the river level (MW-6), Fotka's picture
  export and the view-carrying feedback (MW-6 / 3j), the language switch (3j).
- Downloads to ask the user for when those loops start: ZTM's GTFS (tram and bus routes), the
  1 m NMT for the box (3d-1's open question), Open-Meteo only if Live weather is wanted.
