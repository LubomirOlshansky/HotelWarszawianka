# Road life (żywe drogi)

F, 2026-11-23: "оживити дороги": tow trucks with cars, an ambulance racing on a call (hit it and
respect drops), taxis stopped by the police for a papers check, more things to do on the road.
Plan with the fun/cost table and the critique: https://claude.ai/artifact/SrDXMWUXdudeWwfqSXg6wB.

## Stage 1 (built)

- **Karetka na sygnale** (`game/scripts/road_life.gd`, rules in `road_rules.gd`). Every 2.5-5 min,
  then every 3.5-6.5 min, an ambulance comes up behind the player on the road they drive, out of
  sight, blue lamps on, its own yelp (`ambulance_siren`), racing to a hospital at least 500 m away
  by the racers' driver (`traffic.race_to`). Traffic pulls over for it like for any light bar.
  It is the police pool's shape 2 (`police.ambulance_car`, role `ambulance`): +0 draw calls, and a
  bump into it never starts a chase. Off screen within 130 m, a yellow disc with a red cross sits
  at the screen edge. KEBAB FM reads it out.
- **Respect** (F chose "−10, але чесно"):
  - in its way (0-40 m ahead, in its lane, going its way): toast KARETKA Z TYŁU;
  - let it pass by changing lane or slowing under 4 m/s: **+3**, KORYTARZ ŻYCIA!, the paramedic
    thanks you; an ambulance that only went round you gets nothing;
  - in its way 4 s while moving at 4.2+ m/s on a road with 2+ lanes its way: **−3**, Panie, zjedź!;
  - hitting it: **−10**, only when it is the player's fault (not the ambulance running into their
    back), never below the threshold of the ladder rung already reached (`road_rules.respect_floor`,
    an open race stays open), the paramedic shouts, the radio comments;
  - each once per ambulance. `wallet.lose_respect(loss, least)` is the only way respect goes down.
- **Kontrola taksówki** (`crash_scenes.gd`, kind `taxi`, 40 % of scenes): a TAXI-pool taxi by the
  kerb, a police car behind it with its lamps, two officers, the driver, a passenger with a
  suitcase and a gawker; their own lines (`dialogue.json` `taxi_check`) and the radio's.
- **"Zielone!"**: the player stands within 14 m of a stop line that went green 2.5 s ago with a car
  behind within 12 m: that car honks and its driver shouts. At most once every 2 min, 60 % chance.
- **Quiet**: nothing starts during a race, a police chase or pull-over, the first minutes' guide or
  in the helicopter (`road_life.hushed`, shared with the crash scenes).

## Cost

Nothing new draws: the ambulance is in the police MultiMesh, the taxi in the taxi one, the people
are SCENE figures, the mark is in the HUD's police overlay. Per frame: one more racer driver while
an ambulance runs, and a 4 Hz tick. One shortest-path table per hospital, made the first time.

## Flags

`--ambulance=now|on|0`, `--road-log`, `--crash=taxi`, `--crash=tow` (archive flags table).
Check: `game/tools/check_road_life.gd` (verify step `roadlife`, in CI).

## Stage 2 (built): the laweta

