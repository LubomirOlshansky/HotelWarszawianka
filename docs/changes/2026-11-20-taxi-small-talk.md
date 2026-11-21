- Taxi rides are easier on the eyes: passengers make small talk in smaller bubbles and no longer ask a question to answer while you drive; how the ride went decides the tip.
- The rating falls more slowly during a ride: a crash or hard braking costs less often, lateness counts every 25 seconds, and a ride loses at most 1.5 stars to driving.
- Passengers now say a short funny line when you crash or smash through a fence.
- A new PODWÓZKA tab in QUESTS is the taxi app: what you earned in total, the average fare, your rating, your rides and your best streak.

## Backlog
- fixed: the taxi story question card (two answers, 10 s) was too much to read and choose while driving (F, 2026-11-20); it is off (`Rides.ask_cards`), the stories now end by how the ride went (`Stories.ending`)
- fixed: the live rating fell too fast during a ride (F, 2026-11-20): drive penalties 5 s apart (was 2), at most 1.5 (was 2.0), thresholds 6 m/s bump, 22 m/s² braking, 19 m/s² corner (were 4, 18, 15), lateness half a star per 25 s (was 15), at most 1.0 (was 1.5)
- found: the lifetime taxi earnings are kept for an online leaderboard (`keep.podwozka_earned`, `podwozka_best`, `podwozka_best_streak`; `Rules.account` is the row); the leaderboard itself (server, nickname, anti-cheat, privacy) is not built: add "Online taxi leaderboard" to the backlog
- found: the 26 stories' `ask`, `answers.say` and `reply` texts are not shown any more; their tips and outros still are. A pass could cut the stories' lines to 40 characters or fold the question into the third line

## Roadmap
- ticked: "Side jobs: Podwózka stories" stays; added: "Online taxi leaderboard (after the beta)"
