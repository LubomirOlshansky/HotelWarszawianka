# Map markers: what the minimap and the full map show, and when

Every mark the player can see on the minimap, the full map and in the 3D world, the situations
that change them, how it is wired today, and the planned marker registry that the next quest lines
should grow into. Design background: docs/design/quest-map.md and docs/design/main-line.md.

## 1. The layers today (loudest first)

| Layer | Looks like | Minimap | Full map | In the world | Owner and setter |
| --- | --- | --- | --- | --- | --- |
| Active target | glowing, pulsing pin in the quest's colour, edge arrow, metres, dotted route | yes (the registry's TARGET mark `MapMarkers.ACTIVE_TARGET`, `active_pin`; `set_minimap_route`) | yes, with a dotted line from the car | `beacon.gd` ring and light column | each activity sets its own (missions, jobs, rides, rivals, tours, boat race...) |
| Picked place | the same pin, for a place tapped in the map's one list (first hour step 4; it was the ZADANIA tabs) | yes | yes | arrow only | main.gd `quest_pin` (`_on_quest_picked`) |
| Main line | gold star in a breathing glow | registry MAIN `main:star` (`MainLine.map_marks`); goal line `hud.set_main_goal` | yes, same mark | the guide's beacon | `main_line.gd`; today only for the first kebab (`FIRST_JOB_ONLY`) |
| Questline starts | round badge, white "!", the line's own colour | pinned to the rim up to 1.5 km | twice a job icon, with the name | lit column and the waving friend within `BEACON_R` 320 m | registry STORY, owner "stories" (`StoryQuests.map_marks`: name, line, small in `extra`); quest focus `hud.set_quest_focus` |
| Street jobs | small icon per stand, station or depot | yes (registry JOB) | yes, zoomed in | the kebab stands' rings | `jobs.gd` (owner "jobs"), `roundup_job.gd` (owner "roundup", its pins during a run), main.gd `_quest_entries` for the list |
| Ladder and final | the list's RYWALE section: six chips (`ladder.gd` `chips`), the final's line, the night button; the final's start is the main line's star | registry MAIN "rivals:final" (kept, not drawn) | `set_rivals` | the race beacon at Rondo Daszyńskiego | `ladder.gd`, `rivals.gd` |
| Garage | its diamond within reach | registry SERVICE "garage:workshop" | yes | | `garage.gd` |
| THE TAPCZAN (pub) | its beer mug (`POI_MUG`) within reach | registry SERVICE "tapczan:door", shape `POI_MUG`, `extra.name` "THE TAPCZAN" (the full map prints the name; a SERVICE mark may carry a shape and a name) | yes | | `tapczan.gd` |
| Unfound places | "?" | registry PLACE (owner "notebook") | no (F 2026-11-08) | | `notebook.gd` |
| Police and traps | chasers, known traps, edge rooster | yes | | the patrol cars | `police.gd` |
| Districts, landmarks, metro, hospitals | printed silhouettes and names, hospitals only during a rescue | | `set_districts`, map art | | `districts.gd`, `map_icons.gd`, `missions.gd` |

## 2. What changes them

| Situation | What the player sees | Where it is decided |
| --- | --- | --- |
| Free drive | everything above, the main star glowing | default |
| Something runs (job, ride, race, rescue, tour, questline) | **quest focus**: street jobs, garage, "?" and questline badges hide; the main star stays without glow; only the active target is loud | main.gd `_quest_running()` → `stories.focus`, `hud.quest_focus` (`_story_tick`, every 0.25 s) |
| Flying | car quests' markers hide, heli quests always show once taken; questline badges hide | `quest_lines.gd` `shows`, `StoryQuests.marks(defs, focus or flying)` |
| Hours and days | a questline outside its hours is dimmed in WĄTKI and its friend says when to come | each def's `hours`, `days` in `story_quests.gd` |
| Night | minimap night palette; night-only jobs (Leżak depots, courier race) appear | `hud.gd` `_night`, each job's own hours |
| Fresh save | the guide's targets and the main star | `first10.gd`, `main_line.gd` |
| Progress | rungs open, the final appears, places found | `ladder.gd`, `wallet.gd`, `notebook.gd` |

## 3. How to add a marker today

- **A questline** (a friend, a start spot, hours): one `stories.add({...})` block in main.gd
  `_build_stories` with `at`, `colour`, `hours`, `days`, `call`, `meet`, `busy`, `idle`. The badge,
  the beacon, the greeting, the WĄTKI row and quest focus come for free. This is the model to copy.
