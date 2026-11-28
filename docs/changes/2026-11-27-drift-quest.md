- New side quest, Bokiem na Narodowym: after your first night meet Darek calls with a drift event inside the National Stadium. Lena's warm-up lap first, then qualifying (try as often as you like until you beat the cut), then a tandem final against Hrabia: lead him, then chase him close without touching. Win it for 800 zł, respect and the neon "Bokiem" paint; lose it and the rematch starts at the final. After the win "Bokiem: trening" stays in your quests with your best score.

## Backlog
- found: Hrabia's needle is 41.5° (the spec said 44°): with no chase help for the player's bot (a thumb has none), a decent bot player wins 7, draws 2 and loses 7 of 16 seeded finals at 41.5°, 4 of 16 at 43°, 11 at 41°; his pace on the phone is for F to judge (PHONE-CHECK 15zzdrift3)
- fixed (review): a parked leader skipped run 2 (Hrabia capped behind a stopped car scored nothing; parking won 13 of 16): past 1.5 s at a crawl he drives his solo lap; T4b holds it
- fixed (review): a chase was all or nothing (a held touch fired a second KONTAKT a second later and dropped the whole pile): a touch pushes the chaser back to 0.5 m under the leader's speed, the next counts only after the cars were apart, and the second and later cost half the pile; no KONTAKT in Hrabia's over-hold or a second after the leader brakes hard
- fixed (review): a won quest came back after a reload (its name and Darek's pitch were read before the save), the consolation money paid on every loss and every WYJDŹ (now once ever), the win paid only on ODBIERZ (now on the result card), ✕ on the drive silenced Darek for the session, BANKED over the result card, PONÓW shown in the final, the warm-up's unscored pile number
- found: the tandem's KONTAKT box test and the 0.5-4 m BLISKO band are tuned against bot drivers only; a real thumb may find the chase too tight or too loose
- found: the drift event has no own sounds yet (the call is the friend-call ring; KONTAKT, UCIEKASZ! and PREZENT! are silent), as the stadium's flame and crowd sounds before it
- found: sector_streamer.gd `_drop_task` waits for the worker with an unbounded `wait_to_finish` (lines 858-868): on the runtime city build the quest run hangs for good a few seconds after the bot's car is put at the gate (2 of 2 runs; 3 of 3 on the prebuilt city finish), the worker asleep on a lock inside the sector build; for the streamer's owner. The CI step runs `--prebuilt`; the quest has no end-to-end run on the runtime city (QUESTIONS)
- found: the garage card holds two rows of paints; the "Bokiem" prize shows only once won, then the row is six across, so each name has less room (ellipsis on long names)
- found: main.gd STORY_BLURBS has no room under the `_build_*` ratchet; the event sets its own map blurb (drift_tracks.json "blurb")

## Roadmap
- ticked: "Side quest: Bokiem na Narodowym (grey box in; the stadium's look, then the event)": the event is in; the phone pass (PHONE-CHECK 15zzdrift3) is what is left
