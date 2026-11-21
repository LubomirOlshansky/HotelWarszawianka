- The opening flight no longer shows models popping in: "tap to drive" now waits until every part of the city the flight looks at is loaded, and the flight starts lower and closer, as it did before the morning opening.

## Backlog
- fixed: #911's first key (140 m up, 520 m view) showed about 9-10 sectors while the title only waited for the 4 round the start, so 5-6 sectors were far-away proxies at the flight's start; the title now waits for the flight's own views (`expect_shot` over `CameraShots.open_samples`), and the first key is 100 m up, 400 m
- found: the far-sector proxies (sector_proxies.gd) have no night look, so any that still show stand out against the lit city; the preload makes this moot for the opening, not for a fast night drive
- found: only the phone can show the extra loading time (about 1-2 s on a fresh save, estimated) and whether the first frames are clean (PHONE-CHECK line 1a)
- open (F's call): a shorter flight than 12 s, with the host's line retimed

## Roadmap
- added and ticked: "Opening flight: no models popping in (preload the flight's sectors, lower first key; F, 2026-11-19; phone check open)"
