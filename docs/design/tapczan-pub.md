# THE TAPCZAN, phase 2: walk in, a pint, beer pong (F's ask, 2026-11-24)

Phase 1 (PR #1046) built the pub on Sienkiewicza 4 (landmarks site `tapczan`, the street level and
the pallet terrace) and the bar crawl route "Kraftowa" that starts there. Phase 2 makes it a place
to go into.

## What the player gets

1. **The door, any time.** Within 120 m an amber ring with its beam stands at the terrace's kerb
   edge in front of the bay with the door. Stop there (under 6 km/h, within 11 m) and the context
   pill says **WEJDŹ / GO IN**. No call, no quest, any hour. The maps carry the pub's mark
   (SERVICE layer, group `crawl`), and QUESTS lists it under SIDE JOBS as "Rajd Kraftowy · THE
   TAPCZAN" with SHOW ON MAP and the number of crawls done.
2. **Inside** (a cutaway like Smoła's), rebuilt from the real pub's photos (second pass,
   2026-11-24): the curved bar with its copper-edged wooden top over rubble stone piers and dark
   slate panels, two long chrome tap pipes with arched ends (a coloured handle per tap, glowing amber
   glasses on top), the row of amber glass lamps and lit bottle shelves on the brick behind, the
   black soffit following the curve with the numbered chalk tap list, black leather stools on wooden
   legs, the porthole in the brick, BREW ENJOY EMPTY REPEAT on the grey concrete (the first letters,
   BEER, in white), the steel mezzanine with its cable railing over the arched way out, the black
   ceiling's edge and the silver ducts, dark slate tiles, square wooden tables with wooden chairs,
   the pong table at the front with tonight's three rivals. Craft-beer memes hang as chalkboards
   ("Piwo nie ma być smaczne, ma być DRUGIE", "Chmiel, Honor, Ojczyzna", "NEIPA: mętne jak moje
   plany", "Kraftowe 28 zł za 0,3, ale z duszą", "Nie ma jasnego. Jest lager z nutą nostalgii"); a
   tap on a board or the wall reads it in Polish with English. Tap a person for a line. Third pass
   (2026-11-25, F: "a bit more detail inside"): copper pendant domes over the bar, chrome drip
   trays, stickers on the black column, a lit fridge and crisps, the radiator under the porthole,
   spots along the brick, a succulent on every table, plants, a barrel table by the way out,
   Chmiel the pub dog (tap him) and the cat on the bar, and a PIJ LOKALNIE board. The UI (padel's
   pixel look on the root viewport, `tapczan_ui.gd`): slim chips top left (THE TAPCZAN, RACHUNEK,
   the wallet), lines as bubbles pinned to the speaker, three tiles on the objects:
   - **PIWKO** (over the taps): the **tap list** as a chalkboard docked right, six rows (name, price, style, ABV, glass):
     Mętna Sprawa (NEIPA 6,5%, 28 zł), Chmiel, Honor, Ojczyzna (West Coast IPA 7%, 26 zł), Czarna
     Owca z Pragi (imperial stout 11%, 32 zł), Kwaśna Mina (raspberry sour 4,2%, 24 zł), Dla Teścia
     (lager 4,8%, 16 zł) and Trzeźwy Kierowca (alcohol-free, 12 zł). A pick: the price out of the
     wallet and onto the visit's **bill** (the amber line under the title, with the wallet), the
     barman's sommelier-style answer, the first sip's line 2.4 s later. A beer's strength for the
     drive after it is ABV / 5 drinks (the stout about two, the zero none). Short of the price: the
     visit's first glass is on the house (the barman's "house" line, 0 zł on the bill), after that
     one of the barman's refusals, nothing poured. The bar stops at four glasses a visit.
   - **GRAJ** (over the pong table): the rival card (bust, stake, how they play, last time's
     result this visit), then beer pong.
   - **WYJDŹ** (at the door): back to the car.
3. **Beer pong v2, "Rzut na raz"** (2026-11-25; the whole design: `tapczan-pong-v2.md` and its
   addendum `tapczan-pong-v2-physics-and-fun.md`, which wins where they differ). Full screen in
   padel's pixel look, seen from the side: you on the left, the rival on the right, the pub's brick
   behind, the regulars at the back table reacting.
   - **Hold and let go**: the gold ring swings over their cups; the finger down holds the breath (the
     swing slows to 60 %, the cyan lung bar drains: 1.3 s for the whole turn, 0.1 s less a drink);
     up throws. The ring is the truth: the ball comes down through the mouth plane exactly there,
     then real physics (lip spins and skips, table tocks, shoved cups, flukes).
   - **Five cups a side**, two balls a turn, **six rounds** then last orders (more cups wins; level:
     up to three rounds of sudden death; still level: a draw, nobody pays). A clean drop near the
     centre (CZYSTO) brings the ball back once a turn; the heat of a streak widens that window.
   - **The bounce shot**: drag the held finger down: two cups in clean, but a watching rival may
     swat it. **The flick**: one tap on the gold tick takes their spinner out of your cup.
   - **The dare** (TEGO NIE TRAFISZ): a middle cup taken with a drop is a KARNIAK, a rival ball fewer.
   - **The rivals**: the open-space crew (80 zł, three hasty balls, half the time on their phones),
     Pani Gienia (150 zł, dozes until three cups or round 4, then sharp, flicks and nudges the table),
     Pan Hubert (120 zł, tasting glasses, a guarding hand, re-sets his rack after your hits, a third
     ball when you blank a turn). A decent thumb (the 48 ms model) wins about 62 / 51 / 23 %.
   - **Each cup the rival takes is a drink** (the wobble, and the drive after). **Win**: the stake and
     5 respect (wallet kind `pong`); the receipt, then REWANŻ or DO BARU; the ✕ gives up.
4. **The drive after** (about a minute, fading out): the city seen double and soft at the edges, the
   camera swaying and rolling a touch, odd thoughts drifting across the screen ("Gołąb na dachu
   ocenia twoje życie"), and the car wandering gently one way and then the other. One of the lines
   says it plainly: in real life, a taxi. More drinks, a stronger start (a pint 0.35, up to 1).
   At Graphics Low (and Auto's Low on an old Adreno; tiers.gd `screen_fx`) the doubling and soft
   edges are skipped, since that pass reads the screen back, which costs a tile-based GPU a resolve
   and a copy; the sway, the thoughts and the pull stay at every level.

## How it is built

| Part | Script | Notes |
| --- | --- | --- |
| The door, the run, pay, QUESTS row, map mark | `tapczan.gd` | an activity of the kit with no call: `_idle_tick` puts the ring (`set_mark`) and the pill; the pill's `start` is the run; `_ended` gives back the HUD and the car and starts the tipsy spell; `rescue_calls` HOLD |
| The room, the tap list, the bill | `tapczan_room.gd` | one mesh (about 18k triangles, the chalk's pixel text merged into runs), one MultiMesh of people; built on the first visit at (9000, 0, -9000); no lights of its own |
| The room's UI | `tapczan_ui.gd`, `pixel_kit.gd` | one Control's `_draw` on a CanvasLayer of the root viewport (not the city image's SubViewport: drawn there it was doubled on the phone), unit `min(h/216, 2 pt)`, redrawn on change; touch areas 44 pt+ |
| Beer pong's rules and ball | `pong_sim.gd` | pure, deterministic, 60 Hz, ported from `tapczan-pong-v2-physics-sim.py`; the bots (`bot_finger`, `play_bot`) for auto_play and the check |
| Beer pong's view and touch | `pong_match.gd` | padel's 216-row SubViewport canvas through `pixel_kit.gd`; the city's 3D off while it plays (`GameCtx.city_drawn`, main.gd `set_city_drawn`) |
| The drive after | `tipsy.gd`, `shaders/tipsy.gdshader` | the overlay lives in the city's SubViewport (the HUD stays sharp); hidden and `_process` off when sober; the screen pass skipped where tiers.gd's `screen_fx` is off (Low; `Tipsy.screen_pass`, main.gd `_set_quality` → `set_level`); car.gd `tipsy_pull` |
| Words | `game/data/tapczan.json` | every on-screen line, [Polish, English]; `taps` (the tap list), `refusals`, `memes` (the boards' pixel lines and their tap) |
| The map mark | `tapczan.gd` `setup` | the registry's SERVICE layer (map_markers.gd), shape `POI_MUG`, `extra.name` "THE TAPCZAN": both maps, from the start, quiet in quest focus like the garage |

main.gd: the join line, the camera's `room_view` branch and `sway`, "on foot" for the sounds and no
helicopter while inside, and the QUESTS entry (11 lines). Check: `game/tools/check_tapczan.gd` (verify
step `tapczan`); the whole flow in the game: verify step `tapczan-run` (`--tapczan=pong`).

**Add-ons check.** Beehave: not used, because a rival is a table of numbers, a timer for where the
eyes are and at most two flags (Gienia's wake, Hubert's re-set); nothing chooses between behaviours. Dialogue
Manager: not used, because there are no branching conversations: taps give one line from a bag and
the rivals' quips follow the game's events, so `data/tapczan.json` line bags are enough.

## Decided for now (park list)

- The tap prices (12-32 zł), ABV / 5 as drinks, the stakes (80/120/150 zł) and the pong v2 numbers are first guesses for the phone
  feel test (PHONE-CHECK 15zzq to 15zzt; the 48 ms thumb is the first thing it replaces).
- Drinks do not lead to a chase: the tipsy minute is a comic wobble. The one exception is road life's
  night sobriety check (2026-11-26): blowing over 0,00 there costs a fine and respect, no chase.
  The App Store age rating's "alcohol references" answer needs F's look before the next submission.
- No sound of its own yet (the radio plays on; the room counts as "on foot"): a pub murmur loop and
  the pong's cup "plip" are next.
- The rivals' portraits are 32x32 busts drawn in code (pixel_kit.gd `bust`); PixelLab versions optional later.
