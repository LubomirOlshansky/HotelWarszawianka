# Dekalog na kółkach · Decalogue on wheels

F's ask, 2026-11-07: a visitor comes to Warsaw and wants to be driven round the places where
Krzysztof Kieślowski filmed, ending on the Muranów estate where most of the *Dekalog* and *A Short
Film About Love* were shot. Script `game/scripts/dekalog_tour.gd`, check `check_dekalog_tour.gd`
(verify step `dekalog`), lines `dekalog_claire` in `game/data/dialogue.json`.

## Sources

The places come from mapadekalogu.pl (a map of the series' 25 locations) and the Filmweb thread on
*A Short Film About Love*: the estate is the Inflancka / Stawki complex, main block **Dzika 6**
(between Inflancka and Dzika), used in episodes I, IV and VI (Tomek and Magda live in neighbouring
blocks; Magda's flat interior was shot elsewhere). Across Inflancka is **Ośrodek Sportowy Inflancka 8**,
the pools F meant by "the centre of Muranów with the pools". Off our map (not in the tour): the Gocław
lake (I), the Ursynów church (I), the airport (IV), Józefów station (VII), Bródno hospital (IX), the
Northern Cemetery (X).

## The tour

Claire, a film student from Lyon writing her thesis on the *Dekalog* (fictional), phones between
16:00 and 23:30 (ODBIERZ, JADĘ). Pickup on Aleje Jerozolimskie by Warszawa Centralna (III, IX: her
train). Then six stops, each a KADR card in our own words (no quotes from the films):

| # | Stop | Episode | Shot on the leg there |
| --- | --- | --- | --- |
| 1 | Noakowskiego 12, the courtyard shrine | VIII | quiet: no hit on the whole leg |
| 2 | Plac Trzech Krzyży, St Alexander's | III | rush: arrive within 150 s |
| 3 | The University gate, Krakowskie Przedmieście 26/28 | VIII | long take: 15 s at 5-40 km/h |
| 4 | The taxi rank by the Hotel Europejski | V | static: stand 5 s |
| 5 | The café, Krakowskie Przedmieście 27 | VI | none (200 m) |
| 6 | The estate on Inflancka, Dzika 6 and Inflancka 15 | I, IV, VI | the W-Z tunnel under Plac Zamkowy (III) |

The last card asks her question ("would you watch through a telescope or knock?") with two
answers; her reply, tomorrow's plan (the Inflancka pool, then a candle at Powązki) and the pay.
Pay *guess*: 260 zł - 15 zł a hit (at most six) + 25 zł a shot, 70 respect - 6 a hit. The ✕ drops it.
Flags: `--dekalog` / `=call`, `=go`, `=auto`, `=0`, `--dekalog-log`.

Tone: affectionate, a little Franglais, respectful about episode V (the death penalty) and the
grave at Powązki (mentioned, not modelled).

## What waits for F's photos

The estate (Dzika 6, Inflancka 11/15/19, Dzika 19/23, Stawki 6/8, Dzika 4A, Stawki 4A, the yards)
and the Inflancka pools are today OSM boxes and nothing. F's photo list:
`/mnt/project-files/kieslowski/KIESLOWSKI-PHOTOS-NEEDED.txt` (rows K01-K19; photos go to
`~/Documents/warsaw-kieslowski-photos/` on the Mac). Then: the estate as a landmark site (the
14-storey slabs with their balcony rhythm, lit windows at night, the sightline from Dzika 6 to
Inflancka 15), the pools (summer basins, the paddling pool, slides, the indoor hall), Noakowskiego 12's
courtyard shrine, the café front at Krakowskie Przedmieście 27, and St Alexander's portico.

## Quest map

After PR #504 (quest map and starts) merges: one `stories.add` block in `main.gd` `_build_stories`
for "Dekalog na kółkach" (start at Centralna, colour `DekalogTour.COLOUR`), and a `meet()` for an
in-person start.
