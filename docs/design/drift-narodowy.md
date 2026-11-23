# "Bokiem na Narodowym": the drift quest, the drift technique and the stadium scene (plan, 2026-11-22)

F (2026-11-22, the garage thread): after the garage, a drift quest at the National Stadium. Your
mate in the Bawarka calls: someone from his team dropped out, come and drift. You are moved into a
scene of its own (like the club), where our car can drift, and there is a drift competition. Work
out the drift technique for our arcade and our reality, test it well, invent the story, research
how other games do it. Then (22:37): "maybe a couple of tracks there, smoke, more drift physics",
"and they give us a drift Bawarka". F's reference pictures: the real Drift Masters layout on the
stadium floor (two grass islands, a figure-eight-like loop, smoke, flame jets, screens, the roof),
kept at `/mnt/project-files/refs/drift-narodowy/` (never in the repo). **A plan for F's approval;
nothing is built yet.** It builds on `docs/design/garage-and-cars.md` (the cars' feel, 4b).

## 0. The revised plan (2026-11-22, after the Opus review)

**This section wins over everything below it.**

1. **A drift mode, only in the stadium**: a `drift_mode` branch in `car.gd` (like `weighty`), the maths in
   a pure static `drift_model.gd`, on only inside the scene. No drift state in city driving (lane
   assist, the wall rules and `check_lane_drive` stay untouched), no city practice pad yet.
2. **RĘCZNY takes BRAKE's plate**, not the nitro's: the thumb rocks GAS ↔ RĘCZNY without lifting
   (the existing GAS ↔ BRAKE roll), the left-handed layout mirrors it; BRAKE moves to the small slot.
   Pad: the shoulders. Point controls: the stick is the line, the full assist sets the angle. The
   assist setting has an "auto gas" choice.
3. **A venue owner** for scenes off the map (`inside`, `centre`, `view_size`, what stops while you are
   inside: streaming, traffic, police, the minimap) instead of a fourth copy of the club's pattern in
   main.gd; no entry during a chase.
4. **Shorter event**: qualifying (best of 2 runs, instant retry with a Lena line), then one final
   tandem against „Hrabia" (2 runs, his recorded line). About 6 minutes. Top 4, the second track
   (Wielka Pętla), Thursday practice, the notebook page and the replay camera come later.
5. **One score**: the chain with banking; the three judges' cards only show its three parts.
6. **Numbers**: RĘCZNY tap at 30 km/h or more with the wheel turned opens the angle in ~0.3 s; the
   full assist holds 20-45°, a spin at 75°; off the gas it straightens in 1.2 s; a transition 0.6 s;
   runs 30-35 s. Smoke at most 64 puffs (2.5 m, 1.2 s, alpha ~0.35, unshaded); a crowd of at most
   2,000 in one MultiMesh; about 15 draw calls with both cars (not 10).
7. **Names and jokes**: the event "Puchar Bokiem", the sponsor parody "Bycze Skrzydło" (no can of
   any shape); the copied memes (the anime inertia-drift line, the Eurobeat lyric) are cut by the
   warsaw-tone rule 1 (original writing only); kept: Lena's pierogi deliveries, the pickle jar,
   the commentator's wall line, the fan who paid to breathe tyres, our own Eurobeat-style loop. Bjørn's
   line is about winter, not his country.
8. **The prize**: the drift setup for the Bawarka 325 in Darek's WNRC colours (the road Bawarka 325
   can be bought at Mirek's).

Phases: D0 drift model + `drift_score.gd` + `check_drift` + a line recorder → D1 the venue owner,
the stadium and Ósemka (smoke, marks, camera; the near stands cut away) with a bench → D2 the short
event (the call, Hrabia's line, the prize). After the garage's C1a.

## 1. The real thing

- **Drift Masters Grand Finale at PGE Narodowy** (Red Bull, every September since 2019): a track laid
  on the stadium floor under the closed roof, about 50,000 people, smoke, pyro, the season's final.
  Sources: [Red Bull, Grand Finale 2026](https://www.redbull.com/pl-pl/red-bull-drift-masters-grand-finale-info-harmonogram-wiadomosci-2026),
  [the 2025 preview](https://www.redbull.com/pl-pl/red-bull-drift-masters-grand-finale-2025-zapowiedz-atrakcje-zawodnicy),
  [the rules of drifting explained](https://www.redbull.com/al-sq/rules-of-drifting-explained),
  [how the asphalt gets onto the pitch](https://www.eska.pl/motoryzacja/roboty-drogowe-na-pge-narodowym-ciezarowki-walce-i-tony-asfaltu-aa-P7Gm-SxFN-VADb.html).
- **The format**: qualifying (solo runs, judged on line, angle and style, with clipping points and
  zones marked on the track), then tandem battles from Top 32 to the final: two runs per battle,
  each driver leads once and chases once; a draw means "one more time".
- **The layout** in F's pictures: an asphalt loop round two grass islands (stages, screens, flame
  jets on them), a transition between the islands, walls with sponsor boards all round.
- Our version is a **parody**: "Bokiem Masters", an invented amateur Pro-Am night, invented drivers,
  sponsor parodies only ("Red Byk"); no real drivers or brands.

## 2. How the games do drifting (what we take)

| Game | How drift works | What we take |
| --- | --- | --- |
| FR Legends (mobile) | Left/right buttons, gas, a handbrake button; tap the handbrake to start, gas and steering hold the angle; scored on angle, speed and line, tandems with chase/lead | The phone layout: RĘCZNY (handbrake) button, tap to start; tandem chase/lead |
| CarX Drift Racing (mobile) | Physics drift with steering assist settings; points for angle × speed, zones | Assist levels (full / medium / off) |
| Forza Horizon drift zones | Points = speed × angle, a chain multiplier that grows while you keep sliding; points are "banked" only when the drift ends cleanly | Chain multiplier, banking, losing the chain on a wall |
| Need for Speed (Underground, Heat, Unbound) | Brake-tap or gas-and-turn starts a drift; points and multipliers on screen, transitions earn extra | Brake-flick entry in the city, "PRZEKŁADKA!" bonus for switching sides |
| Ridge Racer, Mario Kart | Drift is an assisted arcade state: you choose when, the game keeps it pretty | The full assist keeps the angle in a good band so a phone thumb can do it |
| Gran Turismo drift trial, real judging | Clipping points and zones on the track, judges for line, angle, style | Zones on our tracks and three judges' scores (Linia, Kąt, Styl) |

Sources: [VDrift drift scoring](https://raw.githubusercontent.com/VDrift/vdrift/master/docs/Drift_scoring.md),
[FR Legends scoring](https://loganhayes2.github.io/frlegnds),
[Forza drift zone scoring](https://forums.forza.net/t/what-makes-up-the-drift-score-for-drift-zones/84508),
[GT7 drift trial](https://gran-turismo.com/us/gt7/manual/worldcircuit/06).

## 3. The story

- **Who**: Darek „Bawarka" and Lena „Bokiem" from the night racing club (`street_meet.gd`): they are
  already the drift pair of the game (Lena spins donuts, Darek chases her in the tandem at meet 2).
  The quest opens after the first night meet.
- **The call** (at night; offered by day with the clock jump, like the other night quests):
  > Darek: „Mamy problem. Lena wypadła: skręciła nadgarstek, otwierając babci słoik ogórków. Dziś
  > na Narodowym runda Pro-Am Bokiem Masters i team WNRC nie odda miejsca. Widziałem, jak kręcisz
  > na parkingu. Bawarka drift czeka, klucze u mnie. Wchodzisz?"
  > ("Lena's out: sprained her wrist opening her gran's jar of pickles. Tonight there's the Pro-Am
  > round at the Narodowy and team WNRC won't give up the slot. I've seen you spin on the car park.
  > The drift Bawarka's waiting. You in?")
  WCHODZĘ / NIE DZIŚ. Mirek has a line too ("Lena's diff is in my shop anyway").
- **The way in**: drive to the stadium's gate (the night meet's spot "Parking pod Narodowym"), stop
  in the ring; a short fade with the crowd's roar; **you are in the paddock inside the stadium**.
  Your own car waits at the gate.
- **The paddock**: Darek with the **Bawarka 3.2 Drift** (his spare: welded diff, big steering lock,
  hydraulic handbrake, WNRC hot-neon red with "BOKIEM TEAM"), Lena with her arm in a sling giving
  tips, a mechanic, the screen with the bracket. Tap people for lines; pick the assist; START.
- **The event**: practice → qualifying → Top 8 → Top 4 → the final, each battle two runs (you lead
  once, chase once). Three invented rivals with their own cars and a line each (warsaw-tone): Kaśka
  „Ścinka" (a tiny Japanese-style coupe), Bjørn Bokvist (a Nordic estate, very calm), and the final's
  champion "Hrabia" (the Count) in a V8 coupe.
- **The end**: podium, flames, confetti, Lena's thanks. Prize: 1st 800 zł + 150 respect + **the
  Bawarka 3.2 Drift is yours** (Darek: "Lena i tak chce nowe auto"), plus a "Bokiem" livery for any
  car; 2nd 400 zł; 3rd 250 zł; out in qualifying 100 zł and "spróbuj w czwartek" (a retry the next
  night).
- **After**: "Trening na Narodowym" stays: Darek calls on Thursdays, or start it from MOJE AUTO; the
  second track opens after the final; your best per track is kept.

## 3b. Drift lore and memes (F 22:38: "add drift lore and memes, maybe some dialogues")

Drift has a big meme culture; we use it the warsaw-tone way: affectionate, our own words, parody
names, no real drivers, no real songs.

- **Where drift came from** (the paddock's lore card and Lena's tips): mountain passes in Japan in
  the 70s and 80s, kids sliding old rear-drive coupes at night, then the races, the films and the
  anime. In Poland: Beemki (old BMWs) with a **welded diff** ("spawany dyfer"), donuts on supermarket
  car parks after closing, winter practice on frozen lots, and now 50,000 people in the Narodowy.
- **The memes, as our jokes**:
  - **The tofu delivery** (the anime's hero learned to drive delivering tofu down a mountain): Lena
    learned to drift delivering her gran's **pierogi** from the bar on Ząbkowska before they went
    cold. "Pierogi muszą dojechać ciepłe. Zakręt musi być bokiem."
  - **"Did you just do a kansei dorifto?"** (the inertia-drift meme): the commentator, at a clean
    transition: "Czy to było... kansei dorifto? W Bawarce?!"
  - **"Déjà vu"** (the Eurobeat meme: "I've been in this place before"): a rival at the second lap
    of the same corner: "Déjà vu! Już tu byłem. Bokiem."
  - **Eurobeat**: the scene's music is our own fast Eurobeat-style loop (made like the club's
    loops), on a one-night radio "BOKIEM FM"; the crowd claps on its beat.
  - **"Grip is for cowards"** / **"Angle, not time"**: the team's mottos on the paddock banner:
    "Przyczepność jest dla tchórzy" and "Liczy się kąt, nie czas".
  - **"Tyres are currency"**: the drift world's money is tyres; Darek pays you in "opony" as a joke
    before the zł appear ("Wygrasz, to masz cztery nowe. No dobra, i kasę.").
  - **The welded diff**: the Bawarka Drift's spec sheet in the paddock: "Dyfer: spawany. Hamulec
    ręczny: hydrauliczny. Rozsądek: brak."
  - **The 'Janusz' with the Pasatini 1.9 TDJ** (our crazy driver) turns up at the practice pad in the
    city: "Ja też tak umiem. Na mokrym. Przypadkiem."
  - **The police** at the stadium gate: "Pan tu bokiem? A, to na tor. To jedź pan, tylko prosto do bramy."
- **Lore that stays**: a "BOKIEM" page in the notebook after the event: the team (Darek, Lena,
  Tadek), your best runs, the rivals and their quotes; the Bawarka Drift's plate "WB0K13M".

## 3c. Dialogue samples (Polish with English; final lines go through the warsaw-tone skill)

| Who | Line |
| --- | --- |
| Darek (the call) | „Mamy problem. Lena wypadła. Słoik ogórków babci wygrał z jej nadgarstkiem." / "We've got a problem. Lena's out. Gran's pickle jar beat her wrist." |
| Darek | „Bawarka drift czeka. Spawany dyfer, ręczny jak w autobusie. Pokochasz albo się pobijecie." / "The drift Bawarka's waiting. Welded diff, a handbrake like a bus's. You'll love it or you'll fight." |
| Lena (tip 1) | „Ręczny to nie hamulec. To zaproszenie." / "The handbrake isn't a brake. It's an invitation." |
| Lena (tip 2) | „Gaz trzyma kąt. Puścisz gaz, puścisz bokiem." / "The gas holds the angle. Let go of the gas, let go of the slide." |
| Lena (tip 3) | „Patrz tam, gdzie chcesz jechać. Nie tam, gdzie jest ściana. Ściana sama cię znajdzie." / "Look where you want to go, not at the wall. The wall will find you by itself." |
| Mirek (on the radio) | „Dyfer Leny mam u siebie w kawałkach. Ty mi tylko Bawarki nie przywieź w torebce." / "I've got Lena's diff here in pieces. Just don't bring me the Bawarka in a bag." |
| The commentator, Zbyszek Gumiak | „Panie i panowie, ten kąt jest nielegalny w trzech województwach!" / "Ladies and gentlemen, that angle is illegal in three provinces!" |
| Zbyszek Gumiak (a transition) | „Czy to było... kansei dorifto? W Bawarce?!" / "Was that... a kansei dorifto? In a Bawarka?!" |
| Zbyszek Gumiak (a wall) | „Ściana: jeden, kierowca: zero. Ściana nie ma licencji, a i tak wygrywa." / "Wall one, driver nil. The wall has no licence and still wins." |
| Judge (cards) | „Linia: 8. Kąt: 9. Styl: babcia by płakała. Ze wzruszenia." / "Line 8. Angle 9. Style: gran would cry. With joy." |
| Kaśka „Ścinka" | „Mam 120 koni i każdy jest wściekły." / "I've got 120 horses and every one is furious." |
| Bjørn Bokvist | „W Norwegii drift to transport. Tu to sport. Dziwne." / "In Norway drifting is transport. Here it's a sport. Strange." |
| „Hrabia" (the final) | „Moje opony kosztują więcej niż twoje auto. Ale twoje auto ma serce. I spawany dyfer." / "My tyres cost more than your car. But your car has heart. And a welded diff." |
| A fan | „Zrób dym! Mama ogląda!" / "Make smoke! Mum's watching!" |
| A fan | „Kupiłem bilet za trzy stówy, żeby wdychać opony. Najlepsze trzy stówy w życiu." / "Paid three hundred to breathe tyres. Best three hundred of my life." |
| Lena (the podium) | „Dobra, możesz zostać w teamie. Ale pierogi dalej wożę ja." / "Fine, you can stay on the team. But I still deliver the pierogi." |

## 4. The drift technique (more physics, still arcade)

A **drift state** in `car.gd`, on top of each car's feel (garage plan 4b), used in the scene and
(lighter) in the city, so the Bawarka's "drifts fill nitro" perk and city drift points use the same
rules.

- **The numbers that matter**: the slip angle β (between where the car points and where it goes),
  the speed, the steering, the gas, the handbrake.
- **Getting in**: (a) a **tap on RĘCZNY** (the handbrake, in the scene) with the wheel turned above
  30 km/h; (b) a **brake-flick** in a bend (a short brake under 0.4 s while steering, above 35 km/h);
  (c) **power-over** for rear-drive cars: full gas in a slow bend. The rear tyres let go (rear grip
  falls to the car's drift grip) and β opens in about 0.3 s.
- **Holding it**: the angle follows a target: about 30° plus up to 25° more when you steer into the
  bend, less when you steer out of it (counter-steer); the gas holds the angle and the speed (rear
  drive: more gas, more angle); off the gas β closes and the car straightens in about 1.2 s. The
  drift costs speed by sin β, the gas pays it back.
- **Transition** ("przekładka"): flick the steering the other way with a short lift: the weight
  swings, β crosses zero and opens on the other side in about 0.6 s. Big points.
- **Too much**: β over 80°, or slow with β over 50°: a spin (a fail in a run). A wall keeps 70 % of
  the speed and breaks the chain.
- **Assist** (in the scene, setting kept): **PEŁNA** (full: the game counter-steers for you and keeps β
  between 20° and 55°; you only choose the line: the phone default), **ŚREDNIA** (it helps only past
  60°), **BRAK** (off: points ×1.2). Point controls work with the full assist.
- **The Bawarka 3.2 Drift**: max angle 65° (others 50-55°), the strongest power-over, the quickest
  transitions. Other cars can drift too, by their feel: Bolonez and Bawarka M3 well, the TT badly
  (quattro), the Iżera quietly.
- **What you see and hear**: white smoke from the rear tyres by slip × speed (one small MultiMesh of
  puffs, capped), black tyre marks on the asphalt (a ring buffer), the front wheels counter-steering,
  the body leaning, the camera leading where the car *goes*, not where it points, and widening a
  little with the angle; tyre squeal pitched by slip, the engine bouncing on the limiter, the crowd
  roaring at a zone or a big chain.
- **Controls in the scene**: the nitro's place (above GAS) becomes **RĘCZNY** (no nitro in drift
  competitions, like the real ones); GAS, BRAKE and steering as always; pad: A/RT gas, X handbrake;
  keyboard: Space handbrake.

## 5. Scoring (readable on a phone)

- **Points a second** = speed (km/h) × angle factor (best between 35° and 55°) × closeness to the
  wall (within 1.5 m ×1.5) × the **chain** (×1 to ×5: +1 every 3 s of unbroken drift, +1 for each
  transition).
- **Zones** (the real clipping points): 4-6 per track, painted on the track: the nose near an inner
  marker ("KLIP!"), the tail near the outer wall ("ZONA!"): a flash, a flame jet on the island, +500 ×
  the chain.
- **Banking**: the chain's points wait in the middle of the screen and drop into the total when the
  drift ends cleanly; a wall or a spin loses them (the arcade tension).
- **The judges** turn a run into a score out of 100: **Linia** (zones hit), **Kąt** (the angle held in
  the band), **Styl** (speed, transitions, no wall). Three parody judges hold up cards.
- **Tandem**: chasing, staying within 3 m of the leader adds "BLISKO!" and copying his angle scores;
  passing him in a drift loses that run; leading, drive clean and fast. The judges compare the two runs.
- **Qualifying**: two runs, the best counts; 60 of 100 gets you into the Top 8.

## 6. The scene and the tracks

- **The scene**: the stadium's bowl as a cutaway diorama, far off the map like the club (`club.gd`
  PLACE): the two tiers of stands as one stepped mesh in the Narodowy's red and white, a crowd of
  tiny figures (one MultiMesh, phones lit at night), the roof ring with its membrane and the central
  spire with the hanging screen cube, a ring of LED boards with parody sponsors, the asphalt floor,
  the two grass islands with a stage, screens, flame jets and an inflatable "Red Byk" can, concrete
  barriers and tyre walls, the paddock tent. Target **≤ 10 draw calls** and about 25k triangles;
  smoke capped (alpha is the phone's fill-rate risk); a bench before the PR.
- **Tracks** (same floor and islands; a layout is a set of barriers, cones and zone marks, so a new
  track is cheap):
  1. **"Ósemka"** (the real 2025 layout from F's pictures): a start on the south straight, a long
     sweeper round the west island, the transition between the islands, the east island's hairpin,
     back to the line. About 550 m, a run about 35 s.
  2. **"Wielka Pętla"**: round the outside of both islands along the walls: long, fast, all outer
     zones. About 700 m, opens after the final.
  3. **"Kółko pod Narodowym"**: the free practice pad *in the city*, on the night meet's car park:
     a cone circle and a gymkhana, drift points with no scene change.
- **The camera: isometric, not top-down** (F 22:39 asked which). Default: our isometric follow
  camera, lower (about 40° instead of the city's pitch) and closer, leading where the car *goes*,
  so the angle of the drift reads as the car's side turning to the camera and the stands rise
  behind the track (the spectacle of F's pictures). A **WIDOK Z GÓRY** button switches to a high
  top-down view: the angle and the line read best from above (the old top-down drift games), good
  for learning the track; the choice is kept. Both are only the camera, so both are cheap; the
  broadcast camera from the stands is for the replay. Both are tested in the Autopilot rows and on the phone.
- **Scale**: the floor about 150 × 90 m; drift speeds 50-90 km/h (the real cars go faster; at our
  camera's 80 m view these read as fast). The camera sits lower and closer than in the city; a
  broadcast camera from the stands for the replay after a run.

## 7. How it plugs in (architecture)

- The questline: one `stories.add({...})` in main.gd `_build_stories`, started by Darek's call
  (the calls owner and pacing as every friend).
- The event: an activity on the Activity kit (`activity.gd`), the scene a Node3D like `club.gd`
  (built on the first visit, the pause owner and the camera's `inside` rules), the drift state in
  `car.gd`, the scoring in a new static `drift_score.gd` (testable without a map), the rivals in
  tandem as **recorded lines played back** (a path with an angle and speed per metre, smoke and all),
  not physics: reliable and cheap, as Lena and Darek's tandem at the meet already are.
- Add-ons: **Beehave not used** (the rivals follow recorded lines; nothing chooses between
  behaviours). **Dialogue Manager not used** for the call (two buttons, like every friend's call, in
  `dialogue.json`); the paddock's lines are taps. Revisit if the paddock gets branching talk.
- New flags: `--drift=narodowy`, `--drift-track=1|2`, `--drift-assist=full|mid|off`, `--drift-log`.

## 8. Testing (it has to feel good, so it is tested a lot)

1. **`check_drift.gd`** (headless, joins `verify.sh`, `--fixed-fps 60`), the real car script:
   a tap of RĘCZNY at 60 km/h with the wheel turned opens β to 25-50° within 0.6 s; with the full
   assist and the wheel held it stays in 20-55° for 5 s; off the gas it straightens within 1.5 s; a
   transition crosses to the other side within 0.8 s; with the assist off it can spin; the city's
   Cruise stays under F's G4 slip rule unless the player asks for a drift.
2. **Scoring tests** in the same check: the chain grows and breaks, banking, zones, the judges' 100,
   the tandem's closeness.
3. **A drift bot** follows each track's ideal line with a target angle: the Bawarka Drift with the
   full assist scores over the qualifying line on both tracks, the hatch over 40, a car driven
   straight and slow under 10. The rivals' recorded lines run clean.
4. **Bench and shots**: `--drift=narodowy --shots`, the scene's draw calls and frame time, the
   turntable sheet for the Bawarka Drift and a site sheet for the stadium interior.
5. **Autopilot on F's Mac** (docs/PLAYTEST.md, new rows): **P24** the whole quest from the call to
   the podium; **P25** free practice on both tracks: how long a new player takes to hold a 3 s drift,
   where it spins, whether RĘCZNY is found. One run under 6 minutes each.
6. **The phone**: the thumb on RĘCZNY, the assist's feel, smoke on the iPhone (fill rate), the crowd's
   cost; PHONE-CHECK rows.

## 9. Phases (after the garage's P0 nitro and P1a car feel)

| Phase | What | Model | Size |
| --- | --- | --- | --- |
| **D0** | The drift state, assist, entries, transitions, smoke and marks, `drift_score.gd`, `check_drift` | Opus (feel) | 1 PR, ~2 days |
| **D1** | The stadium scene and the two layouts, crowd, pyro, camera; Bawarka 3.2 Drift model | Sonnet modeler, Opus directs | 1-2 PRs, ~3 days |
| **D2** | The questline: the call, paddock, practice, qualifying, tandems with recorded rivals, judges, podium, prizes, the Thursday practice, the city pad | Opus | 1-2 PRs, ~3 days |
| **D3** | The drift bot, bench, Autopilot P24/P25, phone pass | Opus on the Mac | ~1 day + an evening |

About 9 thread-days. D0 can start right after the garage's P1a (the drift state uses the feel
presets); D1 can run beside D0.

## 10. Questions for F (defaults built if nobody answers)

1. The event's name "Bokiem Masters" (Pro-Am round) and the sponsor parody "Red Byk". *Default: yes.*
2. Lena drops out with a wrist sprained on gran's pickle jar. *Default: yes.*
3. The Bawarka 3.2 Drift: on loan for the event and **yours after winning the final** (default), or
   yours at once?
4. The assist on the phone: PEŁNA by default. *Default: yes.*
5. Two tracks in the stadium plus the practice pad in the city. *Default: yes.*
6. The garage plan's buyable BMW look-alike becomes **"Bawarka M3"** (the game already calls
   Darek's car Bawarka). *Default: yes.*
7. The camera: isometric (lower, closer) by default with a WIDOK Z GÓRY switch. *Default: yes.*
