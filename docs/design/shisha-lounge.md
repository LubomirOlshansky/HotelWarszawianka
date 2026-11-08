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
| **Mati (Mateusz)** | the caller, lives at 19. Dzielnica | The friend from Smolna (code name still `Ziomek` in `rave.gd` until the rename lands; this quest reuses whichever name main has). F also wrote "Ivan" as the caller: parked in QUESTIONS (one of them is Mati, or Ivan is a third friend). Default built: Mati calls. |
| **Bogdan** | second friend, picked up from the tennis courts | Plays tennis (WTS DESKA, Zaruskiego, already in game as the padel call's courts, so the detour is free). Arrives sweaty, in a headband, talks about his backhand and how glad he is to finally smoke shisha. |
| **Mistrz Fajki** (name TBD: "Pan Dymek") | the shisha master | Calm, in a waistcoat, speaks like a sommelier about tobacco-free "mixes". Never rushed. |
| **You** | the driver | Silent as always; your choices are the buttons. |

Mati: easy-going, always has a plan, vetoes everything with "no, that's too sweet". Bogdan:
earnest, competitive, turns everything into a match ("15:0 for menthol"), wants the strongest.
Tension: Mati wants light and fruity, Bogdan wants strong, you cast the deciding vote.

## Beats

1. **The call (any evening 17:00-02:00).** "📞 MATI DZWONI": ODBIERZ / ODRZUĆ, then "Szisza dziś?
   Podjedź po mnie na 19. Dzielnicę, weźmiemy Bogdana", JADĘ! / NIE DZIŚ. Same ring/answer/decline
   structure as `rave.gd` `ring` -> `_offer` -> `_on_card`. Starts also by `stories.add` (id
   `shisha`): a start beacon at the 19. Dzielnica block, a greeting in person, a WĄTKI list entry.
2. **Pick up Mati** at 19. Dzielnica (Kolejowa / Przyokopowa, sites `d19` / `noho`): a dashed
   ring at the kerb, he waves, gets in (rave's pickup, `_board`).
3. **Pick up Bogdan** at the WTS DESKA gate (Zaruskiego): second ring, 3-4 km across the city
   (Wola -> Śródmieście -> Powiśle). Bogdan tennis monologue (below). A two-stop route is what
   `trend_job.gd` "Czwarty" already does with three stops.
4. **The car argument** on the way to the lounge: a vote scene with three rounds (flavour,
   strength, the nickname of the pipe), banter in between (below). Your votes set the mini-game.
5. **Arrive at SENATOREK LOUNGE.** Park at the kerb ring; a door line, a short bouncer-free
   "dress code" gag (Bogdan's tennis shorts), in.
6. **The lounge room** (cutaway, like Smoła): sofas, cushions, the three of you sitting.
7. **Mini-game "Miks u Mistrza"** with the master (below): choose the bowl.
8. **The pipe arrives; smoke or leave** (the Smolna choice): PALIĆ (a short smoking scene) or
   WYJDŹ (back to the car). Either ends the quest; PALIĆ pays more respect and unlocks the
   after-scene.
9. **After**: the three of you in the car, Mati and Bogdan dropped off (Bogdan's rating of the
   evening as a tennis score), pay.

✕ gives up at any step (Mati takes the night bus), as in the rave.

## The car argument (dialogue jokes)

Authored lines in `dialogue.json` under `shisha_ride` (tags like `rave_ziomek`'s: board_mati,
board_bogdan, flavour, strength, nickname, arrive). PL first, English in the file as everywhere.

**Bogdan and the tennis (opening, when he gets in).**
- „Pół godziny forhendu o ósmej rano i tak chcę tylko dymu, który pachnie arbuzem.” / "Half an hour of forehand at eight in the morning and all I want is smoke that smells of watermelon."
- „Przegrałem 6:4, 6:3, ale w szishy jestem mistrzem Mokotowa.” / "I lost 6-4, 6-3, but I'm the Mokotów shisha champion."
- „Trener mówi: oddychaj głęboko. Zrobiłem z tego plan treningowy.” / "My coach says: breathe deeply. I turned it into a training plan."
- „Najlepszy serw dnia był do kelnera w szatni.” / "My best serve of the day was to the waiter in the locker room."

**Mati against Bogdan on flavours (vote round 1: pick whose flavour wins).**
Invented flavours, the stranger the better (each is a button in the mini-game too):
- **Arbuz-Mięta "Lato w Wilanowie"**, **Podwójne jabłko po warszawsku** (apple with a second apple), **Guma balonowa z Pragi**, **Ruskie pierogi** (savoury, a legend: "tylko Bogdan zamawia"), **Kebab z białym sosem** ("na wynos, ale dla fajki"), **Zupa pomidorowa z makaronem**, **Lody z ogórka**, **Kompot babci Zosi**, **Mgła nad Wisłą** (grey, mystery menthol), **Różowy autobus 175** (rose + something), **Beton cytrusowy**, **Syrenka Truskawka**, **Tramwaj Cola**, **Pan Cebulka** (the one nobody chooses), **Paczek w smogu**.
- Mati: „Ruskie pierogi? Bogdan, to nie jest smak, to jest zarzut.” / "Pierogi ruskie? Bogdan, that's not a flavour, that's an accusation."
- Bogdan: „Ogórek z lodami to klasyka. Klasyka z mojej głowy.” / "Cucumber ice cream is a classic. A classic from my head."
- Mati: „Każdy lounge ma menu z siedemdziesięcioma smakami. I zawsze bierzemy to samo: arbuz z miętą.” / "Every lounge has seventy flavours. And we always take the same: watermelon-mint."
- „A pamiętasz, jak wzięliśmy 'Zupę pomidorową'? Pachniało obiadem do końca tygodnia.” / "Remember when we took the tomato soup? It smelled of lunch for the rest of the week."

**The industry, strength and the "ale mocna" debate (round 2: strength 1-5).**
- „Mistrz mówi 'lekka', ale u niego lekka to taka, że sąsiad płacze z okna.” / "The master says 'light', but his light makes the neighbour cry from a window."
- Bogdan: „Mocna! Jak backhand! Do końca!” Mati: „Mocna to jest kawa. A to ma być spokojnie.” / "Strong! Like a backhand! Mati: Strong is coffee. This is meant to be calm."
- „Teraz wszystko jest 'premium'. Premium węgiel, premium woda, premium kłęby.” / "Everything is 'premium' now. Premium coal, premium water, premium puffs."
- „Cena fajki rosła szybciej niż czynsz na Mokotowie. A czynsz tam też rośnie.” / "The pipe's price rose faster than rent in Mokotów. And rent there is rising too."
- „Mistrz fajki: kiedyś kelner, teraz konsultant dymu. Z certyfikatem. Z dwoma.” / "Shisha master: used to be a waiter, now a smoke consultant. Certified. Twice."
- „Węgiel na miejscu, węgiel w rurze, węgiel w rachunku.” / "Coal on the spot, coal in the pipe, coal on the bill."
- „Aromat? W Warszawie aromat to każdy smak, który ma w nazwie słowo 'ice'.” / "Flavour? In Warsaw, every flavour with 'ice' in its name counts as a flavour."
- „Moc: 1 to herbata, 3 to randka, 5 to rozmowa o polityce.” / "Strength: 1 is tea, 3 is a date, 5 is a talk about politics."

**The pipe's nickname (round 3, a joke vote with no effect except a toast at the end).** The
three of you name the pipe: „Kazik", „Premier", „Tramwaj". Bogdan insists on „Forhend".

**At the door of SENATOREK LOUNGE.**
- „Dress code: 'smart casual'. Bogdan: smart? Casual? Tenis.” / "Dress code smart casual. Bogdan: smart? Casual? Tennis."
- Mati: „Przepraszam, mamy rezerwację. Na 'Mati x3'.” / "Excuse me, we have a reservation for 'Mati x3'."

## The lounge: "SENATOREK LOUNGE" (parody)

F's name is "Senator lounge". The real Senator is a building on Królewska (BACKLOG "Saski Crescent
and Senator"), so the lounge takes a clear parody name: **SENATOREK LOUNGE** ("little senator";
sign: SENATOREK · dym & sofy, EN: smoke & sofas). Alternatives if F prefers: SENATORSKA FAJKA,
LOUNGE PRZY SENACIE. Parody sign through `neon_signs` LANDMARK_WORDS; no real brand
(`brand_denylist.json` unchanged; "Senator" alone stays a plain word).

Where: **in the Senator building itself**, Bielańska 12, Śródmieście (the mapped office block
beside Saski Crescent, already in the game: BACKLOG "Saski Crescent and Senator", CITY_INVENTORY
row 106). Research (2026-11-08): Senator is a ~25,000 m² office building on the site of the
pre-war Polish Bank, rebuilt to follow the old facade (Ghelamco's press release); nothing found
online ties a shisha lounge named Senator to it, so this is our invention, not a real venue. The
lounge door sits down a few steps at the building's Bielańska front under a lit sign. Needs a
car-reachable kerb on Bielańska/Królewska (the map engineer checks which side is open);
fallback: the Senatorska tenements nearby. Notebook place `senatorek`.

### Research: what a shisha lounge looks like inside

No verified photo set of a "Senator lounge" in Warsaw was found, so the room is built from the
genre plus one Warsaw reference. The genre list is design knowledge, not verified.
- Warsaw reference: the oriental-styled Aura Bar in a pre-war Śródmieście tenement
  ([Trendland](https://trendland.com/oriental-aura-bar-warsaw/)): brass and marble counter, bar
  clad in left-over stone slabs, brass details made on site, Moroccan carpets, locally made
  upholstery, a "mystic" mood. We borrow the brass-and-marble bar and the carpets.
- Genre (unverified): low sofas and floor cushions round low brass or mosaic tables, one pipe
  per table with a long hose, dim warm light (lanterns, pendant lamps, string lights), arches and
  niches, dark wood and patterned tiles, plants, curtains between booths, smoke haze at ceiling
  height, a counter with rows of jars for flavours, a coal station at the bar, soft oriental
  lounge music.
- For the pre-war Senator front: a basement under brick vaults, so the exposed brick and
  arched niches below fit the building.

Question for F: if a real lounge was meant (a name or street), the room and site follow it.

## The room (cutaway like Smoła's, reuse of `club.gd`)

A 14 × 10 m cutaway, back and left walls cut away, camera at 45°. Exposed brick, arched
niches, low ceiling beams, string lights, a long bar, a wall of jars (flavours in rows with
handwritten labels), a coal stove with orange glow, Persian carpet, low tables, cushions.
Three of you on a corner sofa; other tables with 8-12 seated silhouettes in smoke. Smoke
particles are a MultiMesh of soft puffs rising to a haze (like the club's lights, same draw
budget: room mesh, people MultiMesh, haze MultiMesh = 3 draw calls). Music: a lounge track on a
radio (lo-fi, oriental-house flavour, `docs/MUSIC.md` has a "lounge" slot to fill) played at
low volume; ElevenLabs Music on F's Creator plan.

## Mini-game "Miks u Mistrza" (flavour choice with the master)

Idea: the master brings a tray of **six jars** and says „Co dziś palimy?" and the three of you
have different tastes set by the car argument. One screen, about 40 seconds, three steps:

1. **The bowl (pick 2 of 6 flavours).** Each flavour has two values, sweetness and coolness (a
   2-axis chart). Mati's wish is a target on sweetness, Bogdan's a target on strength/coolness,
   shown as two pins on the chart. Pick two jars: the bowl's mix point is their midpoint, its
   distance from the pins sets how satisfied each friend is (hearts 0-3).
2. **The coal (timing).** The master lays coals; tap when the glow reaches the green band (like
   the club's TAŃCZ ring pulsing at the beat) to make it "just right"; too early is weak, too
   late is harsh (the strength set in the car, 1-5, widens or narrows the band).
3. **The first draw (optional tiebreak).** Hold the button to draw a cloud and release inside
   the band; a clean ring of smoke is a bonus.

Result: Mati's hearts + Bogdan's hearts + your bonus (0-9) set the pay and the closing line;
perfect = both friends 3 hearts, "Mistrz Fajki: 'Dawno nie było takiego miksu'" and the pipe is
named in the toast. Wrong choices are funny, not punishing (the "Ruskie pierogi" mix is a
legend: Bogdan beams, Mati leaves the table, the master writes it on the wall).

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
| Bogdan's pickup site | WTS DESKA (`landmarks.gd` DESKI) |
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

## Ideas to make it better

1. **The votes matter.** The car argument is not only jokes: each friend's flavour pick and the
   strength set the mini-game's targets and the pay.
2. **A running tennis gag.** Bogdan scores everything as a match; at the end he gives the evening
   a score ("6:4, 6:3, my pipe wins").
3. **The master as a sommelier.** Rare "master's choice" mix when the player picks two flavours
   that pair well; a note in the notebook (new place `senatorek`).
4. **Coal runs.** A repeatable street job: deliver coal and "premium" water to lounges
   (like the kebab and słoiki jobs), tied to the same city.
5. **Lounge stamp card.** Visit the lounge 5 times for a free mint tea ("herbata dla kierowcy"):
   a driver-friendly alternative that avoids glorifying smoking for the player's own side.
6. **A tobacco-free setting.** An option "bez dymu" in settings renders the room with
   mist (nicotine-free steam) and the mini-game unchanged, for a wider rating.
7. **After-scene dawn ride** home with Mati and Bogdan asleep; a quiet radio, tram bells.
8. **A second visit** with different jars each week (rotating "menu sezonowe"), parody trend
   humour (pumpkin spice, "jesienna mgła").
9. **A secret flavour** unlocked by finding three real-looking jars in the city (an easter egg).
10. **Voices**: ElevenLabs lines for the master and the friends (F's plan), as LEKTI's clips.

## Content notes

- Shisha is a legal 18+ product; the game shows an evening with friends, not instructions or
  a recommendation. The joke is the industry: price, premium everything, silly names, strength
  bragging. No drug jokes (as the rave). The driver does not smoke while driving: PALIĆ is the
  friends and a mint tea for you.
- Rating/store check: parked in QUESTIONS (is smoking OK in a 12+ build? default built: yes with
  the "bez dymu" option).
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
4. Portraits (PixelLab, Mac, F's photos): Mati, Bogdan, the master.
5. Lines (Sonnet), voices (ElevenLabs), lounge track, check `check_shisha.gd`.
