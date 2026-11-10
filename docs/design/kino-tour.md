# "Kino objazdowe" · the travelling cinema

F (2026-11-07): a quest about arthouse cinema. A director friend made an abstract film about Warsaw
and asks you to drive him round the central cinemas (Muranów, the Kinoteka, Amondo, maybe one more)
so he can get it screened; on the way he jokes about niche cinema (Gaspar Noé, Enter the Void,
Sorrentino). Design the cinemas too, and say which photos are needed.

Built in `game/scripts/kino_tour.gd`; lines `kino_wiktor` in `game/data/dialogue.json`; Kino
Muranów's model in `landmarks.gd` (spec `docs/landmarks/specs/kino_muranow.md`); checked by
`game/tools/check_kino_tour.gd` (verify step `kinotour`). Flags: `--kino-tour[=call|go|auto|0]`,
`--kino-log`.

## Who

**Wiktor "Mgła" Pustelnik**, a director: a beret, a scarf in the heat, the only 35 mm copy of
**"Warszawa. Wjazd w pustkę"** (3 h 40 min, one take, Rondo Dmowskiego as a pigeon sees it; the
English title "Warsaw. Enter the Roundabout"). Affectionate: he is the butt of his own jokes. The
directors he talks about are parody names only (warsaw-tone): **Gaspar Nojé** (the soul flying over
Tokyo, strobing titles), **Paolo Sorrentello** (beautiful people bored on a terrace), **Béla
Tartak** (seven hours of a cow in the rain), **Lars von Tramwaj** (the dogma), **Wong Kar-Wajs**.
No real film's title, footage or poster; the posters on the cinemas are shapes and colours.

## Flow

1. **The call** (like Szymek's boat race and the night racing club): 14:00-23:00, once the player
   has driven 8 minutes, then every 30 minutes. 📞 WIKTOR DZWONI: ODBIERZ / ODRZUĆ, then
   "Zawieziesz mnie?" JADĘ / NIE DZIŚ.
2. **The pickup** on Plac Zbawiciela (a beacon with a person; stop in the ring).
3. **Four cinemas, south to north**, each a stop in the ring, then a pitch card (the manager's
   answer, his comeback) with JEDZIEMY DALEJ:
   - **Amondo** (Żurawia): "forty seats and one sofa", a no.
   - **Atlantic** (Chmielna; the car stops round the corner on Widok): "we show stories", a no.
   - **Kinoteka** (the Palace; the service road on its west side): "Wednesday 3 a.m., screen 7",
     almost a yes.
   - **Kino Muranów** (Andersa, by the fountain): yes, tonight at 21:00. The end card and the pay.
4. **TAŚMA (the reel)**: five frames; a hit over 3 m/s scratches one (one per 1.2 s). No fail: at
   none left he calls it experimental cinema.
5. **UJĘCIE (the shot)** a leg, optional, +25 zł each: a long take (15 s at 5-40 km/h, a hit
   restarts it), a static shot (5 s standing still), reverse chronology (20 m in reverse), the rush
   (4 s over 60 km/h). The status line shows the reel, the shot and its progress bar.
6. **Banter**: a `kino_wiktor` line every 16-24 s while he rides, tagged lines for the pickup,
   each scratch, the ruined reel and each shot.

## Pay *guess*

220 zł - 20 a lost frame + 25 a shot, 60 respect - 8 a lost frame. The ✕ drops the tour (no pay);
it gives up by itself after 40 minutes.

## Cinemas and photos (the landmarks-photos-only rule)

| Cinema | In the game | Photos |
| --- | --- | --- |
| Kino Muranów | photo build (F's four photos + Mapillary): pavilion, MURANÓW and KINO, posters, terrace, pillars, arch, fountain, café garden and festoons | done |
| Kinoteka | inside the Palace's model; the KINOTEKA marquee | none needed |
| Atlantic | the KINO ATLANTIC marquee (moved onto its OSM point, Chmielna 33) | F's photo of the front for a poster facade |
| Amondo | the map's building only (a marquee there pushed a Frogs shop out of `check_parodies`' range) | F's photo of the entrance, then a small sign |
| Scena Relax (Złota 8) | the SCENA RELAX sign (R1) | a cameo line only |
| Iluzjon | south of the map | - |

## Not built yet (BACKLOG)

The premiere evening as a scene (a queue in berets at Muranów, a short screening cut), a voice for
Wiktor, a notebook card, the posters' parody titles as text, a lasting evening crowd at Muranów.

## On the quest map

The tour is a questline on the quest map (story_quests.gd, docs/design/quest-map.md): its start is
the pickup on Plac Zbawiciela in the tour's red, Wiktor greets the player there in person from 14 to
23 h (`meet` starts the tour; outside the hours he says when to come back), and the questline list
and his phone call start it too.
