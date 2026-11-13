# Extending the game: where each change goes

Read this before adding anything. Each row names the one owner. If the owner is marked
**planned**, it doesn't exist yet: do what the "Until then" column says, so the change is easy to
move later, and don't build a third private copy.

## The table

| You are adding | Plug into | Don't |
| --- | --- | --- |
| A line of text on the HUD (toast, ticker, note) | `hud.toast` / `ticker` / `show_note` with a priority from `messages.gd` (PR #652: AMBIENT, RADIO, INFO, QUEST_LINE, ALERT) | own cooldown or own "is the player busy" test |
| A speech bubble | `bubbles.say` (QUEST), `say_reaction`, `say_ambient`; police use the POLICE class | a timer that decides when a character may talk |
| An incoming phone call | `hud.call_ok()` before ringing (PR #652), `messages.call_rang()` when it rings (`show_call` and an ODBIERZ card record it themselves) (the rescue line too: missions.gd waits at zero until it may ring) | ringing from your own timer without asking |
| Dialogue words | `game/data/dialogue.json` (Polish and English pair), read with `dialogue.line(group, tag)`; branching scenes in Dialogue Manager (skill `dialogue-scenes`) | text inside code |
| A new activity (quest, job, race mode, tour) | **the Activity kit** (TD-1): a script that `extends "res://scripts/activity.gd"`, gives the words (`_call_card`, `_offer_card`) and the play (`_begin`, `_run_tick`, `_card_pressed`), and uses `set_target`, `show_card`, `status`, `finish` and `drop`. Optional hooks: `_tick` (every frame, in every phase: a timer of its own for the next call), `_refused` (the call or the offer was turned down or not answered), `_ended`. A card can close by itself (`show_card(..., life)`: that counts as a press of its first button, unless the script gives its own `_card_expired()`, as the rave does for a bouncer nobody answered), a status line can take its own tint and a badge beside its title (`status(..., tint, badge)`: the place in the street meet's race, "3/9"), the arrow can say its own words in place of the metres (`target_label(metres)`: "???" on the way to the rave's meeting point), and the ring can stand beside the target (`set_target(point, person, ring_at, radius)`: a kerb's ring while the arrow leads to the road). A second ring that is not the target is `set_mark(at, radius, tint)` (a door to see from down the street; `clear_target` and the end take it down), a card's buttons go one under the other with `show_card(..., life, true)`, and a card takes a colour of its own with `show_card(..., life, stacked, tint)` (the marina's card, the red of a lost race). On a card of the run the autopilot presses the button `_auto_button()` names (the first unless the script says another; -1: none). One the player flies, or leaves the car for, sets `flown` (its arrow shows in the air, and the stop assist and the autopilot's car leave its target alone); one whose own things lead the player takes the arrow down with `target_arrow()` (the boat race's rings on the water: the minimap keeps the dot); and one that starts without a call calls `start()` itself (a job the player pulls into gives its own `_idle_tick` in place of the call's clock, as the round-up does). A side job sets `is_job` (while the first minutes' guide runs its target is the main line's, and the other jobs are not told the player is away on a tour) and, for cards at the bottom of the screen, `cards_low`; one whose request is a card beside the road as the player drives past (ACCEPT / SKIP) sets `offer_busy` off, so it is on only once it is taken (the trend job), shows what it says at the end beside the road too with `show_side_card(...)` (its buttons one under the other with the last argument), and gives a caller a face that is not under their name with `_call_card`'s "face". One whose drive goes on under its cards sets `cards_hold` off (Podwózka: the passenger's question on the way, the result card that goes once the car moves on): `_run_tick` runs under the card and the ✕ still ends the run; it takes a card down without a press with `close_card()` (the door reached before the answer). One that drives the autopilot's car itself on a test run gives `drive_player()` (true: the car was driven this frame; main.gd asks the activity whose target is up, after the races). One with small pictures beside its status line gives them to `status(..., icons)` (the kebab's heat, the jars that are whole). One whose cards take the M and K keys (the pad's A and X) gives `primary()` and `secondary()` (true: the key was its own; the director asks every activity in turn, `activities.primary()`, and main.gd goes on to the rescue line's card only after the last). A side job is asked through the director (`activities.job_on()`: one of them is on), never by its script's name; one that points the player somewhere outside a run (the deliveries' pointer to the next stand) says so with a question of its own (`pointing()`), which main.gd shows after every activity's target. main.gd builds it and calls `activities.add(it)` (with a second argument, its own test for everything outside the kit, only when `world_free` does not fit it: the EV tow may start from the air); a questline also joins with one `stories.add({...})`. Its check takes its stand-ins from `game/tools/fakes.gd`. A new **tour** is no code: a data file `game/data/<id>_tour.json` and one line in `_build_tours` (`check_activity` reads every tour's data and plays it to the pay). A new **race mode** runs its race on **the race session** (`race_session.gd`, `RaceSession`: `course`, `add` each racer, `start`, every frame `advance` and `signals`, 5 Hz `rank`, `turned_back` / `hop_refused`, `end`), as `rivals.gd` and the race bench do; the mode keeps its words, cards and pay | your own `enum State`, call clock, beacon, `hud.card_pressed` listener or free test; a `busy()` added to `_free_block()` (the director answers for the kit). The 2 activities not moved yet (`rivals.gd`, `missions.gd`) keep theirs until their own PR; a race mode's own ranking, effort, plans or legs; a new `jobs.busy()` asked by name for "is a side job on?" (it is the deliveries' own now) |
| When the game offers the next thing | **planned offer pacer** (TD-3). Until then: ask `_free_block()` and `hud.call_ok()`; keep your own timing numbers as named consts at the top of your script | a third unrelated random timer; a new writer of `missions.paused` that doesn't put the old value back |
| A card with buttons | In an activity of the kit: `show_card` (the press comes to `_card_pressed`, and the run's clock stands while it is up). Elsewhere: `hud.show_card` (or `show_side_card`, `show_call`), then `hud.own_card(self)` and a `card_pressed(index)` method: the press comes to you alone (TD-16). A picture on the card (the race result's two routes): any `Control` with its `custom_minimum_size`, handed to `hud.set_card_art(control)` right after `show_card`; the card owns and frees it. A card nobody owns still goes to every listener of the `card_pressed` signal, as the activities not moved yet expect | a new listener of the `card_pressed` signal; `hud.hide_card()` when the card may be somebody else's (ask `hud.card_is(self)`) |
| A questline, a job's places, or anything on the minimap or full map | map-markers.md section 3 (`stories.add` for a questline). **Planned marker registry** (TD-13) | a new `set_minimap_*` setter, or writing a list another script owns |
| A target on the map (arrow, metres, pin, beacon) | In an activity of the kit: `set_target(point, person)` and `clear_target()` (TD-2). main.gd reads `activities.targeted()` for the arrow, the metres, the minimap's dot and the stop assist, and the end of the activity clears it. Outside the kit, until that activity moves: `beacon.gd` for the world marker, `route_line.gd` + `hud.set_minimap_route` for the road route, `hud.show_status` for the card, all cleared in the function that ends it (the #637 bug was a missed `return`) | a beacon or an arrow of your own in an activity of the kit; a new `if x.has_target()` block in main.gd `_show_target` or `_stop_assist` |
| Money, respect, records, anything kept | `wallet.gd`: a key in an existing section, or a new section added to `SECTIONS`; bump `VERSION` and extend `migrate` only when old data changes meaning; add the case to `check_save.gd`; call `wallet.save()` when an event ends (it is a safe write through `safe_file.gd`, about 0.3 ms) | a second save file, your own `ConfigFile`, or `cfg.save()` straight to a path |
| A setting | `settings.gd` (the file) + `settings_panel.gd` (the control) + `access.gd` if it is comfort or accessibility | reading `user://settings.cfg` yourself |
| A sound | a one-shot: a row in `Sfx.SHOTS` (and `SHOT_RULES` for its priority, voice limit and pitch spread), then `sfx.play("name")` or `sfx.play_at("name", at)`; an interface sound: a row in `Sfx.UI`, then `Sfx.ui("name")`; extra takes are `name_2.wav` to `name_4.wav` beside the file. A recorded or generated file (ElevenLabs) goes in with `tools/add_sfx.py` (loop, loudness, `sources.json`); a synth one with `tools/make_sfx.py`. A venue's own music keeps its player on a bus from `Sfx.setup_buses` (Music, SFX, Ambience, Voice) | a private `AudioStreamPlayer` for an effect or interface sound, loading a file under `audio/sfx` or `audio/ui` yourself (`check_sfx` fails on it), a new `AudioServer` bus |
| Turning the radio or a bus down under something (a talk, a venue's music, a voice) | a row in `Sfx.DUCKS` (`sfx.gd`), then `Sfx.duck("name")` and `Sfx.release("name")`, or `Sfx.duck("name", seconds)`; ducks stack, the deepest counts (`check_mixer`) | writing a player's or a bus's level yourself, or saving and restoring the level you found |
| A vibration | `Access.buzz` (goes through `haptics.gd`) | `Input.vibrate_handheld` directly |
| An AI car or group of people | city-ai.md section 7 | a node per car, a new person material |
| Something solid the car hits (a collider) | in `map_builder.gd`: `_solid(class, faces)` with a class of `solidity.gd` (the list is `game/data/object_palette.json`; a new class is a row there); a script's own `StaticBody3D` in the city: `set_meta("solid", class)`. `check_solids` compares the classes on both city paths | faces added to a body or an array of your own without a class; a class name that is not in the palette |
| A building, landmark or prop | `landmarks.gd`, `models.gd`, `props.gd` and the skill `model-from-photos`; the map bake for data (skill `bake-map`) | geometry added to only one city path |
| A window, balcony, ledge, cornice, column, pediment or wall colour on a landmark | the facade kit: a `kit_*` part and a `PAL_*` colour of `facade_kit.gd` (docs/design/facade-kit.md); a new style goes into the kit | a private `_xx_window` helper or a one-off hex colour (`tools/check_facade_kit.py` fails the first) |
| Something drawn every frame, a light, a material, a shader | graphics.md, then report bench before and after | a new shader without `check_shader_budget` |
| A quality-dependent extra | a field in `tiers.gd` and, if it costs CPU, a step in `governor.gd` | `if OS.get_model_name() ...` in a feature |
| A place's dressing (furniture, signs, standing people, a small structure at one spot) | a script that `extends "res://scripts/place.gd"` and overrides `build()` (reads `map` and `ctx`), plus one row in `Places.TABLE` (`places.gd`) with its triangle budget (`tris`) and how many draw items of its own it may add (`own`, 0 for a purely poured place). Static meshes go through `pour(mesh, shadows)`: places.gd merges them into one mesh per sector, so the dressing costs one draw call per sector however many places stand in it. A mesh with its own material, a mover or a StaticBody3D goes through `part(node)`. `check_place_scripts.gd` holds the budget, the own count and the mesh defects (ratchet `KNOWN`) | a `_build_x` hook or a `preload` in main.gd; a `MeshInstance3D` of your own in the actors' material; a visibility range in metres (the camera is orthographic, decisions.md) |
| A setup step at load | a `_build_x(world)` in main.gd followed by `await LoadYield.tick("_build_x")` (a place is not one: it is a row in `Places.TABLE`, built by `_build_places`) | long work in one frame |
| Something the title shows or the first frame needs | `title.gd` (or `boot.gd`), using only the scripts on `check_boot.gd`'s `BOOT_SCRIPTS` list; a script it needs only later is loaded at that moment (the title's start sound: `load(SFX)` when the title goes, then `ui("start")`) | a `preload` of a game script from `boot.gd`, `title.gd`, `settings.gd`, `lang.gd` or `error_trap.gd`: it is loaded before the title can show, and with it everything it preloads (`check_boot` fails) |
| A pause | main.gd's `_pause` (`pause_reasons.gd`, TD-20): a new reason gets a name there, main.gd calls `_pause.hold(reason)` when the thing goes up and `_pause.release(reason)` when it goes; a system asks through a callable or signal main.gd gives it (the garage's `opened` / `closed`) | writing `get_tree().paused` anywhere (step `pause` fails); letting go of someone else's reason |
| Something that can fail (a missing file, a bad value) | `push_error` or `push_warning` naming the script, then a safe default. The error trap (`error_trap.gd`) keeps the line for a debug run's report, and the checks fail on it in the log | failing silently; an `assert` (only a debug build runs it); leaving it to the engine to report a null or a missing key (a release build does not, TD-21) |
| What the game was doing when an error came | one more field in the context line `main.gd` `_trap_frame` gives the trap once a second | a log file of your own |
| A test flag | parsed in `main.gd` `_parse_args`, noted in the archive's flags table; release builds ignore it (`release.gd`) | a flag read anywhere else |
| Rules or numbers worth testing | a pure static script (like `ride_rules.gd`, `upgrades.gd`) and a `game/tools/check_*.gd` that prints `<name>: OK`, joined to `tools/verify.sh` | logic only reachable from a running scene |
| A check's stand-in for the HUD, the dialogue, the bubbles (and the wallet, the rescue calls, a flat map, a car) | `game/tools/fakes.gd` (TD-11): `Fakes.Hud.new()`, `Fakes.Dialogue.new()`, `Fakes.Bubbles.new()`; they remember what they are given (toasts, notes, cards, lines, in both languages) and answer what the check sets (`say_words`, `line_words`, `ok`). What only one check needs goes into a small class in that check that `extends Fakes.Hud` (or the others). When the game's function gets a new argument, the stand-in gets it in the same change | a class of the check's own with `toast`, `show_card`, `say` and the like (step `fakes` fails); a stand-in's function that takes other arguments than the game's (the same step) |
| A new script file | a row in systems.md or city-ai.md (`check_architecture` fails otherwise) | |

