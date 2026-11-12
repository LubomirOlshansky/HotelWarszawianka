- During a bar crawl no delivery job starts until the night is over, and no other call comes while the crawl's last card is still up.

## Backlog
- fixed: architecture TD-1, the bar crawl is the third activity on the kit (`bar_crawl.gd` extends `activity.gd`): its own state machine, card listener, two beacons, `busy()`, `drive_player` and its three places in main.gd's "is the player busy?" tests are gone; proved against the old script over 38,636 frames before it was replaced
- fixed: the kit grew what the crawl needed and the next activities will use: `_refused` (the call or the offer turned down or not answered), a card that closes by itself, a status line's own tint, a ring beside the target, and no offer when there is nowhere to meet
- fixed: `check_bar_crawl` only read the data and the rules; it now plays a whole crawl (the call, the offer, the pickup, the stays, the mood, the lines, the pay, out of time, the ✕) against the shared stand-ins
- fixed: `check_bar_crawl` ran only in a local `tools/verify.sh` (the step `crawl` was in no CI group); it has its line in `tools/ci_steps.txt` now (quick)
- found: 12 activities still carry their own state machine (`shisha`, `ev_tow`, `rave`, `missions`, `boat_race`, `rivals`, `street_meet`, and the jobs family: `jobs` with `courier_race` and `roundup_job`, `rides`, `trend_job`); each moves to the kit in its own pull request (tech-debt TD-1)

## Roadmap
- added: "Activity kit: the bar crawl on it (F, 2026-11-12, architecture plan step 2; tech-debt TD-1)": ticked, `bar_crawl.gd` is an activity of the kit (verify steps `crawl`, `crawl-run`); 3 of 15 activities moved