- **Laweta** (`models.gd` `_van`, VAN family shapes 2 and 3): the box van's cab on a 6.6 m chassis
  with an aluminium platform, ramp tips, a headboard and a yellow beacon bar lit at night; shape 3
  carries a hatch on the platform. +0 draw calls (the VAN MultiMesh); every van carries the
  hidden parts (1,566 vertices a van instead of the old family's count).
- **In traffic**: 12 % of the vans the band spawns (`traffic.gd` TOW_CHANCE, its own generator so
  the rest of the traffic's draws stay the same), half of them loaded. Never a crazy courier.
- **Odholowanie** (`crash_scenes.gd` kind `tow`, 25 % of the roadside scenes): a hatch left half on
  the pavement, a laweta in the kerb lane ahead of it, the operator at the ramps, a city guard
  with the ticket, the owner running back in a bathrobe from Frogs ("Byłem pięć minut!") and an
  onlooker filming (`dialogue.json` `tow_scene`, KEBAB FM's "tow"). When the player comes within
  50 m the car is pulled onto the platform over 5 s (moved every frame along `load_path`), the
  laweta turns into the loaded shape exactly where the car ended, and 7 s later it pulls out and
  drives off as ordinary traffic.

## Stage 3 (F, 2026-11-23: "мені всі ідеї подобаються": all of them, in this order)

- **The wreck towed** (built): half the fender benders (`crash_tow`) have a laweta where the
  ambulance would stand and its operator in the paramedic's place; when the player comes near, the
  hit car is pulled onto it like the Odholowanie's and the laweta takes it away.
- **The fire engine** (built): 35 % of the runs behind the player are a red fire engine instead of
  the ambulance (the BUS family's third shape, `models.gd` BUS_FIRE: cab, white band, grey lockers,
  roof ladder, blue light bar; +0 draw calls), a little slower (16.5 m/s top), with its own slow
  wail (`fire_siren`, tools/make_sfx.py) and edge mark (a red disc with a white flame), racing to
  a fire 500-1100 m ahead the way the player drives. Same respect rules as the ambulance (+3 for
  the corridor, −3 for blocking, −10 for a hit at fault, rung floor), a firefighter's lines and
  KEBAB FM's "fire"/"fire_hit". Done, its lights go off and it drives on as traffic.
- **"Pan wolny?!"** (built): at 60 % of the taxi checks, when the player rolls past slowly (under
  4.5 m/s, within 16 m), the passenger waves them down ("Pan wolny?!") and Łuber offers their
  ride from right there (`rides.gd` `offer_stranded`: card titled PAN WOLNY?!, the pin where they
  stand, no story, the usual fare and stars). Once taken, the scene's passenger leaves with the
  player and says no more.

- **Dostawczak na awaryjnych** (built 2026-11-26): 15 % of the roadside scenes are a courier's van
  (the panel or box van) standing in the kerb lane on its hazard lights: four amber corner lamps
  that blink together at 1.4 Hz (`models.gd` HAZARD_BEAT, `traffic.gd` Driver.hazard, the VAN
  family's custom alpha + 8; +0 draw calls). The courier at the back doors, the customer on the
  footway (`delivery_scene`); the player's horn within 35 m gets an answer. After 40-70 s the
  courier gets in, the hazards go off and the van pulls out. On 2+ lane roads only (the queue goes
  round it, as at every scene).
- **Kontrola trzeźwości** (built 2026-11-26): at night (21:00-05:00 on the game clock), 40 % of
  the scenes are a sobriety check, once a session: a car pulled in behind a patrol car with its
  lights on, an officer at its window, a second at the lane's edge waving cars in. In that lane or
  the next, the player is waved in (toast); stopping by the officer is a breath test (DMUCHNIJ,
  2.2 s): 0,00 is +2 respect; after THE TAPCZAN (`tipsy.gd` amount × 1.4 per mille) a 500 zł fine
  and −5 respect; driving on past is −3. Every loss stops at the ladder rung reached; no chase.
- **The Elka** (built 2026-11-26): 2.5 % of the band's cars (normal launch; `--elka=X`) are a
  driving school's car: white, a blue roof box with a white L front and back (`models.gd` `_dress`,
  part 9, shown in mode 3: +0 draw calls), at 62 % of the road's pace and 55 % of the pull.
  Tailing one for 3 s brings a line from the instructor or the learner; the horn behind one, the
  instructor's "please don't honk".
- **The wedding convoy** (built 2026-11-26): every 8-15 minutes by day (12:00-21:00), four cars
  with white ribbons from the mirrors to a bouquet on the bonnet (part 10, mode 4) start 110-160 m
  ahead of the player on their road, in the kerb lane, a white or black saloon leading, at 80 % of
  the road's pace, to one far junction (their church), never through a red. Near the player they
  honk (two horn sounds, every 0.5-1.6 s) and shout "Gorzko!"; the player's horn by them makes a
  wedding guest (+1 respect, once a convoy). KEBAB FM reads out the check and the convoy.

## Left

- A bus pulling out of a stop.
- The dostawczak in a one-lane street (the queue can't pass it: the town drivers don't go round a
  standing car over the centre line yet), the Elka stalling at a green.
- **Real sirens from ElevenLabs** (F, 2026-11-24, plan only, not now): replace the synth
  `ambulance_siren` and `fire_siren` (tools/make_sfx.py) with ElevenLabs takes, each its own
  sound: the Polish ambulance's two-tone, the fire engine's slower wail and air horn, and the rest
  of road life's sounds (the laweta's winch and beacon click, the police car at the taxi check).
  Loops through tools/add_sfx.py (seamless, `--rotate` if the seam clicks), same names so the code
  doesn't change; check_sfx LOOPS; a by-ear PHONE-CHECK row. Uses ElevenLabs credits: ask F first.
- Cut: tow-ramp jump, korytarz życia in a jam.