## The shape of a new system

```gdscript
## What it is and why, the ask and date, the design doc.
extends Node3D

const Rides := preload("res://scripts/rides.gd")   # in main.gd

## Set by main.gd before setup(); never looked up by path.
var hud: Node
var wallet: Wallet
var free_now: Callable          # main.gd decides if anything else runs

func setup(world: Node3D) -> void: ...   # build once, cheap
func busy() -> bool: ...                 # true while it owns the player
func _process(dt: float) -> void: ...    # thin; decisions at 5-10 Hz
```

In main.gd: a `const` preload, a `var`, a `_build_x` that sets the references and calls `setup`,
a `LoadYield.tick`, and a test flag if needed. An activity takes its shape from the kit instead
(`activity.gd`, the first row for it above): it joins the director, and nothing is added to
`_free_block`.

## Extending the facade kit

The kit (`facade_kit.gd`, docs/design/facade-kit.md) is meant to grow. When a landmark needs a
facade element the kit lacks:

1. **A new part or style goes into the kit, in the landmark's own PR**: a `kit_*` function, or a
   value in `Win`, `Balcony`, `Attic` or `Order`. Its arguments are where, how big and which
   colours; its proportions are fixed inside it. Never a private helper in `landmarks.gd`
   (verify step `facadekit` fails it).
2. **Add it to `kit_sampler()`** so `check_mesh_quality` examines it (z-fighting, floating
   parts, normals), raise the sampler's budget on purpose, and **describe it in
   docs/design/facade-kit.md** (the check fails when the kit and the doc disagree).
3. **Prove nothing else moved**: `site_dump.gd` before and after, `tools/site_parity.py`; every
   site but the landmark's own must be `same`.
4. **A colour**: a building's own measured colour is a named constant of that building. A colour
   a second building needs joins the palette (`PAL_*`, the kit and the doc's table together).

These are decisions, not routine edits, so they go to the Opus or Fable session and to F's look:
changing a proportion of an existing part or a palette value (it moves every landmark that uses
it: before and after shots of each), and any look that would need the building shader (it has no
budget; decisions.md).

A Sonnet `object-modeler` uses the kit and escalates when a part is missing; the session that
wrote the spec adds the style.

## When the owner can't do it

1. Extend the owner in the same PR, with its check script, if the change is small.
2. Otherwise build the smallest workaround, mark it `# WORKAROUND(arch): <why>, see tech-debt TD-n`,
   and add or update the row in [tech-debt.md](tech-debt.md).
3. Say it in the PR under "Architecture": used owner X / added workaround TD-n.
