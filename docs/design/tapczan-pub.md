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
2. **Inside** (a cutaway like Smoła's): old brick, the bar along the back wall with sixteen lit taps
   and the chalk menu, the gold bottle-cap sign, barrels, five long tables with regulars on the
   benches (they lean and lift their glasses), the beer pong table at the front with tonight's three
   rivals. Tap a person for a line (barman Kuba, the beard who brews in the bathtub, Polibuda
   students, backpackers, a couple on a date, the rivals' hellos). Three buttons:
   - **WYPIJ PIWKO**: a pint, 16 zł (the first of a visit is on the house when the player is broke;
     the bar stops at four). Each pint makes the drive after it tipsy.
   - **ZAGRAJ**: the rival card, then beer pong.
   - **WYJDŹ**: back to the car.
3. **Beer pong** (2D over the room, drawn from behind the player's end):
   - **Slingshot**: finger down anywhere, pull back and to the side, let go. Further back is
     harder; pulled left, the ball goes right. A **dotted arc** shows where it goes for the first two
     throws of a game, then the player is on their own.
   - **Six cups a side** (3-2-1). **Two balls a turn**; two hits in one turn and **the balls come
     back**. At three cups a side is **re-racked** once (2-1).
   - **A bounce** (one touch of the table, then in) takes **two cups**. A ball on a **rim spins**
     round it once and drops in or pops out (half and half).
   - **Each cup the rival takes is a drink**: the hand sways more (sim `sway`), and the drive after
     is more tipsy.
   - **The rivals** (invented people): Pan Hubert, beer sommelier (skill 0.75, 120 zł: wine-note
     trash talk about hops), the open-space crew (0.5, 80 zł: KPI and sprint jokes), and Pani Gienia,
     "pierwszy raz" (0.3 until her cups are re-racked, then 0.95: "Mistrzostwa Pragi '98, dziecko",
     150 zł).
   - **Win**: the stake in złoty and 5 respect (wallet kind `pong`). **Lose**: nothing paid, the
     round is on you. JESZCZE RAZ or DO BARU; PODDAJ SIĘ gives up.
4. **The drive after** (about a minute, fading out): the city seen double and soft at the edges, the
   camera swaying and rolling a touch, odd thoughts drifting across the screen ("Gołąb na dachu
   ocenia twoje życie"), and the car wandering gently one way and then the other. One of the lines
   says it plainly: in real life, a taxi. More drinks, a stronger start (a pint 0.35, up to 1).

## How it is built

| Part | Script | Notes |
| --- | --- | --- |
| The door, the run, pay, QUESTS row, map mark | `tapczan.gd` | an activity of the kit with no call: `_idle_tick` puts the ring (`set_mark`) and the pill; the pill's `start` is the run; `_ended` gives back the HUD and the car and starts the tipsy spell; `rescue_calls` HOLD |
| The room | `tapczan_room.gd` | one mesh (about 6k triangles), one MultiMesh of people, the panel; built on the first visit at (9000, 0, -9000) |
| Beer pong's rules and ball | `beer_pong_sim.gd` | pure; the flight is integrated at 120 Hz once per throw; the aim's preview traces into one reused array |
| Beer pong's view and touch | `beer_pong.gd` | `_draw` only, a fixed perspective; nothing allocated per frame |
| The drive after | `tipsy.gd`, `shaders/tipsy.gdshader` | the overlay lives in the city's SubViewport (the HUD stays sharp); hidden and `_process` off when sober; car.gd `tipsy_pull` |
| Words | `game/data/tapczan.json` | every on-screen line, [Polish, English] |

main.gd: the join line, the camera's `room_view` branch and `sway`, "on foot" for the sounds and no
helicopter while inside, and the QUESTS entry (11 lines). Check: `game/tools/check_tapczan.gd` (verify
step `tapczan`); the whole flow in the game: verify step `tapczan-run` (`--tapczan=pong`).

**Add-ons check.** Beehave: not used, because the rivals have no behaviour to choose between (each
throw is the sim's aim plus a skill scatter, and Pani Gienia's switch is one flag). Dialogue
Manager: not used, because there are no branching conversations: taps give one line from a bag and
the rivals' quips follow the game's events, so `data/tapczan.json` line bags are enough.

## Decided for now (park list)

- The pint price (16 zł), the stakes (80/120/150 zł) and the skills are first guesses for the phone
  feel test (PHONE-CHECK 15zzi).
- Drinks do not lead to police or fines: the tipsy minute is a comic wobble, not a crime mechanic.
  The App Store age rating's "alcohol references" answer needs F's look before the next submission.
- No sound of its own yet (the radio plays on; the room counts as "on foot"): a pub murmur loop and
  the pong's cup "plip" are next.
- The rivals' portraits are their initials (no PixelLab art yet).
