# Map markers: what the minimap and the full map show, and when

Every mark the player can see on the minimap, the full map and in the 3D world, the situations
that change them, how it is wired today, and the planned marker registry that the next quest lines
should grow into. Design background: docs/design/quest-map.md and docs/design/main-line.md.

## 1. The layers today (loudest first)

| Layer | Looks like | Minimap | Full map | In the world | Owner and setter |
| --- | --- | --- | --- | --- | --- |
| Active target | glowing, pulsing pin in the quest's colour, edge arrow, metres, dotted route | yes (`active_pin`, `set_minimap_target`, `set_minimap_route`) | yes, with a dotted line from the car | `beacon.gd` ring and light column | each activity sets its own (missions, jobs, rides, rivals, tours, boat race...) |
| Picked place | the same pin, for a place tapped in the ZADANIA list | yes | yes | arrow only | main.gd `quest_pin` (`_on_quest_picked`) |
| Main line | gold star in a breathing glow | yes (`main_star`) | yes (`set_main_line`) | the guide's beacon | `main_line.gd`; today only for the first kebab (`FIRST_JOB_ONLY`) |
| Questline starts | round badge, white "!", the line's own colour | pinned to the rim up to 1.5 km | twice a job icon, with the name | lit column and the waving friend within `BEACON_R` 320 m | `story_quests.gd` `marks`, `hud.set_story` / `full_map.set_story` |
| Street jobs | small icon per stand, station or depot | yes (`set_minimap_pois`) | yes | the kebab stands' rings | `jobs.gd`, `roundup_job.gd`, main.gd `_quest_entries` for the list |
| Ladder and final | rival rows, Seba's diamond | `set_minimap_final` | `set_ladder` | the race beacon at Rondo Daszyńskiego | `ladder.gd`, `rivals.gd` |
| Garage | its icon within reach | `set_minimap_garage` | yes | | `garage.gd` |
| Unfound places | "?" | `set_minimap_unknown` | yes | | `notebook.gd` |
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
| Spacer (wander mode) | nothing comes by itself | `spacer.gd` |
| Progress | rungs open, the final appears, places found | `ladder.gd`, `wallet.gd`, `notebook.gd` |

## 3. How to add a marker today

- **A questline** (a friend, a start spot, hours): one `stories.add({...})` block in main.gd
  `_build_stories` with `at`, `colour`, `hours`, `days`, `call`, `meet`, `busy`, `idle`. The badge,
  the beacon, the greeting, the WĄTKI row and quest focus come for free. This is the model to copy.
- **A street job's places**: an entry in main.gd `_quest_entries` (the ZADANIA list) and its icons
  through `hud.set_minimap_pois`. Careful: that setter replaces the whole list, and `jobs.gd` and
  `roundup_job.gd` both write it (TD-13).
- **The active target**: a `beacon.gd`, `hud.set_minimap_target`, `route_line.gd` +
  `hud.set_minimap_route`, `hud.show_status`, and clear every one of them where the activity ends.
- **Its busy state for quest focus**: add it to `_quest_running()` in main.gd (another copy of
  `_free_block`, TD-1).

## 4. The weak spots

1. **Many setters, no registry.** About a dozen `set_minimap_*` and `full_map.set_*` calls, each
   replacing its own list. Two owners of one list overwrite each other.
2. **Quest focus has its own busy test.** `_quest_running()` checks six activities and the
   questlines' `busy`; `_free_block()` checks fifteen. They disagree: a Podwózka ride or a plain trend delivery blocks new starts in `_free_block()` but does not count for `_quest_running()`.
3. **The active target is set by each activity.** 24 scripts touch the route line or beacon;
   forgetting one clear leaves a stale arrow (PR #637).
4. **Visibility rules live in several places**: quest focus in main.gd, flying in quest_lines.gd,
   hours in each def, night in each job.

## 5. The planned marker registry (`map_markers.gd`, TD-13)

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
| STORY | badge | hidden | hidden | hidden |
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
