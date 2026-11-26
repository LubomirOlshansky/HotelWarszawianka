# TD-4 (b): each activity wires itself

The spec the review of TD-4 (a2) asked for before (b) starts (its points C2 and C4): it comes
before the rest of TD-1, item 4 of the second plans review's order
(`docs/design/tech-plans-review-2.md`, section 10), because both edit main.gd's wiring and busy
tests. Measured on main f54df999, 2026-11-15, and read against the code by a second reviewer, whose
eleven findings are built in. Row TD-4 in `docs/architecture/tech-debt.md`.

## 1. Why

- `main.gd` is 7,314 lines, held under 7,464 by step `architecture`. 1,823 of them are its 35
  `_build_*` functions.
- The 14 joins of the activity kit (13 scripts; the two tours share one) are wired there by hand:
  about 460 lines that set the same fields on each one (`hud`, `wallet`, `map`, `graph`, ...), 7 of
  the 18 copies of the "where is the player, how fast, in the air?" lambda, about 80 lines that read
  its test flags, and its test start a second into the drive.
- So a lane that adds an activity edits main.gd in three places: the field, a new build function
  and its call in `_build_world`. This is a large part of why main.gd changes in so many merges.

## 2. The mechanism

- **`game_ctx.gd`**, a small RefCounted with typed fields: what an activity may use from the game.
  - Services: `world`, `data`, `flags`, `activities`, `hud`, `dialogue`, `bubbles`, `wallet`, `map`,
    `graph`, `traffic`, `police`, `radio`, `city_sounds`, `tod`, `weather`, `life`, `crowds`,
    `heli`, `car`, `cam`, and the activities that others still name by field today (`jobs`,
    `rides`, `rivals`).
  - Functions, one copy each of today's lambdas, made as lambdas in `_build_ctx` (so main.gd gains no
    functions for them): `vehicle()` (position, km/h, flying, forward speed), `hour()` (the local
    clock's hour), `life_hour()` (`life.hour_now()`, 12 without life: the tours and the boat race),
    `focus()`, `seen(p)`, `focus_at(p)` (the camera's focus, for the test starts), `take_off()`.
  - The list is not closed: a pull request adds what its activity needs, under a name that says
    what it is (the meet's `ground_mat`, the round-up's `storefronts`, the city life's places for
    the trend job).
  - It holds no reference to main.gd itself (not `m`, the a2 review's rule).
- **`_build_ctx()`** in main.gd fills it from main's fields just before each activity is installed,
  so each one sees what exists at its place in the build, as today (`traffic` is null with
  `--no-traffic`, `police` with `--no-police`). It is wiring, so its lines count as `_build_*`.
- **`activity.gd`** gains three methods.
  - `install(ctx) -> bool`, before the activity is in the tree: it copies what it needs into its
    own fields, reads its own flags from `ctx.flags`, and returns false when it is off (`--crawl=0`,
    no traffic). It does not keep the ctx. The base sets only `hud`, `wallet` and `map`: all 12 that
    are wired by field get those today, and main.gd never sets them again; the rescue line gets
    them through its own `setup`.
  - `setup_in(ctx)`: `setup(ctx.world)` by default. The street races give `setup(world, data)`,
    which carries their finishes and the Trzy mosty route.
  - `joined(ctx)`, after the join: the lines that run after `activities.add` today. That is the
    wiring that must follow `setup` (the rave's `--rave-spot`, which `setup` would overwrite;
    `jobs.clear_stands`; the races' `preset_ladder`; the boat race's mark among the jobs' places)
    and the test starts made at the join (the same timers: one second for most, two for the
    shisha's "hold"). A test start moves `ctx.car` with the same lines as today and sets the
    camera's focus with `ctx.focus_at`, and the constants it uses move with it (`SHISHA_HOLD_S`).
    In a release build the flags keep their defaults, so the test starts do nothing.
  - The fields stay public, so the 22 checks that build an activity by hand do not change.
- **main.gd** gains `_install(a, parent, index := -1)` (`install`, the child under `parent`, the
  world or main.gd, at `index` when given, then `setup_in`) and `_add(a, world_test := Callable())`
  (`activities.add(a, world_test)`, then `joined`). `world_test` is the activity's own test for
  everything outside the kit, as `activities.add`'s second argument today: the EV tow's
  `_ev_free`, the round-up's, and the "yes" of the five that keep their own rules. `_join` does
  both. In `_build_world` an activity is then one line at its place today:
  `crawl = _join(BarCrawl.new(), world)`.

**Rules**
- No field gets a value it does not have today. What differs is each activity's own line in its
  `install`: `autopilot` stays off for the rave, the meet and the EV tow, and is on for
  `--boat-race=auto` and a tour's "auto"; `car` stays unset for the rave, the shisha, the crawl and
  the EV tow; `dialogue` for the crawl and the street races.
- The join order stays. It decides who gets M and K, the ✕, the arrow and the stop assist (the
  rescue line last). The parents, indices and setup order stay too: they set the order of the
  frames, and two setups connect to the car's `bumped` in turn.
- main.gd's hooks into its own rooms and camera stay main.gd's lines right after the join:
  `rave.enter_club`, `shisha.enter_lounge`, `trend_job.enter_padel`, the meet's `place_car` (it
  also turns the car and cuts the camera, so it stays the meet's hook and is not a test helper),
  the boat ride's two signals. A test start that drives one of main.gd's rooms (the rave's `club`
  and `patio`, the shisha's `lounge` and `terrace`) stays in main.gd with them.
- The test starts that run later in `_build_world` stay where they are, as one chain: after
  `_build_garage`, the rescue line's start or `close`, then the kebab, the słoiki or a ride (one
  `elif` chain: one start per run), then the races' starts. They decide what a run begins with and
  depend on everything built before them; moving them is TD-4 (a)'s leftover, not this.

## 3. What moves, in order: one pull request per activity

| PR | Activity | Today in main.gd | Lines out, about | Notes |
| --- | --- | --- | --- | --- |
| b1 | the ctx, `install`, `setup_in`, `joined`, `_install`, `_add`, `_join`; **the bar crawl** as the pilot | `_build_crawl` | 27 | the smallest: one reference outside its build (the car's `bumped`) |
| b2 | the EV tow | `_build_ev_tow`, `_ev_start` | 52 | `_ev_free` stays: it tests main's own state (TD-1) |
| b3 | the night racing club | `_build_meet` | 32 | `ground_mat` in the ctx; `place_car` stays its hook |
| b4 | the raves | `_build_rave` | 35 | the club's room and its two test starts stay |
| b5 | the boat race | `_build_boat_race` | 43 | the boat ride's signals stay |
| b6 | the tours (Kino, Dekalog) | `_build_tours`, `_build_tour` | 53 | one script, two joins |
| b7 | the shisha night | `_build_shisha` | 65 | the lounge's room and its two test starts stay |
| b8 | Łuber and the deliveries, together | `_build_side_jobs` | 56 | they set up in one order (the deliveries first) and join in the other (Łuber first): two `_install`, then two `_add`; `jobs.rides` set in Łuber's `joined` |
| b9 | the trend job | `_build_city_life` | 32 | the padel, egg and Spacer hooks stay; `jobs.trend` in its `joined` |
| b10 | the round-up | `_build_storefronts` | 27 | at the index before `jobs.gd`; `jobs.roundup` in its `joined` |
| b11 | the street races | `_build_life` | 20 | `setup_in` with the map data; their test starts stay in the chain |
| b12 | the rescue line | `_build_world` | 7 | `_install` early (its `setup` waits, and its wallet, lines and anchor follow it), `_add` last, as today |

About 450 lines leave `_build_*` and about 70 come back (the joins, the hooks that stay,
`_build_ctx`). After b12: `main.gd` about 6,950 lines, `_build_*` about 1,450, `flags.` reads about
450. b1 adds four functions to main.gd (`_build_ctx`, `_install`, `_add`, `_join`) and removes one, inside
the band of 258.

## 4. The proof, in every pull request (a2's way: old against new)

1. **The proof's test patch**, put on both sides and never committed (as TD-4 (a1)'s flags dump,
   kept in the project files with the tools). It seeds every activity's dice (ten of them call
   `randomize()` in `setup`, and four have no seed of their own), so two runs of the same code print
   the same: a control run, old against old, shows it first.
2. **The wiring dump**, printed by that patch after the build: every joined activity in the
   director's order, with its parent and index and every script field (values; objects by node
   path or class; Callables by method, the pure ones called in two states: the car at the spawn by
   day, the helicopter at night); every signal connection of the activities and of the shared
   services (the car, the HUD, the helicopter, the traffic), in order, with the target's class and
   method; and the fields of the other objects the moved block writes today, which the pull request
   names (`jobs.boat_spot`, the jobs' place marks, `cam_focus`). It is taken in a plain run and under
   each of the activity's test flags, because a line that sets a default shows only under its flag.
   Both sides give the same dump, except lines the pull request lists (a lambda in main.gd that
   became a method of the activity, as the crawl's `on_bump`).
3. **Whole-game runs** with the same patch, under each test flag of the moved activity, its log on,
   `--fixed-fps 60`: the same log on both sides. And one run with only `--nosave` on both sides
   (a2's condition: the path a tester's launch takes).
4. **Breaks:** each line of the new `install` and `joined` taken out once; the dump or a check
   catches each.
5. The activity's own check and steps `activity`, `devflags`, `architecture` and `boot` pass.

## 5. The measures

- Each pull request lowers the bands it moves (`main.gd`'s lines, functions, `_build_*` lines and
  `flags.` reads) to its new numbers, as the ratchets' rule says (tech-debt.md, "What is clean
  today").
- b1 adds one exact ratchet to step `architecture`: **`activities.add` outside `_add`**, the call
  sites still wired by hand: 12 after b1 (the two tours share one), 0 after b12.

## 6. What stays, and the target

"Under 6,000 lines" (tech-debt.md, the measures) is not reached by this alone. After b12 main.gd
still has:
- the city's own systems, wired the same way: the storefronts, the crowds, the packs, the fans,
  the buses, the old tram, the event day, the crash scenes and the rest (11 of the 18 lambda
  copies, about 900 lines of `_build_*` outside `_build_world`). They can take the same ctx as a
  **phase 2**, decided with phase 1's numbers;
- the questlines' wiring (`_build_stories`, 125 lines, which names the rave, the meet, the tours
  and the EV tow), and the busy tests and cross-questions (`_free_block`, `_ev_free`,
  `_quest_now`, `_show_target`): TD-1's end;
- what TD-4 (a) left: about 450 flag reads, the chain of test starts, test branches inside game
  functions.

## 7. Collisions

- This collides with any lane that adds an activity or changes one's wiring. None is open on
  2026-11-15.
- Each pull request first checks the open ones that touch its activity's build, as the ratchets
  pull request did.
- From b1, extending.md's "A new activity" row says: the script's `install(ctx)` (and `joined`
  for what follows its setup) and one `_join` line in `_build_world`, no build function of its own.

## 8. Open questions (each with the default)

1. **Where the test starts made at the join live.** Default: in the activity's `joined`, beside
   what they start. The other way: in the test harness, which would then load for every activity's
   test flag.
2. **The checks.** Default: they keep building activities by hand. Later they can build one
   through `install` with a ctx of fakes (TD-11's `fakes.gd`), the same path as the game.
3. **Phase 2**, the city's systems: decided after b12, with its numbers.
