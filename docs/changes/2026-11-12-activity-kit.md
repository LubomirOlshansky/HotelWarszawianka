## Backlog
- fixed: architecture TD-1's first step, the activity kit: `activity.gd` (the base class: the call, the offer, the run, its own cards, the target, the ✕ and one end that takes down what it put up) and `activities.gd` (the director: which activity is on, who may start, where it sends the player); the Kino and Dekalog tours, two near copies of 479 and 541 lines, are one `tour.gd` and two data files (`game/data/kino_tour.json`, `dekalog_tour.json`), proved against the old scripts frame by frame before those were removed; a new tour is a data file
- fixed: architecture TD-16, cards have an owner: `hud.own_card(owner)`, and a card's press goes to that owner only (a card nobody owns still goes to every listener, so the other activities move one at a time)
- fixed: architecture TD-2 inside the kit: `set_target` is the one place an activity of the kit sets its beacon, arrow, metres, minimap dot and stop assist, and its end clears them
- found: 13 activities still carry their own state machine (`roundup_job`, `courier_race`, `shisha`, `bar_crawl`, `missions`, `ev_tow`, `rave`, `jobs`, `boat_race`, `rides`, `trend_job`, `rivals`, `street_meet`); each moves to the kit in its own pull request (tech-debt TD-1)

## Roadmap
- added: "Activity kit (F, 2026-11-12, architecture plan step 2; tech-debt TD-1, TD-2, TD-16)": ticked, the base class, the director and the card's owner are built and the two tours run on them (`activity.gd`, `activities.gd`, `tour.gd`, verify step `activity`); the other 13 activities follow one per pull request
