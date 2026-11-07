# Playtest plan and bug log

How Around Warsaw is played for bugs: what each tool covers, the test plan (areas × kinds of
run), the bug log every finding goes into, and how a bug goes from a run to a fix thread. Started
2026-11-02 with Autopilot (F's ask: "make the test plan, start testing, add the places to a bug
log, then fix them one by one in separate threads").

## 1. What finds which bugs

| Layer | Tool | Finds | Runs where |
| --- | --- | --- | --- |
| Static | `tools/check_roads.py`, `check_map_data.py`, the `check_*.gd` scripts (`tools/verify.sh`) | road/deck rules, map counts, lane boxes overlapping colliders | cloud + Mac, every PR |
| Scripted drive | `game/tools/check_drive.gd`; the game's own `--autopilot` (missions, races, jobs) | fixed routes over bridges and tunnels, mission flows end to end | cloud + Mac |
| Looks | `tools/shots.sh`, screenshot-review skill, art-director | wrong-looking things at fixed spots | cloud (lavapipe) + Mac |
| **Free play** | **Autopilot** (`.claude/skills/autopilot-playtest`) | what a player meets off the scripted routes: stuck spots, dead stops, falling under the ground, clipping, menus and prompts that trap you | Mac only (Godot editor + Aura) |
| Feel and frame time | the iPhone (device-run skill), the user | touch feel, haptics, frame time, heat | the phone, with the user's yes |

Autopilot is the free-play layer: a decision model drives the real game in the editor inside a
harness that Claude writes from our code, like a curious player would. It doesn't replace the
checks; every bug it finds should end as a check or a fixed spot so it can't come back.

## 2. The test plan

The queue of what to run next, built from F's comments: `docs/TEST_BACKLOG.md`.

A run is one row: an area, a kind and a time limit (10 minutes of game time unless the row says
otherwise). Areas follow the start outwards, the order a new player meets them (first 10 minutes
first, F's design goal). Mark the row's last run date and its result; re-run a row after each fix
in its area (the regression run).

Kinds (Autopilot's own): **explore** (drive/fly freely, report anything wrong), **test** (go
over one thing systematically: every kerb of a square, every ramp), **verify** (one claim, e.g.
"the unstuck button frees the car at X"), **goal** (reach a goal, e.g. finish the first mission).

| # | Area | Kind | What to look for | Last run | Result |
| --- | --- | --- | --- | --- | --- |
| P1 | Start: Plac Defilad, Marszałkowska, Świętokrzyska | explore | stuck spots, kerbs, tram islands, the Palace forecourt | 2026-11-02 (runs 1, 2) | PT-1 confirmed, PT-4 and PT-2 suspects, PT-3 closed; only Marszałkowska driven: next run forces the other streets |
| P2 | The first 10 minutes as a new player (title → language → guide stand → first job) | goal | prompts that trap, a step the guide never explains, a dead end | 2026-11-03 (runs 9-14; 1266x585) | done as far as Autopilot reaches: finger, stand, order, race, trap, rescue, heli (HELI button), tape arrow and Powiśle (met 283 s, run 14) seen in play; the tape pickup, Mirek's garage (GARAGE_AT 570 s) and the end card come after the ~6 min mark where every run on the Mac is killed (-9, runs 11-14), so they rest on the headless `verify.sh --only=first10-run` (heli 375 s, tape 378 s with the BUW cassette, Powiśle 237 s, garage 570 s, `first10: OK`). PT-10..PT-17 |
| P3 | Śródmieście grid: Jerozolimskie, Nowy Świat, Chmielna, Krucza, Mokotowska, Świętokrzyska, Królewska | explore | stuck spots, invisible walls, parked cars that pin | 2026-11-02 (runs 3-8) | done: every street driven; on-road stops were traffic-car bumps (the driver's shout confirms it), PT-6, PT-7, PT-8, PT-9 |
| P4 | Krakowskie Przedmieście, Plac Zamkowy, Old Town (the narrow streets) | test | every gate, bollard, the Castle Square slope | – | – |
| P5 | Bridges and ramps: Śląsko-Dąbrowski, Poniatowskiego, the W-Z tunnel, Wisłostrada | test | falling through decks, snapping heights, ramp ends | – | – |
| P6 | Powiśle and the river edge (boulevards, barges, the off-limits river) | explore | water tow, stuck at the embankment, under-deck entries (G6) | – | – |
| P7 | The map's edges (east yard, Gdańska, Wschodnia; since 2026-11-02 roadworks close every road there) | test | edge walls, falling off the map, a gap round the roadworks' barriers, a car wedged against them, traffic queued at them | 2026-11-06 (run 20261106-005901, main + #457 + #452) | one closure only, south edge at -735,1722: the barrier is visible and held a 25 s push at 80 km/h, no gap, no sinking; PT-23. The other closures, the east yard and traffic at the barriers are still open |
| P8 | The helicopter: take-off, landing on roofs, the rescue roofs | goal | landing on landmark roofs, clipping into towers | – | – |
| P9 | Menus: pause card, map, garage, settings, POMOC DROGOWA | test | a button that does nothing, a screen you can't leave | – | – |
| P10 | Police chase and the clamp; crash scenes | explore | a chase that pins the car, a scene that blocks a street for good | – | – |
| P11 | Trasa Łazienkowska and Wisłostrada, both ways, under and over (GAMEPLAY_PLAN 1.6) | test | the car hidden under the deck, tunnel portals, ramps, long curves | 2026-11-03 (run 20261103-152948) | baseline: 8 spots driven 8-9 s each from a teleport landing, y within 0.02 m of `drive_height` except Solec (0.65 m below once) and Wał Miedzeszyński (0.17 m); under the deck on Solec the car is covered by the deck in the first filmed frames (no x-ray yet, GAMEPLAY_PLAN 3.5); the tunnels themselves were not driven through (C11.1 not driven over the bridge, C11.3/C11.4 only from the landing); PT-18 |
| P12 | Teleport from the full map: 10 holds on tunnels, bridges, courtyards, the river bank | test | where the car lands; on a tunnel or a roof; heading against traffic | 2026-11-03 (runs 20261103-151750, -151009) | landings recorded for all ten (none in a tunnel, none under `drive_height`); drive-off not measured: gas moved the car ~5 m then speed 0 at 8 of 10 spots (probably the harness input hold); PT-19 · 2026-11-04 re-run (run -102329 probe, Classic keys, gas re-sent every 0.2 s): the three drive-offs moved 43-55 m in 3 s (>20 m), so the 11-03 gas failure was the harness; but the -700,900 hold did nothing again (the car stayed at its earlier spot) |
| P13 | Stuck on purpose: 60 s into walls, parked cars, a tram island | test | bubbles and toasts per 10 s; time to the tow offer | 2026-11-03 (run 20261103-152518) | baseline 41 s per case: fence 6 bubbles + 6 toasts, parked car 0 + 1, traffic bumps 2 + 0; most are ambient lines and quest toasts, "Towed free" came in two cases; car position and speed were not logged, so "truly pinned" is unproven; PT-20 · 2026-11-06 (runs -005204, -005901): position and stall now logged: a true pin at the barrier got no offer behind the ride button (PT-23), a back-and-forth at a wall got none either (PT-24); the tow itself was not taken · 2026-11-06 (run -092040, button free): the offer came at 8.03 s at -884,411 and the button towed the car 30 m to the lane at -864,433, y 13.69: the tow works |
| P14 | Narrow streets: Frascati, Hoża, Ordynacka, Sienna, Aleja 3 Maja, living streets | explore | pinches, jolting kerbs, dead ends with no turn-round | 2026-11-04 (run 20261104-102329) | baseline, straight gas 12 s per street from the landing, no steering: no height problems; hard slow-downs at bends on Frascati, Hoża, Ordynacka and Sienna (PT-21), none on Aleja 3 Maja; a steered drive is still open |
| P15 | The helicopter high over Varso, the Palace and the map edge | test | sky past the edge, floating buildings, the heli's place on screen | 2026-11-04 (run 20261104-102925) | partial: top height 233.5 m, holds 10 s with no drift; the flights to Varso and x 2100 did not happen (the harness's keys did not move the helicopter), so the sky, floating buildings and screen centring are still unchecked |
| P16 | Trzy mosty at full speed | goal | every contact at race speed; the look-ahead on the bridges | 2026-11-04 (headless, `check_lane_drive`) | not on the Mac yet (the harness can't follow a route); headless, the real car steered along the route's lanes drives all three legs (4.3, 2.4 and 3.4 km) with no stall, unstick or sink; the frames and the look-ahead at race speed are still open |
| P17 | Street races and police chases with the racer AI (street-races.md R1/R2, 2026-11-04): `--race=3` (Pani Halina), `--race=5` (Zbyszek), `--police=1` | goal | does the rival look fast and race (leads, passes, takes reds), is it close at the end, does it ever stand still or look silly; can the chaser be escaped | 2026-11-05 (human rivals #448: Halina beaten by ~11 m with 3 lead changes; Seba won by ~980 m with 1 cut, Zbyszek by ~940 m with 2 cuts and 1 block, the agent crashing at the first corners; no rival stood, circled or stuck; PT-22) · 2026-11-04 (runs 20261104-115030, -120021, -120641) | Halina won by the agent by 155 m (she 57 km/h average, raced, one 3.5 s stand at -827, 487: RACE_KNOT now 1.5 s), Zbyszek by 151 m (led until 38 s); chase not escaped by a slow agent (inconclusive); a touch with a dark car at the Palm ring |
| P18 | The sunken Patelnia and the Rotunda stair (#452, tested before merge) | test | can the car get in, get trapped, get out | 2026-11-06 (run 20261106-092040) | from the north-east the car crept 5-7 km/h along the east side for 25 s and pinned on the rim at -884,411 (y 11.79), never reaching the centre; towed out. Rotunda: reached the stair at -820,376 (y 12.05) and drove out over the plaza, no trap. The west approach by Kokota is still open |

**Budget.** The decision model bills to F's Aura account. One 10-minute row at a time; ask F
before more than three rows in one go or anything longer than 15 minutes.

## 3. The bug log

Every finding gets one row here, with an id that a fix thread, its PR and its branch use
(`PT-<n>`). A finding that isn't confirmed stays `suspect` and gets a `verify` run before anyone
fixes it.

Fields: **id** · **area row** · **place** (street or landmark, plus Godot world `--at=x,z` so
anyone can drive there: `godot --path game -- --nosave --at=X,Z --heading=H`) · **what happens**
· **severity** (S1 blocks progress or loses the car: stuck with no way out, falling under the
map, a crash; S2 costs the player time: a dead stop, a clip that needs the unstuck button; S3
looks wrong but plays) · **evidence** (the run id and trace/recording; Autopilot keeps runs in
`~/Library/Application Support/Autopilot/memory/Around Warsaw/runs/<run>/`; copy frames worth
keeping to `shots/autopilot/`, never into git) · **status** (suspect → confirmed → fixing (thread)
→ fixed (PR) → verified (the re-run)).

| id | Row | Place (`--at=`) | What happens | Sev | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| PT-1 | P1 | Marszałkowska at the Centrum tram stop, north of the start (`--at=-1025,-45 --heading=-12`; the spot x -1005..-1032, z -95..83) | 24-30 m/s to ~0 in under a second, the same line in 3 runs; reversing frees it. **Cause** (reproduced with no traffic at all, so not a traffic car): the stop's 0.9 m platform wasn't solid, the car drove inside the slab and hit the shelter on it end on; brushing the fence along the kerb also cost 1.2/s of the whole speed. **Fix**: platforms ≥ 0.5 m are solid at their edges (except edges along or across a road: OSM's platforms overlap outer lanes elsewhere), the wall scrape scales with how hard the car presses in; `check_stuck_spots.gd` drives 5 lines through the spot | S2 | runs 20261102-115157 trace1 t=19.8; 20261102-122308 `run2-events-all.jsonl` | fixed (PR #289) |
| PT-2 | P1 | a block NE of Plac Defilad (run 1 kit x 360-430, y -280..380; Godot coords unknown) | ~10 near-stops in a minute; unsticks 1 → 23 over run 1 | S2 | run 20261102-115157 trace2 t=240-300 | not reproduced (2026-11-02): ~330 straight lines (every 40 m, both ways, 12 m/s, gas held) along every road centre in x -950..-300, z -650..260 drive clean except at dead ends, and kerb-hugging lines stop only at the walls past the kerb; the stops were the agent wandering into courtyards and gated service roads. Four lines (Mazowiecka, Świętokrzyska, Nowy Świat ×2) now guard it in `check_stuck_spots.gd`; reopen with a frame |
| PT-3 | P1 | Dobra at the foot of the Powiśle escarpment (`--at=375,-396`) | the car 29 m below its start height | – | run 1 trace3 t=339; terrain there is -15.3 m, the car -14.6 m | closed (not a bug: low ground) |
| PT-4 | P1 | Marszałkowska by Rondo Dmowskiego (`--at=-807,494`; x -790..-860, z 406..494) | hard stops at 29, 20, 13, 15 m/s, then a full stop; reversing freed it | S2 | run 20261102-122308 episode 2 | not reproduced after the roundabout rebuild (PR #307, 2026-11-02): four straight runs at 25 m/s up and down Marszałkowska to the ring keep full speed (`check_stuck_spots.gd`), and `check_drive.gd` routes round all four sides of the ring and past the south-east stairs are clean; reopen with a frame if a run hits it again |
| PT-5 | P3 | side streets west of Marszałkowska (x -1690..-2960, z 30..415; worst `--at=-2447,205`) | 28 hard stops, 10 stucks freed in 1.6-8.6 s, while the agent wandered off its route | S3? | run 20261102-122308 `run2-events-ep1.jsonl` | not reproduced (2026-11-02): ~350 straight lines over x -2960..-1690, z 0..450 clean except at dead ends (service-road ends, the map edge at Przyokopowa); kerb lines stop at walls only. Two lines (Żelazna, Prosta) guard it in `check_stuck_spots.gd`; reopen with a frame |
| PT-6 | P3 | the HUD, any street | the guide's speech bubble ("On your left! Left! ...") covers the minimap and the +/- buttons for ~4 s | S3 | run 20261102-125901 frames | not reproduced on main 4baac64 (2026-11-02): layout keeps bubbles clear; `check_hud.gd` now sweeps a speaker over and past the whole screen at 6 sizes, and a cloud shot with 5 bubbles round the minimap is clean. Open: the exact frame (which bubble, which window size) |
| R3 | P3 | Jerozolimskie by Plac Defilad (`-1053,235`, `-1117,248`), Szpitalna corner (`-584,154`), the excavation by Fangora (`-1141,27`) | hard stops at 108 km/h | – | run 20261102-125901 frames | closed (not bugs: 30 m off the road into a car park wall and a barrier, a building corner on a living street; at the pit the car follows the dug ground, the terrain grid doesn't) |
| PT-7 | P3 | the approach to Krucza and Mokotowska by the curved glass building (`--at=-610,186`; seen at -597..-630, 166..190 in 3 runs) | the car pinned for 3+ s: the game's own POMOC DROGOWA tow fired ("Towed free") | S2 | runs 20261102-154847, -155644 frames | fixed 2026-11-02: the building is the block on the south side of the Chmielna square (Zgoda's end to Bracka), and the range's two ends are its two traps: a 3 m notch where two buildings meet at -630,186 and a 0.5 m slit with a 0.3 m step between the glass corner and Jabłkowski's at -596,190. A car held towards Krucza slides along the front, its front corner catches, it is turned out, pinned again within 5 s, towed. Same with and without traffic (no traffic car or prop there; `check_stuck_spots` has none). "No wall in front": the camera's see-through ghost hides that building when you drive south. Every building block now gets low collider walls across slits under 0.9 m and notches up to 4.5 m wide and 3 m deep, and a ~9° taper in front of steps up to 0.6 m (map_builder `_bridge_pockets`, ~15,100 short walls city-wide, none on a carriageway); 4 spots in `check_stuck_spots` (all 4 fail on the old map) |
| PT-8 | P3 | Mokotowska's far end (`--at=-120,676`) | a flat 6 km/h crawl for ~20 s while Pani Halina's "flash back to race" prompt is on screen | S2? | run 20261102-155644 frames | fixed 2026-11-02: pinned by her car. Facing west at one-way Hoża's end she was put on two-way Hoża's lane that starts 9 m ahead (`_behind` found no way in behind it) and held 12 m in front on the 3 m street; the car crawled into her at a wall's 6-7 km/h for the 20 s prompt. She now rolls up only on a lane running the car's way, at a point really behind it, else the call waits (`check_ladder` checks the spot) |
| PT-9 | – | the HUD | speech bubbles and the radio subtitle cut off at the screen edge mid-word; the KEBAB distance label overlaps the BRAKE and sound buttons and the subtitle; a bubble's pointer ends off its car | S3 | runs -154847, -155644, -161411 frames | fixed 2026-11-02 (bubble tail runs to its speaker, also from below; typed text keeps its final wrapping; `check_hud` PT-9 sweep at 6 sizes). The KEBAB label overlap and the cut-off at the edge did not reproduce at any of the 6 sizes: needs the next run's frame. Run 10 at phone shape (1266x585) reproduced the edge cut-off: the radio subtitle box slides past the left edge as it animates ("fternoon, Warsaw!"); the KEBAB/BRAKE overlap didn't show there. The ticker cut-off fixed 2026-11-02: it eases in inside the safe area and fades instead of sliding from off screen (`check_hud` checks every step of the slide); the KEBAB label overlap still needs a frame |
| PT-10 | P2 | the order tracker, first order | the orange distance marker and arrow draw on top of speech bubbles ("297 m" over a bubble, "14 m" over KIEROWCA's line); the "Go! Kasia is waiting" banner covers the marker; at the screen edge the marker's number runs into its arrow | S3 | run 20261102-175913 t=48-78, run -174743 frames 4-12 | fixed 2026-11-02: the pointer draws under bubbles and panels and goes faint under the banner or a bubble; the edge arrow slides along the edge clear of them; the distance sits past the arrow by its own size (`check_hud`: draw order, 72 directions, a bubble in the arrow's spot). Phone look open |
| PT-11 | P2 | the first race (Pani Halina) | the race card cuts its goal to "Rondo ..." / "Ro..."; after the flash-back nothing says "drive to X", only the pink arrow (the agent stood still and lost) | S2 (first 10 min) | run 20261102-175913 t=96-176 | confirmed (frames); the "nothing says drive" half is a design call · fixed 2026-11-02: the card names the goal short ("WYŚCIG · POD PALMĘ", a long one wraps), and the hint says "Jedź pod Palmę! … Różowa strzałka pokaże drogę." · design half fixed 2026-11-02: in the first race Halina waits at the line until the car moves (at most 12 s); still for 2 s after START! brings the GAZ! JEDŹ ZA STRZAŁKĄ banner, the ghost finger on the stick and her "go" line; stopped 5 s mid-race (not on the last 140 m) brings a "stall" nudge, at most twice (rivals.gd `first_start_step`, `first_stall_due`; check_first10). Verify on the next P2 run |
| PT-12 | P2 | the first rescue call | the card ("A cyclist is hurt ... Get them to the hospital in 3:00") doesn't say where the cyclist is; the hint reads "rescue call: tap WEZWANIE" (English with the Polish label) | S3 | run 20261102-175913 t=255-290 | fixed 2026-11-02: the card says "Od ciebie: ok. N m <direction>" (English: "About N m <direction> of you"), the hint reads "tap the button at the top"; phone look open |
| PT-13 | P2 | the first order card | the card with Go! / Not now went away and the order started without a tap | ? | run 20261102-175913 t=44-52 | not a bug, unclear: jobs.gd `_order_tick` starts an order by itself after 9 s (14 s for the craft kebab, or once the car drives off) by design; 8 s in the run. Fixed 2026-11-02: the button that will happen counts the seconds down ("JEDZIEMY! · 7" / "GO! · 7"; the craft card's ZWYKŁY), `check_hud` covers the label |
| PT-14 | P2 | the helicopter after the heli beat (`--at=-1023,-167`) | for 100 s the helicopter sat at ground height (13-14 m) and then stopped moving; the agent's key calibration found W/D turning in odd directions. Either it landed and Space didn't lift it again, or the harness mixed the camera-relative keys | S2? | run 20261102-231535 t=398-500, `heli_events.jsonl` (no frames) | closed 2026-11-03 (harness): run 12 landed at 13 m and Space lifted it to 44 m then 82 m; run 11 had mixed up its own keys |
| PT-15 | P2 | Pani Halina's race flash-back | a taxi "New ride" card (Marek ★ 4.9, 303 m) came up while the flash-back offer was on screen: two offers at once | S3? | run 20261102-231535 (text log only) | fixed 2026-11-03 (cause in the code, no frame needed): a Podwózka request only waited for a race, not for a rival's prompt or Halina rolling up, and her call only waited for a job, not for a request card. Now no request comes while any rival prompt is up or she is on her way (rivals.gd `calling`), and neither her call nor a rival's FLASH LIGHTS prompt comes while a request card is up (jobs.gd `ride_offered`; first10 counts it as busy). A probe run with `--first-race` forcing requests during her call got none; run 14 (text, on a Mac checkout that likely predates this fix: run 13 there still showed the old WEZWANIE hint) had the Halina flash-back banner and the ride-app banner on screen together at 178 s and 266 s, and a ride card with the EASTER EGG toast at 250 s: re-check on main |
| PT-16 | P2 | the first order | the agent drove the same order card to its ring six times; after each arrival the order still showed as on. Either the stand chains a new order at once or the harness misread the arrival | ? | run 20261102-231535 t=22-200 | fixed 2026-11-03 (likely cause): the DOWIEZIONE result card waited for OK for ever, with the customer still standing in the orange ring; the agent never pressed OK, so the order looked on, it drove back to the ring, and every beat of the guide waited (the race at 203 s). The kebab and słoiki result cards (and "order dropped") now go by themselves after 12 s or once the car is 25 m away, as Podwózka's always did (jobs.gd RESULT_LIFE, RESULT_OFF). Verify on the next P2 run; the guide holding beats while a job is on: default built 2026-11-03, new offers held while a beat is due (first10.gd `due`; QUESTIONS) |
| PT-17 | P2 | Plac Dąbrowskiego by Jasna (`--at=-950,-305`) | following the KASETA arrow by car, the car moved ~40 m in 70 s, circling on the carriageway, until POMOC DROGOWA towed it free | S2? | run 20261103-005809 t=441-509, `heli_events.jsonl` (no frames) | fixed 2026-11-03: reproduced without traffic, with the stick held north-east (the arrow to the BUW roof): Jasna's east facade at the square's corner (-925..-940, -279..-302) has a 24 m bay 2.3 m deep between two rounded piers 2 m proud. The car slid along the bay at 15 m/s into one pier, was turned out along the wall into the other and back, 4 unsticks in 20 s, until the tow. Bays up to 30 m wide and 2.5 m deep now get a low collider wall across the mouth too (map_builder BAY_MOUTH, BAY_DEPTH; ~7,500 more short walls, ~22,600 city-wide; deeper recesses, like the 9 x 3 m one on Bracka, stay open); 4 spots in `check_stuck_spots` (all 4 fail on the old map); run 14 drove through at t=210 with no stuck or tow (one pass) |
| PT-18 | P11 | Solec under the Trasa's deck (`--at=1347,1077`) | the car is covered by the deck for the first ~2 s (frames 27.07-27.74 of run -152948, a red sliver only); on the way north it climbs a ramp from y -14.6 to -9.3 and stops for ~1.6 s at (1308,960) | fixed: deck visibility in #419, the ramp stall in #421; re-check on the next P11 run | run 20261103-152948 trace1 t=26.8-35.9 | baseline for the under-deck fix (GAMEPLAY_PLAN 3.5); the stop is not confirmed as a bug |
| PT-19 | P12 | the map teleport (`_teleport_from_map`) | in a re-run three holds left the car where it was (C12.3 116,1619; C12.7 -700,900; C12.10 -1013,-45) with no message; also the 3 s gas test moved the car only ~5 m (speed 0) at 8 of 10 spots | suspect | runs 20261103-151750 (probes after the episode) | likely the harness input hold or a teleport refusal / lane graph not streamed in; re-run with a different gas path · 2026-11-04: gas works with a re-sent hold (43-55 m in 3 s); the -700,900 hold again left the car in place · 2026-11-07: the teleport itself lands at -705,874 (added to `--teleport-test`); found on the way: the map's refusal (`can_teleport`) was only set under the `--quest-pick` test flag since G12 part 2, so in play a hold teleported mid-race, mid-job or mid-chase; **fixed** (PR pending, `_wire_full_map`, checked by `teleport`). The hold that did nothing stays suspect (harness input) |
| PT-20 | P13 | the Świętokrzyska kebab toast | "The kebab stand by Świętokrzyska has your first order." came twice 0.2 s apart (t=25.2, 25.4) during C13.1 | fixed in #417 (dedupe in hud.toast), re-check on the next P13 run | run 20261103-152518 trace1 | may have been the poll catching one toast twice |
| PT-21 | P14 | narrow streets, straight gas from a teleport landing | hard slow-downs at bends: Frascati (108,881) 13 to 0 m/s and (138,942) 20 to 5, Hoża (-106,812) 23 to -1, Ordynacka (-261,-170) 18 to 5 and (-319,-146) 20 to 0, Sienna (-1706,294) 25 to 7 | closed (not a road bug) | run 20261104-102329, probe after episode 1 | with no steering the car ran into the bends' walls. Steered along the lanes (`check_lane_drive`, verify step `lanedrive`, 2026-11-04) all five streets drive end to end both ways with no stall (slowest 5.8 m/s, the driver's own corner speed) |
| PT-22 | P17 | Pani Halina's race finish (Autopilot on the Mac, 2026-11-05) | the agent won by about 11 m but the card said "by 47.1 s": at the finish both routes left read ~530 m (the finish node lay round a dual-carriageway loop), so the rival would also have driven a 500 m loop from 30 m away | S2 | Mac run 2026-11-05 editor log | fixed 2026-11-05: the rival finishes at the same 16 m circle as the player, and the margin's metres are capped at 1.4x the straight line (rivals.gd MARGIN_DETOUR) |
| PT-23 | P7, P13 | the south-edge roadworks (`--at=-735,1722`), any spot with the ride button up | pushed into the barrier for 25 s, stalled 15.4 s (the offer is due at 8 s), yet no POMOC DROGOWA and no toast: the context button showed "ride app", and `_stuck_offer_frame` only offers on a free button (`hud.pill_free`) | S2 | run 20261106-005901 t=128-153, events.jsonl `ram_end`, `shots/autopilot/20261106/` | confirmed (trace, frames, code) · the KASETA ("tape") button holds it the same way (run 20261106-092040, up at the Rotunda t=106) · fixed in #460, verified in run 20261106-100916 |
| PT-24 | P13 | a yard off Marszałkowska (`--at=-680,725`) | driving into a wall and backing off, 13 tries over 65 s, never brought the offer: backing out of STALL_RADIUS (4 m) resets `stalled`, so a player who keeps retrying is the one who gets no help | S3? | run 20261106-005204 t=148-212 | suspect (the ride button may have been up here too, PT-23); a design call on the radius · fixed in #460, verified in run 20261106-100916 |
| PT-25 | crazy drivers (#451) | near the Patelnia and east of it (-893,329; -869,461; -690,385; -701,389) | 5 cut-ins near the player in three runs, each with a horn, and no driver line at all (`CrazyDrivers.lines` stayed 0): either `d.visible` is false at the cut, or the chatter budget refuses key "crazy" | S3? | runs 20261106-004005, -005204, -005901 | suspect; `check_crazy_drivers` checks that the lines exist, not that one is said · 2 more cut-ins at Grójecka with the car pinned, again no line; lead: `_cut` sets `_talked[d]` before the budget says yes, so a dropped line (the car struggling, the reaction window) spends that car's one line · **fixed** 2026-11-07 (PR pending): a line the budget refuses no longer spends the car's one line; it stays pending 6 s and comes when the budget allows (`crazy_drivers.gd` PENDING, check `crazy`) |
| PT-26 | P1 | Marszałkowska by the start (`--at=-1000,-10`) | the "MARSZAŁKOWSKA ROADWORKS · PHASE 47 OF 312" bubble covers part of the steering hint at the bottom of the screen | S3 | run 20261106-004005 episode 2 t=20 | confirmed (frame) · **fixed** 2026-11-07 (PR pending): the ghost finger's hint is room taken (`hud.gd` finger_hint_rect), bubbles keep off it (check `hud`) |
| PT-27 | HUD at 1266x585 | near the south edge (-720,1700), driving south | the "KEBAB 1948 m" label touches BRAKE and its arrow overlaps the button | S3 | run 20261106-005901 t=126 | confirmed (frame); check on the phone · run 20261106-092040: again over BRAKE at t=50, 65, 70, clipped by a toast at 55, behind the minimap at 110 · **fixed** 2026-11-07 (PR pending): with no clear spot on the edge the arrow takes the one that covers least and never one on a pedal (`_edge_spot`); check `hud` now sweeps both schemes and the long label |
| PT-28 | P7 | Grochowska at the east edge (`--at=2174,-1448`) | the two barrier sets close the two carriageways, but the tram strip between them is open: the car drove up it level with the barriers until a low grey band and the fence stopped it from 58 km/h | S3 | run 20261106-101542 t=50-58 | confirmed (frames); the car stays in the map · **fixed** 2026-11-07 (PR pending): a collider across every tram strip between two closures, barriers beside the trams' way (`edge_roadworks.gd` rail_gaps, check `roadworks` W3) |
| PT-29 | Dead EVs (PR #472) | carrying Bartek's TESŁO at 59 m into a taller tower (`--at=-741,399`) | the helicopter is blocked by the tower; the hanging car, swung over the tower's footprint, "rested" on its 108 m roof, 50 m above the helicopter (swing 177°), and fell back over 2.5 s | S2 | Autopilot run 20261106-130817 t=48-57 | fixed (PR #472: a roof above the hook is a wall, `ev_tow.gd` `is_wall`, check `evtow`) |
| PT-30 | Padel call (PR #500) | arriving at the DESKA gate (`--at=1546,1172`, `--trend-job=7`), 1278x719 editor window | the match's point cards were never placed (side card: 3 shots in a row wider than the room beside the car; stacked: taller than the screen), so no shot could be played and each point timed out | S2 | Autopilot run 20261107-120130 ep 3, 5 | fixed (PR #500: the centred card, shots in a row; shots at 1278x719 and 1266x585) |
| PT-31 | Padel call | the street route from Solec to Zaruskiego (the service road mapped as a bridge, (1452,1225)-(1536,1176)) | the car can't get onto it: it ends at the bridge end on the bank and is towed; DESKA is reached by car only from Czerniakowska in the south | S2 | Autopilot run 20261107-120130 ep 1 t=60-200 | confirmed (frames); map lane |
| PT-32 | Padel call | a district discovery card ("Discovered: Ujazdów and Łazienki") came up while the call rang | the call ended (Idle) right after it was answered | S3 | Autopilot run 20261107-120130 ep 4 | suspect (no repro without the district card) |
| R4 | P3 | on-road hard stops on Krucza, Świętokrzyska, Królewska | 50 km/h to 1-8 km/h for 1-2 s, a traffic driver's bubble ("The indicator isn't an optional extra!") as it slows | – | runs -154847, -160539, -161411 frames | closed (not bugs: bumps into traffic cars; the bubble is dialogue.gd's shout from a car the player hits) |

No run so far put the car under the ground (it stayed 0.7-1.0 m above the terrain at every
logged event in run 2).

## 4. From a run to a fix (the loop)

1. **Run** one plan row (Mac, autopilot-playtest skill). The harness logs every stop, clip and
   height jump with its position; frame-describer describes the frames at each.
2. **Log** each finding above as `suspect`, with its evidence.
3. **Confirm**: reproduce it once, cheapest first: drive there with `--at=`, or a `verify` run, or
   a check (`check_drive.gd --debug=X,Z`). Confirmed → S1/S2/S3. Not reproducible after two tries
   → `closed (no repro)` with the reason.
4. **Triage**: S1 first, then S2 by how early a player meets it (row order), then S3. Message the
   coordinator one confirmed bug at a time (or a batch of small ones on the same street); the
   coordinator starts **one fix thread per bug**, named after the place ("Fix the dead stop on
   Świętokrzyska").
5. **Fix thread**: prove the cause first (WORKFLOW "Prove the cause first"), fix, and add the
   spot to a check where one fits (`check_drive` routes, `check_roads` allow list, a new
   `--at=` shot), so the bug can't come back silently. The PR names the `PT-<n>` id and sets
   its status to `fixed`.
6. **Verify**: the next run of that row (or a `verify` run of that spot) sets `verified`, or
   reopens it.

Sources for the practice: bug triage (reproduce and enrich every report, severity by whether it
blocks progress, blockers first, triage after every phase: [HacknPlan, "The bug triage
process"](https://hacknplan.com/blog/the-bug-triage-process)); automated agents for coverage and
stuck/exploit spots in large maps (EA SEED, [curiosity-driven playtesting
agents](https://www.ea.com/seed/news/gameplay-testing-curiosity), [Augmenting automated game
testing with deep RL](https://arxiv.org/pdf/2103.15819)); exploratory test sessions with a charter
and a time box ([Exploratory testing strategies for video
games](https://sol.sbc.org.br/index.php/sbgames/article/view/27667)).

## 5. Driving-first cases (P11-P16, GAMEPLAY_PLAN 1.6)

The rows above in detail, written for the harness (section 2 of the autopilot-playtest skill
applies to all of them: trace every stop, unstick, height jump and clip with game time, world
x, z and heading; one episode under 6 minutes; phone shape 1266x585). Each case is one option the
agent is forced through in turn. **Pass** is what a player should see; anything else is a PT row.

**P11 Trasa Łazienkowska and Wisłostrada** (`--at=919,1291`, Aleja Armii Ludowej west of the
bridge, heading east)
- C11.1 East along Armii Ludowej onto Most Łazienkowski (1042..2126, 814..1218) to the far end,
  then back. Pass: no stop, no unstick, the car never 1 m under `drive_height`.
- C11.2 Under the Trasa's deck: Solec north and south where it passes under (1347,1077), Rondo
  Sedlaczka and Myśliwiecka (800,1335), Wał Miedzeszyński on the east bank (2075,835). Pass: no
  stop; **frame every second under the deck**:
  the car must be visible (today it is not: GAMEPLAY_PLAN 3.5; after 0.3 the x-ray shows it).
- C11.3 Through Aleja Armii Ludowej's tunnel (116,1619 and 41,1636) both ways. Pass: the x-ray
  silhouette on; the portals entered and left without a stop.
- C11.4 Wisłostrada north from 265,-836 through Tunel Wisłostrady (429,-800 → 594,-586) and back.
  Pass: as C11.3.

**P12 Teleport from the full map** (any start; the map's hold-to-teleport, or `--map-jump=` per
episode). Ten holds, each followed by 3 s of gas:
- C12.1-C12.4 Over the tunnels: 429,-800; 594,-586; 116,1619; -761,-1399. Pass: the car stands on
  the street above (never in the tunnel, never 1 m under `drive_height`) and drives off (0.1 fix;
  the headless `teleport` step checks the landing, this checks the drive-off).
- C12.5 On Most Łazienkowski over the river (1700,973). Pass: on the deck or a bank road, never in the
  river.
- C12.6 Under the Trasa's deck on Solec (1347,1077). Pass: on the road under it, visible.
- C12.7-C12.8 A courtyard (Hoża, -700,900) and a gated service road off Nowy Świat. Pass: lands
  on a public street lane, can drive away.
- C12.9 The river bank by the boulevards (300,-700). Pass: on a road, not the beach or water.
- C12.10 The start (-1013,-45). Pass: on Marszałkowska heading with the traffic.

**P13 Stuck on purpose** (`--at=-1013,-45`, Marszałkowska at the start, traffic on)
- C13.1 60 s pressing into the tram-stop fence and the shelter. Log every bubble and toast with
  its time. Pass after 0.2: at most 2 bubbles and 1 toast in any 10 s; no comment per hit.
- C13.2 60 s nose into a parked car on Świętokrzyska. Pass: the tow offer (POMOC DROGOWA) within
  10 s of getting nowhere; the chatter rule as C13.1.
- C13.3 Repeated bumps into a traffic car at 15-20 km/h. Pass: one driver shout at most per 20 s.

**P14 Narrow streets** (one street per option; lanes under 2.5 m from the GAMEPLAY_PLAN audit)
- C14.1 Frascati (127,850). C14.2 Hoża east to west (-107,669 → -1339,1113). C14.3 Ordynacka
  (-219,-222). C14.4 Sienna (-1835,336). C14.5 Aleja 3 Maja (668,-70). C14.6 Three living
  streets near the start. Pass: no stop on the carriageway; log every kerb jolt and every dead end
  where the car can't turn round in three tries (with x, z).

**P15 The helicopter high** (HELI at the start, then climb)
- C15.1 Climb to the top over the Palace of Culture, hold 10 s, frame every 2 s. C15.2 Fly to Varso
  (-1700,620) at the top. C15.3 Fly east to the map edge (x 2100) at the top. Pass: no flat sky
  inside the city's outline, no building floating over sky, the helicopter in the middle third of
  the screen (fixed by 0.4; before it, log what you see).

**P16 Trzy mosty at full speed** (the final race; `--trzy-mosty` needs the ladder beaten, so drive
its route as a free drive: Rondo Daszyńskiego → Most Śląsko-Dąbrowski → Most Świętokrzyski → Most
Poniatowskiego → the stadium's south stands, 10.1 km)
- C16.1 The route at top speed, split into three episodes of one bridge each (the 6 minute limit).
  Pass: no stop on the route; log every contact with speed lost and whether the look-ahead showed
  the turn in time (frames 1 s before each bridge head).
