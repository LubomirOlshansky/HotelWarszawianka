## Backlog
- found: the plans in flight were reviewed a second time (docs/design/tech-plans-review-2.md); the order from here is in its section 10, in `city-objects-plan.md` section 5.1 and in the order of `tech-debt.md`
- found: main's map cannot be made again from the raw data, also after #778 (28 of 70 keys differ from scratch); with main as the base (F, 2026-11-14) a map change is a guarded pass on main's file and the data is frozen until a re-stamp after the demo (tech-debt TD-25)
- found: with fences hard (the default) every sector rebuilds its fence and hedge colliders on the main thread as it loads; step 8a adds parked cars to it (tech-debt TD-26)
- found: TD-4 (a2) as planned loads the test harness whenever any game flag is passed, and `--nosave` is one, so only a release build would ever run without it; three conditions in `tech-debt.md`'s order
- found: the first review's measuring items were skipped (the sloppy table with `mid` and soft fences; a race and a chase with a player who cuts through); each now names its thread
- found: `landmarks.gd` is 43,134 lines and every church has its own builder: the split (TD-10) goes now, before the plain blocks
- found: 19 verify steps are `local` and nothing records when they last passed on main; they become the build gate (docs/WORKFLOW.md "The build train")
- found: town traffic, walkers, trams and buses still have no plan; a first outline, T0 to T5, in the review's section 7 and `city-ai.md` section 8
- fixed: the phone checks scattered over `QUESTIONS.md`, the plans and thread notes are one list, `docs/PHONE-CHECK.md`

## Roadmap
- added: "Left: the phone": "Build 11 after the Mac build gate; F's sitting with docs/PHONE-CHECK.md"
- added: "Left: a city built for driving": "Hard colliders ready in the sector (TD-26); the car applies every soft cost itself (TD-24); cutting through fences measured in a race and a chase"
- added: "Left: map and roads": "One re-stamp of the map from fresh data after the demo (TD-25)"
