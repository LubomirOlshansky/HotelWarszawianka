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
   tap on a board or the wall reads it in Polish with English. Tap a person for a line. Three buttons:
   - **WYPIJ PIWKO**: the **tap list**, six beers in two columns (name, price, style, ABV, glass):
     Mętna Sprawa (NEIPA 6,5%, 28 zł), Chmiel, Honor, Ojczyzna (West Coast IPA 7%, 26 zł), Czarna
     Owca z Pragi (imperial stout 11%, 32 zł), Kwaśna Mina (raspberry sour 4,2%, 24 zł), Dla Teścia
     (lager 4,8%, 16 zł) and Trzeźwy Kierowca (alcohol-free, 12 zł). A pick: the price out of the
     wallet and onto the visit's **bill** (the amber line under the title, with the wallet), the
     barman's sommelier-style answer, the first sip's line 2.4 s later. A beer's strength for the
     drive after it is ABV / 5 drinks (the stout about two, the zero none). Short of the price: the
     visit's first glass is on the house (the barman's "house" line, 0 zł on the bill), after that
     one of the barman's refusals, nothing poured. The bar stops at four glasses a visit.
   - **ZAGRAJ**: the rival card, then beer pong.
   - **WYJDŹ**: back to the car.
3. **Beer pong** (2D over the room, drawn from behind the player's end):
   - **Slingshot**: finger down anywhere, pull back and to the side, let go. Further back is
     harder; pulled left, the ball goes right. A **dotted arc** shows where it goes for the first two
     throws of a game, then the player is on their own.
   - **Six cups a side** (3-2-1). **Two balls a turn**; two hits in one turn and **the balls come
     back**. At three cups a side is **re-racked** once (2-1).
   - **A bounce** (one touch of the table, then in) takes **two cups**. A ball on a **rim spins**
     round it once and drops in (three times in four) or pops out.
   - **Each cup the rival takes is a drink**: the hand sways more (sim `sway`), and the drive after
     is more tipsy.
   - **The rivals** (invented people), a ladder (see "Difficulty" below): Pan Hubert, beer sommelier
     (skill 0.70, 120 zł: wine-note trash talk about hops), the hardest; Pani Gienia, "pierwszy raz"
     (0.3 until her cups are re-racked, then 0.67: "Mistrzostwa Pragi '98, dziecko", 150 zł), the
     tricky one in the middle; the open-space crew (0.45, 80 zł: KPI and sprint jokes), the easiest.
   - **Win**: the stake in złoty and 5 respect (wallet kind `pong`). **Lose**: nothing paid, the
     round is on you. JESZCZE RAZ or DO BARU; PODDAJ SIĘ gives up.
4. **The drive after** (about a minute, fading out): the city seen double and soft at the edges, the
   camera swaying and rolling a touch, odd thoughts drifting across the screen ("Gołąb na dachu
   ocenia twoje życie"), and the car wandering gently one way and then the other. One of the lines
   says it plainly: in real life, a taxi. More drinks, a stronger start (a pint 0.35, up to 1).
   At Graphics Low (and Auto's Low on an old Adreno; tiers.gd `screen_fx`) the doubling and soft
   edges are skipped, since that pass reads the screen back, which costs a tile-based GPU a resolve
   and a copy; the sway, the thoughts and the pull stay at every level.

## Difficulty (calibrated 2026-11-25, F's ask)

`game/tools/pong_calibrate.gd` plays 1000 seeded games of the pure sim per cell (about 10 s for the
whole table; `-- --set=sommelier:0.7,office:0.45,first:0.3/0.67` tries numbers without editing the
data, `--sweep` gives the decent bot's win rate against a plain rival of skill 0..1, `--rates` one
throw's odds). The player bots aim exactly at a random cup and scatter (lateral, power): poor
(0.20, 0.10), decent (0.12, 0.06, check_tapczan's reference bot), good (0.07, 0.035); "+1/+3
drinks" start the decent bot with that much sway already (the game starts every game at 0; this is
the sway's sensitivity). One throw at a full rack goes in for the poor bot 22 %, decent 37 %, good
54 %; a rival of skill 0.45 about 27 %, 0.70 about 43 %.

**Target** (F via the coordinator): for a decent sober player a ladder, the sommelier hardest
(25-35 % player wins), Pani Gienia the tricky beginner (40-50 %), the open-space crew easiest
(60-70 %); a poor player still wins sometimes (> 8 %) against the easiest; a good player wins > 50 %
against all but the sommelier; 8-14 throws a side.

**Before** (skills 0.75 / 0.5 / 0.3→0.73, RIM_IN 0.5), player wins and throws a side (player, rival):

| player | sommelier | Pani Gienia | open space |
| --- | ---: | ---: | ---: |
| poor | 7 % (15.3, 16.0) | 17 % (22.9, 22.6) | 32 % (26.2, 25.7) |
| decent | 20 % (15.1, 15.1) | 36 % (19.1, 18.2) | 59 % (21.8, 20.5) |
| good | 56 % (12.8, 11.3) | 73 % (13.7, 11.4) | 88 % (14.6, 11.8) |
| decent +1 drink | 19 % | 33 % | 56 % |
| decent +3 drinks | 13 % | 24 % | 45 % |

**After** (skills 0.70 / 0.45 / 0.3→0.67, RIM_IN 0.75), the full table:

| player | rival (skill/late) | player wins | throws/side (player, rival) | turns | player cups | won on a bounce | late switch |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| poor | sommelier 0.70 | 10% | 14.4, 15.0 | 13.8 | 3.4 | 3% | - |
| poor | office 0.45 | 37% | 22.0, 21.4 | 21.2 | 4.6 | 19% | - |
| poor | first 0.30/0.67 | 23% | 19.9, 19.5 | 19.1 | 4.3 | 11% | 85% |
| decent | sommelier 0.70 | 30% | 13.9, 13.4 | 12.4 | 4.4 | 1% | - |
| decent | office 0.45 | 68% | 18.1, 16.4 | 16.4 | 5.4 | 7% | - |
| decent | first 0.30/0.67 | 46% | 16.4, 15.1 | 14.8 | 5.0 | 3% | 97% |
| good | sommelier 0.70 | 68% | 11.1, 8.9 | 8.5 | 5.4 | 0% | - |
| good | office 0.45 | 90% | 11.9, 8.8 | 9.2 | 5.8 | 2% | - |
| good | first 0.30/0.67 | 80% | 11.5, 8.8 | 8.8 | 5.7 | 0% | 100% |
| decent +1 drink | sommelier 0.70 | 28% | 14.1, 13.6 | 12.7 | 4.3 | 2% | - |
| decent +1 drink | office 0.45 | 65% | 18.6, 16.9 | 16.9 | 5.3 | 8% | - |
| decent +1 drink | first 0.30/0.67 | 42% | 16.5, 15.3 | 14.9 | 4.9 | 3% | 97% |
| decent +3 drinks | sommelier 0.70 | 21% | 14.2, 14.1 | 13.1 | 4.0 | 2% | - |
| decent +3 drinks | office 0.45 | 52% | 20.2, 18.9 | 18.8 | 5.1 | 9% | - |
| decent +3 drinks | first 0.30/0.67 | 33% | 17.5, 16.6 | 16.2 | 4.7 | 4% | 95% |

(4000 games for the decent row: 32 / 48 / 68 %.) "Turns" counts both sides' turns; "player cups"
the rival's cups the player sank; "won on a bounce" the games whose last ball was a bounce shot.

**Why these numbers.** The decent bot's win rate against a plain rival falls steeply between skill
0.4 (70 %) and 0.8 (14 %), so the ladder sits there: 0.70 → 30 %, 0.45 → 68 %, and Pani Gienia's
weak start (0.3) plus her late 0.67 lands in between at 46 %. `RIM_IN` (one rule constant) goes
0.5 → 0.75: a rim spin is a near hit (30 % of a decent throw), so rewarding it shortens every game
by ~2 throws a side and barely moves the win rates (it helps both ends). Met: every win-rate
target, and 8-14 throws a side against the sommelier for decent and good players. **Not met:** a
decent player still needs ~16-18 throws a side against Pani Gienia and the crew, because their
own game needs six cups at ~37 % a throw (and fewer cups after the re-rack, which are harder to
hit); RIM_IN 0.85 bought only ~0.6 more and kills most rim-outs. Getting there would take a rule
change (five cups, or a bigger catch on the last cup), parked for F after the phone test. The
drinks matter: three drinks of sway take ~10 points off a decent player against every rival.
A bot is not a thumb: PHONE-CHECK 15zzl decides.

## How it is built

| Part | Script | Notes |
| --- | --- | --- |
| The door, the run, pay, QUESTS row, map mark | `tapczan.gd` | an activity of the kit with no call: `_idle_tick` puts the ring (`set_mark`) and the pill; the pill's `start` is the run; `_ended` gives back the HUD and the car and starts the tipsy spell; `rescue_calls` HOLD |
| The room, the tap list, the bill | `tapczan_room.gd` | one mesh (about 16k triangles, the chalk's pixel text merged into runs), one MultiMesh of people, the panel, the tap list and the bill line; built on the first visit at (9000, 0, -9000); no lights of its own |
| Beer pong's rules and ball | `beer_pong_sim.gd` | pure; the flight is integrated at 120 Hz once per throw; the aim's preview traces into one reused array |
| Beer pong's view and touch | `beer_pong.gd` | `_draw` only, a fixed perspective; nothing allocated per frame |
| The drive after | `tipsy.gd`, `shaders/tipsy.gdshader` | the overlay lives in the city's SubViewport (the HUD stays sharp); hidden and `_process` off when sober; the screen pass skipped where tiers.gd's `screen_fx` is off (Low; `Tipsy.screen_pass`, main.gd `_set_quality` → `set_level`); car.gd `tipsy_pull` |
| Words | `game/data/tapczan.json` | every on-screen line, [Polish, English]; `taps` (the tap list), `refusals`, `memes` (the boards' pixel lines and their tap) |
| The map mark | `tapczan.gd` `setup` | the registry's SERVICE layer (map_markers.gd), shape `POI_MUG`, `extra.name` "THE TAPCZAN": both maps, from the start, quiet in quest focus like the garage |

main.gd: the join line, the camera's `room_view` branch and `sway`, "on foot" for the sounds and no
helicopter while inside, and the QUESTS entry (11 lines). Check: `game/tools/check_tapczan.gd` (verify
step `tapczan`); the whole flow in the game: verify step `tapczan-run` (`--tapczan=pong`).

**Add-ons check.** Beehave: not used, because the rivals have no behaviour to choose between (each
throw is the sim's aim plus a skill scatter, and Pani Gienia's switch is one flag). Dialogue
Manager: not used, because there are no branching conversations: taps give one line from a bag and
the rivals' quips follow the game's events, so `data/tapczan.json` line bags are enough.

## Decided for now (park list)

- The tap prices (12-32 zł), ABV / 5 as drinks and the stakes (80/120/150 zł) are first guesses
  for the phone feel test (PHONE-CHECK 15zzl); the skills are calibrated ("Difficulty") but a bot
  is not a thumb. Pani Gienia's stake (150 zł) is the highest while the sommelier (120 zł) is now
  the hardest: kept, since her stake is the hustle's bait; F can swap them.
- Drinks do not lead to police or fines: the tipsy minute is a comic wobble, not a crime mechanic.
  The App Store age rating's "alcohol references" answer needs F's look before the next submission.
- No sound of its own yet (the radio plays on; the room counts as "on foot"): a pub murmur loop and
  the pong's cup "plip" are next.
- The rivals' portraits are their initials (no PixelLab art yet).
