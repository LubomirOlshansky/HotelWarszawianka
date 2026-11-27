- New side quest, Bokiem na Narodowym: after your first night meet Darek calls with a drift event inside the National Stadium. Lena's warm-up lap first, then qualifying (best of two), then a tandem final against Hrabia: lead him, then chase him close without touching. Win it for 800 zł, respect and the neon "Bokiem" paint; lose it and the rematch starts at the final. After the win "Bokiem: trening" stays in your quests with your best score.

## Backlog
- found: Hrabia's needle is 43° (the spec said 44°): with a bot chaser that brakes inside 3.5 m, a decent bot player wins 2 of 8 seeded finals against 44° and 6 of 8 against 43° (the spec's 4-6); his pace on the phone is for F to judge (PHONE-CHECK 15zzdrift3)
- found: a chase run is all or nothing: the lap is one long chain, so the second KONTAKT drops the whole pile (a bot that brakes only inside 1.5 m banked about 60 points a chase)
- found: the tandem's KONTAKT box test and the 0.5-4 m BLISKO band are tuned against bot drivers only; a real thumb may find the chase too tight or too loose
- found: the drift event has no own sounds yet (the call is the friend-call ring; KONTAKT, UCIEKASZ! and PREZENT! are silent), as the stadium's flame and crowd sounds before it
- found: on the runtime city build the quest run hangs for good a few seconds after the bot's car is put at the gate (2 of 2 runs; 3 of 3 on the prebuilt city finish): the main thread waits in sector_streamer.gd `_drop_task` (from `_load_now`, `update`, main.gd `_stream_frame`) for a worker that sleeps on a lock inside the sector build; not made to happen without the teleport, not fixed here (the streamer's owner); the CI step runs `--prebuilt`
- found: the garage card holds two rows of paints; the "Bokiem" prize shows only once won, then the row is six across, so each name has less room (ellipsis on long names)

## Roadmap
- ticked: "Side quest: Bokiem na Narodowym (grey box in; the stadium's look, then the event)": the event is in; the phone pass (PHONE-CHECK 15zzdrift3) is what is left
