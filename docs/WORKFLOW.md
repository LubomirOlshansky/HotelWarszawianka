# How the work is run

Around Warsaw is made by one person and a set of AI agents (Claude Code). This page says how
the work moves from an idea or a complaint from the phone to a change that is verified and
written down. The rules every session follows are in `CLAUDE.md`; the agents and skills are
in `.claude/`.

## The loop

Work comes in **loops**: one theme, three to seven items in priority order, done by one agent,
then checked before it is accepted.

```
 the user plays on the iPhone ─► notes, wishes, shots
            ▲                              │
            │                              ▼
   report: what changed,          pick the next loop (DEMO.md milestones,
   numbers, "try this on          ROADMAP order, BACKLOG, the notes)
   the phone", Open Questions                 │
            ▲                              ▼
   verify it yourself:            brief: goal, read-first, items, budget,
   verify.sh, shots, bench,       hard constraints, acceptance, report format
   scope, docs                    (.claude/skills/loop-brief)
            ▲                              │
            └──── one agent does it ◄──────┘
                  (measure → change → measure; stop cleanly after a finished item)
```

- **Roads and performance before content.** A feature that breaks the phone's budget or sits
  on a broken road is not done, however good it looks.
- **Prove the cause first.** A brief's suspected cause is checked with a measurement
  (a replay test, a debug render, a bench split) before anything is changed.
- **One writer at a time.** The folder is shared and benches disturb each other; read-only
  reviews (art direction, design proposals) can run beside a writer.
- **The user's phone is the playtest.** Each report ends with what to try on the iPhone and
  what to tell back; those notes become the next loop or BACKLOG lines. From the demo on, add
  outside players: watch them play, don't explain, write down where they hesitate.

## Backlog mode

The user's standing rule (2026-10-30): **the work never stops for a question.** Loops run
one after another, by priority, until the backlog is empty; the procedure is the
backlog-loop skill (`.claude/skills/backlog-loop/SKILL.md`).

- **Next item.** When a loop or a subagent's item finishes, the orchestrator picks the next
  one for that agent at once: the user's latest asks and answered questions, regressions,
  ROADMAP "The road to the 1.0 demo" in order, BACKLOG-TRIAGE, then BACKLOG.
- **When the checklist is done** (F, 2026-11-01): check ROADMAP "v1.0 checklist" for anything
  left to improve. If nothing is, go street by street through the centre: analyse every
  landmark and improve the houses, roads, parks and everything else, with our best approaches
  (photos, the landmark lane, the street details), so the city feels alive and real.
- **Park, don't wait.** A question for the user goes into `docs/QUESTIONS.md` "Waiting" with
  its options and the safe, reversible default that was built; an item with no such default
  is marked blocked and the next item starts. The user gets the parked list in one batch.
- **Lanes.** Several sessions can run (the Mac orchestrator, cloud threads); each holds one
  lane (driving, map, visuals, content, performance, landing, store release), claims it in
  `docs/QUESTIONS.md` "In progress", and checks open PRs and recent main commits first.
- **Merging.** A cloud session merges its own PR once every check is green (the user's yes,
  2026-10-30); never on red, with open review comments, or with a force-push.
- **Still the user's yes**: anything that can't be undone (store submissions, releases, the
  live site, purchases), paid tools or services, device runs not allowed for this loop. Free
  dev tools, data downloads and Godot add-ons are pre-approved (the user, 2026-10-30): install
  them and name each in the PR with its source, size and licence.
- **The end**: every item done, blocked on a parked question, or in another session's lane;
  then one report with what landed, what to try on the phone and the whole parked list.

## Playtesting and the bug log

