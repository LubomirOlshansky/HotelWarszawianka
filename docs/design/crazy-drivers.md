# Crazy drivers: taxis, couriers and the Pasatini 1.9 TDJ

F (2026-11-05): "taxi drivers going fast in the city, and the dostawcy (couriers) who cut people off
and overtake, on fake Skoda parodies, the Passat the craziest; city traffic more real with those
crazy drivers; use the racing mechanics so they run fast, on the roads, not off them."

This spec covers the lore, the names, the look, the behaviour (built on the race rivals' racer mode,
docs/design/street-races.md sections 1 and 9), the lines and the cost. Build starts once the race
rivals PR (branch `claude/project-thread-c43ki2`) is in main, because the crazy drivers reuse its
blocking and tight cut-in code.

## 1. Lore (why every Pole knows these three drivers)

Research notes (Polish internet folklore, no content copied; sources at the end):

- **The Passat B5 with the 1.9 TDI** is the cult car of Polish memes: the "Janusz" car, "king of the
  Polish roads", reliability taken with a wink. The engine is joked to be indestructible, sipping
  fuel at half a million km. The car comes "from Germany, mint condition (stan igła), the German
  cried when he sold it", always with a rolled-back odometer, chip-tuned "by eye" so it blows black
  smoke, rust under tape. On the road the stereotype is the left lane, headlights flashed at
  whoever is in front, a metre behind your bumper, no indicator. Spidersweb's autoblog even ran
  "Passats attack other drivers" and "the ultimate Polish car" pieces.
- **The Skoda Octavia** is the taxi and app-ride car of Warsaw, and the sales rep's estate on the
  left lane. App drivers are the city's fastest: the meter is time, the rating is stars, the bus
  lane is "almost legal". (The game already has Podwózka, the app taxi, parodies.md 3.)
- **Couriers (dostawcy)**: a van, ninety parcels, one shift. Hazard lights on means "I may stop
  anywhere", the pavement is a car park, the doorbell is never rung ("nobody was home"), the parcel
  is "left with a neighbour". Their vans are the big three-tonne panel vans everyone knows.

The game's take (affectionate, never about a real person, brands only as parodies):

