# The phone check: one list for the next build

Everything that only the iPhone can show, in the order of one sitting of about twenty minutes.
It replaces the phone lines scattered over `QUESTIONS.md`, the plans and the threads' notes
(plans review of 2026-11-15, `docs/design/tech-plans-review-2.md` section 8).

**Rules.**

- A pull request whose change note says "only the phone can show" adds **one line here**, in the
  part it belongs to, with what to do and what to look for. A question with a default still goes
  to `QUESTIONS.md`; a look goes here.
- F answers each line "fine", "wrong: ..." or "skip". An answered line leaves the page in the
  next bookkeeping pull request; a "wrong" becomes a backlog item for the line's thread.
- A build is cut when this page reaches 15 open lines or three days pass (`docs/WORKFLOW.md`
  "The build train"). The build's commit and its Mac gate results are named at the top.

**Build:** 11, commit `1d063882`, archived 2026-11-15; the upload waits for F's go. Last uploaded: TestFlight build 10 (2026-11-14).
**Mac gate at the build's commit:** run 2026-11-15, see `docs/builds/build-11.md`: no red step beyond the known `pois` Q3, `streaming` (step limit) and a flaky `police soak`.

## 1. Launch and the first minutes (3 min)

| # | Do | Look for | From |
| --- | --- | --- | --- |
| 1 | Delete the app, install, launch | the title comes up at once and nothing freezes; once before, a first launch froze and was not reproduced | TD-15, boot scene |
| 2 | Update over the old build | settings and the save are as they were | #666 |
| 3 | Play the first ten minutes on a fresh save, taking what is offered | do the calls and offers crowd each other, or leave you with nothing to do | #774, the kit ports |
| 3a | Launch twice (cold after an install, then warm) and time from the tap to the city | the city comes up no more than about half a second later than in build 10, behind the title (the landmark code is now 17 files in one chain; its cold load in the cloud's debug engine went from 1.9 s to 2.35 s) | TD-10, the landmarks split |
| 3b | Drive a little, swipe home, then close the game from the app switcher and launch it again | the car is where you left it and the money as it was; no "ZAPIS NIEUDANY / SAVE FAILED" note at any time (it shows only when a write fails) | saves when the app leaves |
| 3c | During a tour (or a race or a job) press the pad's A and open the HELI list; then open a rescue call card and leave it | A during the run brings no rescue card and the list has no rescue rows; the unanswered rescue card goes after 12 s: is that long enough to read it while driving | one activity at a time |

## 2. Driving feel: Settings → Świat (6 min)

| # | Do | Look for | From |
| --- | --- | --- | --- |
| 4 | "Zderzenia · Collisions": drive Marszałkowska and scrape a wall, a kerb and a car on Klasyka, then Soft, Medium, Firm | which one should be the default (the measurements favour Medium); does the kick at a head-on hit read as a snap | #760, #765, #780 |
| 5 | "Łamliwe płoty · Smashable fences" on: at Stadion Narodowy drive through a fence, a hedge and a tall net | the feel of the smash, the debris, the sound, the buzz; the broken fence still stands drawn (known, until panels); the park's black bar panels break, the gate piers do not | #776 |
| 6 | The same switch **off** (what testers get): drive fast along Marszałkowska and over a bridge | a hitch each time new streets come in (the fences' colliders are rebuilt at sector load, about 3.3 ms per sector in the cloud) | #780, #732 |
| 7 | Switch on, shove parked cars on Krucza, end-on and from the side | a push, never a dead stop; where the pushed car comes to rest (it may sit a kerb low); the frame among parked cars (the cloud measured about 40 µs more per physics step there) | #796 |

## 3. Races and police (4 min)

| # | Do | Look for | From |
| --- | --- | --- | --- |
| 8 | A ladder race by day | rivals' lamps by day; a stutter at the start (the route plan) or on the worst frame | racer 6b, #748 |
| 9 | A street race at night | does it feel like a race; rivals taking yards and back ways | #744, the race links |
| 10 | Get chased and try to shake them off | the chasers' driving; with fences on, whether cutting through a fence ends the chase at once | the chasers' line driver, #776 |

## 4. Places (4 min)

| # | Do | Look for | From |
| --- | --- | --- | --- |
| 11 | Park Świętokrzyski at night, drive along the light garden | the projection strip answers the car; the arches read at the phone's zoom; the night fill | #786, #788 |
| 12 | Warsaw Spire at night | the LED band's bloom; the frame with the Spire on screen | #784 |
| 12a | Warsaw Spire at night, then Tamka and Pasaż Wiecha (behind the Eastern Wall's stores) by day | the Spire's LED band and its night lines of light are on the glass (they were missing on the phone's city); Tamka has its red-and-white bollards on both kerbs and blue name plates at the Powiśle corners; white Y lamp masts stand all along the pasaż; the frame on Tamka (about 110k more triangles than before on the phone) | phone map data |
| 12b | Drive down into Patelnia (the sunken square by Centralna) and along the railway cutting's edge west of Centralna; look at the island platforms by Warszawa Główna | the car and the people stand on the drawn floor and steps, not floating above them (they were up to 3 m off in Patelnia and 7 m in the cutting on the phone's city); the people on the platforms walk on top of them | phone heights |
| 13 | Złote Tarasy at night | the glow | Tarasy glow |
| 14 | The Old Town by car or helicopter: Miodowa, Piwna, Freta, Krakowskie Przedmieście | the frame rate with the rebuilt churches in view; the Archikatedra's roof is green copper and its walls brick | #701 to #789, #775 |
| 14a | Varso Tower by day from Rondo ONZ and at night from Chmielna | the grey frame reads as a grid (not noise) at the game's zoom; the louvred crown; the spire's dish platforms glow white at night | Varso rebuild |
| 14b | Drive Trasa Łazienkowska through its cutting, then Wisłostrada past Bednarska and Miodowa | the road is clean of beige ground wedges; the frame there against the rest of the city (the ground there now has finer cells, +4.7 % vertices over 26 places) | #779 |
| 14c | Centrum LIM's tower by day from Centralna and at night from Jerozolimskie | the white corner piers read as stripes at the game's zoom; the PREZYDENT and SAMSONG names lit at night; the red-and-white mast | LIM tower rebuild |
| 14d | Błękitny Wieżowiec from Plac Bankowy and Solidarności, by day and at night | the glass reads deep blue with its panel grid (F's photo), not grey; the glass hall reads as a barrel vault; the red-and-white antennas on the roof | Błękitny rebuild |
| 14e | Babka Tower from Jana Pawła II and the Babka roundabout, by day and at night | the tower reads pale stone with a glazed loggia column on each face, rising out of the 34 m stone office block; WEKTRA lit on the top floor at night | Babka Tower build |
| 14f | Stadion Narodowy's park fence and gate boards, from Waszyngtona and the east path, by day and at night; then drive through a fence panel (it breaks with Łamliwe płoty on) and into a gate pier (it stands) | the black bar fence on its dark base reads open (you see the park through it); the red gate boards over the gates; no new stutter near the stadium | Narodowy grounds #808 |
| 14g | Warsaw Trade Tower from Rondo ONZ and Chłodna, by day and at night | the dark glass drum's floor bands, the warm beige stone, the silver crown's slits; the mast down the west screen with its red-and-white top | WTT photo rework |
| 14h | Krakowskie Przedmieście at the University's gate, then the campus avenue to the Old Library, then round Pałac Kazimierzowski to the escarpment, by day and at night | the gate's iron and the eagle read against the campus; the Old Library's clock shows the time and lights at night; the brick escarpment wall with its graffiti from the Powiśle path; the frame on the campus (about 25 k new triangles, no new draw calls) | University campus |
| 14i | Stadion Leguminy (Legia) from Łazienkowska and the Trasa, by day and at night | the roof's edge reads as a row of white peaks over a dark truss; the green pitch shows; the columns and green banners along the concourse; the floodlight strip lit at night | Legia photo rework |
| 14k | The Forest (Burakowska, north of Rondo Radosława) from the helicopter, by day and at night | the low roofs read as green gardens with rusty beds and a black rail, not as a grid of boxes; the terrace's white tent and pavilion; the phone's frame near the tower (about 1,500 more triangles than before in the one Forest mesh, no new draw call) | Forest roof garden |
| 14j | Gmach Główny Politechniki from Plac Politechniki and Nowowiejska, by day and at night | the pale stone front reads (not grey); three tall arched windows between paired columns; the attic with its figure group against the sky; the glass hall roof stays blue-grey glass, not zinc; the lamp globes lit at night | Politechnika front |
| 14k | At night: Legia from Łazienkowska, Hotel Europejski from Krakowskie Przedmieście, Babka Tower, and a shop street (Nowy Świat) | LEGUMINA, HOTEL EUROPEJSKI and WEKTRA lit and whole (not cut off); the shops' neon words unchanged; no new stutter | Landmark signs atlas fix |
| 14n | Dom bez Kantów and Królewska 2 (the block on the square's south-east corner) from Plac Piłsudskiego, from Królewska going east and from Krakowskie Przedmieście, by day and at night | one long block with every corner rounded and a row of round arches at street level; the cream west part and the sandstone east part read apart, the sandstone one taller; the courtyard open; none of LoD2's old wings left standing beside it; no new stutter near the square | Dom bez Kantów rebuild |
| 15 | Settings → the experimental graphics switch, on and off at the Palace | the look and the frame | #647 |

## 5. The frame (3 min)

| # | Do | Look for | From |
| --- | --- | --- | --- |
| 16 | Settings → BENCH, run it | the numbers against the last build's | budgets |
| 17 | Drive across the map for three minutes without stopping | streets that come in late, a hole in the ground, heat | #732 |

## Answers F owes that are not looks

These wait in `QUESTIONS.md` and block something: the opening's "go" (drop the ignored first
kebab, then Mati's call); the Powiśle bar names; the Android build's go. (The walls' four
defaults were answered on 2026-11-15.)