Free play is tested with **Autopilot** (an AI player in the Godot editor on the Mac; skill
`autopilot-playtest`), by the plan in `docs/PLAYTEST.md`: one area row per run, 10 minutes,
its findings into that file's bug log as `PT-<n>` (suspect → confirmed → fixing → fixed →
verified). The playtest thread only finds, confirms and logs; each confirmed bug (or one
street's small batch) goes to the coordinator, who starts **one fix thread per bug**. A fix
proves the cause first, adds the spot to a check where one fits, and names its PT id in the PR;
the next run of that row verifies it. Runs cost Aura credit: ask the user before more than
three rows at once.

Lessons of the first week (2026-11-02..08, skill section 3): one Autopilot session on the Mac at
a time (`tools/autopilot.sh on <thread>` / `off`, the coordinator keeps the queue); runs under 6
minutes on the latest main; a stop a player could make (lane, kerb, pavement, tram strip) goes
straight to a cloud fix thread, which reproduces it headless in minutes, instead of a second Mac
pass; only a car 10+ m off the road, a traffic bump or a key the harness sent wrong is "harness
only". PT ids come from `/mnt/project-files/autopilot/bug-log.md` first, so two threads never
take the same number. Hunts start on F's word or after a merge train, not on a timer.

## Who owns what

| Area | Agent | Files |
| --- | --- | --- |
| Gameplay, controls, HUD, missions, jobs, police, traffic behaviour, landmarks in code, sound code | `gameplay-dev` | `game/scripts`, `game/shaders`, `game/tools`, `project.godot` |
| Map data, bakes, roads, bridge decks, the lane graph, the demo area's map, city.scn | `map-engineer` | `tools/*.py`, `game/map`, `map_builder.gd`, `chunked_surface.gd` |
| Frame cost, quality levels, budgets, device benches | `perf-engineer` | any code, for cost only; DEVELOPMENT.md "Performance budgets" |
| Design, tuning, jokes, text, 2D art (PixelLab) | `game-designer` | design docs, `game/data`, `game/art` |
| Applying an approved spec to landmarks, facades, signs, props | `object-modeler` (Sonnet) | the named object code |
| Look and readability review | `art-director` | none (read-only) |
| Running checks, shots, device runs, Autopilot playtests (Mac) | `qa-tester` | none in the project; the bug log in `docs/PLAYTEST.md` |
| Lookups, counts, log crunching | `scout` | none |
| Planning, briefs, verification, docs that tie it together, talking to the user | the main session | `CLAUDE.md`, `docs/WORKFLOW.md`, ROADMAP/BACKLOG updates |

## Models: one loop, several tiers

The main session runs on Sonnet by default (Opus only for map geometry, gameplay design, performance and device runs, chosen per thread) and picks a model for every delegation by the kind of
work (the table in CLAUDE.md, "Model routing"): **Opus** decides, **Sonnet** applies what is
already decided, **Haiku** looks things up and counts. A loop is often split that way:

| Loop | Opus | Sonnet | Haiku |
| --- | --- | --- | --- |
| Performance | `perf-engineer` measures, ranks and cuts the costs | | `scout` turns bench and device logs into a before/after table |
| Roads | `map-engineer` finds the defect classes, fixes the bake and writes the exact fix list | `gameplay-dev` applies that list across many files (each change spelled out) | `scout` re-counts the findings over the whole map |
| Police | `game-designer` designs the police; then `gameplay-dev` builds their AI and the feel | `game-designer` or `gameplay-dev` adds the strings and translations from the approved text | `scout` checks `dialogue.json` parses and counts the new lines |
| Landmarks and objects | the lane writes the spec with every value from the reference photos in `refs/` (the model-from-photos skill: detail level L2/L3, identity features, triangle budget); `art-director` scores the matched shots against the photos and accepts | `object-modeler` builds it and renders before/after; escalates what the spec leaves open | `scout` / `Explore` find the functions and OSM ids |
| Any loop's end | the main session verifies; `art-director` judges the shots | `qa-tester` runs `tools/verify.sh` and the shot set | |

A cheaper run that returns Open Questions, fails a gate, overshoots its files or can't be
verified is re-run one tier up with the whole task, not patched. Performance and anything on
the phone never go below Opus. Only the main session spawns agents; an agent that wants a
helper asks for one in its report.

## Review sheet, status page and resumable bakes (from the Isometric Istanbul docs, 2026-11-04)

- **Review sheet.** A look change (roofs, façades, night, signs, a landmark) takes the same fixed
  cameras before and after: `tools/shots.sh --set=... --tag=before` (on main), then `--tag=after`,
  then `python3 -I tools/shot_sheet.py BEFORE_DIR AFTER_DIR`. The PR shows one sheet, and F picks
  from it instead of asking for single shots. Compare different looks the same way: identical
  input, one sheet.
- **Status page.** `python3 -I tools/status_page.py` writes `build/status/index.html`: a map of the
  city with one dot per ranked place (CITY_INVENTORY Part 1) coloured by stage, click for the
  details, the percentages by stage, tier and district, and the ROADMAP v1.0 checklist. It reads the
  repo every time, so a landed place changes its colour once its row in Part 1 does. A row that lands
  without a dot: add its map name to `ALIASES` in that script.
- **Resumable map bake.** `tools/bake_all.sh --resume` skips the steps that already finished after
  a failed or interrupted run (stamps in `build/bake/done/`); a run without it starts clean.

## The documents

| Document | Holds | Updated |
| --- | --- | --- |
| `docs/DEVELOPMENT.md` | a short index; the full reference (controls, flags, map data, bench, **Performance budgets**) is `docs/archive/DEVELOPMENT-full.md`: read a section, never the whole file | a note in the matching section when a flag or behaviour changes |
| `README.md`, `CONTRIBUTING.md` | the public front page (pitch, run, credits) and the contributor rules | when what a visitor needs changes |
| `docs/ROADMAP.md` | the **v1.0 checklist** (done and left), the order of work and the history up to 2026-10-31 | every PR that lands or finds a v1.0 item ticks or adds its checklist line; no progress-log rows |
| `docs/BACKLOG.md` | issues found along the way and decisions taken by default | each item: fixed removed, found added (plus one CHANGELOG.md line for player-visible changes: it feeds /progress/) |
| `docs/QUESTIONS.md` | parked questions for the user (with the default built) and the lanes in progress | when a question is parked or answered, a lane claimed or freed |
| `docs/DEMO.md` | the demo plan: area, quality bar, road defects, police, milestones | when the plan changes |
| `docs/WORKFLOW.md` | this page | when the way of working changes |
| `CREDITS.md` | data and asset licences, add-ons | with every new source, asset kind or add-on |
| `.claude/skills/screenshot-review/art-bible.md` | the art bible | only with the user's agreement |

## Definition of done (a loop item)

Two sizes, picked by the kind of change.

**Light** (content, text, landing/site, docs, object polish, tooling, small fixes that touch no
driving, map geometry or per-frame code):

1. CI **verify** is green (and `tools/verify.sh --only=` for the checks the change touches).
2. A visible change was seen in one phone-size shot (2532x1170).
3. BACKLOG updated (and a CHANGELOG line if player-visible); CREDITS for anything new from outside.

**Full** (gameplay, driving feel, police/AI, map geometry, roads, streaming, anything that runs
per frame or adds geometry, materials or lights, anything for the phone):

1. **It works**: `tools/verify.sh` RESULT: PASS; the item's own checks pass, with numbers. CI
   runs `tools/verify.sh --quick` on Linux for every push to main and pull request
   (`.github/workflows/verify.yml`): a red **verify** on main is fixed before new work.
2. **It was seen**: phone-size screenshots (2868x1320 for HUD work), before and after, on both
   city paths when the map builder changed; art bible for anything visible.
3. **It fits the phone**: bench before/after within the "Performance budgets"; vertices reported.
4. **It ships**: `tools/verify.sh --ios` BUILD SUCCEEDED at the loop's end.
5. **It is written down**: BACKLOG; a note in the archive section for a new flag; CREDITS for anything new from outside.
6. **It is honest**: what only the phone can tell (feel, heat, sound, touch) is named, with what
   the user should try; Open Questions list every default taken.

## Milestone gates

Each gate is a **build that plays on the iPhone**, not a list of tasks. If a gate slips, cut
scope; never skip the testing. The loops in docs/DEMO.md "Milestones" fall into these gates in
order: the roads, performance, HUD and streaming loops make Foundations; the demo data,
structures, landmarks, cars, police, jokes, the demo loop and the juice pass make the Demo; the
device pass makes TestFlight. Open-source publication can happen any time after the demo data.

| Gate | Passes when |
| --- | --- |
| **Foundations** | roads and overpasses in the current map have no known defect class left (checks count zero); the river is off-limits; the default view holds 60 fps on the user's iPhone within the budgets; the HUD is sized for the phone |
| **Demo** (vertical slice) | the demo area from docs/DEMO.md at final quality: every activity (drive, rescues, side jobs, races, police) playable start to finish; the first minute polished; day and night; all text Polish + English; the art bible holds; the user's playtest says it is good, and outside players finish the first ten minutes without help |
| **TestFlight** | no crash or soft-lock in repeated sessions; settings and save survive updates; onboarding; credits and licences checked (OpenStreetMap ODbL, GUGiK); privacy (no tracking); the open-source repo published; a channel for testers' notes |
| **Launch** | the v1.0 device pass from the roadmap (iPhone 13 to current: 60 fps target, memory under 1.5 GB, load under 4 s), App Store assets and metadata, review notes |

Further reading: code.claude.com/docs (subagents, skills, memory, best practices);
docs.godotengine.org (performance, GDScript style guide, static typing).

## Developer console (F, 2026-11-04)

`python3 -I tools/console.py [--watch] [--renders DIR]` writes `build/console/index.html`: the status page's map grown into a
console (overview, city map with layers, area picker and counts, content tables, approvals queue, renders). Details:
`console/README.md`. It reads the same sources as the status page and the wiki, so a PR that changes CITY_INVENTORY,
QUESTIONS, ROADMAP or `game/data` needs nothing extra for the console to follow.