| Who | Car (parody name) | In one line |
| --- | --- | --- |
| Taksówkarz / app driver | **Szkoda Oktawia** (the city taxi saloon and Podwózka's hatch) | "Szkoda czasu na hamowanie." Fast, tight lane changes, bus lane when it can. |
| Dostawca (courier) | **Szprynter** (the panel van) | Pulls away hard, squeezes past, cuts in to make the next drop. |
| Janusz z Pasatini | **Pasatini 1.9 TDJ** (a dark estate, sun strip, twin chrome tips) | The craziest: the fastest, tailgates, runs a fresh red, blocks you if you try to pass. |

**Pasatini 1.9 TDJ** is F's "Passatini" with one s, so it reads as the parody, not the model. TDJ is
"Turbo Dizel Janusza": the engine joke without the real trademark (TDI). If F wants the real "1.9
TDI" on screen it's a one-word change in the lines; parked in QUESTIONS with TDJ as the default.

Lore for the egg book and the radio: there is only ever **one** Pasatini in the city at a time ("the
same one, everyone has seen it, nobody has caught it"). It has done "180 thousand km, for three
years now". KEBAB FM's host reports sightings like weather: "Pasatini widziane na Wisłostradzie,
lewy pas. Prosimy zjechać i się pomodlić."

## 2. Look (no new draw call)

- **Pasatini**: a fourth shape in the taxis' family (models.gd `TAXI_PASAT`, share 0, drawn only by
  the crazy-driver spawn), on spec("estate") with roof rails, in Janusz paints (black, graphite,
  bottle green, dark slate, silver-grey), with a dark sun strip over the windscreen, a boot-lip spoiler and
  two chrome exhaust tips. The taxi family then holds four shapes, the most a family takes.
- **Szkoda Oktawia taxi**: the existing city taxi and Podwózka shapes (no change).
- **Szprynter courier**: the existing panel van in courier whites and greys (no change).

They use the taxis' and vans' MultiMeshes, so the draw count stays the same.

## 3. Behaviour (racer mode, on fares)

traffic.gd gets `Driver.crazy` (0 none, 1 taxi, 2 courier, 3 Pasatini). A crazy driver drives in
racer mode (`racing_mode` accepts `crazy > 0`) on the lane graph like any town car. It never
leaves the roads: the same lanes, junction curves, and give-way to trams.

Since racer AI step 6b part 3 (2026-11-14) a crazy driver drives **fares** on the racers' driver.
Each has a fare, a junction 600 to 1500 m away, roughly ahead, in the connected part of the map
and inside the band's area; at the fare (the next is picked with less than 150 m left) it takes
another, and one not reached in 240 s is dropped. It plans its own seconds to the fare, takes a
racing line and brakes honestly into corners (race-ai.md 6.4, `crazy_route.gd`, profiles in
`ladder.gd` `CRAZY`). Before, it wandered with no route and took corners as the junction curve is,
27 to 64 m/s² sideways; now 9 to 15.5. A crazy with no ride (the race bench's `old`) wanders as
before. What makes them crazy is kept: the speed over the limit, fresh reds, blocks and tight
cut-ins, the Pasatini running wide, no slipping through a queue.

| | Taxi | Courier | Pasatini |
| --- | --- | --- | --- |
| Top (m/s, also capped by road class) | 20 (72 km/h) | 18 (65) | 25 (90) |
| Over the road's limit | ×1.35 | ×1.3 | ×1.6 |
| Pull (race_accel, m/s²) | 3.2 | 3.0 | 4.0 |
| Corner grip (`lat` in the `CRAZY` profile, m/s²) | 10 | 9 | 12 |
| Block / tight cut-in (race_block) | 0.5 | 0.5 | 0.75 |
| Runs a fresh red | 10 % | 20 % | 35 % |
| Runs wide in a corner near you | no | no | 15 % |
| At once in the band | up to 3 crazy drivers, one Pasatini at most |

From racer mode they get: the short headway (tailgating), lane changes out of a queue, passes over
the centre line when the oncoming lane is clear, the tight pass back in right in front of your
bumper (BLOCK_TIGHT), and one block across your line when you try to pass. Two changes keep them
believable in town traffic:

- They yield to crossing cars like town cars (not racer mode's 7 m rule), so a red-runner brakes in
  the box instead of driving through someone.
- The racer's "slip through a knot after 1.5 s" is off for them, so a crazy driver never ghosts
  through a red-light queue (a jam out of sight clears the town cars' way, after 45 s).

## 3b. Measured (headless, check_crazy_drivers and a 90 s probe)

- 60 s through the centre with up to 3: 22 crazy drivers met, all three kinds, 11.6 m/s on average
  against 9.1 for town cars (27 % faster).
- Overlaps: about 120 frame-pairs in 90 s involve a crazy driver, all out of sight (one stopped
  Pasatini beside a car of a neighbouring edge); town traffic alone has 81, all in junction boxes.

## 4. Lines and sound (chatter budget)

A crazy driver who cuts in or blocks near the player says a line over its car through
`dialogue.say_reaction` (chatter.gd REACTION, key `crazy`), at most one per driver; the budget
decides the rest. They honk (`horn`, existing sound) when they cut in. KEBAB FM's host reads a
`radio_host` "pasatini" line at most once every 10 minutes after the Pasatini passes the view.

Groups: `crazy_taxi`, `crazy_courier`, `crazy_pasatini`, `radio_host` tag "pasatini". Draft:

**crazy_taxi**
- Szkoda czasu na hamowanie. / Braking is a waste of time.
- Klient płaci za czas, to oszczędzam czas! / The fare pays for time, so I'm saving time!
- Nawigacja mówi w prawo, serce mówi buspas. / The satnav says right, my heart says bus lane.
- Pięć gwiazdek albo jedziemy dookoła. / Five stars or we take the long way.
- Na lotnisko w siedem minut. Proszę się zapiąć. / Airport in seven minutes. Buckle up, please.
- Kierunkowskaz zużywa prąd, panie. / Indicators use up the battery, mate.

**crazy_courier**
- Dziewięćdziesiąt paczek, osiem godzin, zero litości. / Ninety parcels, eight hours, zero mercy.
- Awaryjne włączone, czyli mogę wszystko. / Hazards on means I can do anything.
- Nikogo nie było w domu. Nawet nie dzwoniłem. / Nobody was home. I didn't even ring.
- Zostawiłem u sąsiada. Którego? Niespodzianka. / Left it with a neighbour. Which one? Surprise.
- Paczka sama się nie dowiezie! / The parcel won't deliver itself!
- Szprynter ma trzy tony i zero wątpliwości. / The Szprynter has three tonnes and zero doubts.

**crazy_pasatini**
- Stan igła. Niemiec płakał, jak sprzedawał. / Mint condition. The German cried when he sold it.
- Przebieg sto osiemdziesiąt tysięcy. Od trzech lat. / 180 thousand km on the clock. For three years now.
- Czarny dym to nie awaria, to moc. / Black smoke isn't a fault, it's power.
- Lewy pas jest mój. Mam to w dowodzie. / The left lane is mine. It's in my logbook.
- Jeden dziewięć TDJ. Pół miliona i dalej ciągnie. / One-nine TDJ. Half a million km and still pulling.
- Kierunkowskaz? Nie było w wyposażeniu. / Indicators? Weren't in the spec.

**radio_host "pasatini"**
- Pasatini widziane na lewym pasie. Prosimy zjechać i się pomodlić. / A Pasatini sighted in the left lane. Please pull over and pray.
- Komunikat drogowy: czarne kombi, czarny dym, zero kierunkowskazów. Uważajcie. / Traffic news: black estate, black smoke, zero indicators. Watch out.
- Słuchacz pyta, czy Pasatini da się wyprzedzić. Da się. Raz. / A listener asks if you can overtake a Pasatini. You can. Once.

## 5. Flags, checks, cost

- `--crazy=N` (main.gd): at most N crazy drivers at once (default 3; 0 none). `--crazy-log` prints
  their cut-ins and blocks.
- New check `crazy` (`game/tools/check_crazy_drivers.gd`, in verify.sh and CI quick): the taxi family
  is one surface of four shapes, Pasatini share 0, no reserved paint; the lines (counts, Polish and
  English, under 70 characters, no denylisted brand); 40 s of real traffic: crazy drivers appear, at
  most the target, one Pasatini at most, every crazy driver on a lane, faster on average than town
  cars, at least one pass or lane change; a cut-in near the player makes one line, not two.
- Since step 6b part 3 the check also holds, in the 60 s of traffic: every crazy driver 5 s in the
  band or more has a fare and a plan (it used to wander with no route), some drive their racing
  line, and each one let go leaves its ride. The race bench has a kind `crazy` (one crazy of each kind,
  180 s, three spawns, clear and heavy, with and without the average test player, every race
  twice, old and new: 72 rows) and two marks, **Crazy pace** and **Crazy stays crazy**
  (race-ai.md 7.3); `--crazy-log` also prints the fares taken, reached and dropped.
- `check_loud_cars` updates from three taxi shapes to four.
- Cost: no draw call, no material. Per-frame work is racer mode on at most three more cars (the same
  code the race rivals run). Bench before/after in the PR.

Phone-only: how the cut-ins feel at speed, and whether 90 km/h for the Pasatini is fun or annoying
(the numbers live in traffic.gd CRAZY_*).

## Sources read (no content copied)

- Spidersweb autoblog, "Volkswagen Passat: Janusz, januszowóz, the ultimate Polish car":
  https://autoblog.spidersweb.pl/volkswagen-passat-janusz-sprzedaz-januszowoz-polski-woz-ostateczny
- Spidersweb autoblog, "Passaty atakują innych kierowców": https://autoblog.spidersweb.pl/passaty-atakuja-innych-kierowcow
- Antyweb, "1600 km without refuelling a Passat 2.0 TDI": https://antyweb.pl/1600-km-bez-tankowania-passatem-2-0-tdi
- Spidersweb, Warsaw taxi drivers vs app drivers: https://spidersweb.pl/2016/04/kierowca-ubera-zatrzymany.html
- Spidersweb autoblog, couriers' parking reports: https://autoblog.spidersweb.pl/nieprawidlowe-parkowanie-kurierow-zgloszenia
- F's screenshot of a search summary on the Passat meme (2026-11-05).
