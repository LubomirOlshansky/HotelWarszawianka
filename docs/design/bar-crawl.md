# Bar crawl ("Rajd po barach")

F, 2026-11-04: "quests about a bar crawl: you drive a company through famous bars in Warsaw for a
limited amount of time." First version built 2026-11-07 (`game/scripts/bar_crawl.gd`,
`game/data/bar_crawl.json`, check `game/tools/check_bar_crawl.gd`, verify step `crawl`).

## What the player gets

1. **The call.** At night (20:00-04:00 game clock), with nothing else on, 4-7 minutes into free play
   and then every 20-30 minutes, a group rings: ODBIERZ / ODRZUĆ. The second card names the route,
   its three bars and the clock: JEDZIEMY! / NIE DZIŚ.
2. **The pickup.** The group waits at a kerb 250-600 m away (the dashed amber ring, like Ziomek).
3. **The crawl.** Once they are in, the clock runs. Three bars in a row, each an orange stop ring at
   the kerb nearest the bar's fascia. At the first two the group goes in for a round (15 s): you
   wait at the kerb. The stay counts only within 30 m of the ring. Drive off and the mood drops
   while they stand on the pavement. The third bar is the night's end: they stay there.
4. **The mood** (0-100, starts at 70). A knock (over 2 m/s) costs 7, a hard stop (a drop of over 9
   km/h in a quarter second from over 20 km/h) costs 3, and every 8 s over 15 km/h gives 1 back.
   The status line shows it as a word: szampański / wesoły / tak sobie / ponury.
5. **The end.** All three in time: the group's happy quote, 35 zł a bar, a tip up to 60 zł by mood,
   +40 zł on time, 10 respect a bar and +20 for a happy group (mood 70+). Out of time: "OSTATNIE
   ZAMÓWIENIA", the crawl ends where it is, 35 zł for each bar reached, no tip. ✕ gives up: they walk.

The clock is real seconds: each leg gets its straight distance × 1.6 at 10 m/s plus 20 s, and each
stay is added. A 1.1 km crawl gets about 4.5 minutes; the Klasyczna from a typical pickup about 7.

## The groups (data/bar_crawl.json)

| id | Card | Voice |
| --- | --- | --- |
| panienski | WIECZÓR PANIEŃSKI OLI | the sash, the veil, the maid of honour's list |
| kawalerski | KAWALERSKI MICHAŁA | the groom dressed as a mermaid (the Syrenka) |
| sesja | KONIEC SESJI | students from the Polibuda, a coin whip-round, the resit |
| wdrozenie | ZESPÓŁ PO WDROŻENIU | the team that shipped on a Friday, sprint and stand-up jokes |

Each group has its call, a boarding line, one line per leg, two+ lines going in, coming out and after
a knock, a "late" line under 45 s, and two end quotes. All Polish with English, invented people,
no brands (the check runs the brand denylist).

## The routes (bar_crawl.gd ROUTES)

All bars are the parody fascias already on the map (storefronts.gd), never real names.

| id | Name | Bars |
| --- | --- | --- |
| klasyczna | Klasyczna | KWARTA (Nowogrodzka) → TYGRYS JAZZ (Mazowiecka) → MUZA NA BIS (Wilcza) |
| nad_woda | Nad wodą | SZKIC NOCĄ (Mazowiecka) → Q-BAR POD WIADUKTEM (Powiśle viaduct) → CUDAK NA BULWARZE (the boulevard) |
| odwazni | Dla odważnych | GORĄCZKA PIĄTKOWA (Wilcza) → NEWTWICE (the Party House) → ENKLAWKA (Mazowiecka) |
| praga | Na drugą stronę | SCHRON PIWNY (Nowogrodzka) → ŚWIAT PO PRASKU → POD KUFLEM ZA ROGIEM (Praga) |

A route whose stop has no ground road within 120 m is left out on that map.

## Decided for the first version (park list)

- **Clock:** real seconds, not game minutes (a game minute is too short to drive in).
- **Failing:** a crawl cannot fail outright; out of time still pays for the bars reached.
- **The end:** the last bar, not a drop-off at a hotel (one fewer leg; the group stays out).
- **Not yet:** the "Barowa karta" stamp collection (all four routes), the tip feeding the post-beta
  economy, Fri/Sat-only weighting, street-triggered lines, a phone feel test of the waiting at the
  kerb. These are in BACKLOG "Bar-crawl taxi quests, next steps".

## Add-ons check

Dialogue Manager not used, because the crawl's lines are linear per stop (plain tables, like the
ride stories). Beehave not used: no NPC behaviour, the group rides in the car.

## Flags

`--crawl-call` (the group rings a second in, any hour), `--crawl-route=ID`, `--crawl-group=ID`,
`--crawl=0` (none of it), `--crawl-log` (the `crawl:` lines). With `--autopilot` the call is
answered, accepted and driven.
