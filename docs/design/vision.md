# Moja Warszawa: the city as the main character

Written 2026-10-29 by the game-designer from the user's direction ("not so much about the gameplay,
but about my vision of Warsaw, how I live here for 10 years, with all its memes"). This is the
vision, the pillars, a content catalogue by theme, the small systems that serve it, the demo split
and a loop plan, 103 original lines, 40 easter eggs and a 2D art list. Nothing here is built yet.
Numbers marked *guess* are first values, each with how to tune it.

Rules for everything here: CLAUDE.md "Content", the warsaw-tone skill, `docs/design/parodies.md`
section 0 (affectionate, not mistakable for a real brand, Polish-only uppercase pixel-font words in
the world, the reserved colours of the art bible). Two more rules come from this direction:

- **Near-miss parodies.** Every business gets a parody name a local recognises at once but that
  is clearly changed: a number off by one, a letter or a word swapped, a wordplay on the original
  (the user's example: a tower club called Level 27 becomes **Level 26**). Never the real name,
  never a real logo, never its colours together. A business named after a real family (an old
  cukiernia that carries a surname) gets a wordplay that does not touch the surname. The real
  names appear in this file only in the check table (3.0), as `parodies.md` did. They never
  appear in the game.
- **Places from the songs, never the songs.** Section 3.10 lists Warsaw places that one Warsaw
  rapper's songs mention. The list comes from fan and press guides. Those places are built as
  places. No lyric, line, fragment, paraphrase, title, album name or artist name goes into the
  game or into this file (the artist is named once, as the research source). **Title-collision
  rule:** no in-game line, sign, station, track or place card may use a word that is the title of
  one of that artist's albums, EPs or singles. The designer checks this against the published
  discography when lines are merged; the list is not kept in the repo. Because of this, the photo
  mode is called *Fotka* and never "postcard", street lamps are *lampy* in lines, and the
  1989–2007 stadium bazaar is called "the bazaar at Stadion Dziesięciolecia", never by its
  historic trade name.

---

## 1. The vision (one page)

**Around Warsaw is a drive through one person's Warsaw.** The person has lived here ten years.
They know which corner has two Frogs, where the queue starts on a Friday, which steps catch
the sunset, which bus meets the others at Centralny at night, and what stood on Plac Defilad
before the museum. The player gets that knowledge by driving, slowly or fast, with the radio on.

**The city is the main character.** Every street, square, bridge and metro entrance in the 18.6
km² box is real and named. Every business is a near-miss parody, so a local smiles and nobody is
advertised. The people are types: the bouncer, the queue in black, the dog walkers of Powiśle,
the Wednesday running club, the cargo-bike parent, the night bus driver, the crowd on the river
steps at sunset. They say short, warm lines in Polish with English underneath.

**Now and over the last decades.** The city is the 2020s first: matcha, viral bakeries, the new
towers at Rondo Daszyńskiego, city bikes, scooters lying everywhere, the techno queue. Under it
lie the layers the user lived through and heard about: the blue market hall on Plac Defilad, the
bazaar in the old stadium, the metro dig on Świętokrzyska, the rounded trams, the 1960s neons.
A button at certain places (**KASETA**, the time tape) plays the place's past for six seconds: a
dithered ghost of what stood there and a card. The past is told with affection, never with
politics.

**What the player does.** Drives, wanders, discovers. A notebook called **MOJA WARSZAWA** fills
with a card for every place found (72 in the demo) and every egg (40). Photo spots reward a good
frame. The night has a rhythm: the queues grow after midnight, the doors pick and refuse, the
dawn crowd walks to the Palm in sunglasses, the first tram, the kebab. A late-night radio station
(**PÓŁNOC FM**, 86,0) plays original instrumentals and a host who talks about the city.

**Missions, jobs, police and races stay, as flavour.** Kebab, słoiki, Łuber, rescues, rivals
and the gentle police are the city's errands and characters: they come to you, you can say no,
and they all happen at real places that the notebook then remembers. A **Spacer** (wander) mode
switches off every timer and every push; the city alone is enough to play. Nothing in the game
punishes the player for driving slowly and looking.

**The night is safe.** Nobody is shown drunk or high, nothing glorifies it, and the player is
always the sober driver: the joke at the club door is that the bouncer judges your car, and the
dawn crowd rides home with you because "nikt z nas nie prowadzi, i bardzo dobrze".

---

## 2. Pillars

| # | Pillar | What it means in the game | What it rules out |
| --- | --- | --- | --- |
| 1 | **Miasto jest bohaterem · The city is the main character** | Every activity, line and card is tied to a real place in the box and teaches something about it. The notebook is the game's spine. | Generic content that could sit in any city; invented districts; a line that would read the same in Kraków. |
| 2 | **Teraz i kiedyś · Now and then** | A snapshot of the 2020s plus layers from the 1990s, 2000s and 2010s at the real spots where they happened (the time tape, 4.4). | Nostalgia that mocks; politics; tragedies played for laughs (the Rotunda's 1979 explosion is mentioned only as history, never joked about). |
| 3 | **Bez presji · No pressure** | Wandering is a complete way to play: Spacer mode, nothing missable forever, discoveries by passing slowly. | Timers that can't be switched off, content locked behind failure, losing złoty or respect for exploring. |
| 4 | **Swoi, nie celebryci · Types, not people** | Bouncers, clubbers, runners, dog people, cyclists and police are affectionate types with invented first names at most. Parodies are near-misses. | Real people, real brands or logos, lyrics, real artists' names or voices, any line aimed at a nationality, religion or disability. |
| 5 | **Noc jest wesoła i bezpieczna · The night is fun and safe** | Club culture is joked about the way the police are: the queue, the door, the black glasses, the morning sun. The player drives the others home. | Drugs or drunk driving shown, hinted or glorified; drinking shown as anything but a social scene; violence at the door. |
| 6 | **Lekko na telefonie · Light on the phone** | Everything rides on what exists: the pedestrian and rider meshes, `neon_signs.gd`, bubbles, cards, the traffic buses, the roadworks barriers, MultiMeshes per sector. | One node per person; a new shader without the user's yes; any new per-frame system above its line in section 6. |

---

## 3. The content catalogue

How to read each theme: **places** (real street, the parody name if it is a business, its look,
a joke or legend; "map today" says whether it is on today's 6.3 km² map or comes with the demo
bake, loop 3d), **people** (NPC behaviour), **sounds**, **eggs** (IDs from section 8), **OSM tags**
that find the anchors in the demo download. Business anchors use OSM by position only, never by
name; named venues are placed by their real address point (`addr:street` + `addr:housenumber`)
in the bake.

Looks are for the default 80 m view (≈ 6 image px per metre): a venue is a **shop-front fascia
with a neon word** from `neon_signs.gd` (pixel font, Polish, uppercase) plus at most one cheap prop
(a rope line, a door light, a bench), never a model of its own unless stated.

### 3.0 Parody names and the checks

Checked on 2026-10-29 with web searches (Polish and English) and by opening the obvious `.pl`
domain. A web search is not a trademark search: loop 3k's brand audit (UPRP and EUIPO registers)
re-checks every name before TestFlight.

| Real business (never in game) | Real street (stays) | Parody | The near-miss | What the check found | Decision |
| --- | --- | --- | --- | --- | --- |
| Luzztro (after-hours techno) | Al. Jerozolimskie 6, by the Palm | **LUSTERKO** | the name reads like *lustro* (mirror); *lusterko* is a pocket mirror, and the mirrored sunglasses at dawn | No venue named Lusterko found; `lusterko.pl` exists but failed TLS, content unknown | **Keep** |
| Smolna (techno club) | Smolna 38 | **SMOŁA** | the street's own root: *smoła* is tar (black, and the floor at 5 a.m.) | No club or bar named Smoła found; `smola.pl` is parked at a domain seller | **Keep** |
| Jasna 1 (club) | Jasna 1 | **JASNA 0** | off by one, a house number that doesn't exist: the basement is level zero | No venue found; `jasna0.pl` does not resolve. **Rejected "Ciemna 1"**: the registry shows *Ciemna 1 Sp. z o.o.* at Jasna 1, the real club's operator | **Keep Jasna 0** |
| Level 27 (tower-top club) | Al. Jerozolimskie 123A, 27th floor | **LEVEL 26** (the user's example) | off by one; the egg says it is on the 28th floor | No venue found; `level26.pl` does not resolve | **Keep** |
| Plan B (bar, the crowd on the square) | al. Wyzwolenia 18, Plac Zbawiciela | **PLAN C** | one letter on | No bar found; `planc.pl` is a medical-support organisation (another field) | **Keep** |
| Apteka (bar the user named) | street to confirm (Open Question 2) | **APTECZKA** | *apteczka* is a first-aid kit, the pharmacy's little one | No bar found (only pharmacies; "apteczka" is a feature of a pharmacy app) | **Keep**; place it when the user names the street |
| Hyrox (fitness race) | the Warsaw edition | **HYRAX** | one letter; a hyrax (*góralek*) is our mascot | No fitness race found; `hyrax.pl` is a veterinary clinic in Kraków (another field) | **Keep** |
| Miłość Kredytowa (club) | Kredytowa 9 | **MIŁOŚĆ HIPOTECZNA** | credit becomes mortgage: thirty years of love | Nothing found | **Keep** |
| 1500 m2 (event space) | Emilii Plater 29 | **1499 M2** | off by one; a rent joke | Nothing found | **Keep** |
| Bank (club on Mazowiecka) | Mazowiecka | **LOMBARD** | bank becomes pawnshop | No club named Lombard found | **Keep** |
| Hocki Klocki (river venue) | by Most Poniatowskiego (now Wał Miedzeszyński) | **HOCKI BLOKI** | *klocki* (toy bricks) become *bloki* (housing blocks) | Nothing found | **Keep** |
| Syreni Śpiew (club, closed 2017) | the modernist pavilion on Rozbrat | **SYRENI SZEPT** | song becomes whisper; a then-and-now place | Nothing found | **Keep** |
| Zakąski Przekąski (2010s snack-and-shot bar) | Krakowskie Przedmieście 13 | **PRZEGRYZKI ZAGRYZKI** | two snack synonyms swapped in | Nothing found (a games-bar named Zagrywki on Nowy Świat came up: different word) | **Keep** |
| Asfalt Shop (records, above the club) | Kredytowa 9 | **ŻWIR** | asphalt becomes gravel | No record shop found | **Keep** |
| Warszawa Powiśle (bar in the station's ticket pavilion) | Kruczkowskiego 3B | **KASA BILETOWA** | named after its room, the old ticket office, instead of the station | No bar found | **Keep** |
| Veturilo (city bikes) | city-wide docks | **ROWERILO** | *rower* with the system's ending | `rowerilo.pl` does not resolve; nothing found | **Keep** |
| Bar Prasowy (milk bar; the real one is just south of the box) | Marszałkowska | **BAR PYZOWY** | *prasowy* (press) becomes *pyzowy* (dumplings) | Nothing found | **Keep**, placed on Marszałkowska by Plac Konstytucji |
| The old Nowy Świat cukiernia with the Fat Thursday queue (a family surname) | Nowy Świat | **LUKROWNIA** | no near-miss by the surname rule; *lukier* is icing | Nothing found | **Keep** |
| Matcha bars (several real ones near Plac Zbawiciela) | cafés by position | **GLON** (algae) | invented: the real ones carry the generic word "matcha" | Nothing found | **Keep** |
| Viral trend shops | rotating slots | **WIRALEK** | invented: "viral", Polonised, as a diminutive | Nothing found. **Rejected "Na Fali"**: a café of that name exists in Koszalin | **Keep Wiralek** |
| Running clubs (brand-run in reality) | the boulevards | **KOLKA** (a runner's side stitch) | invented | No running club found. **Rejected "Zadyszka"**: the name of running races in Olsztyn and Szulmierz (same field) | **Keep Kolka** |
| Pet shops | by position | **MERDAK** (from *merdać*, to wag) | invented | Nothing found | **Keep** |

**The existing parodies stay**, each for a reason:
- **Frogs** (was Rechotka 24; the user's pick, 2026-10-30): a plain English word a local reads at
  once as the frog-green shop. A closer near-miss would come too close to the real chain's name.
- **Łuber, Pędzik, Leżak**: each joke is about a kind of app (ride-hailing, delivery, scooters)
  with several real operators. A near-miss of one would point at one company and its workers,
  which `parodies.md` rules out.
- **U Zdzicha, Na cienkim**: invented stands with no real target.

### 3.1 The night and techno scene

| Place (real street) | Parody / what | Look at 80 m | Joke or legend | Map today |
| --- | --- | --- | --- | --- |
| Al. Jerozolimskie 6, by Rondo de Gaulle'a and the Palm | **LUSTERKO**, the after-hours club | A dark facade, a small white neon LUSTERKO, a rope line along the pavement, one door lamp; the queue in black | It opens when the others close; on Sunday at 9 a.m. there is still a queue and the door still picks | on map |
| Smolna 38 | **SMOŁA** | A pre-war tenement's gate, a red door lamp, a courtyard glow, the queue down Smolna | The street is named after tar; so is the club. Police car parked opposite on Fri/Sat nights | on map |
| Jasna 1 | **JASNA 0** | A doorway in a grand old corner building, stairs going down, a cold blue door lamp | "Level zero": the club is in the cellar of a house number that doesn't exist | on map |
| Al. Jerozolimskie 123A (the 28-storey tower) | **LEVEL 26**, the tower-top club | A ring of violet light on the tower's top floor at night, small figures at the parapet seen from the helicopter | It is on the 28th floor. "Winda wie" (the lift knows) | demo bake |
| Mazowiecka (the club street) | **LOMBARD** and generic KLUB neons | Five or six neon fascias in a row, the brightest street of the box after 23:00 | The street of tourists, stag nights and the dressed-up crowd; the doors say no to groups of six | on map |
| Kredytowa 9 | **MIŁOŚĆ HIPOTECZNA**, club; **ŻWIR** upstairs | Pink neon heart with a little house in it; a vinyl-record neon upstairs | Love on a thirty-year mortgage | on map |
| Emilii Plater 29 | **1499 M2** | A big plain warehouse front, an event banner in the pixel font | Now one square metre smaller. Rent is the same | on map |
| Wybrzeże Kościuszkowskie at Most Poniatowskiego (and across, Wał Miedzeszyński) | **HOCKI BLOKI**, river venue | Fairy lights strung on poles, deckchairs, a container bar, music audible from the bridge | Moved across the river once; the river doesn't mind | on map |
| Rozbrat, the modernist pavilion | **SYRENI SZEPT** (then, closed 2017) | A low glass pavilion, dark today; lit and queued only in the time tape | One of the 2010s Powiśle clubs; its lease ran out in 2017 | on map |

**People.**
- **The queue** (*kolejka*): 4 to 24 standing figures along the facade, 0.7 m apart, mostly black
  clothes (a dark palette per instance), a few in sunglasses even at night. One step forward
  every 20–40 s *guess*. Growth by hour and weekday in 4.5.
- **The bouncer** (*bramkarz*, a type, nameless): a broad figure in black at the door, arms
  folded; every 30–60 s *guess* one figure at the head is turned away, walks off with a
  `club_door` bubble and either rejoins the end (the "try again" joke) or walks to the kebab.
- **The dawn crowd** (Sat/Sun 05:00–09:00): 20–40 figures walking from Lusterko, Smoła and Jasna 0
  towards the Palm, Metro Nowy Świat-Uniwersytet, the first trams on Jerozolimskie, the kebab
  stands. Sunglasses on most (two dark pixels at eye height: an instance colour band on the
  pedestrian mesh). Calm, chatty, never staggering.
- **The police by the club**: one parked patrol car with a standing officer opposite Lusterko and
  one by Smoła, Fri/Sat 00:00–08:00; static, never starts a chase from there, says
  `police_club` lines. The usual rules (police.md) still apply to the player's driving.

**Sounds.** A muffled four-on-the-floor kick leaking from a door (a filtered loop, louder
within 25 m, gone when the door "closes" between admissions); queue murmur; a bass rumble from the
pavement grate at Jasna 0; at dawn birds plus the first tram's bell. All made with the project's
own tools (`make_sfx.py`, `make_music.py`), no samples.

**Eggs.** E01 Czarny lakier, E02 Niedziela o dziewiątej, E03 Dzień dobry, Palmo, E04 Selekcja
policji, E05 Level 26 na 28. piętrze, E06 Mazowiecka slow, E07 Miłość Hipoteczna, E08 1499 m2,
E09 Hocki Bloki from the bridge.

**OSM tags.** `amenity=nightclub`; `amenity=bar|pub` with `opening_hours` past 02:00; named
venues by address point; `entrance=*` on the facade for the door; `building:levels` for Level 26's
floor.

### 3.2 Bars and the "study modern Warsaw" places

| Place | Parody / what | Look | Joke or legend | Map today |
| --- | --- | --- | --- | --- |
| Plac Zbawiciela (the round MDM square and the church) | **PLAN C** (al. Wyzwolenia 18), **GLON**, a **WIRALEK** slot | The arcades round the square; on summer nights the crowd stands outside on the pavement and the square's edge, talking, rather than in the small bar upstairs | Everybody comes "na chwilę" (for a moment) and stays till two | demo bake |
| Nowy Świat 22/28, the courtyards | **Pawilony** (a place: the courtyard of small bars) | A narrow gate off Nowy Świat, inside a maze of low pavilions with a dozen tiny lit signs | Twenty bars the size of a kiosk; nobody knows the way out the same way they came in | on map |
| Krakowskie Przedmieście 13 | **PRZEGRYZKI ZAGRYZKI** | A small bright bar front with a menu board of round prices (4, 8, 12) | The 2010s trend of cheap herring and tiny plates; open late, crowded at the counter | on map (rim) |
| Kruczkowskiego 3B, the 1963 ticket pavilion of Powiśle station | **KASA BILETOWA** | The modernist pavilion on the bridge ramp, deckchairs and benches on the grass, string lights | A bar in a ticket hall: "jeden normalny do Powiśla" | on map |
| Powiśle: Dobra, Tamka, Karowa, the university library | Places; the library's green roof garden | The ivy-green roof of the library, students on the steps of Dobra | Study, coffee, kebab, river: the Powiśle day in four stops | on map / rim |
| The old Powiśle power station | Place: a food hall now (no parody needed for the building) | Brick halls and a chimney, a terrace | Power station to food hall; the kebab already lives there | on map |
| Hala Koszyki (Koszykowa) | Place: the restored market hall, a food hall | Brick hall with its iron roof, a glass entrance | Decades of decay, reopened 2016; now a queue for ramen | demo bake |
| Hala Mirowska | Place: the brick market halls, **U Zdzicha** kebab | Two halls, flower stalls outside | "There was a market here, and there still is" (an existing kebab line) | demo bake |
| Mokotowska and Hoża | Design and fashion street; generic MODA, MEBLE Z PRL neons | Small boutiques, a bench made of a 1960s chair | The street where a chair costs a month's rent | demo bake |
| Kopernika, Oboźna | Cafés by position (generic KAWA) | Little lit cafés under the escarpment | | on map |
| Apteczka | street to confirm | A green cross-shaped neon, white tiles, a menu written like prescriptions | "Na receptę: herbata z sokiem" (on prescription: tea with juice) | — |

**People.** The standing crowd at Plan C (up to 40 figures, summer Fri/Sat 21:00–02:00), students
with tote bags and laptops (Powiśle, day), a group photo every few minutes (a figure steps back
and raises a phone: a 1-frame flash pixel), a waiter crossing with a tray, couriers (Pędzik)
waiting at the food halls.

**Sounds.** Glasses and cutlery ambience near terraces, laughter bursts, a busker's accordion on
Krakowskie Przedmieście (original tune), the Plac Zbawiciela tram squeal on the curve.

**Eggs.** E10 Plac C lap, E11 Pawilony maze (helicopter), E12 Jeden normalny do Powiśla, E13
Ogród na dachu.

**OSM tags.** `amenity=bar|pub|cafe|restaurant`, `amenity=marketplace`, `building=retail` with
`name~Hala` (places only), `roof:garden=yes` / `leisure=garden` on the library, `shop=furniture|
interior_decoration|clothes|boutique`.

### 3.3 The river steps (schodki nad Wisłą)

The boulevards were rebuilt in the 2010s; the steps down to the water by Centrum Nauki Kopernik
are where half the city sits on a summer evening. This theme is the calm heart of the vision.

| Place | What | Look | Legend | Map today |
| --- | --- | --- | --- | --- |
| The boulevard steps by Centrum Nauki Kopernik (Bulwar Flotylli Wiślanej) | **Schodki**, a place | Wide stone steps to the water, figures sitting in rows, blankets, bikes leaning on the rail | The best seats in town and nobody pays for them | demo bake (the boulevard's south part is on map) |
| The boulevards from Most Śląsko-Dąbrowski to Most Poniatowskiego | Place: the promenade | Granite, benches, the Mermaid (an existing egg), runners | | part on map |
| Poniatówka, the Praga beach | Place: a sand beach | Sand, a volleyball net, deckchairs, a bonfire ring at dusk | The beach is on the "wrong" side, which is the right side for the sunset over the Old Town | on map |
| The fountain park at Podzamcze (the box's north edge) | Place: the summer water-and-light show | Fountains below the Old Town escarpment | On summer Fridays and Saturdays a show at dusk | demo bake (edge) |
| Hocki Bloki, Kasa Biletowa | see 3.1 and 3.2 | | | on map |

**People** (one crowd per steps sector, see 4.5 for the curve):
- **Sitters**: 70 % of the crowd, in rows on the steps, facing the river; groups of 2–6 with a
  blanket quad; some with a dog lying beside them.
- **The guitarist** (a type): one figure with a guitar, strumming the same three chords (an
  original loop); egg E15.
- **Picnickers**: blankets on the grass above the steps, a basket, a lemonade bottle shape (never a
  beer bottle in close-up; a generic bottle at most).
- **Standers**: 20 %, by the rail, taking the sunset photo.
- **Bikes and Rowerilos** parked along the rail; a Leżak lying on the top step (of course).
- At **sunset** (Live: sunset ±10 min, May–September; non-Live: the Dusk look) most figures turn
  their heads towards Praga, phones up: the *zachód słońca* moment; then applause (egg E14).

**Sounds.** A crowd bed (murmur, laughter), the guitar loop within 20 m, the river lapping on the
granite, a tram bell from Most Świętokrzyski, a boat horn once a dusk, a far-off bass from Hocki
Bloki after 22:00.

**Eggs.** E14 Brawa dla słońca, E15 Czwarty chwyt, E16 Aport (helicopter ball fetch), E17 Pokaz
fontann.

**OSM tags.** `highway=steps` near `waterway=riverbank` / `natural=water` (the Vistula),
`leisure=park`, `amenity=bench`, `natural=beach`, `leisure=beach_resort`, `amenity=fountain`,
`tourism=viewpoint`.

### 3.4 Viral bars and cafés: the trend cycle

The joke: a place goes viral, the queue is the product, everybody photographs the queue, and next
week it is a different place. Three **Wiralek** slots stand in hero streets: **Plac Zbawiciela**,
**Chmielna**, **Tamka** (Powiśle). Each shows one trend at a time on its fascia (a pixel-font
product word, a small PixelLab pictogram on the window).

| Trend (generic product words only) | Sign word | Pictogram |
| --- | --- | --- |
| The square croissant | KWADRATOWY ROGAL | a croissant cube |
| Pistachio "desert" chocolate | CZEKOLADA Z PUSTYNI | a cracked chocolate bar, green filling |
| Strawberries in chocolate, in a cup | TRUSKAWKI W KUBKU | a cup of strawberries |
| Matcha in every form | MATCHA WSZYSTKO | a green cup with a whisk |
| A doughnut with a cream crown | PĄCZEK 2.0 | a doughnut with a swirl |
| Bubble tea | HERBATA Z KULKAMI | a tall cup with dots |
| The giant cookie | CIASTKO XXL | a cookie bigger than its plate |
| A pink-wall café | RÓŻOWA ŚCIANA | a pink wall with a neon wing shape |

**The cycle** *guess*: a trend lives 7 in-game days (Live: the real ISO week, each slot offset by
2 days; non-Live: it moves on every third session). Day 1: **NOWOŚĆ** sign and a queue of 30
round the corner; days 2–3: 20; days 4–5: 8; days 6–7: 2 and a pigeon; then the fascia says
**WKRÓTCE NOWE MIEJSCE** (new place soon) for one day, and a new trend starts. In the queue, one
figure in five holds a phone up (the photo of the queue).

**Fat Thursday** (*Tłusty Czwartek*, the Thursday before Ash Wednesday; computed from Easter, Live
only, or with `--date`): the queue at **LUKROWNIA** on Nowy Świat runs 60 figures down the
pavement from 06:00 to 18:00; egg E20.

**People.** Queuers with phones, the "influencer at the window" (one figure posing, another
photographing, every 40 s), a courier with a square backpack bringing the trend to Mordor.

**Sounds.** The queue's chatter, a phone shutter click, a café bell.

**Eggs.** E18 Cykl życia trendu, E19 Trzy kolejki naraz, E20 Tłusty Czwartek, E21 Zielony pasuje
do menu (Glon).

**Gameplay hook (optional job, "Na czasie" / on trend).** A request card, like Łuber's: an
office worker at Rondo Daszyńskiego wants today's trend before it's "over". Pick up at a Wiralek
slot (stop 2 s; the queue lets the courier through, "odbiór na aplikację"), deliver within 6 min
*guess* to a real address in the Rondo Daszyńskiego towers or Mordor's lobby door. Pay 25 zł + 8
zł/km *guess*, +15 respect; on day 6–7 of a trend the customer says "to już niemodne" and tips
nothing (the joke). One activity at a time, like every job.

**OSM tags.** `amenity=cafe`, `shop=bakery|pastry|confectionery`, `cuisine=bubble_tea|coffee_shop|
donut`, `shop=tea`; the three slots are fixed positions by those anchors.

### 3.5 Metro and buses

**Stations inside the box** (real names, real places):

| Line | Station | Where | Map today |
| --- | --- | --- | --- |
| M1 | Ratusz Arsenał | Plac Bankowy | demo bake |
| M1 | Świętokrzyska (M1 × M2) | Marszałkowska × Świętokrzyska | on map |
| M1 | Centrum | Marszałkowska × Aleje Jerozolimskie, the Patelnia | on map |
| M1 | Politechnika | Waryńskiego, at the box's south edge | demo bake |
| M2 | Rondo Daszyńskiego | the new towers | demo bake |
| M2 | Rondo ONZ | Rondo ONZ | on map (west rim) |
| M2 | Świętokrzyska | see M1 | on map |
| M2 | Nowy Świat-Uniwersytet | Nowy Świat × Świętokrzyska | on map |
| M2 | Centrum Nauki Kopernik | Wybrzeże Kościuszkowskie | on map |
| M2 | Stadion Narodowy | Al. Zieleniecka | demo bake |

(Dworzec Gdański and Dworzec Wileński lie just north of the box: later.)

**Look.** Each entrance (`railway=subway_entrance`, ~40 in the box) is a low glass-and-steel
canopy or a stair opening with a post carrying a plain pixel-font **M** in a square (our own
shape, not the operator's mark), lit at night. Above the M1 × M2 crossing at Świętokrzyska the
ground rumbles under the car twice a minute (egg E22).

**Buses.** The traffic buses (main roads only) get an **N** route sign at night (22:30–05:00) and
gather at **Dworzec Centralny** in a ring of 5–8 every half hour of game time *guess*: the night
hub, a real habit of Warsaw's night network, shown as a gentle egg (E23). Bus stops
(`highway=bus_stop`, the existing `shelters` data) get a waiting figure or two by day and a
bubble when the player stops beside them (`bus_stop` lines).

**People.** Commuters spilling out of the Centrum and Świętokrzyska entrances at 08:00 and
17:30 (a burst of 15 figures), students at Nowy Świat-Uniwersytet, fans at Stadion Narodowy on
match days (Live calendar off; a weekly "match" on Saturday 18:00 *guess*), the night-bus crowd at
Centralny.

**Sounds.** A soft three-note chime near entrances when a "train" arrives below (every 3–4
min; our own chime, not the real one), the ventilation hum from grates, the night bus's kneeling
hiss.

**Eggs.** E22 Tu się krzyżują, E23 Nocny węzeł, E24 Przystanek na żądanie, E25 Wyścig z nocnym.

**OSM tags.** `railway=subway_entrance`, `station=subway` / `railway=station` + `subway=yes`,
`public_transport=station`, `highway=bus_stop`, `public_transport=platform` + `bus=yes`,
`shelter=yes`, route relations `type=route` + `route=bus` + `ref~^N` (night lines).

### 3.6 Food

| Place | Parody / what | Look | Joke |
| --- | --- | --- | --- |
| Kebab stands (14, `parodies.md` 6.1) | **U ZDZICHA** (Hala Mirowska), **NA CIENKIM** (Plac Zbawiciela), the rest KEBAB | existing stand | Kebab at 3 a.m. is a meal category of its own (exists) |
| Frogs (`parodies.md` 2; was Rechotka 24) | the frog-green corner shop | existing spec | Always one hop away |
| Glon (matcha bars, Plac Zbawiciela, Powiśle) | **GLON** | A pale green fascia, a cup-shaped neon | "Green, healthy and allegedly tasty" |
| Bakeries (by position) | generic PIEKARNIA neon; **LUKROWNIA** on Nowy Świat | Warm window, bread shapes | The Fat Thursday queue |
| Milk bar on Marszałkowska by Plac Konstytucji | **BAR PYZOWY** | A 1960s glass front, a tray-shaped neon | The 13:00 lunch rush: students, pensioners, office workers in one queue. Warsaw's first milk bar opened on Nowy Świat in 1896 (a then card) |
| Generic BAR MLECZNY neons | exist in `neon_signs.gd` | | |
| The food halls (Koszyki, the power station) | places | see 3.2 | |
| Wiralek slots | see 3.4 | | |

**People.** The kebab queue at 03:00 (2–6, existing stands), the milk-bar queue at 13:00 (8),
the bakery's first customer at 06:00, couriers waiting.

**Sounds.** Kebab grill sizzle, a tray clatter at the milk bar, the bakery's door bell.

**Eggs.** E26 Godzina pyz, E20 Tłusty Czwartek, the Frogs triple corner (exists in
`parodies.md`).

**OSM tags.** `amenity=fast_food` + `cuisine=kebab`, `amenity=restaurant` + `cuisine=polish`
(milk bars are often `cuisine=polish` with `name~Bar`; position only), `shop=bakery|pastry`,
`shop=convenience` (Frogs), `amenity=food_court`.

### 3.7 Everyday city life

**Dog walkers** (*psiarze*). Figures with a dog (three silhouettes: a long low one, a squat
flat-faced one, a big fluffy one; ≤ 120 triangles, no shadow, `fine_detail`). 06:30–09:00 and
19:00–22:30, twice as many in Powiśle and round Plac Zbawiciela *guess*. The dog stops at trees
(3–6 s), the walker waits looking at the phone. A horn within 15 m: the dog barks (sound) and the
walker says a `dog_walkers` line (once per 60 s). Pet shops **MERDAK** by `shop=pet` anchors.
The "dog influencer" at Plac Zbawiciela: a dog with three figures photographing it (E27).

**Cyclists.** Riders on the cycle lanes (the Pędzik rider mesh and its city-wide MultiMesh, with
instance colours): commuters, **Rowerilo** riders on cream city bikes with a grey basket
(docks `amenity=bicycle_rental`, a row of 6–10 bikes at each), cargo bikes with a child box
(a second rider-mesh variant), a few couriers. They ring a bell at a car parked on the bike lane
(within 2 m of a `cycleway` for 3 s), with a `cyclists` line. Egg E28 (Rowerilo at 19:59).

**Scooters.** Leżak, as `parodies.md` 5 (lying everywhere; the round-up job).

**Runners and the running club.** Single runners on the boulevards and in the parks at 06:00–08:00
and 18:00–21:00 (pedestrians at 3 m/s with a running stride). The running club **KOLKA** meets on
**Wednesdays at 19:00** by Centrum Nauki Kopernik: 12–20 runners in bright tops (pale yellow,
mint, white; never the jobs' orange) run the boulevards to Most Poniatowskiego and back.
- **Zając (the pacer)**, an optional moment: drive along Wybrzeże Kościuszkowskie beside the
  club (lateral ≤ 25 m) at 9–14 km/h for 600 m. The runners cheer (`runners` tag `zajac`), +40
  respect, and the traffic behind honks (existing `traffic` lines). E29.
- **HYRAX**, the parody fitness race, on **Saturdays 09:00–17:00** *guess* on the forecourt of
  Stadion Narodowy: a cordon of the roadworks barriers, a loop of runners, and our own Warsaw
  stations (carry the słoiki up the steps, push a Leżak, a Frogs-basket farmer's walk, the
  stadium's stairs). The mascot is a hyrax (*góralek*) on the banner. Łuber rides tagged
  `hurry` that morning go to the stadium (a late competitor). E30.

**People with pets on bikes, fancy and retro, scooters on the steps**: all of the above share the
pedestrian and rider meshes.

**Sounds.** Barks (three sizes), bike bells, a running watch's beep as the club passes, a
whistle and a cheer at the Hyrax finish, a cargo bike's child laughing.

**OSM tags.** `shop=pet`, `amenity=veterinary`, `leisure=dog_park`, `amenity=bicycle_rental`
(+ `network`), `highway=cycleway`, `cycleway=lane|track`, `leisure=fitness_centre|sports_centre`,
`leisure=track`, `sport=running`, `leisure=park`.

### 3.8 Fancy and retro

| Place | Parody / what | Look | Joke or legend |
| --- | --- | --- | --- |
| Kredytowa 9, upstairs | **ŻWIR**, records | A neon record, crates in the window | Plays the radio station you have on; asks if it comes on vinyl (E31) |
| Record shops by position | generic PŁYTY neon | | |
| Vintage shops | generic CIUCHY and VINTAGE neons | Rails of clothes in the window | |
| Mokotowska, Hoża | design shops: MEBLE Z PRL | A 1960s chair in the window, lit like a jewel | A chair from a flat in Ochota, now priced like a car |
| Plac Konstytucji (MDM) | **the old volleyball-player neon** (a real 1961 neon, restored in 2006 and protected) | Our own pixel drawing of a neon volleyball player on the corner building, its ball animated in three frames | Built as a landmark, drawn in our own pixel style rather than traced from the original (Open Question 9). E32 |
| Marszałkowska's Ściana Wschodnia, MDM's arcades | 1960s-style neon words: RYBY, MODA, FOTO, KWIATY, KSIĄŻKI, OBUWIE, RADIO TV | In the old script shapes the pixel font allows, some flickering | The neons are older than the roadworks. Barely |
| The 1930s tower on Plac Powstańców Warszawy | place (the old insurance skyscraper, now a hotel) | A stepped tower | Warsaw's first skyscraper; the helicopter's card (E33) |

**People.** A vinyl digger with a tote bag, a vintage couple dressed in the 1970s, a man carrying
a 1960s armchair down Mokotowska (a pedestrian with a chair prop, E34).

**Sounds.** A record's crackle at Żwir's door, a neon's buzz and click when it flickers.

**OSM tags.** `shop=music` (records), `shop=second_hand`, `shop=clothes` + `second_hand=yes|only`,
`shop=antiques`, `shop=furniture|interior_decoration|art`, `historic=*` and `artwork_type=neon`
(rarely tagged; the old neons are hand-placed).

### 3.9 Then and now (the time tape)

Each item is a real place in the box, a short fact (Polish card, English below) and a ghost the
**KASETA** button shows there (4.4). No politics, no mockery, no tragedy as a joke.

| # | Place | Then | Now | Card joke |
| --- | --- | --- | --- | --- |
| T1 | Plac Defilad, east of the Palace | The blue sheet-metal market hall of the 1990s–2009 | The museum and the square | "Tu był blaszak. Wszystko za 5 zł, poza parkingiem." |
| T2 | Stadion Narodowy | The 1955 stadium's earth bowl and the giant open-air bazaar (1989–2007) | The 2011 stadium, the Euro 2012 opening match | "Dawniej tu kupowało się wszystko. Dziś kibicuje się wszystkiemu." |
| T3 | Plac Defilad, June 2012 | The Euro 2012 fan zone, a big screen | The square | "Cała Warszawa na jednym placu. I gołębie." |
| T4 | Świętokrzyska | The M2 dig of the early 2010s, the street closed for years | M2 since 2015 | "Najdłuższy remont świata. Do następnego." |
| T5 | Behind Dworzec Centralny | An empty lot and the 1990s folding market stalls | Złote Tarasy, 2007 | "Tu stały szczęki. Teraz stoi dach jak fala." |
| T6 | Rondo Dmowskiego, the Rotunda | The 1960s Rotunda | Rebuilt 2016–2018 to look the same | "Odbudowana, żeby wyglądała tak samo. Udało się." |
| T7 | Plac Konstytucji | The 1961 volleyball neon, dark for years | Lit again after 2006 | "Piłka spada od 1961 roku. Jeszcze nie spadła." |
| T8 | Nowy Świat | Warsaw's first milk bar, 1896 | Bar Pyzowy carries on (on Marszałkowska) | "Pierogi starsze niż tramwaj elektryczny." |
| T9 | Rozbrat pavilion | Syreni Szept's 2010s nights | A quiet pavilion | "Kiedyś kolejka, dziś cisza. Pawilon odpoczywa." |
| T10 | Krakowskie Przedmieście 13 | The 2010s small-plates-and-herring bar boom | Przegryzki Zagryzki, still | "Śledź za osiem złotych. Prawie zabytek." |
| T11 | Rondo Daszyńskiego | Low buildings and a car park | The towers of "new Mordor" | "Mordor się przeprowadził. Orki dojeżdżają metrem." |
| T12 | The Palace and Varso | The Palace the tallest for 67 years | Varso's spire passed it in 2022 | "Pałac już nie najwyższy. Pałac się nie przejmuje." |
| T13 | Tracks on Marszałkowska / Jerozolimskie | The rounded 1960s tram and the boxy 1970s one | The low-floor trams | "Kiedyś skrzypiało. Teraz szumi. Tęsknimy za skrzypieniem." |
| T14 | Main roads | The accordion bus with the rubber bellows | Today's buses | "Harmonijka grała na każdym zakręcie." |
| T15 | Kopernika, on the escarpment | The 1960s cinema, gone in 2008 | Flats | "Tu się chodziło na film. Teraz się chodzi do domu." |
| T16 | The boulevards | Wild banks and a road by the river | The rebuilt boulevards and the steps (2010s) | "Kiedyś krzaki. Dziś schodki. Krzaki też tęsknią." |
| T17 | Plac Konstytucji (or Plac Zbawiciela) | The card payphone | A bench | "Karta na 25 impulsów. Wystarczało na trzy rozmowy i plotkę." |
| T18 | Most Świętokrzyski | No bridge here until 2000 | The single pylon | "Most z jednym pylonem. Drugi poszedł na kawę." |
| T19 | Centrum Nauki Kopernik | The bare riverside before 2010 | The science centre and planetarium | "Tu się nauczysz, czemu niebo jest niebieskie. I nie tylko." |
| T20 | Koszykowa | Hala Koszyki derelict for decades | A food hall since 2016 | "Stała pusta latami. Teraz nie da się wcisnąć." |

All T-card lines are ≤ 70 characters in Polish; the English glosses go with them in `then_cards`
(section 7 shows the pattern; the full set is written in loop MW-6 against these facts).

**Superseded in loop MW-0 (2026-10-30), by the user's answer 3 (section 10): the set covers 2010
to today.** The 20 cards built are in `game/data/then_cards.json` (one place each from
`places.json`, a `ghost` description for MW-6): the Euro 2012 fan zone on Plac Defilad, the new
museum's site (2020), the Palace before the new tower outgrew it (2021), the stadium build (2010),
no metro to Praga (2014), the M2 dig on Świętokrzyska (2012), the Rotunda's fence (2017; reopened
2019), Syreni Szept's queue (2016), Rondo Daszyńskiego before the towers (2010), Centralny's Euro
renovation (2011), Kopernik's last touches (2010), the park before the fountains (2010), Koszyki's
two wings (2014), Hala Gwardii before its 2017 reopening (2016), the empty power station (2015),
the bank before the boulevards (2014), the first rent-by-the-minute scooters (2018), the first
city bikes (2012), the pistachio-chocolate queues (2024) and the latte before matcha (2015).
T1 (as 2009), T5, T7, T8, T10, T13–T15, T17 and T18 above wait for "later" with the older decades.

### 3.10 Miejsca z piosenek · Places from the songs

The places below appear in the songs of the Warsaw rapper **Taco Hemingway**, read from the fan
map mapatacohemingway.pl and two press guides (newonce.net, glamour.pl). No lyric, title or line
was copied and none is used. In the game they are just places; nothing in the game says where the
list came from. "Map today": **built** (a hand-built landmark or egg), **on map** (streets and
lumps on today's map), **demo bake** (comes with loop 3d), **later** (outside the box).

| Place | Where, in or near the box | What to build | An original idea for it | Map today |
| --- | --- | --- | --- | --- |
| Plac Trzech Krzyży | The square at the top of Nowy Świat, St Alexander's | Tier A church (DEMO 2.2), a notebook card | At 02:00 the square is the quietest place in the centre: the radio drops to the PÓŁNOC FM host, the car's engine sound softens for 10 s (an atmosphere beat, no reward) | on map (lump) |
| Nowy Świat | The street from the square to Krakowskie Przedmieście | Shop-front neons, Pawilony's gate, Lukrownia | The street is closed to private cars at weekends in reality; in game the city guards' gentle "pedestrian zone" lines play there on Saturday evenings | on map |
| Chmielna | The narrow shopping street off Nowy Świat | A Wiralek slot, small lit shops | The narrowest queue in the city: the Wiralek queue there fills the whole street width | on map |
| Bulwary Wiślane and the steps | The boulevards by Kopernik | 3.3 | The whole schodki scene | part on map |
| Metro Politechnika | Waryńskiego, south edge | An entrance with the M post | The last station before the box's edge; the metro chime plays there, then silence: the edge of "your" Warsaw | demo bake |
| Plac Zbawiciela and its bar | MDM | Plan C, Glon, Wiralek, the round square | The summer crowd (3.2); the tram curve that squeals | demo bake |
| Krakowskie Przedmieście | The royal route | St Anne's, the Copernicus statue (tier A), Przegryzki Zagryzki | A slow drive from the Copernicus statue to Plac Zamkowy at night fills a notebook spread "Trakt nocą" | on map (south) / demo bake |
| The 1850s hotel on Krakowskie Przedmieście | Krakowskie Przedmieście 13 | Tier B facade | Doorman figure; at dawn a horse carriage passes (the Old Town's joke, existing) | rim / demo bake |
| Pałac Kultury | Plac Defilad | built | The "best view" radio line exists; add the PÓŁNOC FM line about fog and the Varso card (E38) | built |
| Dworzec Centralny | Jerozolimskie | built | The night-bus hub (E23) | built |
| The Rotunda | Rondo Dmowskiego | built | Then card T6 | built |
| Metro Centrum and the Patelnia | Marszałkowska | built (egg) | Buskers on the Patelnia at 19:00 (an original guitar or sax loop) | built |
| Kredytowa | Behind Plac Małachowskiego | Miłość Hipoteczna + Żwir | E07, E31 | on map |
| Emilii Plater 29 | West of the Palace | 1499 M2 | E08 | on map |
| Karowa | Powiśle, under the escarpment | Its curved viaduct, cafés | The Karowa viaduct's curve is a favourite slow drive: the camera eases wider for 5 s there (a tuning of the existing follow camera, flag-testable) | on map |
| Mazowiecka | The club street | 3.1 | E06 | on map |
| Ludna and the riverside venue | Solec, by Most Poniatowskiego | Hocki Bloki | E09 | on map |
| Most Poniatowskiego | The bridge and its towers | built | From the bridge at night, Hocki Bloki's lights and the steps' crowd are visible: a photo spot (4.2) | built |
| The tram route through Muranów to Politechnika and on to Mokotów | Muranów to MDM | The existing trams; one tram line runs it end to end in the box | A slow "follow the tram" moment: tail a tram 1.5 km from Muranów to Plac Zbawiciela without overtaking, and the notebook gets the spread "Tramwajem przez miasto" | demo bake |
| Hotel Warszawa / the 1930s tower on Plac Powstańców Warszawy | Plac Powstańców Warszawy | Tier B stepped tower | E33 | on map |
| The Syreni Śpiew pavilion on Rozbrat | Powiśle | the then place T9 | E-tape | on map |
| Plac Na Rozdrożu | The south edge, Aleje Ujazdowskie | The roundabout and the escarpment road | The box's south gate: entering it from the south plays the radio's "welcome back to the centre" host line once a session | demo bake |
| Aleje Ujazdowskie | South from Plac Trzech Krzyży | Embassy-quiet avenue, trees | Speed trap #7 (police.md) lives here; the host warns you | demo bake |
| BUW (the university library) | Dobra | The green roof garden | E13 (land the helicopter on the roof garden's lawn) | rim / demo bake |
| PGE Narodowy | Praga bank | built | Hyrax Saturdays, then card T2 | built |
| Plac Konstytucji | MDM | The square, the volleyball neon | E32, T7 | demo bake |
| Muranów | North-west | Blocks, Plac Bankowy | The quietest night streets; the radio host's Muranów line | demo bake |
| Trasa Łazienkowska | South-east, partly at the box's edge | after the demo (DEMO 2.1) | A night drive on the trasa with the city's lights below | later |
| Puławska and Mokotów | South of the box | — | The tram route continues; the first district of the update | later |
| Dworzec Gdański and Żoliborz | North of the box | — | Second słoiki station (DEMO 6.3) | later |
| Marywilska (Białołęka) | Far north-east | — | The big market halls: a then-and-now chapter in an update | later |
| Koneser (Praga, Ząbkowska) | Just past the north edge | — | The old vodka factory turned district; the later Praga update | later (edge) |

Places that are album or song titles themselves (a café, for one) are left out by the
title-collision rule.

---

## 4. Systems that serve the vision

Each is small, uses what exists, and has a flag for screenshots and autopilot runs.

### 4.1 MOJA WARSZAWA: the city notebook

**What it is.** A pause-menu tab (one HUD card recipe) with chapters by theme (3.1–3.9 plus
"Miejsca z piosenek" folded into its places, never labelled so: 9 chapters), each a grid of
cards. **Demo: 72 place cards** (8 a chapter) + **40 egg cards** + **20 then cards** + 6
"spreads" (a route, like "Tramwajem przez miasto").

**Finding a place.** Pass within its radius `r` (25 m; 40 m for squares; 60 m for the helicopter
below 60 m altitude) at ≤ 30 km/h, or stop inside it for 1 s, or tap it within 80 m (the landmark
card's tap). A small toast: *NOWY WPIS · NEW ENTRY*, a page-turn sound, a pencil-scratch haptic.

**A card** (Polish above, English below): the real place name (or the parody name for a venue),
the district, one line of fact, one joke line (from `places.json`), the hours if it is a night
venue (e.g. *PT–SB 23:00–12:00*), the date first found, and a 16 px chapter icon (section 9).

**Rewards.** +5 respect a card; a chapter complete: +50 zł, +30 respect, a PÓŁNOC FM track
unlocked (7 tracks for 9 chapters; the last two unlock a horn tune and the gold notebook
cover). All cards: the end card adds "Twoja Warszawa" (your Warsaw) with the counts. The district
completion of DEMO 6.3 counts notebook cards.

**On the map.** In a discovered district, undiscovered places show as "?" on the minimap (DEMO
6.2's question marks), never their names.

**Data.** `game/data/places.json` (designer-owned): `id`, `chapter`, `name_pl`, `name_en`,
`address` or `osm` anchor, `radius`, `fact` [pl, en], `joke` [pl, en], `hours`, `tags`. The bake
resolves anchors to map metres into `pois` kind `place`. *Written in loop MW-0 (2026-10-30)*: the
file also holds `chapters` (ids `noc`, `bary`, `schodki`, `trendy`, `metro`, `jedzenie`,
`codziennie`, `retro`, `kiedys`), a rough `near` [lat, lon] hint per place, `heli_radius` where the
helicopter finds it, `wiralek_slot`, and `guess` + `guess_note` (Apteczka); the brand denylist is
`game/data/brand_denylist.json`.

**Flags.** `--notebook` (open it), `--found=all|none|<chapter>`, `--place=<id>` (car at the place),
`--notes-log` (prints `notes: found <id> (chapter 3, 5/8)`).

**Acceptance.** `check_places.gd` (headless): every entry has PL + EN, Polish ≤ 70 characters,
resolves inside the box, is reachable (a lane or footway point within `r` + 10 m), and its name is
not on the brand denylist (loop 3k); `--place=<id> --notes-log` finds it within 3 s.

### 4.2 Fotka: photo moments

**Mode.** A camera button in the pause card: HUD hidden, the car stops, the view orbits (yaw 360°,
pitch 20–70°, zoom 30–250 m) with one finger, the existing style and VHS settings apply, and a
shutter saves a PNG to `user://photos/` (sharing waits for the Share plugin, which needs its own
yes). Traffic and people keep moving.

**Kadr (photo spots).** 15 spots *guess* (the steps at sunset, the Palace from Plac Defilad at
night, Most Poniatowskiego with Hocki Bloki's lights, the Old Town from Poniatówka, Plac
Zbawiciela's crowd, the Rondo Daszyńskiego towers in the morning, the volleyball neon, the dawn
crowd at the Palm, a Wiralek queue on day 1…). A shot counts when the subject's anchor lies inside
the central 60 % of the frame, at the stated time of day, from within 300 m. Reward: *KADR!*, +20
respect, a notebook stamp. The notebook shows the player's own photo on the spot's card.

**Flags.** `--photo` (open Fotka), `--kadr=<n>` (put the camera at spot n), `--photo-log`.
**Acceptance.** `--kadr=1 --time=dusk --photo-log` logs `kadr: 1 ok`; the HUD is absent from the
saved PNG.

### 4.3 Spacer: wander mode

**Settings → Gra → Tryb: Miasto / Spacer** (City / Wander). In Spacer:
- no request cards, no rescue calls, no rival challenges arrive by themselves (the context button
  still offers ŁUBER, a kebab or a race on a tap);
- no timers anywhere (rescues started by hand run without a clock);
- police: speed traps give the caution only, no chases (the gentle joke stays);
- the radio prefers PÓŁNOC FM at night and KEBAB FM by dusk;
- every 3–5 min *guess*, a soft hint: an edge arrow towards the nearest undiscovered notebook
  place, gone after 15 s or when tapped away.

**Flag.** `--wander`. **Acceptance.** In a 10-minute `--wander --autopilot` run, the log shows no
job, rescue, race or chase start and at least two hint arrows.

### 4.4 KASETA: the time tape

At a then-and-now spot (20 in the demo, 3.9), the context button shows **KASETA · TAPE** within 40
m. Tap: the VHS overlay runs for 6 s (the existing `vhs.gdshader`), a dithered ghost of the old
place fades in (simple boxes: the blue hall, the stadium bowl and its stalls, the folding stalls,
the dig's barriers), a tape-rewind sound, and the then card. First time: +15 respect, a notebook
card.

Cost: the ghosts are a few boxes per spot, built only within 150 m of a spot, using the occlusion
ghost's dithered look **if** `Models.material()` can take a dither uniform; if it needs a shader
variant, that is a rule-5 exception for the user to approve (Open Question 8).

**Flags.** `--tape=<n>` (car at spot n, tape played), `--tape-log`. **Acceptance.** Each of the 20
spots logs `tape: n ghost ok` with its box count ≤ 24.

### 4.5 The night scene: clock, week, queues, door, dawn

**The city clock.** Live: Warsaw time and date (exists). The fixed looks get a clock: Day 14:00,
Dusk 19:30, Night 01:30, and a new **Świt · Dawn** look at 05:45 (Dusk's palette with the sun in
the east-north-east; `time_of_day.gd`, no new shader). Without Live, the night is always a
**Friday night** and the dawn always a **Saturday morning** ("Zawsze piątek", Open Question 4);
Live uses the real weekday. Flags: `--time=dawn`, `--clock=HH:MM`, `--date=` (exist for Live).

**Queue length** at a club = `max_len × hour_curve × weekday`, rounded, rewritten every 20–40 s:

| Hour | 22 | 23 | 00 | 01 | 02 | 03 | 04 | 05 | 06–08 | 09–12 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Clubs (Smoła, Jasna 0, Lombard, Miłość Hipoteczna) | 0.1 | 0.3 | 0.6 | 1.0 | 1.0 | 0.7 | 0.4 | 0.1 | 0 | 0 |
| Lusterko (after-hours) | 0 | 0 | 0.2 | 0.4 | 0.6 | 0.9 | 1.0 | 1.0 | 0.8 | 0.5 (Sun only) |
| Level 26 (roof crowd, not a queue) | 0.3 | 0.6 | 1.0 | 1.0 | 0.8 | 0.4 | 0 | 0 | 0 | 0 |

Weekday factor *guess*: Mon–Wed 0.2, Thu 0.6, Fri 1.0, Sat 1.0, Sun 0.3 (Lusterko on Sunday
morning 1.0). `max_len` 24 for Lusterko and Smoła, 16 for the others. Tune by eye on the phone:
the queue should be the first thing a player notices on Smolna at 01:00.

**The door.** One rejection every 30–60 s when a queue ≥ 4 is in view (a `club_door` `reject`
bubble). **The car at the door**: drive past within 8 m at < 10 km/h → the bouncer comments
(`car`), once per club per night; with the black paint from the garage → `car_black` and egg E01.

**The dawn crowd.** Sat/Sun 05:00–09:00 (Live, or the Dawn look): 20–40 walkers on footway
paths from the three clubs to the Palm, Nowy Świat-Uniwersytet, the tram stops and two kebab
stands; `dawn_crowd` bubbles once per 25 s in view. **Łuber at dawn**: request cards from club
doors (`podwozka_request` tag `club`), passengers with `club` lines; the joke is always that you,
sober, drive them home.

**The police by the clubs**: see 3.1 (static units of the existing police MultiMesh).

**The steps crowd** (3.3): `max 80` sitters and standers in the steps sector × hour curve (10:00
0.1, 14:00 0.3, 18:00 0.6, sunset 1.0, 23:00 0.7, 01:00 0.3, 03:00 0.05) × month (Jun–Aug 1.0,
May and Sep 0.7, Apr and Oct 0.3, Nov–Mar 0.05) × rain 0.1. Without Live the season is summer
(Open Question 5).

**Flags.** `--night-log` (queue lengths, rejections, dawn walkers each minute), `--club=<name>`
(the car by that door), `--crowd=0|1|2` (off, normal, double, for A/B and the bench).
**Acceptance.** `--time=night --clock=01:00 --club=smola --night-log` logs a queue of 24 and a
rejection within 60 s; `--time=dawn` logs ≥ 20 dawn walkers within 2 min; `--crowd=0` A/B in the
bench table.

### 4.6 PÓŁNOC FM, 86,0: the late-night station

**On air** 22:00–06:00 (Live), always in the Night and Dawn looks; by day it plays "powtórki"
(reruns) at 70 % level and the host is silent. 86,0 is outside the FM band, so no real station
sits there (the rule for 86,6 and 108,8).

**Mood.** Warsaw at night, melancholy and warm: slow boom-bap and lo-fi instrumentals, sodium
light, the empty avenue, the night bus, the fog on the Palace. No vocals; the host speaks between
tracks on the ticker (text now; a voice later, Open Question 6). No track imitates any real song;
titles pass the title-collision rule.

**Host.** "Kuba z nocnej zmiany" (an invented type, no surname, no real person behind it). He
talks slowly, about the city, never names anyone, dedicates tracks to the night bus driver and the
people on the steps, and reminds that the driver doesn't drink. Lines: `radio_polnoc` (section 7).

**Track briefs** (made with `tools/make_music.py`, original, procedural, 90–120 s loops):

| # | Title | BPM | Key | Parts | Brief |
| --- | --- | --- | --- | --- | --- |
| 1 | Sód | 78 | D minor | dusty kick and snare, Rhodes 9th chords, sub bass, vinyl crackle | The orange of the sodium lamps on an empty street |
| 2 | Wiadukt | 84 | A minor | swung hats, muted piano stabs, a low string pad | Driving the Karowa viaduct's curve slowly |
| 3 | Nocna przesiadka | 80 | F minor | soft clap, a tram-bell motif played on a vibraphone, tape wobble | The night buses meeting at Centralny |
| 4 | Szkło na Woli | 88 | E minor | crisp kit, glassy plucks, a rising pad | The towers' lit floors at 2 a.m. |
| 5 | Bulwar, 23:40 | 74 | C major 7 | brushes, nylon-guitar chords (the "three chords" nod), river noise | The steps after sunset |
| 6 | Mgła nad Pałacem | 70 | B♭ minor | half-time drums, a wide choir pad, a slow bass glide | Fog; only the clock shows |
| 7 | Świt na Smolnej | 90 | G major | brighter kit, birds, a hopeful piano line | The dawn walk to the Palm |

Each chapter of the notebook unlocks one (4.1); tracks 1–2 are free from the start.

**Flags.** `--station=polnoc`, `--radio-log`. **Acceptance.** The station's lines resolve
`radio_polnoc`; at `--time=night` the host speaks every 60–120 s; at `--time=day` he doesn't.

### 4.7 How the existing systems fit

| System | Role in Moja Warszawa | Change |
| --- | --- | --- |
| Kebab | The 3 a.m. errand; stands at real places; the dawn crowd stops there | Two stands get dawn-crowd queues (Sat/Sun 05–08) |
| Słoiki | The newcomer's errand; the Hyrax station joke | none |
| Łuber | The city's taxi errand; at dawn, the sober driver for the clubbers; the Hyrax late runner | `club` tags (request, passenger), `hurry` rides to the stadium on Saturdays |
| Rescues | Real places; a dog's ball on a roof (E16) as a helicopter mini-rescue | one new kind |
| Rivals and races | Unchanged; the final race "Trzy mosty" is a night drive past the steps and the clubs | none |
| Police | Gentle; static units by two clubs at night; caution-only in Spacer | `police_club` lines, Spacer rule |
| Eggs | Move into the notebook as cards | 5 existing + 40 here |
| Radio | KEBAB FM, RONDO FM, MORDOR FM + PÓŁNOC FM | one station |
| Billboards and posters | Carry the parodies' and the night's jokes | 3 billboards, 4 posters (section 7) |
| Wallet | Notebook and Kadr respect, chapter złoty | rewards above |

---

## 5. What goes into the demo, what comes later, and the loop plan

**In the demo (the 18.6 km² box):** every theme above, at these counts: 72 notebook places, 40
eggs, 20 then spots, 15 photo spots, 17 named parody venues (3.0), 3 Wiralek slots, one steps
crowd (by Kopernik) and the Poniatówka beach, ~40 metro entrances at 10 stations, night buses at
Centralny, Kolka on Wednesdays, Hyrax on Saturdays, PÓŁNOC FM with 7 tracks, Spacer, Fotka,
KASETA. Plus everything `parodies.md` still owes (Frogs shops, Pędzik riders, Leżak scooters,
kebab to 14, billboards to 10).

**Later (the update districts, DEMO 9):** Mokotów (the tram route continued, Puławska), Żoliborz
and Dworzec Gdański, Łazienki and Trasa Łazienkowska, Praga's Koneser and Ząbkowska bars, the
neon museum in Praga, Marywilska, Pole Mokotowskie's runners, more Wiralek slots, a voice for the
host, sharing photos (Share plugin), seasons beyond summer (snow on the steps, Christmas lights on
Krakowskie Przedmieście).

**Order.** After the map work: DEMO 7's loops 3d (demo bake), 3e (structures), 3f (tier-A
landmarks), then these loops, then 3h (the demo loop) can count the notebook as district
completion. Loop 2d-2 (the unbuilt half of `parodies.md`) is folded into MW-2.

| # | Loop | Goal | Acceptance | Phone budget |
| --- | --- | --- | --- | --- |
| 1 | **MW-0: data and lines** (game-designer, now; no code) | `places.json` (72 places), `then_cards`, the section 7 lines merged into `dialogue.json`, the brand denylist for 3k, Apteczka's street | JSON parses; every line PL + EN, ≤ 70 characters, no repeat; the title-collision check done and noted | +0 |
| 2 | **MW-1: the notebook** (map-engineer bake + gameplay-dev) | `pois` kind `place` and the venue anchors (3.x OSM tags) in the 3d bake; the MOJA WARSZAWA tab, finding, cards, rewards, minimap "?" | `check_places.gd` green; `--place=<id> --notes-log` finds each of 10 sample places; HUD shots at 375/390/440 pt | HUD ≤ +5 2D draw calls when open, 0 closed; scripts ≤ 0.02 ms (2 Hz grid check) |
| 3 | **MW-2: storefronts and parodies** (= 2d-2 folded) | Frogs, Pędzik, Leżak, 14 kebab stands, 10 billboards (`parodies.md` 10), and the 17 venues as named neon fascias in `neon_signs.gd`, the metro entrances | `parodies.md` section 10's checks; each venue at its address within 0.3 m of the facade; art-director: no real brand readable | parodies.md 8's ≤ +15/17/20 draw calls; venues +0 (the neon atlas); metro entrances +1 per sector with any |
| 4 | **MW-3: the night and the river** (after 3g-2) | City clock + Dawn look, queues, the door, the dawn crowd, police by the clubs, the steps crowd, Hocki Bloki's lights, Łuber `club` | 4.5's acceptance; shots at night 01:00 on Smolna, dawn at the Palm, dusk on the steps, at phone size | crowd MultiMesh per sector, 2 poses: ≤ +2 draw calls in view, ≤ 25 k triangles, no sun shadow; scripts ≤ 0.04 ms |
| 5 | **MW-4: everyday life and trends** | Dog walkers, cyclists and Rowerilo docks, runners, Kolka and the Zając, Hyrax Saturdays, the Wiralek cycle and the "Na czasie" job, Fat Thursday | `--dogs-log`, `--trend-log` (`trend: slot 1 day 3 queue 20`), `--zajac --autopilot` pays once; a 10-minute soak, no dog or rider overlapping the car | dogs: one city MultiMesh, +1 draw call; riders share Pędzik's (+0); scripts ≤ 0.05 ms |
| 6 | **MW-5: PÓŁNOC FM and the city's sounds** | The station, 7 tracks, the host; the club leak, steps crowd, guitar, barks, bells, metro chime | `--station=polnoc --radio-log`; each sound plays at its place (a headless check of emitters); levels by ear on the phone | audio only; ≤ 8 positional emitters live at once *guess* |
| 7 | **MW-6: Fotka, Spacer, KASETA, the eggs** | Photo mode and 15 Kadr spots, Spacer, the time tape at 20 spots, the 40 eggs wired, the then cards | 4.2–4.4 acceptance; every egg's flag logs its reward (`--egg=<id>`) | ghosts ≤ +1 draw call within 150 m of a spot; Fotka 0 when closed |

Total at the default view after MW-1 to MW-6 (above 2d's own allowance): **≤ +8 draw calls**,
≤ +40 k triangles, ≤ 0.15 ms of script on the Mac, ≤ +6 MB. Each loop reports README rule 9's
numbers before and after and a phone BENCH card from both phones.

---

## 6. Cost on the phone (README "Performance budgets")

| Item | How | Draw calls (default / zoomed out / heli) | Triangles | Script |
| --- | --- | --- | --- | --- |
| Venue fascias (17) and the old neons | `neon_signs.gd` entries, the existing atlas | +0 | +0.5 k | 0 |
| Queues, dawn crowd, steps crowd, Plan C crowd | one static crowd MultiMesh per sector, two poses (stand, sit), the pedestrian mesh (≤ 300 tris), rewritten every 20–40 s; no sun shadow | +2 / +2 / +3 | ≤ 25 k in view | ≤ 0.04 ms |
| Dog walkers | the walker in `pedestrians.gd`, the dog in one city MultiMesh (pool 16, ≤ 120 tris, no shadow, `fine_detail`) | +1 / 0 / 0 | ≤ 2 k | ≤ 0.03 ms |
| Cyclists, Rowerilo, cargo bikes | Pędzik's rider MultiMesh, instance colours; docks a per-tile prop MultiMesh | +0 / +1 / +1 | ≤ 6 k | ≤ 0.02 ms |
| Runners, Kolka, Hyrax | pedestrians at run speed; Hyrax's barriers are the roadworks MultiMesh | +0 | ≤ 4 k | ≤ 0.01 ms |
| Metro entrances | per-tile prop MultiMesh (≤ 300 tris, the M post lit by `Models.material()`) | +1 / +2 / +2 | ≤ 3 k | 0 |
| Night buses | traffic buses with an N sign (instance custom) | +0 | 0 | 0 |
| KASETA ghosts | ≤ 24 boxes, only near a spot | +1 near a spot, else 0 | ≤ 1 k | 0 |
| Notebook, Fotka | HUD cards when paused | 2D ≤ +5 when open | — | 0 when closed |
| Discovery checks, clock, trend cycle | one 2 Hz grid query, 1 Hz state updates | 0 | — | ≤ 0.03 ms |
| **Total** | | **≤ +5 / ≤ +6 / ≤ +7** (≤ +8 near a tape spot) | **≤ +40 k** | **≤ 0.15 ms** |

The phone has more room at the default view than zoomed out or flying (README), and the crowds
are near-view things, so `--crowd` halves them on the Low tier and the governor may drop the steps
crowd to half (README rule 10). Memory ≤ +6 MB (7 tracks streamed, ~2 MB of meshes and data).

---

## 7. Lines (to merge into game/data/dialogue.json)

103 original lines (95 bubbles and cards, 4 billboards, 4 posters). New groups: `radio_polnoc`, `club_door`, `clubbers`, `dawn_crowd`,
`police_club`, `schodki`, `viral`, `runners`, `dog_walkers`, `cyclists`, `metro_announce`,
`bus_stop`, `notes`; additions to `podwozka_request`, `podwozka_passenger`, `radio_host`, `signs`,
`column_posters`. Polish bubbles ≤ 70 characters. Checked against today's file (grep: selekcj,
okular, schod, metro, pies, rower, biega, matcha, kolejk, Rotund, tak.): no repeats; the remont
and kebab callbacks are deliberate with new punchlines. Speakers: "PÓŁNOC FM" (Kuba), "Bramka"
(the bouncer), a first name for passengers, "Sierżant Bogdan" for `police_club`, "Metro" for
announcements, untagged crowd lines with no speaker.

```json
{
  "radio_polnoc": [
    ["Północ FM, 86,0. Miasto ściszone do połowy. My też.", "Północ FM, 86.0. The city's turned down to half. So are we."],
    ["Marszałkowska o drugiej wygląda, jakby ktoś ją wynajął na film.", "Marszałkowska at two a.m. looks like someone hired it for a film shoot."],
    ["Pałac we mgle. Widać tylko zegar. Która godzina? Późna.", "The Palace in fog. Only the clock shows. What time is it? Late."],
    ["Ostatni tramwaj odjechał. Pierwszy jeszcze śpi. Jesteśmy pomiędzy.", "The last tram's gone. The first is still asleep. We're in between."],
    ["Pozdrawiam kolejkę na Smolnej. Stoicie pięknie. Prawie jak w PRL-u.", "Hello to the queue on Smolna. Lovely queuing. Almost like the old days."],
    ["Wisła płynie w stronę morza, a my w stronę rana. Bez pośpiechu.", "The Vistula flows towards the sea, and we flow towards morning. No rush."],
    ["Ktoś na schodkach gra te same trzy chwyty. Pół Powiśla już umie.", "Someone on the steps is playing the same three chords. Half of Powiśle knows them now."],
    ["Słuchacz z Woli widzi z biura trzy inne biura. I Pałac. Zawsze Pałac.", "A listener in Wola can see three other offices from his. And the Palace. Always the Palace."],
    ["Na Centralnym nocne autobusy zjeżdżają się jak starzy znajomi.", "At Centralny the night buses gather like old friends."],
    ["Jest czwarta. Ptaki już wiedzą. Taksówki jeszcze nie.", "It's four. The birds already know. The taxis don't yet."],
    ["Lampy sodowe robią z każdej ulicy wspomnienie. Nawet z Kruczej.", "Sodium lamps turn every street into a memory. Even Krucza."],
    ["Ten kawałek leci dla wszystkich, którzy jadą do domu, a nie z domu.", "This one's for everyone driving home, not away from it."],
    ["Kierowca nie pije. Kierowca wiezie. Reszta niech śpiewa.", "The driver doesn't drink. The driver drives. Everyone else can sing."],
    ["Na Zbawiciela nowa kawiarnia. Poprzednia była nowa w czwartek.", "A new café on Plac Zbawiciela. The last one was new on Thursday."],
    ["Witamy z powrotem w centrum. Tu nawet cisza ma korek.", "Welcome back to the centre. Even the silence has a traffic jam here.", {"only": "south_gate"}]
  ],
  "radio_host": [
    ["W sobotę Hyrax przy Narodowym. Prosimy nie gonić tramwajów.", "Hyrax by the National Stadium on Saturday. Please don't chase the trams."]
  ],
  "club_door": [
    ["Nie dziś. Ale buty ładne.", "Not tonight. Nice shoes, though.", {"only": "reject"}],
    ["Dziś tylko ci, co wiedzą, kto gra. A ty nie wiesz.", "Tonight's only for people who know who's playing. You don't.", {"only": "reject"}],
    ["Za kolorowo. Wróć na czarno.", "Too colourful. Come back in black.", {"only": "reject"}],
    ["Uśmiechasz się. Tu się nie uśmiechamy. Następny.", "You're smiling. We don't smile here. Next.", {"only": "reject"}],
    ["Sześciu chłopaków naraz? Spróbujcie w Lombardzie.", "Six lads at once? Try Lombard.", {"only": "reject"}],
    ["Kolejka idzie. Powoli, ale idzie. Jak remont.", "The queue is moving. Slowly, but it's moving. Like the roadworks.", {"only": "queue"}],
    ["Samochód nie wchodzi. Nawet ładny.", "The car isn't getting in. Not even a nice one.", {"only": "car"}],
    ["Czerwony hatchback. Dziś wchodzi tylko czerń. Sorry.", "A red hatchback. Tonight it's black only. Sorry.", {"only": "car"}],
    ["Kierowca? Szacunek. Woda gratis, ale wejść nie wejdziesz.", "The driver? Respect. Free water, but you're still not coming in.", {"only": "car"}],
    ["Czarny lakier. Spokój w oczach. Wjeżdżasz.", "Black paint. Calm eyes. You're in.", {"only": "car_black"}],
    ["Jest dziewiąta rano. Selekcja dalej obowiązuje.", "It's nine in the morning. The door policy still applies.", {"only": "dawn"}]
  ],
  "clubbers": [
    ["Stoimy godzinę. Nie wiem, czy chcę wejść, ale już nie odpuszczę.", "We've queued an hour. Not sure I want in, but I'm not giving up now."],
    ["Powiedz, że jesteś z Berlina. Nie, nic nie mów. Patrz w dal.", "Say you're from Berlin. No, say nothing. Stare into the distance."],
    ["Mam czarną koszulkę, czarne spodnie i stres.", "Black T-shirt, black trousers and stress."],
    ["W środku nie wolno robić zdjęć. Więc zrobię jedno w kolejce.", "No photos inside. So I'll take one in the queue."],
    ["Jak nie wejdziemy, to kebab i do domu. Plan C.", "If we don't get in, it's a kebab and home. Plan C."],
    ["Ten bramkarz pamięta mnie z zeszłego tygodnia. To źle.", "That bouncer remembers me from last week. That's bad."]
  ],
  "dawn_crowd": [
    ["Okulary? Nie dla stylu. Po prostu słońce jest dziś bezczelne.", "The sunglasses? Not for style. The sun is just rude today."],
    ["Wyszliśmy o siódmej. Miasto idzie do pracy, my wracamy.", "We came out at seven. The city's off to work, we're heading home."],
    ["Która godzina? Niedziela.", "What time is it? Sunday."],
    ["Pierwszy tramwaj, kebab i spać. Rytuał.", "The first tram, a kebab, then bed. A ritual."],
    ["Gołębie patrzą na nas z wyższością. Mają rację.", "The pigeons look down on us. They have a point."],
    ["Bierzemy Łubera. Nikt z nas nie prowadzi, i bardzo dobrze.", "We're getting a Łuber. None of us is driving, and that's how it should be."],
    ["Dzień dobry, Palmo. Ty też całą noc na nogach?", "Good morning, Palm. You've been up all night too?", {"only": "palm"}]
  ],
  "police_club": [
    ["Selekcja nas też nie wpuściła. Stoimy więc tutaj.", "The door didn't let us in either. So we stand here."],
    ["Jesteśmy tu co weekend. Dla wschodu słońca. Ładny stąd.", "We're here every weekend. For the sunrise. Lovely from here."],
    ["Kacper pyta, czemu wszyscy w okularach. Bo rano, Kacper.", "Kacper asks why everyone's in sunglasses. Because it's morning, Kacper."],
    ["Trzeźwy i za kółkiem? Wzorowo. Proszę jechać.", "Sober and behind the wheel? Exemplary. On you go.", {"only": "sober"}]
  ],
  "schodki": [
    ["Kto przyniósł głośnik? Przyznać się.", "Who brought the speaker? Own up."],
    ["Zachód słońca nad Pragą. Pół miasta udaje, że nie robi zdjęcia.", "Sunset over Praga. Half the city pretending not to take a photo.", {"only": "sunset"}],
    ["Siedzimy tu od szóstej. Plan był na godzinę.", "We've been sitting here since six. The plan was an hour."],
    ["Najlepsze miejsce w mieście i nikt nie płaci za wstęp.", "The best seat in town, and nobody pays to get in."],
    ["Jeszcze jedna piosenka i idziemy. Mówimy tak od dziewiątej.", "One more song and we'll go. We've been saying that since nine.", {"only": "guitar"}],
    ["Koc, lemoniada, pies. Weekend kompletny.", "A blanket, lemonade, a dog. Weekend complete."],
    ["Wisła dziś leniwa. My też, solidarnie.", "The Vistula's lazy today. So are we, in solidarity."],
    ["Czwarty chwyt! Świat się zmienia.", "A fourth chord! The world is changing.", {"only": "fourth"}]
  ],
  "viral": [
    ["Stoję po rogala, którego nie widziałem. Ale widziałem film.", "Queuing for a croissant I've never seen. But I've seen the video.", {"only": "queue"}],
    ["Kolejka jest częścią smaku. Tak mówią.", "The queue is part of the flavour. So they say.", {"only": "queue"}],
    ["Zdjęcie jest. Rogal też był. Chyba.", "Got the photo. There was a croissant too. I think.", {"only": "queue"}],
    ["Nowe miejsce. Otwarte od jutra, kolejka od dziś.", "New place. Opens tomorrow, queue starts today.", {"only": "new"}],
    ["W zeszłym tygodniu kolejka na dwie przecznice. Dziś tylko gołąb.", "Last week the queue went round two blocks. Today, one pigeon.", {"only": "gone"}],
    ["Trend minął. Zostało różowe krzesło i wspomnienia.", "The trend's over. A pink chair and the memories remain.", {"only": "gone"}],
    ["Glon: zielone, zdrowe i podobno smaczne. Podobno.", "Glon: green, healthy and allegedly tasty. Allegedly.", {"only": "glon"}],
    ["To już niemodne. Napiwku nie będzie, sorry.", "That's not trendy any more. No tip, sorry.", {"only": "late"}]
  ],
  "runners": [
    ["Środa, dziewiętnasta, bulwary. Kolka zawsze punktualnie.", "Wednesday, seven p.m., the boulevards. Kolka is always on time."],
    ["Biegniemy dziesięć kilometrów, żeby potem stać w kolejce po kawę.", "We run ten kilometres so we can queue for coffee afterwards."],
    ["Zegarek mówi, że żyję. Nogi mają inne zdanie.", "My watch says I'm alive. My legs disagree."],
    ["Ej, samochód robi nam za zająca! Trzymaj tempo, auto!", "Hey, the car's pacing us! Keep it steady, car!", {"only": "zajac"}],
    ["Hyrax w sobotę. Od tygodnia noszę do pracy worek piasku.", "Hyrax on Saturday. I've carried a sandbag to work all week.", {"only": "hyrax"}],
    ["Stacja trzecia: słoiki po schodach. Mama byłaby dumna.", "Station three: carry the jars up the stairs. Mum would be proud.", {"only": "hyrax"}]
  ],
  "dog_walkers": [
    ["On nie gryzie. On tylko ocenia.", "He doesn't bite. He just judges."],
    ["Mamy trzy spacery dziennie. Jeden mój, reszta jego.", "We do three walks a day. One is mine, the rest are his."],
    ["Nie, to nie jest jamnik. To jest styl życia.", "No, it isn't a dachshund. It's a lifestyle."],
    ["Na Powiślu pies ma więcej znajomych niż ja.", "In Powiśle the dog has more friends than I do."],
    ["Pies szczeka na klakson. Ja też bym szczekał.", "The dog barks at horns. So would I.", {"only": "horn"}],
    ["Ma więcej obserwujących niż ja. I lepsze światło.", "He's got more followers than me. And better lighting.", {"only": "influencer"}]
  ],
  "cyclists": [
    ["Ścieżka rowerowa to nie parking. Ale dzięki za zaufanie.", "A bike lane isn't a car park. But thanks for the trust.", {"only": "lane"}],
    ["Rowerilo oddany po 19:59. Gratis. Jestem logistykiem.", "Rowerilo docked at 19:59. Free ride. Logistics genius."],
    ["Rower cargo, dwoje dzieci, zakupy i pies. I tak jestem szybszy.", "A cargo bike, two kids, the shopping and a dog. Still faster than you."],
    ["Mam dzwonek i nie zawaham się go użyć.", "I've got a bell and I'm not afraid to use it."]
  ],
  "metro_announce": [
    ["Stacja Centrum. Przesiadka na M2 i na życie towarzyskie.", "Centrum. Change here for line M2 and for your social life."],
    ["Świętokrzyska: tu M1 spotyka M2. Za każdym razem wzruszające.", "Świętokrzyska: where M1 meets M2. Moving every time."],
    ["Stadion Narodowy. W dniu meczu wysiada cały wagon. I sąsiedni.", "Stadion Narodowy. On match days the whole carriage gets off. And the next one."],
    ["Kopernik. Wysiądź, jeśli chcesz wiedzieć, czemu wszystko.", "Kopernik. Get off here if you want to know why everything."],
    ["Rondo Daszyńskiego. Mordor Zachodni. Proszę zabrać laptopa.", "Rondo Daszyńskiego. Western Mordor. Please take your laptop with you."],
    ["Drzwi się zamykają. Ostatni wbiega zawsze ten z kawą.", "The doors are closing. The last one in is always the one with a coffee."],
    ["Nowy Świat-Uniwersytet. Wyjście na wykład i na kebab.", "Nowy Świat-Uniwersytet. Exits for lectures and for kebab."]
  ],
  "bus_stop": [
    ["Rozkład mówi: za dwie minuty. Rozkład jest optymistą.", "The timetable says two minutes. The timetable is an optimist."],
    ["Tablica od pięciu minut pokazuje „1 min”.", "The board has said \"1 min\" for five minutes."],
    ["Stoję na przystanku na żądanie. Żądam.", "I'm at a request stop. I'm requesting."],
    ["Autobus był pełny, więc czekam na następny. Też pełny.", "The bus was full, so I'm waiting for the next. Also full."],
    ["Nocny autobus: jedyne miejsce, gdzie wszyscy są szczerzy.", "The night bus: the only place where everyone's honest.", {"only": "night"}],
    ["Kierowca nocnego zna wszystkie historie miasta. Nie zdradzi żadnej.", "The night bus driver knows every story in this city. He won't tell one.", {"only": "night"}]
  ],
  "podwozka_request": [
    ["Uwagi: „stoję przed klubem, w okularach, jak wszyscy”.", "Note: \"outside the club, in sunglasses, like everyone\".", {"only": "club"}]
  ],
  "podwozka_passenger": [
    ["Dobrze, że to ty prowadzisz. Ja mam siłę tylko na pas.", "Good thing you're driving. I've only got the strength for the seatbelt.", {"only": "club"}],
    ["Można przez most? Chcę zobaczyć Wisłę, zanim zasnę.", "Can we take the bridge? I want to see the Vistula before I fall asleep.", {"only": "club"}]
  ],
  "notes": [
    ["Nowy wpis w notesie.", "New notebook entry.", {"only": "found"}],
    ["Rozdział pełny. Miasto mówi: dzięki.", "Chapter complete. The city says thanks.", {"only": "chapter"}],
    ["Kadr! Ten widok jest twój.", "Got the shot! This view is yours.", {"only": "kadr"}]
  ],
  "signs": [
    ["PÓŁNOC FM · 86,0 · MIASTO PO CICHU", "PÓŁNOC FM · 86.0 · THE CITY, QUIETLY"],
    ["HYRAX · BIEGNIJ, NIEŚ, WCHODŹ PO SCHODACH", "HYRAX · RUN, CARRY, CLIMB THE STAIRS"],
    ["ROWERILO · DZWONEK W CENIE", "ROWERILO · BELL INCLUDED"],
    ["WIRALEK · NOWOŚĆ TYGODNIA. ZNOWU.", "WIRALEK · NEW THIS WEEK. AGAIN."]
  ],
  "column_posters": [
    ["ZGUBIONE OKULARY. CZARNE. KAŻDE.", "Lost: sunglasses. Black. Every pair.", {"poster": ["ZGUBIONE", "OKULARY.", "CZARNE.", "KAŻDE."]}],
    ["KOLKA BIEGA W ŚRODY 19:00", "Kolka runs on Wednesdays at 7 p.m.", {"poster": ["KOLKA", "BIEGA", "W ŚRODY", "19:00"]}],
    ["NOWY TREND OD WTORKU", "New trend from Tuesday", {"poster": ["NOWY", "TREND", "OD", "WTORKU"]}],
    ["PLAN A: DOM. PLAN C: ZOSTAJĘ.", "Plan A: home. Plan C: I'm staying.", {"poster": ["PLAN A:", "DOM.", "PLAN C:", "ZOSTAJĘ."]}]
  ]
}
```

The venue neon words (`neon_signs.gd`, not dialogue): LUSTERKO, SMOŁA, JASNA 0, LEVEL 26,
PLAN C, APTECZKA, LOMBARD, MIŁOŚĆ HIPOTECZNA, 1499 M2, HOCKI BLOKI, SYRENI SZEPT, PRZEGRYZKI
ZAGRYZKI, KASA BILETOWA, ŻWIR, BAR PYZOWY, LUKROWNIA, GLON, WIRALEK, MERDAK, ROWERILO; generic:
KLUB, PŁYTY, CIUCHY, VINTAGE, MEBLE Z PRL, PIEKARNIA, RYBY, MODA, FOTO, KSIĄŻKI, OBUWIE, RADIO TV.
Every character is in `pixel_font.gd` (no "²": written M2).

---

## 8. Easter eggs (40)

Each first find: a notebook card and the reward shown. Flags: `--egg=<id>` puts the car at the
spot in the right time, weather and weekday; `--egg-log` prints the trigger and the reward.

| ID | Egg | Place | Trigger | Reward |
| --- | --- | --- | --- | --- |
| E01 | Czarny lakier · Black paint | Lusterko, Al. Jerozolimskie 6 | Car painted black at the garage, past the door < 10 km/h, Fri/Sat 23–06 | `club_door` car_black, +50 respect |
| E02 | Niedziela o dziewiątej · Sunday at nine | Lusterko | Live Sunday 08–11 (or `--date`), stop 3 s by the morning queue | dawn line, +30 respect |
| E03 | Dzień dobry, Palmo | Rondo de Gaulle'a | Dawn crowd present, stop within 30 m of the Palm | `dawn_crowd` palm, +20 |
| E04 | Selekcja policji | opposite Smoła, Smolna | Stop beside the parked patrol car at night | `police_club` 1, +20 |
| E05 | Level 26 na 28. piętrze | Al. Jerozolimskie 123A | Helicopter hovering beside the top floor at night, 3 s | Card "Winda wie", +40 |
| E06 | Mazowiecka slow | Mazowiecka | Drive its whole length ≤ 20 km/h after 23:00 | every door's `car` line, +30 |
| E07 | Kredyt na miłość | Miłość Hipoteczna, Kredytowa 9 | Stop 2 s at night | Card "Miłość na 30 lat, oprocentowanie zmienne", +20 |
| E08 | O metr mniej | 1499 M2, Emilii Plater 29 | Pass within 20 m | Card "Teraz o metr mniej. Czynsz ten sam.", +15 |
| E09 | Hocki Bloki z mostu | Most Poniatowskiego above Solec | Stop on the bridge's footway side 3 s after 22:00 in summer | the venue's music rises, +20 |
| E10 | Plac C | Plac Zbawiciela | One full lap of the square ≤ 20 km/h while the summer crowd is out | `clubbers` Plan C line, +30 |
| E11 | Labirynt Pawilonów | Nowy Świat 22/28 | Helicopter over the courtyards at night, 3 s | Card with a map of the maze, +20 |
| E12 | Jeden normalny do Powiśla | Kasa Biletowa, Kruczkowskiego 3B | Stop by the pavilion | Card "Bilet w jedną stronę: na leżak", +15 |
| E13 | Ogród na dachu | the university library, Dobra | Land the helicopter on the roof garden's lawn | +40, a Kadr spot unlocked |
| E14 | Brawa dla słońca · Applause for the sun | the steps by Kopernik | Summer sunset (Live) or Dusk with the crowd ≥ 0.8, stop within 40 m | applause, PÓŁNOC FM track 5, +40 |
| E15 | Czwarty chwyt · The fourth chord | the steps | Stop by the guitarist on three different in-game days | `schodki` fourth, +30 |
| E16 | Aport · Fetch | the Kopernik pavilion roof → the boulevard | A rescue-style call: a dog's ball on the roof; fetch it with the helicopter (< 4 m) and drop it within 8 m of the dog | +40, `dog_walkers` line |
| E17 | Pokaz fontann | the fountain park at Podzamcze | Summer Fri/Sat at Dusk, stop 5 s | the water-and-light show, +20 |
| E18 | Cykl życia trendu | any Wiralek slot | See one slot on day 1, day 4 and its "WKRÓTCE" day | Card "Kolejka, fotka, następne miejsce", +40 |
| E19 | Trzy kolejki naraz | the three Wiralek slots | All three on day 1 at once (a rare overlap, ~1 in 12 weeks) | +50 |
| E20 | Tłusty Czwartek | Lukrownia, Nowy Świat | Fat Thursday (Live or `--date`), drive past the queue | Card, +30, a free pączek pop |
| E21 | Pasujesz do menu | Glon | Car painted green, stop 2 s | `viral` glon, +15 |
| E22 | Tu się krzyżują · They cross here | Marszałkowska × Świętokrzyska | Stop above the M1 × M2 crossing 5 s at night | double rumble, card, +20 |
| E23 | Nocny węzeł | Dworzec Centralny | Be at the bus ring when 5+ night buses stand there | `bus_stop` night, +30 |
| E24 | Na żądanie | any bus stop | Stop at a stop and honk once | a bus pulls in for you, `bus_stop` 3, +15 |
| E25 | Wyścig z nocnym | Jerozolimskie, Centralny → Rondo de Gaulle'a | Beat a night bus to the Palm without speeding past a trap | +30 |
| E26 | Godzina pyz | Bar Pyzowy, Marszałkowska | Weekday 13:00 (Live or `--clock=13:00`), stop by the lunch queue | then card T8, +15 |
| E27 | Pies influencer | Plac Zbawiciela | Stop by the dog with its photographers | `dog_walkers` influencer, +15 |
| E28 | 19:59 | a Rowerilo dock | Follow a Rowerilo rider 400 m to a dock | `cyclists` 2, +20 |
| E29 | Zając · The pacer | Wybrzeże Kościuszkowskie | Pace Kolka (9–14 km/h, 600 m, lateral ≤ 25 m), Wednesday 19–20 or `--egg` | `runners` zajac, +40 |
| E30 | Meta Hyraxa | Stadion Narodowy forecourt | Saturday race on; drive the cordon's full lap ≤ 20 km/h | `runners` hyrax, +30 |
| E31 | Na winylu będzie? | Żwir, Kredytowa 9 | Stop by the shop with PÓŁNOC FM on | card, PÓŁNOC FM track 2, +20 |
| E32 | Piłka spada od 1961 | Plac Konstytucji | Stop under the volleyball neon at night 3 s | the ball's three frames, then card T7, +20 |
| E33 | Pierwszy drapacz | Plac Powstańców Warszawy | Helicopter circle round the 1930s tower | Card, +20 |
| E34 | Fotel z PRL | Mokotowska | Pass the man carrying the 1960s armchair (rare, 1 in 3 days) | Card, +20 |
| E35 | Blaszak | Plac Defilad | KASETA at T1 | ghost of the blue hall, +15 |
| E36 | Bazar na Stadionie Dziesięciolecia | Stadion Narodowy | KASETA at T2 | ghost bowl and stalls, +15 |
| E37 | Najdłuższy remont | Świętokrzyska | KASETA at T4 while today's roadworks are on Świętokrzyska (a rare date) | a double ghost, +40 |
| E38 | Pałac się nie przejmuje | the Palace and Varso | Helicopter between the Palace's spire and Varso's at ≥ 60 m | then card T12, +20 |
| E39 | Zabytkowy tramwaj | the tram tracks | Summer weekend (Live): a tram in old livery runs; follow it 300 m | then card T13, +30 |
| E40 | Karta na 25 impulsów | the old payphone (Plac Konstytucji) | Stop by it | then card T17, +10 |

The five existing eggs (the Palm, pigeons, roadworks, Patelnia, the Mermaid) and `parodies.md`'s
two (the Frogs triple corner, the standing Leżak) join the notebook too: 47 egg cards in all.

---

## 9. 2D art for PixelLab (≤ 60 generations; nothing generated yet)

Follow `.claude/skills/pixellab/SKILL.md`: `get_balance` first, explore with the 1-generation
tool, no text, brand or real person in any image, saved with provenance under `game/art/<kind>/`.
Base palette in every call (as `parodies.md` 9): `#fbf7ee`, `#c9c2d8`, `#ffd23f`, `#3a3b3f`,
`#34404e`, `#a8cde6`; plus the item's colours. Single dark outline, basic shading, `max_colors`
8–16 for icons, ≤ 32 for billboards. **Split across two loops** to keep under 50 a loop: MW-1
takes rows 1–3 (24), MW-3/MW-5 the rest (32).

| # | Asset | Tool, size | Prompt | Item colours | Gens |
| --- | --- | --- | --- | --- | --- |
| 1 | 9 notebook chapter icons (night, bars, steps, trends, metro, food, everyday, retro, then) | `create_image_pixen`, 16 px, no background, 1 explore each + 1 retry pool of 4 | e.g. "tiny icon of a club door with a rope barrier, flat, bold outline"; "tiny icon of wide stone steps by water"; "tiny icon of a queue of three small figures"; "tiny icon of a square sign with one letter shape, no readable text"; "tiny icon of a kebab"; "tiny icon of a dog on a lead"; "tiny icon of a vinyl record"; "tiny icon of a cassette tape" | per icon | 13 |
| 2 | Notebook "?" place marker and "found" stamp | `create_image_pixen`, 16 px | "tiny round ink stamp mark, hand-drawn circle", "tiny question mark shape in a circle, no letters" (if it draws a glyph, use the pixel font instead) | `#ffd23f` | 2 |
| 3 | KADR camera icon and KASETA tape icon (HUD context button) | `create_image_pixen`, 16 px | "tiny vintage camera icon, flat"; "tiny cassette tape icon with a rewind feel, flat" | `#1ae6ff`, `#ff1a8c` | 4 + 5 retries = 9 |
| 4 | Portrait: the bouncer (Bramka) | `create_portrait_character`, 64 px | "broad-shouldered nightclub doorman in black, arms folded, calm stern face with a hint of a smile, invented character, front view" | `#1f1f22` | 10 |
| 5 | Portrait: the PÓŁNOC FM host "Kuba" | `create_portrait_character`, 64 px | "late-night radio host in a dark hoodie with big headphones round the neck, tired kind eyes, soft lamp light, invented character, front view" | `#9e40ff`, `#ff9a3c` sodium | 10 |
| 6 | Billboard art: PÓŁNOC FM | `create_image_pixen`, 128 × 64 | "billboard illustration of an empty city avenue at night under orange street lamps, a tall old palace tower in fog, no text, no people" | `#ff9a3c`, `#34404e` | 2 |
| 7 | Billboard art: HYRAX | same | "billboard illustration of a cheerful rock hyrax mascot running up stadium stairs with a small sandbag, speed lines, no text, no logos" | `#c9a46b`, `#a8cde6` | 2 |
| 8 | Billboard art: ROWERILO | same | "billboard illustration of a cream city bicycle with a grey front basket by a river promenade at sunset, no text, no logos" | `#fbf7ee`, `#8a8d91` | 2 |
| 9 | Wiralek trend pictograms (8 on one sheet) | `create_image_pixen`, 128 × 32 | "row of eight tiny food pictograms: a cube-shaped croissant, a cracked chocolate bar with green filling, a cup of strawberries, a green drink with a whisk, a doughnut with a cream swirl, a tall cup with dark pearls, a giant cookie, a pink wall with a wing shape; no text" | — | 2 |
| 10 | Hyrax mascot for the banner and posters | `create_image_pixen`, 32 px | "cute rock hyrax standing upright like an athlete, headband, front view" | `#c9a46b` | 2 |
| 11 | People-type stamps for notebook cards (bouncer, runner, dog walker, cyclist) | `create_image_pixen`, 24 px | "tiny pixel figure of [a runner in a bright top / a person walking a small dog / a cyclist with a basket / a doorman in black], side view" | per type | 4 |
| | **Total** | | | | **58** |

The venue signs, neons, posters and the volleyball neon are built in code with the pixel font,
not textures. If an explore wins and needs `create_image_pro` (10–25), that needs the user's yes.

---

## 10. Open questions (each with the default this file uses)

**The user's answers (2026-10-29); where they differ from a default below, the answer wins:**
1 yes, (a) as written. 2 APTECZKA goes "in some centre": the Pawilony courtyards off Nowy Świat
stand. 3 **from 2010 on**: the then-and-now set (KASETA) covers 2010 to today only (the M2 dig,
Euro 2012 and the stadium build, Plac Defilad's changes, the riverside boulevards' rebuild, the
viral spots' turnover); the 1990s–2000s items and the three older ones move to "later". 4 yes,
always Friday. 5 yes, always a summer evening. 6 skip the host's voice for now (text only). 7 the
orchestrator's call: Miasto stays the default, Spacer offered once at the first pause. 8 the
orchestrator's call: reuse the existing ghost dither; a new shader only if it costs no draw call
and the art director signs it off. 9 yes, our own drawing. 10 and 11 the defaults. 12 yes, keep
the poster.

1. **How much night-scene content.** The clubs, queues and dawn crowd are a big part of this
   direction. Options: (a) as written (three clubs with queues, a tower club, Mazowiecka, the dawn
   crowd); (b) lighter: queues only at Lusterko and Smoła, no dawn crowd; (c) heavier: a full
   "Noc klubowa" chapter with a late-night job (lifts home all night). *Default: (a).*
2. **Apteka's street.** No bar named Apteka was found in Warsaw. Which street is it on? *Default:
   APTECZKA goes in the Pawilony courtyards off Nowy Świat until the user says.*
3. **Which decades.** The then-and-now set is mostly 1990s–2010s (the blue hall, the stadium
   bazaar, Euro 2012, the M2 dig) with three older items (1896 milk bar, the 1960s Rotunda and
   neon). Options: add the 1970s–80s (queues for everything, the 1970s buses), or keep the
   user's own ten years only. *Default: 1990s–2010s plus the three older items.*
4. **"Zawsze piątek" (always Friday).** Without Live, the night is always Friday and the dawn
   always Saturday. Option: a weekday picker in Settings. *Default: always Friday; Live uses the
   real day.*
5. **The season without Live.** *Default: always summer evening (the steps full), Live uses the
   real month (the steps nearly empty in November).* Option: a season setting.
6. **The host's voice.** Text on the ticker now. Options: a hired Polish voice actor later, or
   text only forever (never a synthetic imitation of any real voice). *Default: text now; a hired
   voice actor is a decision for the release.*
7. **Spacer as the default.** *Default: "Miasto" (jobs and calls arrive) stays the default, with
   Spacer one tap away in Settings and offered once at the first pause.* Option: Spacer by
   default, which fits "not about the gameplay" best.
8. **The KASETA ghosts' look.** If `Models.material()` can't dither, the ghosts need a shader
   variant (a rule-5 exception). *Default: try the existing dither; ask before a new shader.*
9. **The volleyball neon.** It is a real 1961 artwork on Plac Konstytucji (protected). Building
   our own pixel version of "a neon volleyball player" there is a landmark tribute; tracing the
   original design would copy a work. *Default: our own drawing, a player and a ball, no trace.*
10. **Near-miss closeness.** Some names are one character off the real ones (Level 26, Plan C,
    Jasna 0, Hyrax, 1499 M2), which is what the user asked. A real venue could still object.
    *Default: proceed; loop 3k's register search re-checks each, and any name a venue objects to
    is swapped for a wordplay (Plan C → Plan Awaryjny, Level 26 → Antresola, Jasna 0 → Piwnica
    na Jasnej).*
11. **The songs list.** The places are built as places with no link to the songs. Option: a
    hidden notebook spread that groups them. *Default: no spread, no label, nothing in the game
    that points at the source.*
12. **"Plan A: dom. Plan C: zostaję."** The poster nods to the real bar by leaving out B.
    *Default: keep;* option: drop it if it reads too close.

---

## Sources (read for facts and checks; no text copied)

- The demo box, systems and budgets: docs/DEMO.md, docs/design/parodies.md, docs/design/police.md,
  README.md, the art bible, game/data/dialogue.json.
- Places from the songs (place names only, no lyrics or titles taken): the fan map
  https://mapatacohemingway.pl/ ; https://newonce.net/artykul/10-warszawskich-miejscowek-z-kawalkow-taco-hemingwaya-miniprzewodnik ;
  https://www.glamour.pl/lifestyle/miejscowki-z-piosenek-taco-hemingwaya-ktore-istnieja-naprawde/ ;
  https://4fun.tv/news/taco-hemingway-mapa-miejsca-z-utworow-strona
- The discography, read only as the title-collision exclusion list (not reproduced):
  https://pl.wikipedia.org/wiki/Taco_Hemingway
- Venue addresses: inyourpocket.com and events.musicofourdesire.com (Luzztro, Al. Jerozolimskie 6);
  pik.warszawa.pl and ebilet.pl (Level 27, Al. Jerozolimskie 123A; Smolna 38); thediscreetgentleman
  and hopsa.io listings (Jasna 1); travelgay.com and warsawinsider.pl (Plan B, al. Wyzwolenia 18);
  warsawinsider.pl (Miłość, Kredytowa 9); goout.net (Bank, Mazowiecka); warsawinsider.pl and
  fashionbiznes.pl (Syreni Śpiew, Rozbrat, closed 2017); Wikipedia "Warszawa Powiśle railway
  station" and events.musicofourdesire.com (the station-pavilion bar, Kruczkowskiego 3B);
  inyourpocket.com (the Pawilony courtyards, Nowy Świat 22/28).
- Name checks: emis.cn company profile (Ciemna 1 Sp. z o.o., Jasna 1); hyrax.pl (a veterinary
  clinic, Kraków); planc.pl (a medical-support organisation); aplikuj.pl (Kawiarnia „Na Fali”,
  Koszalin); superczas.pl (the Zadyszka races, Olsztyn and Szulmierz); level26.pl, rowerilo.pl,
  jasna0.pl (do not resolve); smola.pl (parked); lusterko.pl (TLS error).
- The fitness race's format, for the parody only: hyroxpoland.com, sportano.pl.
- The volleyball neon: tvpworld.com, lonelyplanet.com, national-geographic.pl.
- Milk bars (the first one on Nowy Świat, 1896): freewalkingtour.com.
- Matcha trend: newsroom.tiktok.com (Year on TikTok 2025); Warsaw matcha listings on
  spottedbylocals.com and matchaplaces.com.
