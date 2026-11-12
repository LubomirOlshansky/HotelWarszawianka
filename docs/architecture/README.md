# Around Warsaw: architecture

How the game is put together, which systems exist, and which one a change must plug into. Written
for agents and for F (an iOS developer who knows apps, not games). Read this page first, then only
the file for the area you touch.

| File | Read it when |
| --- | --- |
| [for-app-developers.md](for-app-developers.md) | you know app development and want the game words mapped to app words |
| [systems.md](systems.md) | you need to know which script owns what (every script in `game/scripts/` is listed) |
| [city-ai.md](city-ai.md) | you touch traffic, rivals, police, trams, trains, pedestrians, crowds or city life |
| [map-markers.md](map-markers.md) | you add a quest, job or place to the minimap or full map, or change what shows when |
| [pipelines.md](pipelines.md) | you touch the map bake, loading order, the save, tests or builds |
| [graphics.md](graphics.md) | you touch shaders, materials, lights, quality levels or anything drawn every frame |
| [extending.md](extending.md) | **before adding anything**: the one place each kind of change goes |
| [tech-debt.md](tech-debt.md) | you hit a workaround, or you want to know what to clean up next and in what order |
| [decisions.md](decisions.md) | you are about to propose a new pattern (an event bus, an autoload, a save format): what was decided, and what was decided against |

## The game in one screen

```
        boot.gd (the first scene) ─ title.gd ─ first10.gd (fresh save guide)
                                │
   tools/*.py bakes ──► game/map/ (centrum.json, index, sectors, prebuilt .scn)
                                │
 main.gd (the composition root: builds everything, owns the frame, wires every system by hand)
   ├─ World:     map_builder.gd · sector_streamer.gd · sector_proxies.gd · landmarks.gd · props, roofs, signs
   ├─ City AI:   lane_graph.gd ─ traffic.gd ─ rivals.gd · police.gd · trams.gd · trains.gd · buses.gd
   │             pedestrians.gd ─ crowds.gd · city_life.gd · packs.gd · fans.gd · wellness.gd
   ├─ Player:    car.gd · heli.gd · boat.gd · drive_controls.gd · follow_camera.gd · camera_shots.gd
   ├─ Activities: missions.gd · jobs.gd · rides.gd · rivals/ladder · tours · story_quests.gd · main_line.gd
   ├─ Feedback:  hud.gd (+ messages.gd queue) · bubbles.gd + chatter.gd · dialogue.gd · radio.gd · sfx.gd
   ├─ Progress:  wallet.gd (the save) · upgrades.gd · garage.gd · notebook.gd · eggs · districts
   └─ Look:      time_of_day.gd · weather.gd · tiers.gd + governor.gd · shaders/ · post.gdshader
```

## The five facts that explain most of the code

1. **One scene, one composition root.** `main.gd` (about 9,300 lines) creates every system with
   `X.new()`, hands it the references it needs as plain properties (`hud`, `wallet`, `map`, `car`,
   `dialogue`) and callables (`vehicle`, `clock`, `free_now`), adds it to the tree and calls its
   `setup()`. There are no autoload singletons except the camera add-on's manager. A system never
   looks another one up by path. (The boot scene before it, `boot.gd`, only shows the title while
   the game's scripts load.)
2. **Rules apart from nodes.** Numbers and decisions live in small static or pure scripts
   (`ride_rules.gd`, `upgrades.gd`, `tiers.gd`, `ladder.gd`, `chatter.gd`, `messages.gd`,
   `padel_sim.gd`, `taxi_stories.gd`), so a `game/tools/check_*.gd` script can test them without
   the map. Keep that split when you add logic.
3. **The map is baked, not built by hand.** OpenStreetMap and GUGiK data go through Python bakes
   into `game/map/`; the game builds the city from that at load (runtime path) or loads prebuilt
   sector scenes (prebuilt path, the phone's). Both paths must give the same city.
4. **The phone sets the budget.** Draw calls and per-frame script time are the gate, not
   triangles. Most crowds are extra instances in an existing MultiMesh (+0 draw calls).
5. **Every word is a pair.** On-screen text is written Polish and English together; `lang.gd`
   shows one. Spoken lines (calls, bubbles, the radio host) come from `game/data/dialogue.json`.
   Short HUD labels and signs are pairs in code today, more than the data file holds (tech-debt
   TD-19): put a new spoken line in the data file, and never write a label without its English.

## The golden rule for agents

If a system below owns the decision, **use it; don't add a private copy**. A new activity, a new
line of text, a new phone call, a new map target or a new sound goes through the owner named in
[extending.md](extending.md). If the owner can't do what you need, extend the owner in the same PR
(with its check script). If that is out of scope, build the smallest workaround, mark it in code
with `# WORKAROUND(arch): <why>` and add a row to [tech-debt.md](tech-debt.md). A silent second copy of
a decision is the bug this folder exists to stop.

`tools/check_architecture.py` (verify step `architecture`) fails when a script in `game/scripts/`
is missing from systems.md or city-ai.md, so the map of the code can't go stale.