- **A street job's places, a service, a "?" mark**: an entry in main.gd `_quest_entries` (the
  ZADANIA list) and its marks in the registry: `hud.markers.put_all("<owner>", [{"layer":
  MapMarkers.Layer.JOB, "at": xz, "colour": c, "shape": MapIcons.POI_*}, ...])` (replaces only
  that owner's marks) or `hud.markers.put("<owner>:<key>", layer, xz, colour, shape)` and
  `remove`. The minimap and the full map draw it by the rule table; no new HUD setter.
- **The active target**: an activity of the kit says `set_target(point, person)` (TD-2); main.gd
  `_show_target` picks the one target now and `_put_target` puts it in the registry
  (`markers.set_target`, the TARGET mark `MapMarkers.ACTIVE_TARGET`, both maps' pin), and `hud.set_target` gets its point on the
  screen (the edge arrow and the metres). Outside the kit: a `beacon.gd`, `route_line.gd` +
  `hud.set_minimap_route`, `hud.show_status`, cleared where the activity ends.
- **Its busy state for quest focus**: add it to `_quest_running()` in main.gd (another copy of
  `_free_block`, TD-1).

## 4. The weak spots

1. **Many setters, no registry.** About a dozen `set_minimap_*` and `full_map.set_*` calls, each
   replacing its own list. Two owners of one list overwrote each other. Mended for the job places,
   the garage, the "?" marks and the final (TD-13 step 1), the questlines and the main line's star
   (step 2), the active target's pin on both maps (step 3) and its road route (step 4).
2. **Quest focus has its own busy test.** `_quest_running()` checks six activities and the
   questlines' `busy`; `_free_block()` checks fifteen. They disagree: a Łuber ride or a plain trend delivery blocks new starts in `_free_block()` but does not count for `_quest_running()`.
3. **The active target is set by each activity.** 24 scripts touch the route line or beacon;
   forgetting one clear leaves a stale arrow (PR #637).
4. **Visibility rules live in several places**: quest focus in main.gd, flying in quest_lines.gd,
   hours in each def, night in each job.

## 5. The marker registry (`map_markers.gd`, TD-13, being built)

One pure registry, like `messages.gd` for text. Every mark is declared once; the minimap, the
full map, the 3D beacon, the edge arrow and the ZADANIA / WĄTKI lists only read it.

```gdscript
markers.put("kebab:stand_07", {
	"layer": Markers.JOB,          # TARGET, MAIN, STORY, JOB, PLACE, SERVICE, INFO
	"at": Vector2(x, z),
	"colour": Jobs.COLOUR, "shape": Markers.ICON_KEBAB,
	"line": QuestLines.CAR,        # CAR, HELI, ANY
	"hours": Vector2(10, 23), "days": [],
	"when": func() -> bool: return wallet.jobs_done > 0,   # progress gate, optional
	"list": true,                  # also a row in the ZADANIA tab
})
markers.remove("kebab:stand_07")
markers.set_target("rescue", at, colour)   # the one active target (the objective channel, TD-2)
markers.clear_target("rescue")             # ending the activity clears it, in one call
```

**One rule table** decides what each layer shows, by the context from the activity director
(TD-1: FREE, QUEST, CHASE, FOCUS), the vehicle and the clock:

| Layer | FREE | QUEST | CHASE | Flying |
| --- | --- | --- | --- | --- |
| TARGET | loud | loud | loud | if its line allows |
| MAIN | glow | no glow | hidden | glow |
| STORY | badge (full map: always, dimmed in QUEST) | hidden (full map: shown) | hidden | hidden (full map: shown) |
| JOB, PLACE | icon | hidden | hidden | heli jobs only |
| SERVICE (garage, hospitals) | in reach | only if the quest needs it | hidden | hidden |
| INFO (police, traps) | yes | yes | yes | yes |

What this gives the next quest lines:

- A new questline or job adds markers with `put`, never a new HUD setter.
- A new situation (an event day, a district unlocked, a tutorial step) is one column or one gate
  in the table, not edits in five scripts.
- The full map and the minimap can't disagree, because they read the same list.
- `check_map_markers.gd` can test every rule without the map (like `check_messages.gd`).

**Order of work.** Build it with TD-1 (it needs the context) and TD-2 (the target is its top layer):
first the registry and the rule table with today's behaviour unchanged, then move the setters one
layer per PR (STORY first, it is already a registry; then JOB; then TARGET), each with before and
after screenshots of the minimap and full map in free drive, a quest and the helicopter.

**As built (F's go 2026-11-15).** Step 1: the registry and the rule table, with the layers that had
plain list setters moved (JOB, PLACE, SERVICE, the final's MAIN mark): it mends the two-writer list
first. Step 2: STORY, the main line's star and quest focus (the context goes into the registry).
Step 3: TARGET, the edge arrow and the full map's pin (main.gd `_show_target`'s chain). Step 4: road
routes, so the arrow and the maps follow the roads for every target, not only the ones that draw a
`route_line.gd` today. Each pull request adds a PHONE-CHECK line for the minimap, the full map and
the arrow.

Step 2 as built: the context has a third column, AIR (flying; quest focus wins over it), which is
how the questline badges hide in the helicopter; each mark carries a `group` (the kind of thing:
"kebab", "sloik", "lezak", "garage", "story", "notebook", "final"; the onboarding plan's one map
list shows a row per group) and an `extra` dictionary (a questline's name, line and small "!");
the rivals have their own layer, RIVAL, drawn nowhere yet (the final's start moved there from
MAIN), for that list.

Step 3 as built: the active target is one TARGET mark, `MapMarkers.ACTIVE_TARGET`, put by main.gd
`_put_target` through `markers.set_target` (every branch of `_show_target` ends there) and drawn by the minimap and the full map
from the registry; `hud.set_minimap_target`, `hud._mini_target` and `full_map.target` are gone, and
the full map's pin is live while it is open instead of a copy made at open. A put that changes
nothing is not a write and a put drops only its own layer's view, so a target put every frame
rebuilds nothing; a moving one (a rival's pin) rebuilds only the TARGET view. The edge arrow and
its metres stay `hud.set_target`: they are a point on the screen, which needs the camera, fed from
the same branch. None is put while the main line's star stands for the target (the guide's first
job), as before.

Step 4 as built: `target_route.gd` gives every target the road route. It reads the registry's
target (`markers.target()`) and the HUD's car (`minimap_car`, `minimap_heading`, `flying`), searches
the lane graph once per goal (a moving goal, a rival's pin, again after 40 m and 3 s; ~6-11 ms a
search on the cloud CPU), walks the line again from the car every second, and puts it in the HUD's
one route slot under the owner "target". An activity that draws its own route (jobs.gd's
deliveries and next stand, the street races, Łuber) wins the slot and this one steps aside. The
full map's dotted line follows the slot's route when it ends at the target, else it stays straight.
In the air there is no road route. The edge arrow still points straight at the target: a road
arrow would change how the drive feels, so it waits for F (QUESTIONS.md).

## 6. Track, filters and "?" marks (F's map ask, 2026-11-16; `map_track.gd`)

**2026-11-17 (F: "too complicated"):** the full map is minimal now. The legend and its filters, the
title, the right-hand list, the ≡ and ? cards, the always-on hint and the metro icons are gone; the
questlines' dots and names show in every context (dimmed in quest focus; STORY's rule row above); a
dot tapped shows its line with ROUTE (its start becomes the pin) and DETAILS. What to do lives on the
QUESTS screen (big button bottom right; quest_book.gd builds it from main.gd `_fill_map_list`'s
facts, quests_screen.gd draws it), whose SHOW ON MAP is the track below. The NEXT line (top left)
leads with the tracked place, else the nearest First step, else the main line's next step, else a
questline that invited. The Filters paragraph below is history.

Three things on the full map, all on the registry and the existing quest pin, none a private copy.

- **Track.** The tracked thing is the quest pin (main.gd `quest_pin`, full_map.gd `quest_pick`): a tap
  on a place's row, on a "?" (TRACK) or a rival's call-out pins it, a second tap lets it go. Nothing
  new feeds the map: `_show_target` already puts the pin as the registry's TARGET mark, so the glowing
  pin, the edge arrow and target_route.gd's road line follow it. What is added: the pin is kept in the
  save's [intro] as one `track_<id>` key (`quest_pin`'s setter, `MapTrack.pin` and `save_to`; no
  wallet version change; places only, a rival's moving pin and a request are not kept) and found
  again from the list or the "?" places (`_restore_track`, from `_story_tick`, up to `MapTrack.TRIES`);
  the full map draws a gold ring round it and the NEXT card leads with it (head TRACKED, a tap lets it
  go); a tracked row wears a ◆.
- **Filters.** The legend's rows are the kinds in `MapTrack.KINDS`, each a set of marks' `group`
  (main, story, side = lezak + boat, kebab, station = sloik, garage) or the metro's map icon. A tap
  hides that kind on the full map only (`full_map._hidden`, session only, never saved); each row says
  "n/total" (n counts what the rule table shows now, 0 when hidden); ALL shows every kind. The
  TARGET mark, the quest pin and the car are not in any kind and never hide.
- **"?" marks.** A new layer, `UNKNOWN` (the end of the enum, rule: full map in FREE and AIR only,
  never the minimap), group "unknown", owner "unknown", put by main.gd `_fill_map_list` from
  `MapTrack.unknown_marks`: a First step not ticked whose place nothing else shows. Only the steps
  with a fixed place (`MapTrack.PLACED`: the garage until its diamond shows, the cassette on the BUW
  roof for the helicopter step). A tap shows the step's teaser (dialogue.json first_steps
  `unknown_<id>`) and a TRACK button; ticking the step takes the "?" away at the next open.

| Layer | FREE | QUEST | CHASE | Flying |
| --- | --- | --- | --- | --- |
| UNKNOWN (full map only) | "?" | hidden | hidden | "?" |

Checks: `check_map_track` (the save key, finding it again, the "?" rules), `check_hud` (the minimal
map's parts, the "?" tap and TRACK, a dot's ROUTE and DETAILS, the QUESTS screen's layout and flows,
the coach marks, no overlaps at six screen sizes), `check_quest_book` (the tabs), `check_map_markers` (the rule row)
and `check_target_route` (the route follows a tracked place and goes when it is let go).
