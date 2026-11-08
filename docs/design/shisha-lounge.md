# Shisha lounge quest: "Dym u Senatorka" (analysis and design, F 2026-11-08)

Status: ANALYSIS ONLY, nothing built. F's ask (2026-11-08): a friend phones, "wanna smoke some
shisha?"; you pick him up at 19. Dzielnica, pick up a second friend, argue in the car about
flavours and how strong it should be, arrive at a lounge with a parody name ("Senator lounge"),
sit with the shisha master, a flavour-choosing mini-game, then like inside Smoła: smoke or exit.
"Maybe you can imagine something better." Portraits come later (PixelLab, F's photos, on F's Mac).

Everything is invented: friends, lounge, master and flavours are fictional parodies. No real
brands (shisha flavour names parody candy and drink brands only as non-trademarked puns), no real
private people, no drug jokes. Shisha here is a legal, ordinary evening out: the jokes are about
the industry, the flavours and the arguing, not about getting high (see "Content notes").

## Cast

| Who | Role | Notes |
| --- | --- | --- |
| **Ivan** | the caller and first friend, lives at 19. Dzielnica | F 2026-11-08: Ivan calls, Mati is not in this quest (Mati is Smolna's friend, the renamed Ziomek). A new character: his own call card, portrait and lines; the call/pickup code is reused from `rave.gd`, only the name and lines differ. |
| **Bogdan** | second friend, picked up at a sports court on the way | Plays tennis, comes straight from a court between Dzielnica 19 and Emilii Plater (WTS DESKA at Zaruskiego was too far: 3.5 km east, and by car reachable only from Czerniakowska, PT-31). Arrives sweaty, in a headband, talks about his backhand and how glad he is to finally smoke shisha. |
| **Mistrz Fajki** (name TBD: "Pan Dymek") | the shisha master | Calm, in a waistcoat, speaks like a sommelier about tobacco-free "mixes". Never rushed. |
| **You** | the driver | Silent as always; your choices are the buttons. |

Ivan: easy-going, always has a plan, vetoes everything with "no, that's too sweet". Bogdan:
earnest, competitive, turns everything into a match ("15:0 for menthol"), wants the strongest.
Tension: Ivan wants light and fruity and cannot smoke strong shisha, Bogdan loves it strong (F, 2026-11-08); you cast the deciding vote, and the master's two-hose pipe (strong bowl for Bogdan, ice-and-water filter for Ivan) is the way out.

## Beats

1. **The call (any evening 17:00-02:00).** "📞 IVAN DZWONI": ODBIERZ / ODRZUĆ, then "Szisza dziś?
   Podjedź po mnie na 19. Dzielnicę, weźmiemy Bogdana", JADĘ! / NIE DZIŚ. Same ring/answer/decline
   structure as `rave.gd` `ring` -> `_offer` -> `_on_card`. Starts also by `stories.add` (id
   `shisha`): a start beacon at the 19. Dzielnica block, a greeting in person, a WĄTKI list entry.
2. **Pick up Ivan** at 19. Dzielnica (Kolejowa / Przyokopowa, sites `d19` / `noho`): a dashed
   ring at the kerb, he waves, gets in (rave's pickup, `_board`).
3. **Pick up Bogdan** (F, 2026-11-08: WTS DESKA is too far, pick him up in the area between
   19. Dzielnica and Emilii Plater): a mapped sports court (`game/data/courts.json`) with a car
   road beside it. Built (2026-11-08): the court on Żelazna at about (-2126, 371) game metres,
   52.2307 N, 20.9928 E, its kerb on Żelazna; Ivan's block is at about (-2900, 735), 52.2274 N,
   20.9815 E (Kolejowa / Przyokopowa), and the lounge's door on Emilii Plater at (-1465, 59). The
   legs are about 890 m and 705 m on a straight line, 1.6 km in all (the court sits on the way:
   the direct line is the same length). An earlier draft of this section measured from a wrong
   19. Dzielnica point and named a court near Pereca; that was wrong. The court is any mapped
   sports pitch, not checked to be tennis; a net, a bag and Bogdan waiting there in white are
   left for later (BACKLOG). The whole drive is then about 2 km and 4-6 minutes, so the
   car argument is the heart of it: the three rounds run over the two legs (Ivan alone, then both
   with Bogdan). A longer way round (Rondo ONZ, Świętokrzyska) can be offered as a scenic
   detour on the second leg if the banter needs more time. Bogdan's tennis monologue (below). The
   two-stop route is what `trend_job.gd` "Czwarty" already does.
4. **The car argument** on the way to the lounge: a vote scene with three rounds (flavour,
   strength, the nickname of the pipe), banter in between (below). Your votes set the mini-game.
5. **Arrive at SENATOREK LOUNGE** (Emilii Plater 53). Park at the kerb ring under the portico, a
   "dress code" gag at the door (Bogdan's tennis shorts), the lift card.
6. **The lounge room** (cutaway, like Smoła): rock wall, olive trees, velvet banquettes, the three of you seated.
7. **Mini-game "Miks u Mistrza"** with the master (below): choose the bowl.
8. **The pipe arrives; smoke or leave** (the Smolna choice): PALIĆ (a short smoking scene) or
   WYJDŹ (back to the car). Either ends the quest; PALIĆ pays more respect and unlocks the
   after-scene.
9. **After**: the three of you in the car, Ivan and Bogdan dropped off (Bogdan's rating of the
   evening as a tennis score), pay.

✕ gives up at any step (Ivan takes the night bus), as in the rave.

## The car argument (dialogue jokes)

Authored lines in `dialogue.json` under `shisha_ride` (tags like `rave_ziomek`'s: board_mati,
board_bogdan, flavour, strength, nickname, arrive). PL first, English in the file as everywhere.

**Bogdan and the tennis (opening, when he gets in).**
- „Pół godziny forhendu o ósmej rano i tak chcę tylko dymu, który pachnie arbuzem." / "Half an hour of forehand at eight in the morning and all I want is smoke that smells of watermelon."
- „Mam remis, ale w szishy jestem mistrzem Woli." / "I have a draw, but I'm the Wola shisha champion."
- „Trener mówi: oddychaj głęboko. Zrobiłem z tego plan treningowy." / "My coach says: breathe deeply. I turned it into a training plan."
- „Najlepszy serw dnia był do kelnera w szatni." / "My best serve of the day was to the waiter in the locker room."

**Ivan against Bogdan on flavours (vote round 1: pick whose flavour wins).**
Invented flavours, the stranger the better (each is a button in the mini-game too):
- **Arbuz-Mięta "Lato w Wilanowie"**, **Podwójne jabłko po warszawsku** (apple with a second apple), **Guma balonowa z Pragi**, **Zupa pomidorowa z makaronem** (savoury, a legend: "tylko Bogdan zamawia"), **Kebab z białym sosem** ("na wynos, ale dla fajki"), **Zupa pomidorowa z makaronem**, **Lody z ogórka**, **Kompot babci Zosi**, **Mgła nad Wisłą** (grey, mystery menthol), **Różowy autobus 175** (rose + something), **Beton cytrusowy**, **Syrenka Truskawka**, **Tramwaj Cola**, **Pan Cebulka** (the one nobody chooses), **Paczek w smogu**.
- Ivan: „Zupa pomidorowa? Bogdan, to nie jest smak, to jest zarzut." / "Tomato soup? Bogdan, that's not a flavour, that's an accusation."
- Bogdan: „Ogórek z lodami to klasyka. Klasyka z mojej głowy." / "Cucumber ice cream is a classic. A classic from my head."
- Ivan: „Każdy lounge ma menu z siedemdziesięcioma smakami. I zawsze bierzemy to samo: arbuz z miętą." / "Every lounge has seventy flavours. And we always take the same: watermelon-mint."
- „A pamiętasz, jak wzięliśmy 'Zupę pomidorową'? Pachniało obiadem do końca tygodnia." / "Remember when we took the tomato soup? It smelled of lunch for the rest of the week."

**The industry, strength and the "ale mocna" debate (round 2: strength 1-5).**
- „Mistrz mówi 'lekka', ale u niego lekka to taka, że sąsiad płacze z okna." / "The master says 'light', but his light makes the neighbour cry from a window."
- Bogdan: „Mocna! Jak backhand! Do końca!" Ivan: „Mocna to jest kawa. A to ma być spokojnie." / "Strong! Like a backhand! Ivan: Strong is coffee. This is meant to be calm."
- „Teraz wszystko jest 'premium'. Premium węgiel, premium woda, premium kłęby." / "Everything is 'premium' now. Premium coal, premium water, premium puffs."
- „Cena fajki rosła szybciej niż czynsz na Woli. A czynsz tam też rośnie." / "The pipe's price rose faster than rent in Wola. And rent there is rising too."
- „Mistrz fajki: kiedyś kelner, teraz konsultant dymu. Z certyfikatem. Z dwoma." / "Shisha master: used to be a waiter, now a smoke consultant. Certified. Twice."
- „Węgiel na miejscu, węgiel w rurze, węgiel w rachunku." / "Coal on the spot, coal in the pipe, coal on the bill."
- „Aromat? W Warszawie aromat to każdy smak, który ma w nazwie słowo 'ice'." / "Flavour? In Warsaw, every flavour with 'ice' in its name counts as a flavour."
- „Moc: 1 to herbata, 3 to randka, 5 to rozmowa o polityce." / "Strength: 1 is tea, 3 is a date, 5 is a talk about politics."

**The pipe's nickname (round 3, a joke vote with no effect except a toast at the end).** The
three of you name the pipe: „Kazik", „Premier", „Tramwaj". Bogdan insists on „Forhend".

**At the door of SENATOREK LOUNGE.**
- „Dress code: 'smart casual'. Bogdan: smart? Casual? Tenis." / "Dress code smart casual. Bogdan: smart? Casual? Tennis."
- Ivan: „Przepraszam, mamy rezerwację. Na 'Ivan x3'." / "Excuse me, we have a reservation for 'Ivan x3'."

## The lounge: "SENATOREK LOUNGE" (parody)

F's name is "Senator lounge". The real Senator is a building on Królewska (BACKLOG "Saski Crescent
and Senator"), so the lounge takes a clear parody name: **SENATOREK LOUNGE** ("little senator";
gold serif sign SENATOREK, tagline dym & sofy / smoke & sofas). Alternatives if F prefers: SENATORSKA FAJKA,
LOUNGE PRZY SENACIE. Parody sign through `neon_signs` LANDMARK_WORDS; no real brand
(`brand_denylist.json` unchanged; "Senator" alone stays a plain word).

Where (F's photos, 2026-11-08): **on a high floor of the Warsaw Financial Centre, ul. Emilii
Plater 53**, with a roof terrace looking at the Palace of Culture. F's photo set shows the real
Senator lounge there: floor-to-ceiling glass with the Palace in the window, a roof terrace over
the city, and the building's porte-cochère with "EMILII PLATER 53" on the black granite plinth.
The tower is already in the game (spec `docs/landmarks/specs/wcf.md`, site `wcf`, white and glass
slabs, granite podium), so the quest needs no new building, only the entrance and the rooms. The
floor number is not in the photos (left to F or a later check). The mapped Senator office block on
Bielańska (BACKLOG "Saski Crescent and Senator") is a different building; the first draft of this
doc put the lounge there by mistake.

How you get in: park at the porte-cochère on Emilii Plater (kerb ring), the three of you walk
through the revolving door, a short **lift card** ("Winda na 38. piętro", the floor invented, a
bell, the friends bicker about the flavours one more time) and the room opens. Ground-floor
cafe in the photo is a real chain: in game it is a parody coffee shop under the existing shop-front
rules, never the real logo.

### The room, from F's photos (design reference, not shipped)

- **The main hall** (photos 3, 5, 6): a dark, tall room, black steel beams and track
  spotlights under a black ceiling; one wall of rough grey rock panels cut in vertical strips by
  thin dark steel bars, with the gold serif logo letters on it, a warm spotlight pooling on the
  rock; olive trees in black planters between the seats; a stone-clad bar on the right with
  a steel hood. Parody sign: **SENATOREK** in the same gold serif letters.
- **Seating**: a long row of curved banquettes in rust/terracotta velvet (photo 5), square black
  tables, grey upholstered armchairs and two-seater sofas with brass-coloured legs (photos 3, 5),
  a burnt-orange leather armchair in the foreground.
- **The windows** (photos 5, 6): floor-to-ceiling glass on one side, the Palace of Culture and
  the towers in the haze, golden sunlight through it; the olive trees stand against the glass.
- **The terrace** (photos 1, 4): a roof terrace with a glass balustrade and the Palace behind,
  teak armchairs with woven backs and cream cushions, light travertine-looking square tables,
  steel pedestal legs, salt and pepper sets, hazy sky.
- **An alternative reference** (photo 2): a dark-leather airport-style lounge with warm table
  lamps on wooden plinths, wood floor, big window at dusk. Not our direction; the Senator look
  above wins.

The mood: **"quiet money"**, a calm, warm, dark-stone lounge, nothing like a basement den.
That changes the design: no Moroccan carpets or brick vaults; the room is rock, olive trees,
velvet and glass.

## The room (cutaway like Smoła's, reuse of `club.gd`)

An 18 × 12 m cutaway, back wall (the rock wall with the gold SENATOREK letters) and the glass
wall cut away in the camera's view, camera at 45°. Black ceiling beams with a few track
spotlights (lights as `club.gd`'s MultiMesh), olive trees in planters, the curved rust-velvet
banquettes in rows, grey armchairs with brass legs, black tables, the stone bar with the jars of
flavours behind it and the coal station on the counter, a window wall with the Palace of Culture
in a lit backdrop (day: golden haze, night: the city's lights; one textured quad, no new
material). A door to the **TERRACE** (the patio's twin in `club.gd`): teak armchairs, cream
cushions, travertine tables, the Palace behind a glass balustrade, the same turning-light rig
reduced to warm bulbs. Three of you on a corner sofa; other tables with 8-12 seated silhouettes in smoke. Smoke
particles are a MultiMesh of soft puffs rising to a haze (like the club's lights, same draw
budget: room mesh, people MultiMesh, haze MultiMesh = 3 draw calls). Music: a lounge track on a
radio (deep-house lounge, `docs/MUSIC.md` has a "lounge" slot to fill) played at
low volume; ElevenLabs Music on F's Creator plan.

## Mini-game "Miks u Mistrza" (flavour choice with the master)

Idea: the master brings a tray of **six jars** and says „Co dziś palimy?" and the three of you
have different tastes set by the car argument. One screen, about 40 seconds, three steps:

1. **The bowl (pick 2 of 6 flavours).** Each flavour has two values, sweetness and coolness (a
   2-axis chart). Ivan's wish is a target on sweetness, Bogdan's a target on strength/coolness,
   shown as two pins on the chart. Pick two jars: the bowl's mix point is their midpoint, its
   distance from the pins sets how satisfied each friend is (hearts 0-3).
2. **The coal (timing).** The master lays coals; tap when the glow reaches the green band (like
   the club's TAŃCZ ring pulsing at the beat) to make it "just right"; too early is weak, too
   late is harsh (the strength set in the car, 1-5, widens or narrows the band).
3. **The first draw (optional tiebreak).** Hold the button to draw a cloud and release inside
   the band; a clean ring of smoke is a bonus.

Result: Ivan's hearts + Bogdan's hearts + your bonus (0-9) set the pay and the closing line;
perfect = both friends 3 hearts, "Mistrz Fajki: 'Dawno nie było takiego miksu'" and the pipe is
named in the toast. Wrong choices are funny, not punishing (the "Tomato soup" mix is a
legend: Bogdan beams, Ivan leaves the table, the master writes it on the wall).

Reused: the club's tap-on-beat ring (`club.gd` `_draw_beat`, DANCE_PAY streak), the door card
stack (`hud.show_card` stacked answers), a new 2-axis chart panel (small custom Control).

## Smoke or exit

Like Smoła's end of room. After the mix:
- **PALIĆ**: a 20 s scene, the pipe passes around, short lines from each friend, smoke rings
  (a tap makes a ring), a "no, ja nie" for the driver (you are driving: the game says so, the
  driver takes a hookah, but the friends "pay for your mint tea" joke). Pays the full fare plus
  respect. A short fade, then dropped off at their stops.
- **WYJDŹ**: back to the car at the door; the friends are disappointed, half pay.

## Reused systems

| Need | Reuse |
| --- | --- |
| Call card, answer/decline, JADĘ, pickup ring | `rave.gd` `ring`, `_offer`, `_on_card`, `_board`; `hud.show_side_card` |
| Quest map start, in-person greeting, WĄTKI entry | `story_quests.gd` `add` (id `shisha`, colour teal-green, hours 17:00-02:00) |
| Two pickups and a drop route | `trend_job.gd` three-stop job ("Czwarty") |
| Bogdan's pickup site | a mapped sports court near 19. Dzielnica (`courts.json`), kerb ring by `rave.kerb_near` |
| The lounge's tower, entrance and view | `wcf` (spec `wcf.md`), the Palace as the backdrop |
| The room, camera, people to tap, exit | `club.gd` cutaway (`enter`, `people`, tap, WYJDŹ) |
| Beat/timing ring | `club.gd` `_draw_beat` and DANCE streak |
| Dialogue banter | `dialogue.json` tags; `dialogue.say` over the car (`rave_ziomek` pattern) |
| Door questions pattern | `rave.gd` `door_quiz` (not needed here, flavour vote instead) |
| Pay | `pay-tables.md` rides; `rave.gd` `pay_for` |
| Autopilot / test flags | `--rave-call` pattern: `--shisha-call`, `--shisha-lounge`, `--shisha-log` |

## Add-ons check

Dialogue Manager: a branching authored scene with three votes would fit it (`dialogue-scenes`
skill); decide at build. Default here: not used, because the votes only set three numbers and a
flat tagged list (as `rave_ziomek`) is enough. Beehave: not used (no NPC behaviour change).

## Ideas to make it better (the list grew to 11)

1. **The votes matter.** The car argument is not only jokes: each friend's flavour pick and the
   strength set the mini-game's targets and the pay.
2. **A running tennis gag.** Bogdan scores everything as a match; at the end he gives the evening
   a score ("a draw, the pipe draws too").
3. **The master as a sommelier.** Rare "master's choice" mix when the player picks two flavours
   that pair well; a note in the notebook (new place `senatorek`).
4. **Coal runs.** A repeatable street job: deliver coal and "premium" water to lounges
   (like the kebab and słoiki jobs), tied to the same city.
5. **Lounge stamp card.** Visit the lounge 5 times for a free mint tea ("herbata dla kierowcy"):
   a driver-friendly alternative that avoids glorifying smoking for the player's own side.
6. **A tobacco-free setting.** An option "bez dymu" in settings renders the room with
   mist (nicotine-free steam) and the mini-game unchanged, for a wider rating.
7. **After-scene dawn ride** home with Ivan and Bogdan asleep; a quiet radio, tram bells.
8. **A second visit** with different jars each week (rotating "menu sezonowe"), parody trend
   humour (pumpkin spice, "jesienna mgła").
9. **A secret flavour** unlocked by finding three real-looking jars in the city (an easter egg).
10. **The terrace at golden hour**: PALIĆ outside on the roof, the Palace in the sunset (time of day decides the light; night shows the Palace lit). The lift ride and the terrace make the lounge feel like a place high above the city, which suits an isometric game.
11. **Voices**: ElevenLabs lines for the master and the friends (F's plan), as LEKTI's clips.

## Content notes

- Shisha is a legal 18+ product; the game shows an evening with friends, not instructions or
  a recommendation. The joke is the industry: price, premium everything, silly names, strength
  bragging. No drug jokes (as the rave). The driver does not smoke while driving: PALIĆ is the
  friends and a mint tea for you.
- Rating/store check: F (2026-11-08): build it as is for now; decide the rating and the "bez dymu"
  (smoke-free) setting before release.
- On-screen text in Polish with English until the one-language switch lands (F 2026-11-08), then
  the player's language only.

## Cost

One room mesh, one people MultiMesh, one smoke MultiMesh (3 draw calls inside, city out of view,
as Smoła). Outside: two pickup rings and the start beacon (~10 draw calls near the start, as the
other starts). Estimated 600-900 lines GDScript (`shisha.gd` plus a room in the club script),
~120 dialogue lines. Needs the full definition of done (verify, shots, bench) because it is
per-frame and adds geometry; the phone look at the room and the mini-game timing are
phone-only checks.

## Build order (when F says go)

1. Map engineer: lounge kerb ring, the pickups, the sign (Opus).
2. `shisha.gd`: call, two pickups, banter, vote (Sonnet) + `stories.add`.
3. Room + mini-game (Opus for the feel, Sonnet for the room's props).
4. Portraits (PixelLab, Mac, F's photos): Ivan, Bogdan, the master.
5. Lines (Sonnet), voices (ElevenLabs), lounge track, check `check_shisha.gd`.
