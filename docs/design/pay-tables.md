# Pay tables: the designer pass (2026-11-01)

The ROADMAP v1.0 item "designer pass over the guide's lines, Halina's lines, the end card, the pay
tables". Nobody has played the economy end to end yet, so this is a desk model, not a playtest:
each activity's pay from its code, its time from the distances it picks at Łuber's 9 m/s
(`ride_rules.gd` SPEED) plus a fixed overhead for pickups and cards. F's timed run on the phone
replaces these numbers.

## The model (złoty and respect a minute)

| Activity (assumed trip) | zł | respect | time | zł/min | respect/min |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kebab (950 m, hot 80 % of the time) | 42 | 8 | 2:30 | 17 | 3 |
| Słoiki, 4 of 6 jars (0.8 km to the station + 1.7 km) | 190 → **160** | 0 | 5:20 | 36 → **30** | 0 |
| Słoiki, all 6 jars | 260 → **220** | 30 | 5:20 | 49 → **42** | 6 |
| Łuber, 5★ (375 m to the pickup + 1.55 km) | 51 | 25 | 4:15 | 12 | 6 |
| Rescue (2.5 km, 20 s to spare) | 86 | 40 | 5:10 | 17 | 8 |
| Na czasie (1 km) | 43 | 15 | 3:05 | 14 | 5 |
| Round-up (10 Leżaks) | 120 | 40 | 5:00 | 24 | 8 |
| Race, Halina, first win (1.2 km + the way to her) | 60 | 100 | 4:10 | 14 | 24 |
| Race, Halina, rematch | 60 | 100 → **20** | 4:10 | 14 | 24 → **5** |
| Race, Mike, rematch | 300 | 100 → **20** | 4:10 | 72 | 24 → **5** |

Bold: what this pass changed. Everything else stays.

## What changed and why

1. **A rematch gives +20 respect, not +100** (`Ladder.REMATCH_GAIN`, `Ladder.race_gain`). The
   ladder's gates (0/100/220/340/480/640, the final 850; docs/design/main-line.md) assume six
   first wins and about 250 respect from everything else. A rematch paid the full +100, so
   re-racing Halina was ~24 respect a minute, three to eight times any job, and walked past every
   gate without seeing the city. At +20 a rematch sits with the jobs (5 a minute): a fair choice,
   not a shortcut. The stake is still paid every time (money only buys paints). The final's
   rematches give +20 too (nothing is gated after it).
2. **Słoiki pay 40 zł + 30 zł a whole jar** (was 50 + 35; `jobs.gd` SLOIK_BASE, SLOIK_PER_JAR).
   It was about twice a kebab's złoty a minute; a fragile load deserves a premium, now ~1.8× with
   four jars and ~2.5× with all six, not 2-3×.

## What stayed, on purpose

- **Łuber earns the least złoty (12 a minute) but the most respect of the short jobs.** That
  is its identity (the rating, the streak); left as it is.
- **The hour.** Respect from things you find while driving (districts +10 each, notebook cards,
  eggs, cassettes, the guide's own rescue and kebab) is roughly 100 in the first 20 minutes, so
  about 150 more comes from jobs at 5-8 a minute: ~25 minutes. With the guide (10), five more races
  (~20) and the final (10-15), the main line lands at **60-75 minutes**, as main-line.md
  estimated. If F's run is over 75, lower the last two gates (640 and 850) first.
- **Prices.** The eight paints cost 1,630 zł in all; the main line alone pays ~1,400 zł (920 in
  stakes, 500 for the final) plus the jobs, so a player who finishes it can buy most of them.
- **The end card's "10 jobs"** stay every paid job kind but races and the courier bonus
  (QUESTIONS 2026-10-31): the card thanks you for working the city, and counting only kebabs would
  push a player who prefers rescues or rides into ten kebabs at the end.

## The words in the same pass

- Player-neutral Polish (as the passengers' lines already are, parodies.md): Halina says
  "dziecko" instead of "synku"/"dobry chłopak" (her "blade jesteś i wolne" agrees with it); Seba's
  "byś mnie nie dogonił" became "nikt mnie nie dogoni"; "Poddałeś wyścig/finał" became "Wyścig
  poddany"/"Finał poddany"; the final's "KRÓL NOCNEJ WARSZAWY" became "KORONA NOCNEJ WARSZAWY
  TWOJA!"; the police's first-contact "nic pan nie zrobił" became "wszystko w porządku. Na razie."
- The end card's free-roam line no longer claims "everything unlocked" (the paints still cost money);
  it points at the Syrenki and the cassettes, with the comma Polish needs
  ("jedź, dokąd chcesz").
- The guide: the first toast gets its full stop; "A time tape" became "A KASETA" in English.
- The trap's roosters line was already there (police.dialogue, first contact: "Koguty na dachu
  to my. Koguty w lusterku — też my."), so DEMO 6.2's beat is met.
- Not changed: the other rivals' voices ("mordo", "szefie", "ziomek" are how those characters
  talk to anyone), the police's "pan" outside the first contact (BACKLOG).
