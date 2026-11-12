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
| A new activity (quest, job, race mode, tour) | a script with `busy()`, `setup(world)`, injected `hud`, `wallet`, `dialogue`, `map`, `car`, `vehicle`, `clock`, `free_now`; a questline joins with one `stories.add({...})` in main.gd | **planned Activity kit** (TD-1: the base class `activity.gd` and the director). Until then: keep the states and method names of a small existing activity (`kino_tour.gd`: `setup`, `busy`, `ring`, `start`, `_quit`, `_reset`) so it ports in one step, and add its `busy()` to `_free_block()` in main.gd, and nowhere else |
| When the game offers the next thing | **planned offer pacer** (TD-3). Until then: ask `_free_block()` and `hud.call_ok()`; keep your own timing numbers as named consts at the top of your script | a third unrelated random timer; a new writer of `missions.paused` that doesn't put the old value back |
| A card with buttons | `hud.show_card` and the `card_pressed` signal, which every listener hears: act only when your own state says the card is yours | **planned card owner** (TD-16). Reacting to `card_pressed` without checking your state |
| A questline, a job's places, or anything on the minimap or full map | map-markers.md section 3 (`stories.add` for a questline). **Planned marker registry** (TD-13) | a new `set_minimap_*` setter, or writing a list another script owns |
| A target on the map (arrow, metres, pin, beacon) | `beacon.gd` for the world marker, `route_line.gd` + `hud.set_minimap_route` for the road route, `hud.show_status` for the card | **planned target in the Activity kit** (TD-2). Until then: clear everything you set in the same function that ends the activity (the #637 bug was a missed `return`) |
| Money, respect, records, anything kept | `wallet.gd`: a key in an existing section, or a new section added to `SECTIONS`; bump `VERSION` and extend `migrate` only when old data changes meaning; add the case to `check_save.gd`; call `wallet.save()` when an event ends (it is a safe write through `safe_file.gd`, about 0.3 ms) | a second save file, your own `ConfigFile`, or `cfg.save()` straight to a path |
| A setting | `settings.gd` (the file) + `settings_panel.gd` (the control) + `access.gd` if it is comfort or accessibility | reading `user://settings.cfg` yourself |
| A sound | a one-shot: a row in `Sfx.SHOTS` (and `SHOT_RULES` for its priority, voice limit and pitch spread), then `sfx.play("name")` or `sfx.play_at("name", at)`; an interface sound: a row in `Sfx.UI`, then `Sfx.ui("name")`; extra takes are `name_2.wav` to `name_4.wav` beside the file. A recorded or generated file (ElevenLabs) goes in with `tools/add_sfx.py` (loop, loudness, `sources.json`); a synth one with `tools/make_sfx.py`. A venue's own music keeps its player on a bus from `Sfx.setup_buses` (Music, SFX, Ambience, Voice) | a private `AudioStreamPlayer` for an effect or interface sound, loading a file under `audio/sfx` or `audio/ui` yourself (`check_sfx` fails on it), a new `AudioServer` bus |
| Turning the radio or a bus down under something (a talk, a venue's music, a voice) | a row in `Sfx.DUCKS` (`sfx.gd`), then `Sfx.duck("name")` and `Sfx.release("name")`, or `Sfx.duck("name", seconds)`; ducks stack, the deepest counts (`check_mixer`) | writing a player's or a bus's level yourself, or saving and restoring the level you found |
| A vibration | `Access.buzz` (goes through `haptics.gd`) | `Input.vibrate_handheld` directly |
| An AI car or group of people | city-ai.md section 7 | a node per car, a new person material |
| A building, landmark or prop | `landmarks.gd`, `models.gd`, `props.gd` and the skill `model-from-photos`; the map bake for data (skill `bake-map`) | geometry added to only one city path |
| Something drawn every frame, a light, a material, a shader | graphics.md, then report bench before and after | a new shader without `check_shader_budget` |
| A quality-dependent extra | a field in `tiers.gd` and, if it costs CPU, a step in `governor.gd` | `if OS.get_model_name() ...` in a feature |
| A setup step at load | a `_build_x(world)` in main.gd followed by `await LoadYield.tick("_build_x")` | long work in one frame |
| Something the title shows or the first frame needs | `title.gd` (or `boot.gd`), using only the scripts on `check_boot.gd`'s `BOOT_SCRIPTS` list; a script it needs only later is loaded at that moment (the title's start sound: `load(SFX)` when the title goes, then `ui("start")`) | a `preload` of a game script from `boot.gd`, `title.gd`, `settings.gd`, `lang.gd` or `error_trap.gd`: it is loaded before the title can show, and with it everything it preloads (`check_boot` fails) |
| A pause | only main.gd sets `get_tree().paused`; a system asks through a callable or signal main.gd gives it (TD-20) | pausing the tree from a system |
| Something that can fail (a missing file, a bad value) | `push_error` or `push_warning` naming the script, then a safe default. The error trap (`error_trap.gd`) keeps the line for a debug run's report, and the checks fail on it in the log | failing silently; an `assert` (only a debug build runs it); leaving it to the engine to report a null or a missing key (a release build does not, TD-21) |
| What the game was doing when an error came | one more field in the context line `main.gd` `_trap_frame` gives the trap once a second | a log file of your own |
| A test flag | parsed in `main.gd` `_parse_args`, noted in the archive's flags table; release builds ignore it (`release.gd`) | a flag read anywhere else |
| Rules or numbers worth testing | a pure static script (like `ride_rules.gd`, `upgrades.gd`) and a `game/tools/check_*.gd` that prints `<name>: OK`, joined to `tools/verify.sh` | logic only reachable from a running scene |
| A new script file | a row in systems.md or city-ai.md (`check_architecture` fails otherwise) | |

## The shape of a new system

```gdscript
## What it is and why, the ask and date, the design doc.
extends Node3D

const KinoTour := preload("res://scripts/kino_tour.gd")   # in main.gd

## Set by main.gd before setup(); never looked up by path.
var hud: Node
var wallet: Wallet
var free_now: Callable          # main.gd decides if anything else runs

func setup(world: Node3D) -> void: ...   # build once, cheap
func busy() -> bool: ...                 # true while it owns the player
func _process(dt: float) -> void: ...    # thin; decisions at 5-10 Hz
```

In main.gd: a `const` preload, a `var`, a `_build_x` that sets the references and calls `setup`,
a `LoadYield.tick`, a test flag if needed, and the `busy()` in `_free_block`.

## When the owner can't do it

1. Extend the owner in the same PR, with its check script, if the change is small.
2. Otherwise build the smallest workaround, mark it `# WORKAROUND(arch): <why>, see tech-debt TD-n`,
   and add or update the row in [tech-debt.md](tech-debt.md).
3. Say it in the PR under "Architecture": used owner X / added workaround TD-n.
