# For app developers: game words in app words

You know iOS apps. Here is the same idea in Godot terms, and where this game does it.

| In an app | In this game (Godot 4) | Where |
| --- | --- | --- |
| `UIApplication` run loop, events drive work | **The game loop**: the engine calls `_process(dt)` on every node about 60 times a second, events or not. Work there costs every frame | `main.gd` `_process` |
| View hierarchy | **Scene tree** of nodes (`Node3D` for the world, `Control` / `CanvasLayer` for the HUD) | `main.tscn` has one node; `main.gd` builds the rest |
| Launch screen, then the first view controller | **The boot scene**: `boot.tscn` shows the title while the game's scripts load on a thread, then the game's scene (`main.tscn`) takes its place | `boot.gd`, pipelines.md section 2 |
| App delegate / composition root | `main.gd`: creates every system and injects its dependencies | systems.md section 1 |
| Delegate, closure, Combine publisher | **Signal** (`signal changed(...)`, `.connect(fn)`) or an injected `Callable` | `wallet.changed`, `car.bumped`, `hud.card_pressed` |
| Singleton (`.shared`) | **Autoload**. This game avoids them: one only (the camera add-on) | project.godot `[autoload]` |
| Model layer, pure logic | Static or pure scripts with no nodes (`ride_rules.gd`, `messages.gd`) | tested by `game/tools/check_*.gd` |
| Unit tests (XCTest) | `check_*.gd` scripts run headless, print `name: OK` | `tools/verify.sh` |
| UI tests | Headless game runs with flags, screenshots, Autopilot | pipelines.md section 4 |
| `UserDefaults` / Codable file | `ConfigFile` in `user://` | `wallet.gd`, `settings.gd` |
| Core Data migration | `wallet.gd` `VERSION` + `migrate` | pipelines.md section 3 |
| Localizable.strings | Text pairs (Polish, English) in `game/data/*.json`; `lang.gd` picks one | skill `warsaw-tone` |
| Feature flags / launch arguments | Test flags parsed in `main.gd`; release builds ignore them | `release.gd` |
| Main thread must not block | Same: a long load yields frames (`LoadYield.tick`); a frame over 16 ms is a visible stutter | `load_yield.gd` |
| Table view cell reuse | **Pooling**: a fixed pool of cars or people, reused as they leave the view | `traffic.gd`, `pedestrians.gd` |
| Drawing many views cheaply | **MultiMesh**: thousands of copies in one draw call, each with its own colour | graphics.md section 5 |
| Rendering cost | **Draw calls** (how many separate things the GPU is told to draw) matter most on phones, more than triangle counts | graphics.md section 4 |
| Notification centre for the user | The HUD message queue: SHOW, DEFER or DROP by context and priority | `messages.gd` |
| A coordinator or router (who shows what screen) | The activity director (`activities.gd`): which activity is on, who may start. `_free_block` in main.gd still answers for the activities not moved to the kit | systems.md section 4, tech-debt TD-1 |
| A base view controller (the shared life cycle, subclasses fill in the content) | `activity.gd`: the call, the offer, the run, its cards and target, and one clean-up when it ends | systems.md section 4 |
| A delegate (the tapped button tells one object) | The card's owner: `hud.own_card(self)`, and the press comes to that object alone | tech-debt TD-16 |
| Backend data | Map data baked offline from OpenStreetMap and GUGiK into JSON and binary files | pipelines.md section 1 |

## Game-only ideas worth knowing

- **Frame budget.** At 60 fps everything (scripts, physics, render) shares 16.6 ms. Per-frame
  code is the expensive kind; decisions at 5-10 Hz or on timers are cheap.
- **Things exist only near the camera.** Traffic and people spawn and vanish out of view; the city
  streams in 512 m sectors. Nothing far away is simulated.
- **Fake it where you can.** AI cars ride on lanes instead of real physics; only the cars nearest
  the player get colliders. The player can't tell, and it costs a fraction.
- **Context decides what the player sees.** A quiet drive, a quest, a chase and a scripted moment
  each allow different noise (`messages.gd` contexts). New features should ask the context, not
  assume they may talk.
- **Juice.** Small feedback (sparks, "+54 zł", a buzz, a camera nudge) makes actions feel good.
  It lives in one place per kind (`crash_fx.gd`, `money_pop.gd`, `haptics.gd`).
