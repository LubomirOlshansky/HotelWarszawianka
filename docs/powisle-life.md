# Powiśle alive: bars, gardens, people (plan, 2026-11-13)

F (2026-11-13): "see our plan for Powiśle, what is done, what is not, what is next, and how to make it
buzz with life: bars in their real places, and so on." This file is the life half of
`docs/powisle-plan.md` (items P6, P7, P8, P9 grown into one lane). Status of everything else is at the top
of that file. Docs only: nothing here is built yet. Names are parodies (CLAUDE.md content rule); the real
places they stand for are in `docs/CITY_INVENTORY.md` under the same street, so a thread can find the
photos and the door.

## 0. Where Powiśle stands for life today (checked 2026-11-13)

- **Signs**: 8 neon shops (`Storefronts.POWISLE`) + the 5 viaduct bars (`VIADUKT`: Q-BAR POD WIADUKTEM,
  WINO POD ŁUKIEM, NITY I KUFLE, BETONIARNIA BISTRO, KAWA PRZY FILARZE). No bar stands on Zajęcza, the
  boulevard, Solec or Aleja 3 Maja yet, although the inventory lists ~25 real ones there.
- **OSM has no bars or cafés in the box** (the baked `pois` hold 261 entries: addresses, scooters, bike docks,
  parks, 10 shops, 3 kebabs). So every bar is placed by hand from a lat/lon, like the `POWISLE` table.
- **People** (`crowds.gd`): the jazz evenings under the saucer, `chill_elektrownia`, 8 `chill_bulwary_*`
  spots (walkers, cyclists, sitters), KEBONAFIDE on Tamka, dog walkers (`city_life.gd`). No queues, no terraces,
  no students, no door staff outside the clubs of vision 4.5.
- **Furniture** is the city average (lamps 220/km², benches 176, bins 53), not above it.

## 1. Rule of the lane

