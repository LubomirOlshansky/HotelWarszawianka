- During Ivan's shisha night no delivery job starts until he is home, and no other call comes while his offer or the night's last card is up.

## Backlog
- fixed: architecture TD-1, the shisha night is the fourth activity on the kit (`shisha.gd` extends `activity.gd`): its own state machine, card listener, two beacons, `busy()`, free test (`_shisha_free`) and its places in main.gd's "is the player busy?" tests and target display are gone; proved against the old script over 29,268 frames before it was replaced
- fixed: the kit grew what the night needed: a second ring that is not the target (`set_mark`, the gold ring at the lounge's door) and stacked buttons on a card
- fixed: `check_shisha` only read the data, the rules and the map; it now plays four nights (the call, the offer, the pickups, the entrance, inside, the way home, the pay, leaving early, the ✕) against the shared stand-ins
- fixed: `check_shisha` ran only in a local `tools/verify.sh` (the step `shisha` was in no CI group); it has its line in `tools/ci_steps.txt` now (quick)
- fixed: the evening inside the lounge now counts as a quest for the HUD's messages (the radio host and notes wait); before, that held only while the status line was up
- found: 11 activities still carry their own state machine (`ev_tow`, `rave`, `missions`, `boat_race`, `rivals`, `street_meet`, and the jobs family: `jobs` with `courier_race` and `roundup_job`, `rides`, `trend_job`); each moves to the kit in its own pull request (tech-debt TD-1)

## Roadmap
- added: "Activity kit: the shisha night on it (F, 2026-11-12, architecture plan step 2; tech-debt TD-1)": ticked, `shisha.gd` is an activity of the kit (verify steps `shisha`, `shisha-run`); 4 of 15 activities moved
