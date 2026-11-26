# The story: Doba w Warszawie · 24 hours in Warsaw

F's ask (2026-11-26): make the story from the five quests (six since 2026-11-27, with Smoła); keep the garage and the bar as visits,
the side jobs as the grind and the rivals as their own track; First Steps becomes bonuses. This
page is the design summary in the repo. The long working papers (research, the plans, Fable's
two critiques, the plane document) are in the project files under `story-structure/`.

Code: `game/scripts/story_arc.gd` (chapters, pure), `game/scripts/napkin.gd` (the list),
`game/scripts/time_of_day.gd` `held` + `game_time.gd` `held_for` (the clock). Checks:
`check_story_arc`, `check_napkin`, `check_game_time`.

## The layers

| Layer | What | Rule |
| --- | --- | --- |
| **Story** | six chapters, one game day, one friend and one vehicle each | one friend rings at a time; the gold star points at the next chapter |
| **Side questlines** | Kawowy rajd, the cinema tour, Dekalog na kółkach, the secret rave, the shisha night (hidden) | "!" badges; calls only after chapter 2 or 15 min of play |
| **Hubs** | Mirek's garage, THE TAPCZAN, the Smoła room, the lounge | always open, never a chapter |
| **Jobs** | deliveries, słoiki, rides, rescues, round-ups, trend orders | the grind; request cards after chapter 2 or 15 min |
| **Rivals** | The Six and Trzy mosty | their own track and end card, unchanged |
| **The napkin (LISTA)** | 14 places where Warsaw lives | the one to-do list, first page of MOJA WARSZAWA |
| **Collections** | notebook places, eggs, then cards, Kadr spots, Syrenki, cassettes | unchanged, pages after the napkin |
| **Bonusy** | First Steps | kept; its list stops showing after chapter 1 |

## The six chapters (data/story_arc.json)

F 2026-11-26 named five; on 2026-11-27 F added Smoła ("a strong quest"), so it leaves the side questlines and comes between the night meet and dawn.

| # | Chapter | Friend | Story hour | Vehicle |
| --- | --- | --- | --- | --- |
| 1 | Tajny klient | Kebabulo | 12:00 | car |
| 2 | Padel na Desce | Kuba | 16:00 | on foot |
| 3 | Stanęło TESŁO | Bartek | 19:30 | helicopter |
| 4 | Nocny spot | Darek | 22:00 | race |
| 5 | Smoła | Mati | 23:30 | the club (Za deckami inside) |
| 6 | Wiślana Szprotka | Szymek | 06:30 | boat |

- **Gates are calls, never doors.** Every chapter can be played at any time from QUESTS or its
  spot, in any order. The order only says which friend rings next.
- **No skip button.** Losing still finishes a chapter (silver); winning makes it gold. A chapter
  is never replayed by a call (F's missions rule, 2026-11-25), only by the player's choice.
- **Done** comes from the save: `qdone_<id>` (activity.gd `finish`). An old save counts the night
  meet and the boat by their job counts, never TESŁO (strangers' tows count there too) or padel
  (paid as "trend") or Smoła (paid as "rave" with the secret rave). Chapter 1 is done at the Tajny klient's stage 3, or, on a save that never saw
  it, at the old guide's end or any job. `qseen_<id>` makes an old save's chapters count once,
  quietly, with no rewards.

## The clock

The game day runs at 30x. Inside a story chapter or a side questline the clock runs at real time
(`pacing.json` `time.hold_speed`, 1; 3 if real time feels frozen on the phone), so a night quest
stays night. It is a flag (`time_of_day.gd` `held`), not a write to `speed`, so Promo mode's
speeds come back untouched, and Promo mode turns the hold off. Jobs, rides, rival races and
rescues keep 30x: an active player's day must not stop.

Phase 3 adds: no chapter starts close to its closing hour (one shared rule), and DALEJ on the
CO DALEJ card jumps to the next chapter's story hour ("Kilka godzin później…"). Chapter 1 never
jumps the clock.

## The napkin (data/napkin.json)

Kebabulo hands over a napkin after chapter 1: "zanim powiesz, że jesteś stąd" (before you say
you're from here). F (2026-11-26): places where Warsaw lives, not tourist sights: bars, cinemas,
the steps, a coffee rave, matcha, vinyl, a 3 a.m. kebab. On screen only the parody names from
places.json; no song lyrics.

Each line is ticked once by being there at its hour (stop 3 s, or a slow pass), through egg_book.gd's
own trigger code. A tick: +5 respect, a "LISTA n/14" note with a friend's joke, the save keeps the
real date. Phase 1 ticks the nine wide-hour lines; the five narrow ones (the dawn bar, the empty
square at 2:00, the 3 a.m. kebab, the club street at night, the cinema) wait for Phase 2's
off-hours card, which offers the jump to the line's hour.

## Phases

1. **Foundations (this PR):** story_arc, the napkin's nine lines, the clock hold.
2. **On screen** (after the phone hub and QUESTS PRs merge): the LISTA page, the buy and
   off-hours cards, the QUESTS story section, the phone slot.
3. **The flow:** the CO DALEJ card, the call queue (one friend per 5 min, 90 s quiet after a
   chapter), the near-closing rule, the gold star.
4. **The city answers:** radio and passer-by lines after chapter 1, the 6/6 end card "EKIPA W
   KOMPLECIE", the napkin's 14/14 ("No. Jesteś stąd" and a paint), the napkin hand-over at the
   kebab buy (a hook asked of the Tajny klient thread).