One real place = one parody sign on its real street, at its real side, plus what that kind of place does:
a bar has a door glow, smokers outside, a queue on Friday and Saturday; a garden has tables and umbrellas
from May to September (the game's summer default), empty in rain; a wine bar has candles. Existing
machinery first (`extending.md`): signs through `Storefronts` tables, crowds through `crowds.gd` sites and
`CHILL`/`BULWARY`, sound through `city_sounds`, text through `dialogue.json`. No private copies.

## 2. The bars, by street (parody names; real place per the inventory line of that street)

Positions: a thread reads the door's lat/lon from Mapillary/OSM photos, like the existing tables; "Mac look"
moves doors afterwards. Names are new and checked against `check_parodies` before use.

| Street | Real places (inventory) | Game names (parody) | Kind and what it does |
| --- | --- | --- | --- |
| **Zajęcza** (the bar row by the Elektrownia, 4 bars) | Centrala, Champs, Gatsby, Kakadu Karaoke | CENTRYFUGA · SZAMPION'S · WIELKI GADSBY · KAKAO KARAOKE | the evening crowd: Thu-Sat queue at 2 doors, smokers, taxi pulls up, karaoke voice through the wall at night (laughing singer, one note off) |
| **Wybrzeże, the boulevard** (pavilions and barges) | BarKa, Ivy Lounge, Kalima, Kandela, La Vinotheque, Plac Zabaw nad Wisłą, Schodki, Wir, Wynurzenie | BARKAS · BLUSZCZ LOUNGE · KALMAR · KANDELABR · WINOTEKA · HUŚTAWKA NAD WISŁĄ · STOPNIE · WIREK · ZANURZENIE | the summer machine: deck chairs and string lights, DJ at 20:00, `chill_bulwary_*` spots get their bars as anchors; winter shuttered |
| **Solec** | wine shop and bar, a bar by the little bridge | DZIEDZICTWO WINO · POD MOSTKIEM | quiet wine evenings; pairs at two tables on the pavement |
| **Aleja 3 Maja** | two bars under the Autoreduta side | KARMA KREW · PRZY TRZECH MAJACH | after-work, students, tram noise over their heads |
| **Browarna** | the "Cheers!" corner | NA ZDROWIE! | the small corner bar, door open in summer; beside the existing stairwell bar ALTANA |
| **Smolna** | Burley (Smolna club itself is already a quest site) | BURLEJ | cocktails; ties into the Smolna 38 start (QUESTIONS) |
| **Wioślarska, Idźkowskiego** (north, by the Tides) | four river-side bars | DRZEMKA · PRZYJAŹŃ NAD WISŁĄ · CUD NAD WARTĄ · POD KARŁAMI | rowers' bars: a boathouse crowd, evening beer on the rail (check the box edge: x -100..800) |
| **Ludna** | a snack bar | PRZEKĄSKI U ROMKA | a milk-bar-style hatch, lunch queue of workers |

Also kept: the 8 existing signs and the 5 viaduct bars. With these the Powiśle sign count goes from 13 to ~38,
which meets plan P6's "about 40".

## 3. Summer gardens (ogródki) and the pavement

- **The helper that is missing**: a terrace set (table, 2 or 4 chairs, umbrella) as ONE MultiMesh per cell,
  placed from a list of (street, side, length) per venue, with a summer and a winter variant (winter: stacked
  chairs, no umbrellas, a heater). BACKLOG "Powiśle streets" already says this needs an Opus thread with a
  renderer and full definition of done (draw calls count): target +1 draw call per cell, not per venue.
- Gardens go on: Tamka (STORCZYK and the bistro), Browarna (ALTANA, NA ZDROWIE!), Topiel (BAR TOPIEL),
  Zajęcza (the four bars), Solec (two), Dobra (the café at the library), the boulevard pavilions.
- **Park gardens**: Skwer Kahla, Park Odkrywców, the BUW roof garden get picnic blankets and sitters (the
  `chill_*` machinery with a smaller radius); benches face the right way.
- **Rain and cold**: tables empty and umbrellas stay up in rain; no sitters under 8 °C (the game's season
  default is summer, so this only matters with Live weather).

## 4. People, by time of day (`crowds.gd`, `city_life.gd`)

| When | Where | Who |
| --- | --- | --- |
| 06:30-09:00 | Dobra, the boulevard | runners, dog walkers, cyclists to work; the bakery queue (PIEKARNIA NA POWIŚLU) |
| 09:00-17:00 | Dobra, Lipowa, Oboźna | students with bags between the UW faculties and BUW; sitters on the BUW steps; a lecture break wave at :15 past the hour |
| 12:00-15:00 | Ludna, Tamka | lunch queue at the hatch, office people on terraces |
| 17:00-20:00 | Aleja 3 Maja, Solec | after-work drift to the bars, cyclists with panniers |
| 20:00-02:00 Thu-Sat | Zajęcza, boulevard | queues, smokers at the doors, the boulevard crowd, a taxi stand |
| any | Tamka | KEBONAFIDE (done) and a second recurring character: a busker on the footbridge steps |

All as `crowds.gd` sites with the existing caps and phone budgets; the queue mechanics already exist for the
clubs (`CLUBS`), so Zajęcza's two doors reuse them, with door lines in `dialogue.json` (Polish with English).

## 5. Sound and night

- Bar music through the door by distance (`city_sounds`: a muffled bass for each lit bar, loudest at the door;
  karaoke on Zajęcza; the boulevard's DJ), the viaduct's tram over Aleja 3 Maja. The jazz level on the
  phone is still open (BACKLOG).
- Night (P9, Opus because of the light budget): the bars' windows lit through the existing neon/shop-window
  path (emissive, no new lights), string lights on the boulevard as emissive MultiMesh, the Elektrownia lit
  from inside, sodium vs LED lamp colour per street.

## 6. Lane order (each is one BACKLOG line, one thread, one PR)

1. **L1 Bars and shops, data only** (Sonnet, light DoD): Zajęcza 4, Solec 2, Aleja 3 Maja 2, Browarna, Smolna,
   Ludna, the boulevard's 9; also P6's cafés and shops to ~40 signs. Parody names above; `check_parodies`.
2. **L2 Terrace helper + gardens** (Opus, full DoD with bench): the MultiMesh set, summer/winter, rain.
3. **L3 People schedule** (Sonnet, then Opus review for caps): table in section 4 as crowd sites; Zajęcza queues.
4. **L4 Sound and night glow of the bars** (Opus, lights budget).
5. **L5 Furniture density to 1.5×** (P5) and the park pass (P7), after L2 so the umbrellas do not hide benches.
6. **L6 Mac and phone look pass** (P12, F's yes for the device).

Not duplicated here (other threads run): Powiśle station and the Poniatowski towers, Tamka 2 and the church,
Wybrzeże Kościuszkowskie 41 and the ASP, Elektrownia Powiśle with life (the yard, the lift, the food hall, its
crowd and night look). L1 and L3 wait for that last thread to merge for the Elektrownia's own spots, then add
Zajęcza and the rest.

## 7. Asks for F (defaults built if no answer)

- Are the parody names above right? (Default: yes; the Zajęcza four are the most recognisable.)
- Summer-only gardens or also a winter set with heaters? (Default: both, the game starts in summer.)
- Real queues and a door on Zajęcza on weekends: should the doorman turn the player away like at the clubs?
  (Default: no, only NPCs; the clubs keep that.)
