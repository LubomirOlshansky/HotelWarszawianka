# Parked questions and lanes in progress

The work doesn't stop for a question (docs/WORKFLOW.md "Backlog mode", the backlog-loop
skill): a question for the user is parked here with the default that was built, and the
session takes the next item. The user answers here, in a PR comment or in chat, in one batch.

## In progress

One session per lane. Add a row when you start an item, remove it when the item lands.

| Lane | Item | Session | Since |
| --- | --- | --- | --- |
| landmarks | One landmark per thread (the Cathedral and the Barbican are done; Poniatowski, MDM and the missing towers wait on photos, see Waiting); order in BACKLOG "Landmarks lane, hand-over" | fresh Sonnet threads | 2026-10-31 |
| landmarks, map, gameplay | The railway: stations, track, catenary, trains (docs/design/railway.md) | cloud thread "Build railway stations and city rail lines" | 2026-11-01 |
| all | The audit beyond the landmarks: BACKLOG "Audit: what is verified beyond the landmarks", its P0 items handed out next | cloud thread "Audit what's left beyond landmarks" | 2026-11-01 |

## Waiting
- **2026-11-02 · landmarks · The seven monuments of the monuments pass, part 2** — Built in the cloud from the Mac's photo reports (docs/landmarks/photo-reports/: nike, slowacki, starzynski, maly_powstaniec, kilinski, umschlagplatz, pomnik_wschod). Look check on the Mac or the phone against `refs/<slug>/`: the figures' poses (Nike's lunge and cloak, Kiliński's raised sabre, Starzyński's faceted armchair), the sizes, and which way Nike faces (the report could not tell; default built: north-east, toward Trasa W-Z). Default built: as the reports measured.

- **2026-11-07 · content, gameplay · Kieślowski tour "Dekalog na kółkach"** — Built (thread "Add Kieślowski quest and redesign Muranów"): Claire from Lyon, six Dekalog places, a shot per leg, her question at the estate (docs/design/dekalog-tour.md). Say: (1) the stops: add *Three Colours: White* places (not verified yet, so left out) or Poczta Główna (X) and SAWA (VI)? (2) Claire's lines and the KADR texts; (3) the hours 16:00-23:30. Default built: the six stops, those texts, those hours. The estate and the pools wait for your photos (K01-K19).
- **2026-11-07 · landmarks · the Palace of Culture's grounds and venues** — Built from OSM (raw tags on the Mac), three 2019-2021 Mapillary photos and F's aerial photo: knee-high (0.65 m) granite planters and retaining walls instead of 1.9 m walls, the five shrub beds as bushes, the Plac Defilad lot in asphalt with 168 bays, pavers at the kerbside lots; venue signs at the OSM doors. **(1) answered by F's six photos (2026-11-07):** Bar Studio sits in Teatr Studio's portico and on the square at its steps (umbrella tables, palms, BAR letters), with corten planters on the forecourt; rebuilt so. Open: (2) the planters' height and colour against the real granite (default 0.65 m, light grey)? (3) a look at the signs' size on the phone. Default built: as above; shots in project files pkin-grounds/.
- **Cinema tour (2026-11-07, thread "Add arthouse cinema tour quest"):** built defaults: (1) parody directors' names only (Gaspar Nojé, Paolo Sorrentello, Béla Tartak, Lars von Tramwaj, Wong Kar-Wajs), never the real names; (2) pay 220 zł - 20 a scratched frame + 25 a shot, 60 respect - 8 a frame; (3) text only, no voice for Wiktor yet; (4) photos wanted from F: Kino Atlantic's front (Chmielna 33) and Kino Amondo's entrance (Żurawia 20). Change any of them?
- **2026-11-07 · map · Grochowska's tram strip at the east edge (PT-28)** — Built: a collider across the tram strip on the barrier line, and barriers only where the trams' sides leave room. Grochowska's strip carries several tracks edge to edge, so no barrier fits there: the stop is unseen and the site fence stands about 10 m on. The other way would be barriers right across the strip, with the trams turning back short of the edge instead of running out under it. Phone look check: `--at=2160,-1447 --heading=90 --size=25`.
- **2026-11-07 · gameplay · Quest map and starts** — Built (docs/design/quest-map.md): (1) Ziomek's block, the rave's start, at Osiedle Za Żelazną Bramą; another spot? (2) the friend walks up within 30 m below 22 km/h; too easy to trigger by accident? (3) a WĄTKI tab tap makes the friend phone you now; or should it jump you to the start? (4) the "!" badge and the main star's glow on the phone. Default built: as listed.
- **2026-11-07 · content, gameplay · Taxi ride stories** — Built (thread "Make taxi rides interactive with stories"): 18 story passengers, each driven to its real place (F's ask the same day; a place that doesn't fit a pickup waits for another ride) in `game/data/taxi_stories.json`; 80 % of rides get one (club nights, dates and Hyrax runners keep their own lines), unheard ones first, the ghost lady only at night. On the way three lines, then a question on a side card with two answers (10 s to answer, the status panel hides meanwhile): the answer adds its tip (the pigeon startup's "investment" takes up to 20 zł of the tip, never the fare) and the liked one is +½ star ("rozmowa"). Check on the phone and say: (1) any story to cut or rewrite; (2) is the card while driving OK, or should the answers be bubbles you tap; (3) is 80 % right, or every ride. Default built: all 15, the card, 80 %.
- **Dead EVs (2026-11-06, thread "Add Bartek's dead Tesla heli rescue"):** built defaults, check on the phone: the parody name TESŁO Model Ś (owner Bartek, CEO joke "Pan Piżmo"); the first call 5-8 min into free play, then every 12-18 min; the loaded helicopter 25 % slower with softer acceleration; 180 zł + 30 respect (+60 zł under 2.5 min), strangers tip 60 zł. Change any of them?
- **2026-11-05 · map · The Patelnia and the Rotunda's stair** — Phone/Mac look check of the site `sunken` (`--at=-905,412 --size=40`, and `--at=-816,372 --yaw=200 --size=28` for the Rotunda): is the square deep enough (built: floor 10.0 m, 3.4 m under Marszałkowska, from the GUGiK grid's own bottom), are dark steel railings right on top of the walls, is the barrels' glass the right smoky grey, and is the whole wedge by the Rotunda a stair (built: treads across it, a glazed door at its foot under the Rotunda's edge)? The two blue tubes at the Patelnia's south-east corner were left at street level (F's aerial shows the corner stair open): open stairs with treads, or keep the tubes? Built default: as in the spec `patelnia.md`.
- **2026-11-05 · gameplay, content · Crazy drivers: TDJ or TDI, and the feel** — Built (spec `docs/design/crazy-drivers.md`): Szkoda Oktawia taxis, Szprynter couriers and the Pasatini in racer mode, at most 3 at once (`--crazy=N`). (1) The Pasatini's engine reads "1.9 TDJ" (Turbo Dizel Janusza) because TDI is a real trademark; say if you want "1.9 TDI" on screen (one word in the lines). (2) Phone feel: the Pasatini at up to 90 km/h (×1.6 the limit), taxis 72 km/h, couriers 65; blocks and cut-ins at race_block 0.5 / 0.75 per roll: fun or annoying? Numbers in traffic.gd CRAZY_*. (3) The name: Pasatini (your "Passatini" with one s, so it reads as a parody). Default built: TDJ, the numbers above, Pasatini.
- **2026-11-02 · landmarks · Sąd Najwyższy: a Mac photo gather for the main block** — The colonnade is built from the Plac Krasińskich reports (green ribbed columns, lettering band, rosette capitals, green beams; spec `sad_najwyzszy.md`). No report covers the rest, so it stays the LoD2 block. Wanted in `refs/sad_najwyzszy/` (Commons photos + the GUGiK ortho, REPORT.md in game coordinates): the fronts on Plac Krasińskich, Świętojerska and Bonifraterska, the roof garden's plan and colours, the three caryatids' spot and size, the glass's colour by day and night, the columns' real count and rib rhythm. Look check too: the green #738483. Default built: colonnade only, main block unchanged.

- **2026-11-05 · map · signals at main-street zebras** — F's round 3 asked for crossing signals. OSM maps none at 79 zebras across main streets with 2+ lanes each way; `road_smooth.crossing_kit` gives each a stop line, solid approach lines and a signal pole (no lit lamp, no controller). Default built: all 79. Check on Mapillary which are really unsignalled, and whether the poles should light up.
- **2026-11-04 · gameplay · Beta values A/B: the delivery clock and pay** — Review in `docs/design/beta-values.md` (A/B 1-5). Built: the route on the minimap, honest road lengths, "Gorący jeszcze 34 s", NASTĘPNE on the delivered card. Phone A/B: (1) hot is half of the fair time (~50 km/h door to door): reachable in traffic? B: 60 %; C: the heat stops at red lights. (2) no tip below 40 % heat; B: the tip shrinks smoothly. (3) a delivery streak "Seria" (× 1.1 a hot delivery in a row, up to × 1.5): not built; build it? (4) the order card waits 9 s; B: 4 s after the first order. (5) NASTĘPNE is a button; B: always point at the next stand. Default built: A for each.
- **2026-11-04 · gameplay · Beta values A/B: police escape** — The police runs P3 and R1 pass again (the test's escaping car now drives like a skilled player). A flat-out escape gets away in ~16 s (chasers 0.8 of your top speed, 6.5 m/s² in corners). A/B on the phone: A as is; B chasers 0.85 of your top. Default built: A.
- **2026-11-04 · gameplay · Beta values A/B: how the race shows** — Built (street races R5): the route to the finish on the minimap, the gap in seconds ("Pani Halina 2,4 s za tobą", "łeb w łeb!"), a lead-change toast with a tick (once in 6 s), the finish margin on the card ("o 0,8 s"). Phone A/B: (7) seconds or metres; (8) the lead-change toast on, off, or a rival's bubble instead; (9) slipstream (+5 % pull right behind the rival for 1.5 s, wind lines): not built, build it? Default built: seconds, toast on, no slipstream.
- **2026-11-04 · gameplay · Beta values A/B: lane assist** — GAMEPLAY_PLAN 1.5's "Asysta pasa" is built (Settings → Jazda → Asysta pasa, Classic only): with the steering strip near the middle, above 15 km/h, the car eases towards the middle of its lane 0.9 s ahead (on a 300 m curve it holds within 0.2 m hands off; a deliberate turn is untouched). A/B on the phone on Marszałkowska and Trasa Łazienkowska: A off (the default built); B on in Cruise, off in Sport; C on for everyone.
- **2026-11-05 · landmarks · Młotek, Kozia 9, Karowa 18a look check** — Built from the Mac photos (specs `mlotek.md`, `kozia9.md`, `karowa18a.md`). Look on the Mac or the phone: the head's overhang on Młotek; Kozia 9's section lengths (photo 1's bays and the ortho's roofs disagree; default between them) and its Moliera side; whether Karowa's ochre reads right. Default built: as the specs say.
- **2026-11-03 · landmarks, gameplay · Warsaw modernism and "Betonowy album"** — Plan in `docs/design/modernism-collection.md` (docs only). Defaults written into the plan: (1) the quest giver is Pani Wanda, a fictional retired architect whose 1970s slides spilled on Karowa's bend; (2) the whole-album reward is the "Betonowa" concrete-grey car paint; (3) two slides need the helicopter (Młotek, Centralna); (4) the Eastern Wall's 1960s towers join the album when the Ściana Wschodnia thread builds them. Also: the build order M1 Młotek, M2 Kozia 9, M3 Karowa 18a; each needs your "go" for a Mac photo gather.
- **2026-11-03 · gameplay · the chatter budget (GAMEPLAY_PLAN 0.2)** — Built as the plan says (`chatter.gd`): at most 2 bubbles, one new every 4 s (Settings → ŚWIAT → Gadatliwość miasta: Mało 8 s, Średnio 4 s, Dużo 2.5 s), one reaction in 20 s, none for a bump under 15 km/h, a near miss once a minute, nothing from the city while the car is pinned, pressing into something under ~11 km/h, held against traffic, trying in one spot for 4 s or offered the tow, and 5 s after; the ride's star toasts merge (one "−1 ★ · stłuczki" 3 s after the last). Defaults built where the plan left a choice: an ambient line while a card or the full map is up is dropped, not queued (city lines are random anyway); easter eggs and the GPS moments count as quest lines (always show); tiny-dog and bike-lane lines count as reactions. Phone check: drive into a wall on Marszałkowska for a minute (Autopilot P13 or by hand) and say whether the city now feels too quiet or still too chatty.
- **2026-11-03 · landmarks · Vitkac, Jabłkowski's and the Sheraton** — Built from the Mac photo reports (`docs/landmarks/photo-reports/vitkac.md`, `jablkowskich.md`, `sheraton.md`) and the OSM outlines (specs `vitkac.md`, `jablkowscy.md`, `sheraton.md`). Look check on the Mac or the phone: Vitkac's window pattern and band rhythm (one photo only) and where its name sits; Jabłkowski's ochre in sun (the Bracka front faces north-east, so it reads grey in shade), the arch count and the cartouche; the Sheraton's drum size and spot (OSM's round corner was used, the report's ortho put it ~15 m north) and whether the bands read too stripy. Not built: Jabłkowski's stained glass, the Sheraton's forecourt pavilion and umbrellas. Default built: as the specs say. The BGK building (F, 2026-11-03, site `bgk`, report `bgk.md`) too: its granite reads blue-grey in shade, the light wells are not cut, the roof signs are left out (real marks).
- **2026-11-03 · map · Ząbkowska's bars are off the map** — The thread asked for Ząbkowska's bar strip (W Oparach Absurdu, Beer Station, La Pepica, Bazzart, Moxy), but all of it lies at z < -2045, x > 1000, in the cut north-east corner (`centrum.json` "outside"). Default built: six parody bars on the Praga streets that are on the map (Okrzei, Wrzesińska, Kijowska, Targowa), see BACKLOG "Praga's old streets". Your call (same as Koneser): grow the map north-east, or leave Ząbkowska out. Also a Mac look check (`--at=770,-1890 --heading=0 --time=night --clock=23:00 --date=20260710`): signs on plausible walls, crowds on the pavement.
- **2026-11-03 · landmarks · Hotel Europejski rebuilt from F's photos** — Spec `docs/landmarks/specs/europejski.md`. Defaults built: the corners rounded at 6.5 m (the photo's pavilions; OSM maps tighter corners, so each bow sits up to 1.2 m inside the mapped corner, and the car still meets the mapped outline); the same facade on all four fronts (only Krakowskie's is photographed square on; the plaque is on that front only); the roof storey's louvres as dark glass with a curved top; the courtyard roofed in glass at 8.5 m (LoD2). Phone look check: the bows and louvres at play zoom, the plaque's gold letters by day.
- **2026-11-03 · map · Ząbkowska's bars are off the map** — The thread asked for Ząbkowska's bar strip (W Oparach Absurdu, Beer Station, La Pepica, Bazzart, Moxy), but all of it lies at z < -2045, x > 1000, in the cut north-east corner (`centrum.json` "outside"). Default built: six parody bars on the Praga streets that are on the map (Okrzei, Wrzesińska, Kijowska, Targowa), see BACKLOG "Praga's old streets". Your call (same as Koneser): grow the map north-east, or leave Ząbkowska out. Also a Mac look check (`--at=770,-1890 --heading=0 --time=night --clock=23:00 --date=20260710`): signs on plausible walls, crowds on the pavement. **Answered 2026-11-03 (F): not now, backlog only (BACKLOG "Grow the map north-east").**
- **2026-11-03 · content · Wilcza and Poznańska's bars (street-by-street pass 1)** — Built: seven parody neon fascias at the real bars' OSM points and pavement crowds on the pub curve. Mac/phone look check (`--at=-520,540 --heading=0 --time=night --clock=23:30 --date=20260710`): signs on plausible walls, crowds on the pavement and not in the road. Default built: as above; positions are OSM points, not doors.
- **2026-11-03 · content · Mazowiecka's club street (street-by-street pass 1)** — Built: five parody neon fascias (TYGRYS JAZZ, SZOTOWNIA, SZKIC NOCĄ, ENKLAWKA, POKÓJ 12,5) at the real clubs' OSM points, and queues on the pavement outside on a club curve (fullest Fri/Sat 01:00-03:00). Mac/phone look check (`--at=-750,-410 --heading=0 --time=night --clock=00:30 --date=20260710`): signs on plausible walls, crowds on the pavement and not in the road. Default built: as above, no ropes or bouncers; clubs sharing an address got one sign.
- **2026-11-03 · content · Nowogrodzka's bar strip (street-by-street pass 1)** — Built: eight parody neon fascias (KWARTA, U HALINKI BAR, ZA BARDZO, KRAFTOWNIA IPA DO DNA, SCHRON PIWNY, PODWÓRKO 22 SZOTY, NALEWALNIA KIEDYŚ PO 4, DŻINIARNIA) at the real bars' OSM points on Nowogrodzka 4-31, and pavement crowds outside them on a pub curve (fullest Fri/Sat 23:00-01:00). Mac/phone look check (`--at=-500,480 --heading=0 --time=night --clock=23:30 --date=20260710`): is each sign on a plausible wall, are the crowds on the pavement and not in the road? Are the names fine (all original parodies; "KIEDYŚ PO 4" is the one-price vodka bar that once cost 4 zł)? Default built: as above, no queues, no notebook cards.
- ~~**2026-11-02 · landmarks · Norblin and Browary courts from the photo reports**~~ — Built from `docs/landmarks/photo-reports/norblin.md` and `browary.md` (ortho positions; no photo shows the courts). Norblin now stands on OSM's "Plater" and "Galwan" (the first pass used "Modsen", the wrong block). Defaults built, for a Mac or phone look: (1) both courts open onto the glass street as notches (the ortho can't say whether a passage closes them); (2) the chimney is gone (the ortho shows none; say if there is one); (3) the glazed storeys go up to OSM's 50 m; (4) the glass street's roof is not built, because the map's 2018 LoD2 halls stand where the ortho shows the street; (5) Browary's 22 trees, S path and two café clearings are placed to the report, not to a photo of the garden.
  **Answered 2026-11-03 (F's look check and Norblin photos):** no chimney; the main lane is open-air between white workshops and the copper-clad blocks; the covered passage is the glazed strip between Galwan and Plater (built as a glass roof at the base's top, its extent still to verify, BACKLOG); Browary's trees are now in clumps with an edged path and paved café clearings. Applied (look-check fixes PR).
- **2026-11-03 · gameplay · the guide's beats behind jobs** — A player who keeps taking side jobs met Halina's race and the first call late (run 11: the race at 203 s; run 12: the call 83 s past its window). Default built: while a beat is due or 45 s away, no Podwózka request or "Na czasie" offer comes by itself (rides run on, the PODWÓZKA button still works); kebab orders at the stand are never held. Alternatives: B: a beat cuts in over a running job (Halina rolls up mid-ride, the job paused); C: also close the stand's next order while a beat waits. Where: BACKLOG "Playtest bugs".
- ~~**2026-11-02 · landmarks · Praga: St Florian's cathedral and Bazar Różyckiego**~~ — Built from the Mac's photo reports (`st_florian.md`, `bazar_rozyckiego.md`; specs `florian.md`, `bazar.md`). Defaults built: the cathedral's front faces west-north-west as the OSM outline says (the report says south-west: the outline wins); belfry and nave heights are proportions from photos 4 and 6 (towers 33 m brick, belfry to 42 m, spires to 71 m, crosses 75 m, nave ridge 35 m); St Michael stands on the axis 12 m before the porch; the bazaar's 16 regular OSM boxes are the 2023 green kiosks (three units a side), the other outlines the old stalls; the bazaar's gate on Targowa is not built (no photo). Mac look check: the front and statue against photos 4-5, the spire colour, the kiosks' unit count, a gate photo.
  **Answered 2026-11-03 (F's look check):** keep the front west-north-west and the muted patinated copper-green spires; three kiosk units a side as the working count; keep the contrast of green kiosks and patched old stall roofs (patches added). Applied (look-check fixes PR).
- **2026-11-02 · landmarks · Koneser and the Multimedia Fountain Park are off the map** — Both photo reports are in, but Koneser (1426, -2355) and the fountain park (-868, -2208) stand in the map box's cut north-east corner (`centrum.json` "outside": z < -2045 east of x -1706), so there is nothing to build them on. Default: not built, rows 85 and 88 marked off the map. Your call: grow the map north-east (a map-lane job: bake_osm's shape, sectors, CI pack), or drop them. **Answered 2026-11-03 (F): not now, backlog only (BACKLOG "Grow the map north-east").**
- **2026-11-02 · landmarks · Krakowskie Przedmieście and Plac Piłsudskiego rebuilt from photos** — ~~four calls where the report and the map disagree~~ **answered by F (2026-11-03)**: Pałac Potockich stays opposite the Presidential Palace, Lech Kaczyński by the Kordegarda-side corner, Bristol's rotunda at Krakowskie and Karowa; the University gate's clear opening is 3.8 x 4.5 m (built 2026-11-03, 20.6 m overall). Still open: the Saxon Palace's reconstruction site west of the square (the 2025-26 ortho: excavations, two white halls, a crane) [grass, as before]; the café gardens, bollards and awnings of photos 26-29 [not built yet: BACKLOG]; the granite setts south of Kopernik (no ground photo) [as before].
- ~~**2026-11-03 · landmarks · Poczta Główna and PAST-a (CITY_INVENTORY 76, 78)**~~ — Built from the Mac photo reports: Poczta as a kept LoD2 mass in salmon plaster with the Jasna corner's grey-silver dome, six white columns before the glazed entrance under a red POCZTA band, a white window strip, arched corner windows and a glazed hall roof; PAST-a as a 51 m grey-brown tower with a five-arch loggia, merlons, a gilt anchor on the roof, two white-and-red banners and the plaque. Open: (1) is the colonnade recessed into the front or standing out (built: 2 m out, on the hall's axis)? (2) PAST-a's footprint: OSM's outline or the ortho's 8 m further west (built: OSM's)? (3) a look on the phone (colours). Default built: as above; shots in project files poczta-pasta/.
  **Answered 2026-11-03 (F's look check):** the colonnade is a shallow recess with a projecting entrance canopy (rebuilt so); Poczta in pale warm stone with a pink cast, PAST-a darker weathered grey-brown; keep OSM's PAST-a footprint (the 8 m ortho shift is roof displacement, inconclusive). Applied (look-check fixes PR).
- ~~**2026-11-03 · landmarks · Warszawa Wschodnia**~~ — Built from the Mac photo report wschodnia (site `wschodnia`, spec `wschodnia.md`): OSM's hall outline (nothing drew the hall before), glass to 9.8 m under a 10.4 m roof grown 3.2 m, its edge folded every 3 m, V struts every 7.5 m (green on the track side, white-grey north), WARSZAWA WSCHODNIA on a dark board, rust-brown ridged roofs over the five long island platforms between x 1860 and 2120. Open: (1) the hall's height (no LoD2; guessed from photos); (2) do the two short platforms by the suburban hall have roofs too (default: bare)? (3) the fascia's pleats against photo 1; (4) a look at the default zoom on the Mac or the phone. Default built: as above.
  **Answered 2026-11-03 (F's look check):** keep 10.4 m as the working roof edge; the short suburban platforms are partly roofed (built from x 2020 east, endpoints to verify); folded eave and V struts made more prominent. Applied (look-check fixes PR).
- ~~**2026-11-02 · landmarks · Muzeum Powstania Warszawskiego**~~ — Built from `refs/mpw/` on the Mac (25 Commons photos, the ortho, REPORT.md, PARTS.md) and LoD2 (spec `mpw.md`, site `mpw`). Look check on the Mac or the phone: the Przyokopowa front (eleven bays, the blind fourth, the cream attic), the halls' gables and the red grids on the park side, the tower (the wedge, the Kotwica's shape and size, the platform's overhang direction, guessed west and south), the Wall of Remembrance's line and length, and whether the white bannered wing north of W1 should be added. Default built: as the parts list measured.
  **Answered 2026-11-03 (F's look check):** add the pale bannered wing north of the first hall (built: three storeys, banners and flags); deeper brick arches (built); the platform's cantilever is confirmed, its west/south direction stays provisional. Applied (look-check fixes PR).
- **2026-11-02 · landmarks · Most Poniatowskiego** — Built from `refs/poniatowski/` on the Mac (30 Commons photos, four orthos, the report `docs/landmarks/photo-reports/poniatowski.md`), spec `poniatowski.md`. Look check on the Mac or the phone: the towers' cream and proportions (heights ±3 m from photos), the shafts' place at the land end of each pavilion (the report saw it on the south-west group and mirrored it), the arcade bays, the pier spacing. ~~Open: is there a pier near the west bank in the deck's shadow (the west span is ~104 m and the record says eight spans; check photo 22 or the ortho), and are the two east floodplain piers at (1250, -243) and (1322, -267)? Default built: five piers as the report measured.~~ **Answered 2026-11-03 (F):** eight river spans, so seven piers; the 104 m west span is unreliable, verify the near-bank support from a bank-side elevation. The Mac checked photos 22 and 1 and the ortho (`poniatowski_piers.md`): a waterline pier under a coat-of-arms pedestal at about (985, -159) ±8 m, the 7th on the east floodplain at about (1375, -284) ±15 m. Built: seven piers (the bank one at s 64, clear of the promenade's paths). Still open: the three floodplain piers' exact places (a photo from the Wał Miedzeszyński side). F also asked to strengthen the towers' shafts and pavilion arcades: done 2026-11-03 (corner piers, two string courses, a corbel table under the cornice, bigger arched windows, a taller belfry and crown; the arcades' piers 0.35 m proud with keystones, an impost band and a plinth); a look on the Mac or the phone says if it is enough.
- **2026-11-03 · landmarks · the Powiśle viaduct's open ribs and the bars in its bays** — Rebuilt after F's answer (below, Answered): two rows of open concrete arch ribs with struts up to a steel edge girder, 27 arched spans per row plus 4 beam spans; the closed bays with doors and windows and five parody bars with neon, lit glass and café tables. Open: (1) which 4 spans are the "supported differently" ones (default: the 4 by the west abutment, on deep steel girders); (2) which bays are really closed (default: all 9 per row between Kruczkowskiego's and Solec's pier buildings, facing Al. 3 Maja, after photo 17 "przy Solcu"); (3) the bars' names are parodies (Q-BAR POD WIADUKTEM nods to K-Bar; WINO POD ŁUKIEM, NITY I KUFLE, BETONIARNIA BISTRO, KAWA PRZY FILARZE) at bays chosen by the cloud, not the real bars' doors: move them to the real bays from a Mac photo or OSM; (4) still open from before: the south arcade standing back under the deck along Al. 3 Maja (s 296-430), and the north stairs' look. Default built: as above.
- ~~**2026-11-02 · landmarks · Pasaż Wiecha and its pavilions (first scene items 4-5)**~~ — Built from the Mac photo report dt_pawilony: four two-storey pavilions (dark shop storey, white band with a strip window, 7.2 m; OSM said 4.3-7.6 m), white Y masts on the pasaż's axis where the map has its lamps plus three, nine café tables under white parasols, planters, bollards across both ends. Open: (1) the slabs above the pasaż are cream-ochre from the 2026-11-01 photo check, the report says grey-white #D8D8D4 with balcony bands: which is right today? (2) a phone look at the default zoom (the pavilions' fronts face away from the default camera; turn it to see them); (3) the 2025 building site at Chmielna's end is not shown (default: street); (4) a Christmas tree on the pasaż for a winter event? Default built: as above.
  **Answered 2026-11-03 (F's look check):** slabs light warm grey (provisional) with clear horizontal balcony bands (built); white Y masts and pavilions first (masts made taller and stouter); the 2025 building site stays out; a Christmas tree for a winter event is a BACKLOG item. Applied (look-check fixes PR).
- **2026-11-02 · landmarks · POLIN and the Ghetto Heroes Monument** — Built from `refs/polin/` on the Mac (25 Commons photos, the ortho, REPORT.md) and the LoD2 roof (spec `polin.md`). Look check on the Mac or the phone: the fins' grey-green (S_FINS reads as panels every 2.4 m, the real fins are 0.3 m with a speckled letter frit), the canyon wedge's width and lean, the west lens's size, and the monument's steps, reliefs and menorahs. Estimates from photos only: the 18 m height (LoD2 agrees), the monument's 9.5 m width. Default built: as the report measured.
- **2026-11-02 · map · junction lines and the loop 3e structures: one Mac pass** **Done 2026-11-03 except the parked points below** (junction medians painted, deck 4 fixed, details in BACKLOG/ROADMAP). Parked, defaults built: (a) Karowa footbridge: the photo shows a ramp landing on the pavement, the deck end is 0.7 m above it and the '2.2 m' is the 10 m grid's slope; pin lone deck ends to the path that continues them (solver-wide)? Default unchanged, and the allow reason at (304, −1554) wrongly names Most Śląsko-Dąbrowski. (b) Edge lines along every main-road kerb are not Warsaw practice (photos show them only on expressways and hatch borders): keep as style? Default unchanged. (c) A zebra refuge inside a bigger painted wedge (e.g. (722, −32)) stays raised; paint the wedge and keep only the zebra span? (d) Add bake_street_details.py and bake_park_details.py to bake_all.sh? (e) Łazienkowski's loop ramps (slab per piece; footbridge deck 159 crosses ramp deck 43 at (2037, 867)) need their own Opus map_builder thread. (f) One grass triangle at Wał Miedzeszyński (1500, −135) is part of a >30 m strip the rule doesn't reach. (g) PR #382's CI: the Mac re-bake dropped three pit fills main's bake had (Olszowa east end (188, −1885), (−49, 1301), (−1006, −1728)); against map-pack-1's terrain Olszowa then reads 13 % (C1, allowed in check_roads_allow.json). Does the Mac's terrain.json differ from the pack (`python3 -I tools/map_pack.py check` on the Mac), and if so publish map-pack-2? Default: allowed, unchanged. Cycleways (`compare_cycleways --list`): tracks 100 %, lanes 85 %, contraflow only 4 % of 33 km (Poselska, Walecznych, Grzymały-Siedleckiego, Elektoralna, Berezyńska, Oczki, Pawia, Nowogrodzka), bus lanes for bikes 1 % (Raszyńska, Królewska). — Both v1.0 lines
  ("Junction lines checked against photos", "Loop 3e leftovers") can't be done in the cloud: the
  cloud's network refuses the GUGiK orthophoto (and every other imagery host), and a structure fix
  needs a re-bake from data/raw (the surface model sets the deck heights). Default built: nothing
  changed. Mac brief (map-engineer, Opus): (1) `python3 tools/overlay_ortho.py shots/jl_p3k.png -77 670 90`,
  `... shots/jl_ponir.png 1381 -344 110`, `... shots/jl_walm.png 1514 -147 110` (Plac Trzech Krzyży,
  the Poniatowski ramps, Wał Miedzeszyński) and judge each white/yellow line inside the junctions
  against the photo; cut the ones Warsaw doesn't paint in `bake_roads.py` (`_crossed` /
  `bake_edges`), keep the real edge lines. (2) The three structure leftovers in BACKLOG "From loop 3e":
  Łazienkowski's Praga loop ramps (slab per piece), deck 4's parapet collider, the Karowa footbridge's
  Praga end 2.2 m in the air at (304, −1554) (a longer ramp or stairs to Okrzei). Then the whole chain
  and `verify.sh`.
- **2026-11-02 · content · Kibice match day: where do the fans come from?** — The map has no tram near Stadion Leguminy, so the walkers come from the two bus platforms by the Trasa Łazienkowska (about 1331,1234, east of the stadium), along Łazienkowska from the west (Agrykola / Myśliwiecka) and up Czerniakowska from the south (`ROUTES` in fans.gd). Do real match-day crowds come mostly from these, or from somewhere we should add (a tram stop further off, the metro)? Also a phone look: are the bunches readable at the default zoom (`--fans-now --fans-phase=arrive --at=1292,1290 --heading=200`)? Default built: the four routes, kick-off 1.5 h into the evening, a win 65 % of the time, a draw otherwise, never a loss.
- **2026-11-02 · content · Wellness circles (F's ideas #2, #3, #4, #8)** — Mac look check: the eight spots (docs/design/wellness.md) are read off the baked lawns, not seen. Do the sound-healing ring, the techno-yoga rows with their hamster balls, the 40+ circle round its tree and the kung-fu schools sit well in Park Świętokrzyski, Skwer Kościuszki, near Rondo Daszyńskiego, at Browary, in Ogród Saski, Park Ujazdowski and Ogród Krasińskich? Built default: daylight hours only, one sign each ("DŹWIĘKOTERAPIA, WEJŚCIE 80 ZŁ", "TECHNO JOGA + CHOMIKI", "KLUB PEŁNI 40+ / BUDZIMY MAŁĄ DZIEWCZYNKĘ", "SZKOŁA ŻURAWIA"); say if a joke is too sharp for the women's club.
- **2026-11-02 · landmarks · railway S3c-e: the WKD stops, look check** — Built from the Mac photo reports (`wkd_srodmiescie`, `wkd_ochota`). On the Mac or the phone (`--at=-1712,742`, `--at=-1640,722`, `--at=-2335,972`): do the two propellers read right (wings ~9.6 m each, set off the axis in opposite ways, tips raised 0.45 m, the raked pier on the side away from the cutting, the parapet box open at the east end)? At Ochota, where does the stair really reach the street (built: one flight at the platform's west end, rising west, per the report's default), and is the slab where OSM has it (the report's ortho reading put the deck ~10 m further south)? Wschodnia and Gdańska stay unbuilt (mostly off the map).

- **2026-11-02 · content · KRINGULA PIZZA joke (F's ideas #6)** — The final joke is yours to write. Built default (placeholder): the neon sign KRINGULA / PIZZA on Poznańska (52.22725, 21.01575, corner approximate), a line of 24 (40 at Fri/Sat dinner and Sunday afternoon, open 12:00-23:00), six placeholder fan lines tagged `kringula` in dialogue.json ("I cried at the first bite..."). Also: is Poznańska the right spot, and should the van or Frogs poster point to it? The longer morning queues at NERWO pavilion and KOSZTA Marszałkowska (16, working days 7-11) are a guess too. Mac look check of the door and the line.
- **2026-11-02 · map · Street widths (map review C)** — Built: one-lane one-way streets 5.5 m (6.5 m tertiary) instead of 3 m, two-lane two-way streets 7 m instead of 6 m (F said yes to both). Left: a phone/Mac look at Mokotowska, Wilcza, Hoża and a two-lane street such as Koszykowa: do the wider streets read right between the houses?
- **2026-11-02 · map · Krajobraz places: Stadion Narodowy grounds** — Mac look check: do the 80 new trees (lime/plane rows 9 m apart on both edges of the four mapped entrance plazas, 9 groups of 3-5 pollarded willows on the big lawns, `tools/planted_trees.py` place `stadion`) match the orthophoto's avenues and groves, and are the shrub belts and the avenues' paving worth adding? Default built: trees only.
- **2026-11-02 · map/landmarks · Skwer Linearny na Złotej and Dom pod Orłami** — Mac look check against your photos: the building's eagles (pose, size), the tower drums' steps, the portals, the metal letters (built as the parody KRAJOWA / RADA SPÓŁDZIELNI ORŁÓW, dim warm grey); on the square, the stone blocks round the rock fountain and on the lawns, the benches, the curved bench by the Marszałkowska fountain, the café gardens and the bollards at Jasna (`skwer_zlota.gd` ITEMS), and the limes (`tools/car_free.py`). Also: is Zgoda in front of the building closed to cars now? Built default: Złota car-free with a 20 km/h zone, Zgoda left as the map has it.
- **2026-11-02 · map · Paving and kerbs at the start (first-scene items 4-5)** — Phone look at a fresh start: do the grey pavements round the start (`ground.gdshader` `START_BOX`) read as Warsaw's grey concrete, or too cold next to the warm map outside, and is the 12 m fade at the box's edge visible? Do the yellow tactile pads at the crossings and the platforms' edge and tactile lines read at the default zoom or only up close, and is their yellow too loud? Built default: the grey only in the start box, pads at every crossing city-wide, `TACTILE_COL` #c6ad60 (ground) and #b89f58 (platforms). The bench on the iPhone 11 (shader only and two triangles a pad, +0 draw calls expected).
- **2026-11-02 · map · Roadworks at the map's edges** — Mac look check: drive to an edge (e.g. `--at=-3110,1336 --heading=270`, Jerozolimskie west; `--at=-170,1700 --heading=180`, Armii Ludowej south) by day and night: do the barriers, the ROBOTY DROGOWE / OBJAZD boards, the excavator and the tarp fence read as real Warsaw roadworks at phone zoom, and is it too samey across 237 closures? Built default: one kit for all, sized by the road (BACKLOG "Roadworks at the map's edges").
- **2026-11-02 · landmarks · Krajobraz K3: Varso Place** — Mac photo check (refs/varso_place/, Commons + the GUGiK orthophoto; the cloud got 403): built from the developer's and ZinCo's pages only (spec docs/landmarks/specs/varso_place.md). Check: where the sky garden's 16 hawthorns really stand (the 205 m step on the tower's north-west half is our guess, and whether it is glazed), whether Varso 1's top and Varso 2's 80/72 m roofs are planted terraces at all and how many trees (default: up to 9 small trees each), the name stone's spot and look (default: granite plinth by Al. Jana Pawła II, VERSO PLACE in warm white) and the erratic's spot and size (default 4.2 x 3.2 x 2.1 m by the tower's north-east corner), the 6 young trees in Chmielna's bare beds. Not built: the lobby's olive trees, Varso 1's 7th-floor terrace.
- **2026-11-02 · map · Krajobraz places: Bulwary splash pool** — Mac look check of the splash pool and the three fish between Most Śląsko-Dąbrowski and Most Świętokrzyski: is the pool at the real spot (built on the plaza between pavilions 3 and 4, at about -124,-1365), are its size and colours right, where are the amphitheatre and trampolines? Default built: a 8.4 x 5.2 m pool with 14 jets, bronze/steel/patina fish.
- **2026-11-02 · map · Krajobraz places: Rondo Daszyńskiego plazas (K5)** — Mac photo check of the planted squares round Skyliner, Generation Park and Mennica Legacy Tower (docs/design/rondo-plazas.md): were they built from the mapped open ground only (121 young trees, 51 beds, 11 benches); do the groves sit where the real ones do, is Skyliner's passage forest-like, are the Mennica forecourts too crowded, where are the real benches and terraces? Default built: staggered rows 6-7.5 m apart, 4.2 m from every scanned trunk. Zones are in `PLAZAS` of `tools/plaza_gardens.py`.
- **2026-11-02 · audio · Beta radio: PÓŁNOC FM hidden** — F chose KEBAB FM (vaporwave) and MORDOR FM (minimal techno) for the beta (`"lineup"` in radio.json). PÓŁNOC FM is out of the cycle, but the first-10 tape, the cassettes and some eggs still open "a PÓŁNOC FM track" (toast and egg card) that the player can't tune to. Options: A: leave it (the unlock is quiet, the station comes back after the beta) / B: rename the reward to respect only while PÓŁNOC is out / C: put PÓŁNOC back as a third station. Default built: A. Also on the phone: the greeting's ticker length (about 130 characters) and DALEJ next to RADIO on the SE.
- **2026-11-02 · map · Rondo Dmowskiego** — Mac look check of the site `rondo` (`--at=-836,461`): are the four flower beds the right size and place against the orthophoto (default: crescents 15-19.6 m out, red and purple by quarter, shrub beds 9.4-11.8 m)? Does every one of the twelve underpass stairs really have a blue tube (default: all twelve; some may be open stairs) and is the tube's height right (default: crown 2.8-3.9 m)? Is the mural on the right wall (default: the Patelnia's south wall, its first 50 m, facing the square)? Built default: as in the spec `rondo-dmowskiego.md`.
- **2026-11-02 · map · Krajobraz places: Arkadia playground** — Mac look check: does the rope course stand where the real playground does (we put it in the green strip by Al. Jana Pawła II west of Arkadka; the real one at no. 82 may be elsewhere), and is its size and colour right? Default built: a 14 x 9 m piece, red-orange ribbon with teal and magenta bands.
- **2026-11-02 · content · Office crowds at Rondo Daszyńskiego** — Phone look check (cloud has no phone and no performance bench): is the crowd dense enough at the metro exits and zebras on a Wednesday 08:30 (`--time=live --clock=08:35 --date=20260916`), are the white/navy/grey figures readable at phone size, do the walkers really cross on the zebras, and are the bubbles (every 12-25 s) too many or too few? Props (lanyards, laptops, coffee) are only in the lines: the shared person mesh has none. Also a bench with `--crowd=2` at 08:30 on the rondo (no new draw calls expected: the walkers reuse the dawn MultiMesh, the standing groups the sector cells' MultiMeshes). Built default: 56 walkers, 88 standing, weekdays only, spots read off the map's zebras and metro exits. The Spire's foyer is not reachable by footway from the rondo's exits in the map data, so nobody walks to it.
- **2026-11-02 · map · Krajobraz places: ul. Bracka** — Mac look check of the Bracka woonerf (Al. Jerozolimskie to Krucza, behind CeDeT): 22 young trees were planted in its mapped beds (`tools/planted_trees.py`, species mix plane / maple / cherry / bird cherry, 5-8 m) because the 2023 tree scan predates the 2024 planting; do they stand where the real ones do (orthophoto), is the paving's colour right (drawn as the minor-road grey; granite slabs as on Chmielna is a guess), are the old service ways across the north wedge still there? Default built: one young tree per bed of 7 m² or more, 33 in all.
- **2026-11-02 · map · Krajobraz K2b: Chmielna's benches** — Mac look check: the 64 benches (4 from OSM, 60 placed every ~7.5 m on alternate sides, facing the street) against photos of the street: where do the real chairs, benches and long flowing benches stand (clusters at the squares?), and is a long-bench model worth it? The fountain by Kino Atlantic already has its 0.45 m stone edge. Default built: as described.
- **2026-11-02 · map · Krajobraz places: ul. Chmielna** — Mac look check of Chmielna (Nowy Świat to Pasaż Wiecha): 65 young trees went into the OSM tree pits (one each, 2.4 m² or more; elms on the narrow stretches, planes on the squares by Pasaż Wiecha and Kino Atlantic, a few cherries, a linden and black locusts), 85 with the 20 scanned (the city's list says 88: 57 elms, 24 planes). Do they match the orthophoto? Is the granite (#c9c7c1, cooler than the old paving) the right tone? Ali's memorial stone stands by the bed on the north-east corner of Pasaż Wiecha and Chmielna; is that its spot, and the square's official name (plate: SKWER BROWNE'A)? Default built: all of the above.
- **2026-11-02 · map · Muzeum Historii Polski** — The museum (Cytadela, ul. Dymińska 13, with its 6,500 m² green roof and park) is ~0.7 km north of the map's north edge, so nothing was built. Grow the map north over the Citadel, or show it as a stand-in on the far skyline? Default: nothing until you say (docs/design/krajobraz-places.md K10).
- **2026-11-02 · gameplay · Life and sound at the start (first-scene items 6-7)** — Phone look and listen at a fresh start: are about 35 people standing at the cafés, kiosk and paving plus the busier pavements (1.6 × walkers) lively or cluttered at the default zoom, do the café sitters read (they sit on the footway beside the tables, not on the chairs), is the tram bell heard over KEBAB FM in the first seconds, is the square's talk too loud? Also the bench at the start on the iPhone 11 (walkers' CPU, no new draw calls expected). Built default: the numbers above (`crowds.gd` `FIRST_SCENE`, `pedestrians.gd` `BUSY_BOOST`).
- **2026-11-02 · content · MROŻULO TV lettering** — Mac/phone look check: is the 5 cm pixel lettering under the pink band readable at phone size (z offset -0.2, y 0.58 on the van's flank; `TrendJob._van_lettering`)? Default built: dark text, both flanks.
- **2026-11-02 · map · Plac Zbawiciela cafés and church night (pass 5)** — Mac look check: the four neon cafés (`Storefronts.ZBAWICIELA`) on the real doors, the six parasol terraces in front of the MDM blocks (spots from the outlines: `TERRACES` in `bake_street_details.py`), and the church at night (lit crosses, amber rose, floodlamps; is the real church floodlit?). Built default: parody names, no heaters or awnings. Own photos of the square's real cafés would settle the doors.
- **2026-11-02 · content · Nowy Świat shopfronts** — Mac look check for the eight signs (`Storefronts.NOWY_SWIAT`): each sits on a wall chosen from the road line, not a real door, so move any that land on a gap, a side street or the wrong side; are the pastel tubes readable at dusk beside the KUKŁA and NERWO signs? Still open (needs photos/orthophoto): per-house plaster colours, real shop awnings, café gardens, the Visitation and Staszic ends. Default built: neon only, no queues, no notebook cards.
- **2026-11-02 · content · Krakowskie Przedmieście shopfronts** — Mac look check for the eight signs (`Storefronts.KRAKOWSKIE`): each sits on the wall nearest a mapped house number, not a real door, so move any that land on a gap, a side street or the wrong side. Open (photos): real awnings, café gardens, a carriage rank. Default built: neon only, no queues, no notebook cards.
- **2026-11-02 · landmarks · Most Poniatowskiego deck, MDM blocks, missing towers** — three lane items stopped for lack of photos (the cloud has none and no LoD2): (1) 1.8 the bridge: built from photos since 2026-11-02 (see Most Poniatowskiego below); (2) 2.8 MDM and Plac Konstytucji arcades, reliefs, corner towers; (3) 2.9 Pekao Tower, Warsaw Towers, Prosta Tower, V Tower: the OSM towers have no names, so which tall outline is which needs your word or a photo (never name Bank Pekao: parody name please). Default built: nothing; the generic towers stay. Send a few free or own photos per item and a thread builds them.
- **2026-11-02 · content · Nowy Świat shopfronts** — Mac look check for the eight signs (`Storefronts.NOWY_SWIAT`): each sits on a wall chosen from the road line, not a real door, so move any that land on a gap, a side street or the wrong side; are the pastel tubes readable at dusk beside the KUKŁA and NERWO signs? Still open (needs photos/orthophoto): whether the new per-house plaster palette (`NOWY_PASTELS`, pass 2, a guess) matches the real houses, real shop awnings, café gardens, the Visitation and Staszic ends. Default built: neon only, no queues, no notebook cards.
- **2026-11-02 · gameplay · G13c police vs the TT, pad nitro** — Chasers now drive at 0.8 of your own top speed (the TT at engine 3: 32 m/s, was 24), the nitro's lift left out so a burn opens a gap. Phone check: does a TT chase still feel escapable, and is LB / RB a good nitro on a real pad (the view now turns with right-stick flicks)? Built default: 0.8, LB or RB, Shift on a keyboard (N no longer, it switched the time of day).
- **2026-11-02 · gameplay · Police chases** — Phone check: with chasers at 0.8 of your top speed and the escape at 100 m, does a flat-out run lose them in about 15 s without feeling free? (`CHASE_TOP` in `police/police_unit.gd`, `ESCAPE_DIST` in `police.gd`.) And a look at the new silver radiowóz estate and the silver police van against the photos: band height, checker strip, bonnet panel, the van's black mesh window. Built default: 24 m/s, 100 m.
- **2026-11-02 · map · Marszałkowska shopfronts (pass 4)** — Mac look check of the eight neon signs (milk bar, dry cleaner, watchmaker, pastry shop, optician, florist, haberdashery, herbalist) on Marszałkowska 140, 124, 85, 83, 62, 58, 53, 43: on a wall, readable, at a plausible door? Also your own photos for per-house plaster colours, cornices and the zebras/cycle crossings (no free photos in the cloud). Default built: signs snapped to the mapped addresses.
- **2026-11-02 · map · Marszałkowska street details** — Mac/phone look check: the new tram-island kits (a bench, a stop post, a ticket machine on the slab of the islands by Świętokrzyska and south of the Rotunda; are they on the slab, not sunk or floating, and facing the tracks?), the planters, bollards, kiosks and columns now on Marszałkowska north of Świętokrzyska and south of the Rotunda (C9, C10: clutter or life at camera size 80?). Also photos for the crossings (zebras and the cycle crossings against real Marszałkowska), the facades and shopfronts house by house. Default built: the bake's placement.
- **2026-11-01 · landmarks · Stadion Leguminy** — Mac look check for the Legia ground on Łazienkowska (built in the cloud with no photo): facade colours (default: light-grey and graphite panels under a graphite band, a red line and a green band), the roof's opening size (default 160 x 122 m round the pitch), seat colours (default white, green, red blocks), where the four floodlight masts really stand, and whether the south and east LEGUMINA signs read at night. The 20 m west stand and the 5.4 m footprint are not modelled separately. Parody name chosen because the club name is a brand; say if the real place name should be used.




- **2026-11-02 · landmarks · Boulevard dressing** — Mac photo check (spec docs/landmarks/specs/bulwary.md, shots in the project files, folder bulwary): are the six pavilions on Bulwar Grzymały-Siedleckiego concrete with green roofs and glass river fronts (built so, one shuttered), and which face holds the bars? What are the four 7.2 x 2.2 m boxes in the park by Karowa (built as bar containers; were 14 m blocks) and the kiosks by the Marina and by Kaskada? Do the 17 deck strips with leżaki sit on the lower promenade, not on steps or the cycle path (positions measured from the shore runs, flat cloud ground)? Phone: do the bulbs and neon read by night? Default built: as described, parody names CUDAK, POMOSTEK, RZECZKA.
- **2026-11-02 · landmarks · Hortus and Moderna** — Mac photo check: Hortus (Topiel 12): the office glass and frame colours (built blue-grey glass in a white grid), are there piers under a recessed ground floor on Topiel and Zajęcza, and the Drewniana flats' plaster, cornice and roof (built warm plaster, mansard)? Moderna Powiśle (Zajęcza 1A): is the old tenement the street front on Zajęcza (built so) or the back, its colour, and is the new wing taller with set-back penthouses (built 14.2 m + a penthouse floor to 17.4 m)? Specs docs/landmarks/specs/hortus.md and moderna.md.
- **2026-11-02 · landmarks · Piano House and Cube House** — Mac photo check: does Piano House (Zajęcza by Topiel) really read as a keyboard (white plaster, dark window strips in 2s and 3s) and is its top floor set back in dark glass? Where are Cube House's (Topiel by Leszczyńska) real bays or loggias, and its colours? Built: specs docs/landmarks/specs/piano_house.md and cube_house.md, sites `piano_house`, `cube_house`; shots in the project files, folder piano-cube.
- **2026-11-02 · landmarks · Pokorna 2** — Mac look check: does the 57 m block off Pokorna now read as flats (balconies, warm plaster #d6c3ad, blue-grey railings), is its real colour closer to grey or pale pink, and do the balcony slabs clash with the real LoD2 walls (gap or z-fight)? Built: spec docs/landmarks/specs/pokorna2.md, site `pokorna2`, `--prebuilt` look not rendered in the cloud.
- **2026-11-02 · content · Language choice** — Phone look check for the new Polish / English choice (title buttons top right, Settings → DŹWIĘK → Język): is the text the right size now that each screen has one line, not two (cards, toasts, the ticker, the pull-over card), do the title buttons clear the notch, and does anything still show both languages? Not covered by `check_language` (drawn text): the notebook page, the pedals' words, the full map's labels. Default built: the phone's language until the player picks one (Polish phone: Polish, any other: English); a text with no English (street, parody and place names) stays as it is in both.
- **2026-11-02 · map · Cycle paths** — Phone look and ride check (the cloud has no GUGiK data, only the baked outlines): after `tools/cycleways.py` closed 195 gaps (ends within 3 m), put 52 ends on a neighbouring path, joined 218 split ways and rounded 68 corners, do the red paths draw smoothly and do riders carry on at the joins instead of turning back? Gaps of 3-8 m (about 600 ends, often the two sides of a street) were left on purpose; default kept. Compare the paths with OSM once on the Mac (`python3 -I tools/cycleways.py --dry` after a re-bake prints the same counts).
- **2026-11-02 · map · Le Régina (Kościelna) and the New Town hotels** — Parked: `centrum.json` has no Kościelna, Freta or Zakroczymska roads and no tenements there, so a hotel front (the `HOTELS` mechanism, landmarks.gd) has nothing to attach to. Needs the bake extended north of Freta (map-engineer, Opus, Mac). Default built: nothing.
- **2026-11-02 · landmarks · Jana Pawła II blocks** — Finding, nothing built: BACKLOG has no such item; buildings of 26 m and up (and slabs 45 m+ long) on the avenue already get the large-panel facade type 2 automatically (`_building_type`). The cluster at (-1855, -530) is ~170 one-metre, 15 m "yes" objects (orange, grey roofs) in an 85 x 64 m patch, not a block row; the Mac look check should say what it really is (OSM way on the real map near Al. Jana Pawła II) before anyone models it. Which blocks F meant (name or photo) is the open question.
- **2026-11-02 · content · Powiśle streets** — Mac look check for the eight Powiśle shop signs (`Storefronts.POWISLE`: FLAT BIAŁY, ROWEROWNIA, WINYLE NA SKARPIE, KSIĘGARNIA POD SYRENKĄ, BAR TOPIEL, PIEKARNIA NA POWIŚLU, ALTANA, PRZY SOLCU): right street and wall, readable by night? Phone: do they crowd the boulevards' signs? Default built: signs only, spots snapped to the baked streets, no doors, queue or notebook cards.
- **2026-11-02 · content · Classic cinemas** — Mac look check for the seven cinema marquees (`Storefronts.CINEMAS`): is each sign on the right street and wall (positions are approximate, snapped to the nearest road and a wall within reach), readable by night? Also: where is Kino Wisła, and should Iluzjon (Narbutta, south of the map) get a pin on the full map? Default built: signs only, real names, no queue, no notebook card.
- **2026-11-02 · landmarks · Plac Bankowy** — Mac look check (the cloud has no photos, LoD2 or terrain): is the Blue Skyscraper's blue right (default #5f94c6 mirror, silver spandrels, cool podium; real photos show sky-blue to steel-blue), is the Treasury palace's yellow right (#e6d8a0 with grey-green roof; real is a pale yellow with white columns), what colour the Voivodeship wing really is (built as palace yellow; OSM says teal), the Arsenal's plaster and roof, Landau's house. Prebuilt path not baked in the cloud (`bake_city` fails on main's known site mismatches); skins use the same landmark outlines on both paths.
- **2026-11-02 · landmarks · Plac Bankowy photo build, Filharmonia, Teatr Polski** — built from the Mac photo reports; guesses to check on the Mac: (1) the Ratusz's colonnades end in an entablature with a lead top, no balustrade or terrace on it (default built; the report does not say); (2) the giant portico's base has five round arches and its attic is plain (built; the report says "pediment-less attic" only); (3) the Bank Polski corner's arches are windows, not open (built as glass); (4) Filharmonia's corner neon is on the Sienkiewicza corner (the map has Sienkiewicza south of the building, the report says north: built at the south-east corner, by the hall's entrance) and has eleven columns (counted from the front's length); (5) Teatr Polski's skin roof is copper green everywhere, the low wings' flat roofs too (default built; the report: "lower flat-roofed wings"); its drums are 2.4 m (the outline's bumps) and reach the cornice.
- **2026-11-02 · landmarks · Gdański Business Center** — Mac look check (site `gbc`, spec `gbc.md`): is this the right complex (tower at Inflancka, 74 m, two 45 m blocks, a 31 m block), the tower crown's slant direction and depth, the blocks' colour (pale blue-green here), logo boxes (AWIWA on the tower, NIELZEN on the blocks; the plaza between them is the map's own, unplanted extras not built). Default built from OSM and the four photos.
- **2026-11-01 · landmarks · Ujazdowski Castle** — Mac look check for Zamek Ujazdowski (`ujazdowski`): the facade's real colour (built cream), the copper roofs and tower caps (spire to 26.5 m), the entrance side (built west, onto the park path), the courtyard (built open; OSM maps an 8.8 m roof patch in it), the east bay. Also the `--prebuilt` look and bench. Built: the model in cream with copper roofs; look shots in the thread. Phone: drive Al. Ujazdowskie south to the castle, stop in its ring for the notebook card.
- **2026-11-01 · driving · Heli camera** — Phone feel check: does the helicopter's camera now turn with it while the stick is held (gain 1.1, as the car's Point), without the held direction circling? Built: camera follows while flying; a held direction keeps the screen it was set against, re-aimed at 20° (like drive_controls.gd). Not run in Godot (none in the cloud).
- **2026-11-01 · visuals · Bulwary life** — Phone look check: do the groups on the boulevard's steps and benches (Karowa to Kopernik, evening) sit where people would, and do the fast cyclists (30-41 km/h) read as fast, not as a glitch? Built: 9 chill spots, 45 % fast riders; default kept.
- **2026-11-01 · visuals · Retro filter** — Phone look check: does the new vaporwave Retro filter (Settings → Obraz, V key; the old VHS tape) read as 80s Miami neon, not muddy, by day and at night? Default built: pink and teal split-tone, soft bloom, light scanlines and grain; the Styl obrazu picker is removed (always Ostry). Where: PR "Rework retro filter".
- **2026-11-01 · landmarks · Grand hotels** — Mac look check for Hotel Bristol (colour of the facade, mansard, door position on Krakowskie Przedmieście) and Hotel Polonia Palace (colour, 25.5 m height, door on Al. Jerozolimskie); built: sand and cream walls, grey slate mansards, door at the middle of the longest street front.

- **2026-11-01 · landmarks · Old Town hotels** — Which tenements are the real Hotel Bellotto (Brukowa 12),
  Castle Inn (Świętojańska 2) and the Rynek aparthotel? Default built: the nearest tenement to each
  address's published spot, parody names KASZTEL INN, CANALETTO, STARÓWKA (`HOTELS` in landmarks.gd,
  `o` and `out` per hotel). Mac look check: is each front on the right house and street face, is
  the neon readable at night. Canaletto's front was not seen in the cloud render.

Newest first. One entry per question.

- **2026-11-01 · landmarks · Mac photo checks: the estate and the stalls** — Built from OSM
  outlines without photos. Check on the Mac: Osiedle Za Żelazną Bramą's real panel colours and
  whether the loggias stack in bays or run in bands (docs/landmarks/specs/zelazna.md), the high
  block (its outline is a wedge), the low pavilions between the slabs, and where the market
  stalls really stand on Plac Mirowski. Also Jana Pawła II's plasters against photos.
- **2026-11-01 · map · Łazienki Królewskie** — The Palace on the Isle (about x 784, z 2101) and the Chopin monument (about x 307, z 2012) are 280-370 m south of the map's edge (z 1736). Default built: the three parks inside the map got their pieces; the `peacock` prop waits. Alternative: extend the map south (map-engineer, Opus), then add the palace, the monument, peacocks and squirrels.
- **2026-11-01 · visuals · parks: Mac look check** — Built in the cloud on flat ground. Please look at the carousel (`--at=-1571,-1475`), the Park Ujazdowski pond with its swans and bridge (`--at=165,1450`), Saski's statues (`--at=-946,-627`): are the pieces' scale and the spots right, do the seated people read on the benches. Default built: as is.
- **2026-11-01 · map · the start area's last two items need the Mac** — R8 and R3 part 2 of
  docs/design/start-area-real.md can't be placed from the cloud (no photos, no orthophoto there).
  R8: from refs/msn/2.jpg and 4.jpg, where the museum's mid-height dark ribbon runs and where it
  breaks on each long face (metres from the north end), and how far and where the roofline steps
  down near the south end. R3 part 2: from the orthophoto, the kerb line and the three new crossings
  on Marszałkowska (Złota and its fountain are now the 2026 linear park, built 2026-11-02).
  Default built: the ribbon all round, the flat roofline, today's kerbs and crossings. A Mac
  session with the photos (model-from-photos skill) can measure and build both.
- **2026-11-05 · landmarks · MDM rework: Mac look check** — Built in the cloud from F's Street
  View shots and Mapillary frames (refs/mdm_ne, refs/mdm_nw), flat ground, no LoD2. Default built
  (`_build_mdm`, spec mdm.md): cream skin, a sand-stone base 11 m high 0.6 m proud on every street
  face, deep arcades only within 80 m of the square's centre, four attic pavilions, roof neons
  MDM (NE block's south end), BYDŁO (east block's roof), XIAOMY (the SE gate block), HOTEL MDM at
  6 m. For F on the Mac: does the base sit right on the LoD2 walls, which facades truly have
  arcades, where the real signs stand, balcony railings, the pavilions' shape; `--prebuilt` too.

- **2026-11-01 · landmarks · church kit and Plac Zamkowy: Mac look check** — Built in the cloud
  from outlines alone (docs/design/churches.md, spec churches.md). Defaults: the front is the
  outline's end nearest a street; towers, caps and colours by a guessed style per church
  (`CHURCHES` in landmarks.gd). Check on the Mac: for each of the 22 kit churches, which end is
  the real front, how many towers and which cap, the plaster or brick colour; fix the entry in
  `CHURCHES` (`out` flips the front, `towers`, `cap`, `wall`, `roof`). Plac Zamkowy: do the new
  gables (stepped, pediment, curved) stand on the right houses' top edges on the real LoD2 walls,
  and do the pastels look right next to the Castle's brick. Phone: frame cost of the Old Town with
  the extra gables.

- **2026-11-01 · gameplay pass · phone checks** — F's six screenshots drive BACKLOG "Gameplay pass" G1-G13. Phone checks: (G1) a fresh save shows HELI at 0:00 and the map hold teleports; (G2) the Low default feels calm and the slider moves it; (G3) the zoom buttons clear the minimap and the pill; (G4) is Cruise easy enough (grip 16, turn pull 10, steer 0.14 s, soft gas; lane change at 50 km/h slides under 1.1 m/s), is Sport still wanted, and do Settings → Jazda → Prowadzenie and the moved Tryb gry (now in Świat) read well; (G5) which wall-like blocks F meant (a photo of one helps). Defaults built: heli and teleport free, Low traffic, Cruise handling.

- **2026-11-01 · gameplay pass · phone checks** — F's six screenshots drive BACKLOG "Gameplay pass" G1-G13. Phone checks: (G1) a fresh save shows HELI at 0:00 and the map hold teleports; (G2) the Low default feels calm and the slider moves it; (G3) the zoom buttons clear the minimap and the pill; (G4) is Cruise easy enough (grip 16, turn pull 10, steer 0.14 s, soft gas; lane change at 50 km/h slides under 1.1 m/s), is Sport still wanted, how the Czułość slider (0.6x to 1.4x turn rate, middle = as is) feels at both ends, and do Settings → Jazda → Prowadzenie and the moved Tryb gry (now in Świat) read well; (G5) which wall-like blocks F meant (a photo of one helps). Defaults built: heli and teleport free, Low traffic, Cruise handling.

- **2026-11-01 · driving · photo mode and POMOC DROGOWA: phone check** — Fixed in the cloud
  (headless check and a game run: the car moved 0.00 m under Fotka; the button towed it onto the
  lane). Default built: the button is the last row of JAZDA's left column, always available on
  the ground (also mid-job or mid-chase; in the water it calls the water tow, in the air it does
  nothing). Phone check: open FOTKA by a wall for a minute and close it, the car stays; press
  POMOC DROGOWA, the card closes and the car is on the road with the "Towed free" toast.

- **2026-11-01 · landmarks · metro entrances: Mac look check** — Built in the cloud (flat
  ground). Default built: `Props.add_metro_entrance` per bake form (`canopy` vaulted glass over
  steel ribs with a red lit fascia, `steps` granite stairwell, `footway` stepped concrete walls),
  treads painted down the dark opening (the terrain has no hole, so the stairs are drawn, not cut),
  a 3.4 m red M post, a glass lift on 3 in 5 (hash of the position, not a real lift list). For F on
  the Mac: do the canopies sit right on slopes, is the red M readable at the default zoom, should
  every canopy have a lift, are the 3 `u` passage-only entrances fine without a canopy.

- **2026-11-01 · map · the land past the map's edge: Mac look check** — Built in the cloud,
  where the ground is flat. Default built (`scripts/map_edge.gd`): bare ground in the city's
  ground colour for the first ~40 m past the outline, then scrub green, fading into the sky's
  colour by 520 m; a tree line 10-70 m out; low blocks (8-30 m, a few to 60 m) 90-400 m out
  with lit windows at night; the rails and the main roads run 320 / 240 m on. On the Mac please
  look at Warszawa Wschodnia (`--at=1950,-1990`) and Dworzec Gdański (`--at=-2009,-2740`) by day
  and night: does the ring meet the real ground without a step or a gap, does the fade read as
  distance (not fog), are the blocks the right scale. Shots of the cloud look are in the PR.

- **2026-11-01 · landmarks · Mariensztat's photo check (M2) and KP's leftovers** — The K1-K6 photo check is done (2026-11-02, from `refs/krakowskie/`, see the entry above). Still open: Prus's and Wyszyński's spots and facings, the Wizytki front, Mariensztat's real reliefs' subjects and places, and the Rynek's well or fountain.
- **2026-11-01 · landmarks · the Old Town Market Square, the Syrenka and the decks: Mac look check**
  Built in the cloud with no photos (free-licence sources are not reachable from there). Default
  built: sand-grey paving with a border band and a pale disc, 58 café umbrellas in nine colours,
  the Syrenka 6.4 m tall (taller than life, to read from the camera) in lit-patina green bronze,
  Varso's deck on the crown's roof (the real deck is glazed, ~230 m) and St Anne's terrace on the
  tower's cornice at 25 m (the real one is higher, ~40 m, above the louvres). On the Mac please
  look at: the paving's colour with the real terrain under it, the umbrellas against the houses'
  plaster colours, the statue's pose (sword hand, shield side, which way she faces), the rim
  wall against the mapped pond, whether Varso's visitors stand on the crown's roof. Photos of
  the square's four sides (one per house front) would let the plaster colours be set per house.
- **2026-11-02 · content · the Zagłębie's names and Femina** — Default to build: KEBAB KRÓL MAZOWSZA, STAMBUŁ 24, DONER PASZA, U WUJKA ERDALA and the craft ZAKWAS I ROŻEN (spec `zaglebie-kebabowe.md`, section 2); Kino Femina keeps its real name with a red KINO / FEMINA fascia on the mapped building. Say if you want other names, or if the real shops' names should show instead. The Mac photo check of Femina's front is parked (BACKLOG).

- **2026-11-01 · content · the Norblin milk bar's name** — Default to build: **KROWA 2.0** (a bar
  mleczny rebuilt as a start-up, sign "BAR MLECZNY / KROWA 2.0", pale-blue tube, open 8-18 with a
  long lunch line). Say if you want another name. Also parked: the Mac look check of the four
  sites (BACKLOG "Norblin, Browary, Koszyki, Elektrownia").

- **2026-11-01 · content · the trains' parody names** — Default to build: KOLEJE MAZOWE (the
  green and white suburban units), SKiM (the red and yellow city line), INTERSZYBKO (the
  long-distance coaches). Say if any should change. docs/design/railway.md section 4.

- **2026-11-01 · store release · the Mac version** — Default: the native Mac App Store version is
  post-v1.0 (after the iPhone demo and TestFlight), on the same App Store Connect record as a
  universal purchase. Two calls for F: (1) say if the Mac should come before v1.0; (2) the iPhone
  build can also be offered on Apple Silicon Macs as it is (Pricing and Availability → "iPhone and
  iPad Apps on Apple Silicon Macs"): keep it on for the beta, or off until the native Mac build?
  Default: decide after trying the first TestFlight build on the Mac. Lane:
  docs/store/mac-and-gamepad.md.
- **2026-11-01 · driving · the gamepad's buttons** — Default built (gamepad.gd): RT gas, LT or B
  brake, Y car / helicopter, A / X the mission card, LB / RB turn the view, Start Settings, Back
  the map, D-pad zoom / radio / flash. Say if any should move once you try a pad.
- **2026-11-01 · content · parody names for the food-hype lore** — Default built: TIMBER (dating
  app, F's pick), Mrożulo (food blogger, F's pick) with his grade MLASK (not the real catchphrase),
  KUKŁA (crêpes), KOSZTA COFFEE, GREEN CAFFE NERWO, HOTEL PIURE with its rooftop bar LORETKA (F's pick), ROBUR on
  Dom Partii's roof, the bars NEWTWICE, ZAMĘT and PRZEGRYWKI (Zagrywki: F asked for it, kept a
  parody), the burger chain WACZEK (an upside-down W; Warsaw calls the real one "Maczek"). Say if any should change (fallback for
  Mrożulo: "Mlaskacz"). docs/design/gaulle-and-food-hype.md section 2.

- **2026-11-01 · visuals · pavement colour** — R3 (docs/design/start-area-real.md) made the mapped
  footways Warsaw's grey concrete pavers. The wide pavements and squares drawn as plaza areas
  stay the warm granite beige the game always had. Default built: grey footways only; since
  2026-11-02 the start box's plazas, paving and bare ground are grey too (first-scene items 4-5).
  Alternatives: grey for every pavement and square (more like the street, less warm), or back to
  beige footways.

- **2026-11-01 · driving · does the vibration feel right on the phones?** — Crash sparks and the
  vibration fix (haptics.gd) were built and checked without a phone. Default built: every buzz at
  least 45 ms at 55 % strength, a crash up to 160 ms at full strength, on by default with the
  DOSTĘP switch to turn it off. Needs a device run on the iPhone (and an Android phone if one is at
  hand): crash into a few cars and walls, take a job; say if it's too weak, too strong or missing,
  and whether the first crash after a pause hitches.
- **2026-10-31 · gameplay · opening flyover** — How long the first launch's camera flight over
  the Palace down to the car should be. Default built: 7.5 s (skippable with a tap), with a
  WARSZAWA caption. Alternatives: 5 s, or 10 s with one more pass (the Eastern Wall and the
  Rotunda). docs/design/opening-flyover.md.
- **2026-10-31 · gameplay · opening flyover** — The guide's beats count from the flight's end, so
  the stand's arrow comes 10 s after you get control (17.5 s after the tap). Default built: that.
  Alternative: the arrow at once after the flight, since the flight already showed the square.
- **2026-10-31 · gameplay · first-10 polish** — Where a new game starts: on Marszałkowska's
  northbound side level with the Museum of Modern Art, facing north to the Świętokrzyska stand
  ~350 m ahead (the Palace on the left). Only a run that gets the guide starts there; the map's
  spawn (southbound by the Rotunda) stays for everything else. Default built: that. Alternative: a
  start nearer the stand (~150 m, DEMO's figure) at the cost of the museum in the first frame.
- **2026-10-31 · gameplay · first-10 polish** — The first mixtape lies on the University Library's
  roof (the roof garden by the boulevards) and gives the next PÓŁNOC FM track, +10 respect. Default
  built: that. Alternative: the Copernicus Science Centre's roof, right on the boulevards.

- **2026-11-01 · landmarks · the Eastern Wall stores' banners and west names** — The photo
  check's optional items: printed ad banners (A4) are built on the faces the game's camera sees
  (each south end and east face, 3 per store; since 2026-11-01 the 2025/26 mix: DO WYNAJĘCIA, FROGS XXL, KAPCIE, SAMSONG, LODY, PROMOCJA, WYPRZEDAŻ), not on the
  street (west) faces where the real ones hang, because the iso camera never sees those. The
  second small name on the west top-storey face (A6) is not built for the same reason. Default
  built: those. Alternatives: no banners, or banners on the west faces too.


- **2026-10-31 · landmarks · University Library (BUW)** — The four philosophers' columns stand
  on Dobra before the copper pages (the orthophoto can't show them; the Mac check kept them).
  The height follows LoD2 since 2026-11-01 (deck 15 m), the roof the orthophoto. Open: the
  south garden's beds are drawn as shrub, heather or lawn by a hash, not plant by plant; the
  four mapped vents at the north corner stand outside the outline as the city's plain drums.
  Default built: those. F to check against a photo or the street (docs/landmarks/buw.md).

- **2026-11-01 · landmarks · Ministerstwo Finansów** — Built from the outline and public facts only
  (no photo): pale pink-grey stone, rusticated ground floor, three storeys of bays, a cornice, a
  central risalit with three doors, hipped roofs on the two south pavilions (the court's fountain is
  the map's own). Mac photo check wanted: the real colour, whether the pavilions and the entrance
  rise above the roofline, the window rhythm and the entrance's column or pilaster count. Default
  built as above (spec docs/landmarks/specs/mf.md).

- **2026-11-01 · landmarks · the Palace's stone colour** — The Mac photo check (PR #128) finds the
  Palace's stone too warm: the photos show a cooler grey-beige (about #cfc6b5 in sun) than the
  game's sandstone #d8c49c (SANDSTONE in landmarks.gd, also the LoD2 bake's colour). Default
  built: the warm sandstone kept (it carries the golden-hour landing shot and the Dusk floodlight).
  Alternative: move SANDSTONE towards #cfc6b5 and re-shoot the landing.

- **2026-11-01 · landmarks · Copernicus Science Centre** — The Mac's photo check is applied
  (copper-red planetarium drum and dome, warm strip facade, craters and paths on the roof, the
  cantilever), and the re-check's roof layout (all seven craters, 2 + 3 + 2 with the stair head)
  and faceted planetarium with its dark clerestory. Still parked: the river corner's glazed
  ground floor (kept as built), the steel frame's stairs. Details:
  docs/landmarks/kopernik.md.

- **2026-10-31 · driving · quest stop assist** — Every pickup and drop-off (rescue, Podwózka,
  kebab and słoiki doors, "Na czasie", the Leżak depot) now has a 9 m ring (was 6-7), counts
  under ~16 km/h as stopped (was 4-9 km/h), and the car brakes itself into the ring when it heads
  in and holds still ~1.5 s; BRAKE at a standstill reverses out. Always on, no setting. Default
  built: that, plus (2026-11-01) a Settings → DOSTĘP switch to turn the auto-brake off (default on).
  Still open: the assist only on touch controls (keyboard players get it too).
- **2026-10-31 · gameplay · the main line** (docs/design/main-line.md) — The main line is the
  guide (first 10 min), then the ladder's next rival (a gold star on the minimap and the full map,
  pinned to the rim at any distance), then the final at night; the respect gates are lowered to
  0/100/220/340/480/640 and 850 (was ... 850 and 1100) so the final comes in about an hour, an
  estimate from the pay tables. Default built: that. To check: F times a fresh save on the phone;
  whether the on-screen edge arrow should also show the star, and whether a short goal line belongs
  on the driving screen (today it is on the full map only). **Default built 2026-11-03**
  (`main_nudge.gd`): both, as a nudge rather than a fixture: the goal line is a toast when the
  step changes, the gold "★ N m" edge arrow shows for 25 s then and after every 150 s of free
  driving, never over another target. Alternatives: the arrow always on while free, or a goal
  chip under the minimap; the timings are for F's run on the phone.

- **2026-10-31 · gameplay · the game map** — Teleport: free and unlimited, by holding a spot for
  0.6 s; refused during a race, a job, a rescue, a police chase and the first-drive guide. The
  districts' and ladder cards now sit behind a ≡ button (hidden when the map opens) so the map
  shows. Default built: those. Alternatives: a price or a cooldown on teleports, only to places
  already discovered, or the cards shown at open.

- **2026-10-31 · gameplay · loop 3h slice 4** — Who gets the guide: a save with no job done, no
  złoty, no rung beaten and the guide not finished; quitting before the first delivery repeats it.
  Default built: that. Alternative: once per install whatever happens.
- **2026-10-31 · gameplay · loop 3h slice 4** — On a fresh save the helicopter waits for the first
  rescue (the HELI chip hidden, H explains), or a helicopter-only call, or 7:00 of play. Old saves
  never see it locked. Default built: that. Alternative: never lock it.
- **2026-10-31 · gameplay · loop 3h slice 4** — Halina's first-race rubber band: pace 1.15 aiming
  25 m behind, ±0.012 a metre, 0.4-1.5, lifting off in her last 140 m for a close player; a player
  150 m behind races her plain. Default built: those (a 1-D model: 34 km/h wins by 2.4 s). F to judge
  on the phone.
- **2026-10-31 · gameplay · loop 3h slice 4** — Halina rolls up 6 s after the first delivery's card
  (or at 3:00 without one), waits 20 s for the flash back, tries 3 times 60 s apart; the finish is
  the Palm unless it is over 1.6 km by road. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 4** — The end card's "10 jobs" are every paid job kind
  (kebab, słoiki, rescue, Podwózka, round-up, "Na czasie") but races and the courier's bonus; old
  saves count from their totals. Default built: that; kept by the designer pass
  (2026-11-01, docs/design/pay-tables.md).
- **2026-10-31 · gameplay · loop 3h slice 4** — In the guide, Mirek's garage waits for 9:30 (and the
  first earnings), then its toast and an arrow; outside the guide it opens at the first earnings as
  before. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 4** — The spawn faces south on Marszałkowska, and the
  Świętokrzyska stand is ~530 m north (behind the car), so 6.2's "ring 150 m ahead" is an arrow at
  0:10. Default built: the arrow. For the first-scene thread: a spawn facing north, or a nearer stand.
- **2026-10-31 · content · loop 3h slice 4** — New words: the guide's toasts (first10.gd LINES),
  Halina's three first-race lines (rivals.gd FIRST_LINES), the ghost finger's hint and the end card
  ("Dzięki za grę! … a Palma… dalej sztuczna."). Default built: mine, reviewed in the designer
  pass of 2026-11-01 (player-neutral Polish, docs/design/pay-tables.md).
- **2026-10-31 · visuals · the dusk loop** — Dusk now matches the user's 16:20 photos: an overcast blue hour (slate-blue sky, flat cool light, no sun shadows, a soft glow) instead of the pink-violet sunset; Dawn, which reuses Dusk's palette, turns blue too. Default built: that. Alternative: keep the pink sunset as Dusk and add the blue hour as a sixth look.
- **2026-10-31 · landmarks · the dusk loop** — The towers' lit names are parodies: PREZYDENT (the Marriott tower's crown), SAMSONG (its band, as on the Spire), NOWOTEL, WESTYNKA, CHILTON, INTERKONTI. Rondo 1's tenants, PHN and the Bank Polski tower got no lit name (not sure which building wears which; no network to check). Default built: that. Alternative: name those too.
- **2026-10-31 · design · the first scene** — Where the game starts (the street the player sees first, to be polished for a "wow"). Default planned: Marszałkowska by Plac Defilad (the Palace, the new Museum of Modern Art, the Eastern Wall, the towers), where the spawn and the first-10-minutes script already are. Alternatives: Plac Zamkowy and the Old Town, Rondo Daszyńskiego's towers, Most Świętokrzyski. Plan: docs/design/first-scene.md.
- **2026-10-31 · design · the first scene** — The light of the first frame. Default planned: day, as decided on 2026-10-28. Alternative: a late-afternoon golden light for the first minutes, once the dusk thread's work lands.
- **2026-10-31 · gameplay · loop 3h slice 3** — "Trzy mosty" is 10.1 km by road (Rondo Daszyńskiego → Most Śląsko-Dąbrowski east → Most Świętokrzyski west → Most Poniatowskiego east → the stadium's south stands); the autopilot needs ~14.5 min of play, a player maybe 7–10. Default built: the full DEMO route. Alternative: a start nearer the river (e.g. Rondo ONZ) or two bridges.
- **2026-10-31 · gameplay · loop 3h slice 3** — Ladder thresholds 0/100/250/400/600/850, the final 1100 respect; race wins +100; the final pays 500 zł + 250 respect (rematches too). Default built: that, numbers for the designer to tune.
- **2026-10-31 · gameplay · loop 3h slice 3** — Rival pace: Halina 1.25, Słoik 1.3, Bartek 1.35, Seba 1.4, Zbyszek 1.45, Mike 1.5 (× the street's limit; was 1.45 for all); Seba in the final 1.45. Default built: those, guesses until F races Halina on the phone.
- **2026-10-31 · gameplay · loop 3h slice 3** — Once the final is open, at night Seba waits at the start held still (so his own rung can't be re-raced at night). Default built: that. Alternative: he cruises and only the marker waits.
- **2026-10-31 · content · loop 3h slice 3** — Six refusal lines (one per rival) and Seba's four final lines (`rivals.gd` RIVALS `refuse`, FINAL_LINES). Default built: mine, reviewed in the designer pass of 2026-11-01.
- **2026-10-31 · gameplay · loop 3h slice 4** — DEMO 6.2's first race: **decided, Pani Halina** (the
  ladder's first rung, stake 60; a win counts as her rung beaten), so Seba stays the boss of the
  final "Trzy mosty". DEMO 6.2's 1:30 row says so. Alternative: a Seba race outside the ladder.
- **2026-10-31 · gameplay · loop 3h slice 2** — The Palace's and the stadium's Syrenki stand 148 m and 211 m from their anchors (no ground street nearer). Default built: that (a 260 m fallback). Alternative: anchor them elsewhere in `syrenki.json`.
- **2026-10-31 · gameplay · loop 3h slice 2** — No hint for the Syrenki (no "?" marks, no minimap dot, no chime); only a cyan diamond over each and "Syrenki n/20" on the full map. Default built: that. Alternative: a chime under ~40 m or a dot once the district is discovered.
- **2026-10-31 · gameplay · loop 3h slice 2** — Rewards: 5 Syrenki open the "Łuska Syreny" paint, 10 give 150 zł and 50 respect, 20 open "Srebro Syreny" and 300 zł; +5 respect a find. Default built: that, numbers for the designer to tune with the ladder.
- **2026-10-31 · content · loop 3h slice 2** — The 20 Syrenki's names and lines (`game/data/syrenki.json`) and their places (one real statue, the Old Town's; the Powiśle statue stays an egg only). Default built: mine, for the designer's review.
- **2026-10-31 · gameplay · loop 3h slice 1** — District list: nine districts (Praga, Stare Miasto, Muranów, Śródmieście, Trakt Królewski, Powiśle, Wola, Śródmieście Południowe, Ujazdów i Łazienki); Śródmieście Południowe is not in DEMO 2.3, Mokotów left out (off the map). Default built: that. Alternative: fold Południe into Śródmieście.
- **2026-10-31 · gameplay · loop 3h slice 1** — District completion counts notebook places too (vision 4.1), plus eggs, Syrenki and jobs up to `jobs_goal` (3 hero, 2 other). Default built: that. Alternative: jobs, eggs and Syrenki only.
- **2026-10-31 · gameplay · loop 3h slice 1** — The starting district is discovered quietly, so its card never shows. Default built: that. Alternative: show it after the first 30 s.
- **2026-10-31 · gameplay · loop 3h slice 1** — +10 respect per discovered district. Default built: that; a guess, for the designer to tune with the ladder.
- **2026-10-31 · gameplay · loop 3h slice 1** — The discovery card reuses the note card (5.5 s). Default built: that. Alternative: a bigger centred card with its own sound (visuals lane, 3i).
- **2026-10-31 · gameplay · loop 3h slice 1** — The Palm (Rondo de Gaulle'a) counts in Śródmieście, not Trakt Królewski. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 1** — A save from a newer version is read but never overwritten, so that session's progress isn't kept. Default built: that. Alternative: write a side file.
- **2026-10-31 · gameplay · loop 3h slice 1** — Map lane ask: places for Ujazdów i Łazienki (it has none, so no "?" there and jobs-only completion) and a baked river line (the Praga line north of Śląsko-Dąbrowski is extrapolated). Default built: as is.
- **2026-10-31 · content · L-shaped map** — The notebook's 9 chapters × 8 cards rule: the new places
  (Rondo Radosława in `kiedys`, Arkadia in `codziennie`, Forest in `bary`) went in as ninth cards, the
  rule is now 8–10 per chapter and a chapter of 9 is drawn 5 × 2. Default built: that. Alternative: a
  10th chapter "Północ · Up north" (the chips row is already tight). The words for the 3 places are
  mine, for the designer's review.
- **2026-10-31 · visuals · L-shaped map** — The off-map tan (#c8b48e) is drawn on the minimap and the
  full map past the bounds as well as over the corner, so the edge reads the same everywhere.
  Default built: that. Alternative: tint only the corner. Wants an art-director look.
- **2026-10-31 · content · L-shaped map** — The streamed and prebuilt paths with the L were not seen
  here (derived index stale; every shot is `--monolithic`). Check on the Mac after
  `tools/setup_map.sh --if-needed`.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Sofitel Victoria is shown as
  **"Hotel Wiktoria"** (Sofitel is a brand). Default built: Hotel Wiktoria, a 30 m slab on an 8 m
  podium (estimated). F can veto the name.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Muzeum Narodowe raised to
  18.5 m wings and a 25 m entrance block (OSM's 4 levels gave 14.2 m). Default built: the new heights
  (estimates). Alternative: back to 14.2/20 m.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Dom bez Kantów's card plays on
  "kant" (an edge, or a swindle): "Kantów tu nie ma." Default built: the pun. The unnamed block
  south-east of Europejski has no card (no name in the data).
- **2026-10-31 · landmarks (content thread) · museum and Plac Piłsudskiego** — Built from mapped
  footprints only, no photos: the museum at the mapped 14.2 m with a 20 m entrance block, the army
  museum's tank and gun in the east courtyard, ~~Hotel Europejski's cornice at 19 m (estimated)~~ (Europejski rebuilt from photos 2026-11-03, cornice 20 m from LoD2). Default
  built: as listed. With F's photos or a quick "taller/shorter" these are a few constants.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego** — Sofitel Victoria (a brand: would
  be "Hotel Victoria") and the Metropolitan's curved fins are not modelled; two black 2.5 m mapped
  boxes stand beside the Tomb. Default built: left as they are.
- **2026-10-31 · content · couriers** — The courier race's pace: the rider's time is the order's
  road distance at 10 m/s, so a player averaging 30–50 km/h wins about 2 in 3. Default built: that.
  Alternative: a fixed speed (e.g. 8.5 m/s), or tune after phone runs.
- **2026-10-31 · content · couriers** — Kerb riders ride 0.45 m from the kerb (parodies.md says 0.6 m;
  at 0.6 m AI cars would clip them). Default built: 0.45 m. Alternative: 0.6 m with AI cars nudging
  past riders (a traffic.gd change).
- **2026-10-31 · content · couriers** — Kerb riders: 3 by day, 5 at night, on top of the 4/6 path
  riders, all in the pool of 16. Default built: that. Alternative: read "3–6" as the total.
- **2026-10-31 · content · garage** — When does Mirek's garage open? Default built: after the first
  earnings (a job, any złoty, or an owned paint), not the 10:00 clock beat.
- **2026-10-31 · content · garage** — Prices: cream 150, pea green 180, Vistula blue 200, tram
  yellow 250, black 300, doughnut pink 350 zł; factory red free; Mermaid gold free at 5 eggs found.
  Default built: as listed (a guess to tune).
- **2026-10-31 · content · garage** — Black at night reads as a dark teal slate with silver stripes
  (a stronger glow so it doesn't vanish). Default built: that. Art director / visuals to judge.
- **2026-10-31 · content · garage** — The garage is on Brzeska (narrow, one-way; the ring fills the
  street). Default built: Brzeska. Alternative: a wider kerb on Ząbkowska or Targowa.
- **2026-10-31 · content · garage** — Mirek's 12 lines (dialogue group `garage`) were written in this
  loop. Default built: as written, for the designer's review.
- **2026-10-31 · content · vintage tram** — Without Live the clock's looks are always Friday, so the
  vintage tram (weekends 09:00–19:00) almost never runs and E39 is hard to find. Default built: the
  game's weekend only. Alternative: one run an hour in the Day look whatever the day.
- **2026-10-31 · content · vintage tram** — Hours and pace are guesses. Default built: 09:00–19:00,
  one 25-minute run an hour, 29 km/h (modern trams 40).
- **2026-10-31 · content · vintage tram** — E39 gives +30 and its line; the then card T13 waits for
  the older decades (F's "from 2010"). Default built: no card.
- **2026-10-31 · content · night buses** — The horn's key is **B**, because H already toggles the
  helicopter. Default built: B.
- **2026-10-31 · content · night buses** — The horn button's icon (a bell with sound arcs) reads like
  a volume button. Default built: the icon, no label. Alternatives: a "KLAKSON" label or a trumpet icon.
- **2026-10-31 · content · night buses** — E25's race against the night bus starts quietly. Default
  built: no card. Alternative: a "WYŚCIG Z NOCNYM · RACE THE NIGHT BUS" pill.
- **2026-10-31 · content · night buses** — A stop's random bubble can say the request line ("Żądam.")
  without a honk. Default built: left random. Alternative: keep that line for E24 only.

- **2026-10-31 · content · jobs-2 (courier race, round-up, payphone, armchair)** — The Leżak
  round-up follows parodies.md 5.3 (collect into the boot, unload at the depot), not pushing
  scooters with the car. Default built: the spec.
- **2026-10-31 · content · jobs-2** — Pędzik rides at 6.5 m/s and rarely beats a player; tune
  with `--courier-v=` on the phone. The race's gap reads high at the start when the order's
  lane is the far carriageway (jobs.gd's order picker, BACKLOG). Default built: 6.5 m/s.
- **2026-10-31 · content · jobs-2** — E40's card shows T17's line (+10) rather than adding a
  21st KASETA then card (that set is 2010–today). Default built: as said.
- **2026-10-31 · content · jobs-2** — The payphone (a small grey post by the bus shelter at Plac
  Konstytucji) and the armchair man (rust shirt, teal chair, Mokotowska, 1 day in 3, 08–20) are
  hard to spot in shots; art-director pass and a phone look. Default built: as made.

- **2026-10-30 · content · MW-2 (storefronts and parodies)** — The Frogs stamp card reaches 8 m
  from the door (parodies.md says 6 m), and 15 % of Podwózka passengers are `detour` (ask for a
  Frogs). Default built: 8 m, 15 %.
- **2026-10-30 · content · MW-2** — Pędzik couriers have their own MultiMesh (+1 draw call in view)
  rather than sharing the bikes'. The courier race and the Leżak round-up job aren't built (not
  cheap; BACKLOG). Default built: as said.
- **2026-10-30 · content · MW-2** — Billboards are text only until PixelLab pictograms can be
  made; the metro sign is a generic cream M on navy (no operator logo). Default built: as said.
- **2026-10-30 · content · MW-2** — `easter_lezak`'s English is trimmed to fit 70 characters: "A
  Leżak standing up. In its own zone. Someone should report this." Default built: trimmed.
- **2026-10-30 · map · MW-2's asks** — The bake should add `shop=convenience`,
  `railway=subway_entrance`, `amenity=bicycle_rental` and scooter-zone pois, and an address for
  Kruczkowskiego 3B; the shops find their walls at runtime today. Default: runtime placement.

- **2026-10-30 · content · F's asks** — LEVEL 26 costs +2 draw calls at night in view (the
  violet band and the crowd cell with the roof crowd and the door queue) against a +1 target.
  Default built: both kept; 0 by day and beyond 350 m.
- **2026-10-30 · content · F's asks** — With the pedestrian slow zones off (the new default),
  should the guards still whistle as flavour? Default built: no whistle, run or guards' car; the
  clamp stays.
- **2026-10-30 · content · F's asks** — The full map shows "?" marks only within 400 m of the
  car (the minimap's rule) so it doesn't spoil the notebook. Default built: 400 m.
- **2026-10-30 · content · F's asks** — The shop sign: "FROGS" with the blade disc keeping
  "24", or "Frogs 24" as the name? Default built: Frogs, the disc says 24.
- **2026-10-30 · store release · Android back** — `quit_on_go_back` is Godot's default (true):
  the back gesture may quit the app instead of closing the full map. Check on an Android phone.
  Default built: unchanged.
- **2026-10-30 · performance · full map** — The 3D city still renders under the open full map
  (paused). Stop it while the map is open? Default built: not done.

- **2026-10-30 · content · MW-4 (everyday life and trends)** — How often does a trend move
  without Live? Vision says every third session. Default built: every 4 sessions. Live counts
  8-day cycles from 2026-01-05 rather than the ISO week.
- **2026-10-30 · content · MW-4** — E28 is built as "follow a Rowerilo rider 400 m" (vision: "to
  a dock"). The "Na czasie" job pays 51 zł on time, 21 late, no tip on days 6–7; the offer shows
  within 60 m of a slot, then waits 240 s. Default built: as said.
- **2026-10-30 · content · MW-4** — Kolka and Hyrax show only in Live (or `--zajac`), plus Hyrax
  in the fixed Day look before noon. Dogs are drawn 1.35× so they read. Default built: as said.
- **2026-10-30 · content · MW-4** — The player has no horn signal (car.gd, driving lane), so the
  AI cars' horns make the dogs bark for now. Default built: AI horns.
- **2026-10-30 · content · MW-4** — Cost cut: movers within 15 m of the car step at full rate
  (was 30 m); off-screen ones at 3.75 Hz. Default built: as said.

- **2026-10-30 · content · Podwózka's name** — F is thinking of renaming Podwózka (the lift
  app) to something like "zUber". Take: a near-Uber name carries trademark risk (the rule is
  parodies that don't lean on a real name or logo), and Podwózka already reads as a joke in
  Polish. Options: keep Podwózka / **Hopka** ("hop in") / **Wiozę** ("I'm driving you") /
  **Szofer** / "zUber" anyway. Default built: Podwózka, nothing renamed until F picks.

- **2026-10-30 · content · MW-3 (night and river crowds)** — A real sitting pose? Sitters are
  squashed standing figures; a real pose needs `actor.gdshader` work (visuals lane) or a second
  mesh (+1 draw call). Default built: squashed.
- **2026-10-30 · content · MW-3** — Guessed curves: Plan C's hours, the dawn curve (20 at the
  window's edges, 40 at 06–07), weekday factors, the guitarist 16:00–01:00, rain 0.1. Tune by eye
  on the phone. Default built: as listed in DEVELOPMENT "The night and the river".
- **2026-10-30 · content · MW-6 (eggs, KASETA, Spacer, Fotka)** — Words written in this loop
  need a designer pass: egg lines vision doesn't quote, the English egg names, and the 15 Kadr
  photo spots (`game/data/eggs.json`, `kadr.json`). Default built: as written.
- **2026-10-30 · content · MW-6** — The KASETA ghost is faint (dithered, reusing the building
  shader) and dim at night. Brighter needs a visuals-lane shader uniform. Default built: faint.
- **2026-10-31 · map · loading fix** — Far-target looks: the camera's look at a new target waits
  up to 1.5 s for its sectors, and on the iPhone 11 a few city-coloured proxies still flash past in
  flight (25 frames over 6 looks). Alternatives (camera lane): cut instead of flying for targets past
  ~1.5 km, or a shorter look; or 28 map slots (+5 MB). Default built: the 1.5 s wait.
- **2026-10-31 · map · loading fix** — "Tap to drive" waits for the start's sectors (870 ms on the
  iPhone 11, at most 8 s). Default built: on (the old way showed far-tower proxies at the start).
- **2026-10-31 · map · loading fix** — Jumps (tow, race start) load the view's sectors at once:
  1-2 extra frames over 33 ms per cut, instead of 0.5-1 s of proxies at the new place. Default built: at once.
- **2026-10-31 · map · content POIs** — Place addresses OSM has on non-home buildings (11, Kruczkowskiego
  3B among them) are baked as `address` pois with `v` = 1, so places and venues find them with no
  code change, but the job shuffles move (the kebab run's first order changed). Or a separate kind
  that leaves jobs as they were? Default built: `address` + `v`.
- **2026-10-31 · map · content POIs** — Leżak zones: "one per ~400 m" read as at least 400 m apart
  (56 zones), not one per 400 m of street (several hundred). Default built: 56.
- **2026-10-31 · map · content POIs** — Leżak density: parodies.md's guess of 30 / 12 per km²
  (468 scooters; about 3 per 300 m square, sparse at street scale). Default built: the guess.
- **2026-10-31 · map · content POIs** — Corner shops store no names, only `fr` for the chain the
  Frogs parody; or a parody-name field per chain? Default built: `fr` only.
- **2026-10-31 · map · map north** — Shape of the growth: only the west side of the north edge
  (an L, 1.04 km²), or the whole north strip (~3.9 km², Praga north and Dworzec Gdański too)?
  Default built: the L.
- **2026-10-31 · map · map north** — North edge at 52.2591 cuts the Jana Pawła II and Andersa
  viaducts; taking them in whole needs a new OSM, orthophoto and tree fetch past 52.2595.
  Default built: cut at 52.2591.
- **2026-10-31 · map · map north** — Looser LoD2 match: footprint share 50 % (8 models kept), or
  30 % (27 models, 44 blocks)? Default built: 50 %.
- **2026-10-31 · map · map north** — Outdated 2018 LoD2 models under much taller mapped buildings
  give way to OSM map-wide (46 models, mostly Wola: low sheds become the mapped towers as plain
  blocks), or only in the new area? Default built: map-wide.
- **2026-10-31 · map · map north** — Arkadia's roof car park: ~~left out of the bake~~ modelled 2026-11-01 as parked-car boxes on the deck (no ramps, no drivable deck); DEMO 6.4's car-park race would still need a drivable deck. Default built: static cars.
- **2026-11-01 · landmarks · Arkadia** — Mac photo check: Arkadia's real facade colours (cream/terracotta is a guess), whether the roof skylights are pyramids, where the real entrances are (canopies sit on the three longest faces). Default built: that. (The Forest was rebuilt from F's photos on 2026-11-03, see below.)
- **2026-10-31 · map · map north** — The flag mast on Rondo Radosława isn't in OSM: no placeholder,
  left to the landmarks lane (spot in DEMO.md 2.1). Default built: none.
- **2026-10-31 · map · 3e** — Ground under trenches: 1 m sub-cells only at tunnel portals and
  road cuttings (keeps the +1 % vertex budget), or a new builder feature that cuts the ground along
  a lowered corridor and draws the floor as one strip (would also fix the rail cutting and ~40 more
  findings for a few vertices per cell)? Default built: sub-cells; the strip is a follow-up loop.
- **2026-10-31 · map · 3e** — check_drive now drives all 98 structure routes (~2 s more), which
  surfaced allowlisted jumps at Poniatowski deck 13, Łazienkowski deck 20 and Towarowa. Default
  built: keep 98 routes (the alternative was back to 20, hiding them).
- **2026-10-31 · map · 3e** — Plac Na Rozdrożu's tube ends stop a few metres short of the street
  over them: extend a tunnel under any way crossing its open road within 15 m of the portal?
  Default built: OSM geometry kept, allowlisted with its cause.
- **2026-10-31 · map · 3e** — Portal headwalls are plain concrete; the new tall W-Z east headwall
  reads as a dark slab at night. An art pass on portal frames (lining, lamps)? Default: none
  until the art director picks it up.
- **2026-10-31 · map · 3e** — Parked cars at `PARKED_FILL` 0.27 (14,637 → 4,927) as asked. If
  it now looks too empty, it's one constant in `bake_osm.py`. Default built: 0.27.
- **2026-10-30 · map · 3d-2b** — A far level by zoom: draw the helicopter's highest views (above
  ~200 m) as painted proxies? Over the centre ~357 draw calls would drop to a few dozen, but those
  views lose their 3D detail. Default built: no far level, full detail everywhere (the orthographic
  camera shows no proxies today). Where: BACKLOG "From loop 3d-2b".
- **2026-10-30 · map · 3d-2b** — Map slots for the per-sector AO/light maps: keep 24 (32 MB) or
  raise to 28–32 for headroom (+5–11 MB)? The 3-minute soak reached 24 with no waits. Default: 24.
- **2026-10-30 · map · 3d-2b** — check_streaming's spot 8 limit (1 %): lower it now that it
  measures 0.015 %? Default: leave it until more runs agree.
- **2026-10-30 · map · 3d-2b** — Landmarks in the proxies need a LOD1 model from `landmarks.gd`
  (landmarks lane). Default: none until round 3f's landmark factory.
- **2026-10-30 · map · 3d-2a** — Clean the terrain at bake time (snap near-flat 20 m blocks within
  15 cm) so flat ground can merge into bigger quads? It would let ~47 % of cells merge but moves
  driving heights by up to 15 cm and needs a full re-bake. Options: snap / keep exact heights.
  Default built: keep exact heights. Where: BACKLOG "From loop 3d-2a".
- **2026-10-30 · map · 3d-2a** — Cut the ground along road edges (with skirts) rather than only
  dropping 10 m triangles fully under a cover? Default built: only whole covered triangles go;
  the full cut waits for a phone Metal trace showing ground fill under streets costs something.
- **2026-10-30 · map · 3d-2a** — Next flat-mesh target: footways (1.88 M vertices), grass (1.39 M),
  roads (1.21 M), kerbs (0.80 M). Default: footways first, after 3d-2b.

- **2026-10-30 · content · MW-5 (PÓŁNOC FM)** — Listen to the 7 new tracks (attached in the
  thread, or `--unlock=all --station=polnoc`): mood, balance, does the bass reach the phone's
  speaker? They're 22 kHz, 40 kbps to stay under 4 MB; raise it if you hear artifacts.
  Default built: as made.
- **2026-10-30 · content · MW-5** — New words for a designer pass: the day caption "powtórka ·
  rerun · the host is back at 22:00" and the unlock toast "Kuba ma nową płytę: „…”".
  Default built: as written.

- **2026-10-30 · content · 3g-2 (police, part two)** — Rescue escort: how often after the first
  rescue, and how fast? Default built: the first rescue always, then one in two; 45 km/h, 15–25 m
  ahead. Tell back after a phone run.
- **2026-10-30 · content · 3g-2** — The pedestrian-zone cap only cuts the gas: a car entering
  faster coasts down to 20 km/h. Brake it harder? Default built: coast down.
- **2026-10-30 · content · 3g-2** — The clamp card reads BLOKADA NA KOLE · ZDEJMUJĘ ZA 0:10 /
  WHEEL CLAMP ON · OFF IN 0:10. Wording for a game-designer pass? Default built: as written.

- **2026-10-30 · landing · beta form** — The aroundwarsaw.app sign-up form still posts to
  Stillplace's Formspree form (`mykaeqjp`), so beta sign-ups land in that inbox. Make a form
  for Around Warsaw on your Formspree account (free) and send its id, or keep the shared one?
  Default built: shared form, nothing changed. The id is one string in `site/src/index.html`
  (and the Polish page); then a redeploy. Where: BACKLOG "From the website".
- **2026-10-30 · performance · phone runs** — May I run the bench and a streaming soak on the
  iPhone 11 (a test build through Remote Control)? The Mac work is done (PR #27 memory −20 MB,
  #33 traffic, #35 bench result); what's left needs the phone: static memory on the iPhone 11
  (BENCH's memory line, before the beta), and whether a sector's load still makes a 25–65 ms
  frame there. Default built: nothing run on the phone. Where: BACKLOG "From the performance
  baseline", "From loop G0+".
- **2026-10-30 · landmarks/models · landmark models** — Do the towers now read as the real
  ones? Look at the before/after shots in the PR. Default built: 18 towers in their own skins
  and colours, Złote Tarasy golden, Muzeum Narodowe in stone, new bus shelters. Say which
  still look wrong and how. Where: PR (landmark models).
- **2026-10-30 · landmarks/models** — ~~Złota 44's top is cut on a slope, high at its north end.~~
  Answered by F's photos (2026-11-02): the tip is the south-east corner; rebuilt that way.
- **2026-11-02 · landmarks/Złota 44 · Mac photo check** — The tower was rebuilt from F's two
  photos (spec `docs/landmarks/specs/zlota44.md`). On the Mac, put Commons photos beside the
  game: is the crown box (184 m, from 45 % of the roof slope, 4.5 m back from the east face) the
  right size, does the wing lean the right amount (9 m at the top, the waist at 64 m), and is
  the podium garden on the right block? Default built: as the spec says.
- **2026-10-30 · web · deploy** — May I deploy the web build? It creates the Worker
  `aroundwarsaw-play` with the custom domain play.aroundwarsaw.app (a new DNS record in the
  aroundwarsaw.app zone) and uploads build/web (~141 MB), then redeploys the landing so the
  "Play online" button and the /play/ redirect go live. Both are public; `wrangler rollback` and
  deleting the Worker undo them. Default built: everything ready and tried locally; nothing
  deployed. Where: docs/DEVELOPMENT.md "The web build".
- **2026-10-30 · content · MW-1** — The chapter-complete card reads ROZDZIAŁ GOTOWY · CHAPTER
  DONE with "+50 zł, +30 ★". Wording for a game-designer pass? Default built: as written.
- **2026-10-30 · store release · app IDs** — The iOS bundle ID is still
  `com.olshanskysoft.nocnawarszawa`. Change it to `com.olshanskysoft.aroundwarsaw` before the
  App Store Connect record exists, or keep it? Nobody ever sees it (the home-screen and store
  name is "Around Warsaw" on both platforms). The Android package can't change: Play has had
  version code 1 under `com.olshanskysoft.nocnawarszawa` since October, and a new package
  would be a new app. Options: keep (both platforms match) / change iOS only. Default built:
  keep, as the rename of 2026-10-30 decided. **Answered 2026-10-31 by the user: change iOS only; done in `game/export_presets.cfg`** (Android stays). Where: `game/export_presets.cfg`, ROADMAP
  "rename + open source".

- **2026-10-30 · store release · store listings** — Ship the iOS app for iPhone and iPad, or
  iPhone only? Once an iPad version is on the App Store, later versions can't drop iPad.
  Options: iPhone and iPad (needs an iPad device pass) / iPhone only. Default built: nothing
  changed (the preset still says iPhone and iPad, which is fine for TestFlight; iPad
  screenshots are rendered). Decide before the first App Store release. Where:
  docs/store/app-store-connect.md section 10.
- **2026-10-30 · store release · store listings** — Account steps only you can do: create the
  App Store Connect app record and the Play listing from docs/store/, pick the support email
  (not written in the public repo), upload the first builds, invite testers. And a yes to
  redeploy aroundwarsaw.app so `/support/` goes live (the store forms link to it). Default
  built: everything written; nothing submitted.
- **2026-10-30 · visuals · night water (PR #11)** — Is the river's new night sheen right on the
  phone's OLED: too faint, right, too strong? Options: keep / stronger / fainter. Default built: the
  faint version (`ground.gdshader`, the `0.16 * broad` and `0.1` shore terms).

<!--
- **2026-10-30 · HUD · radio skip** — On the phone, holding RADIO for 0.5 s skips to the
  station's next track; a tap changes the station as before. Nothing on screen tells the
  player about the hold. Options: A: leave it hidden / B: a one-time hint on the ticker
  ("przytrzymaj RADIO: następny utwór · hold RADIO: next track") / C: a separate ⏭ button.
  Default built: A (the ticker shows the new track's name, so a skip explains itself).
- **2026-10-30 · HUD · fallback toast** — The first launch at Auto's coarser picture (after a
  session that struggled at the sharp one) now shows once: "Obraz prostszy, żeby było płynnie ·
  A coarser picture for a smoother ride · Settings → Obraz". It doesn't mention heat, because
  the struggle is measured frame time, not temperature. Options: A: as built / B: the backlog's
  "Obraz prostszy, bo telefon się grzał · the phone was struggling" / C: no toast. Default built: A.
- **2026-10-30 · performance · compressed map textures** — May I run one bench on the iPhone
  with the AO and lamp-light maps VRAM-compressed (BACKLOG "Memory still on the table")? On the
  Mac they look the same and textures drop 42 MB, but video memory rises 23 MB from a one-time
  allocation; only the phone shows which way it goes there. Options: A: one device bench, before
  and after / B: drop it. Default built: nothing landed (the code waits on its branch).
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->
- ~~**2026-11-02 · landmarks · Hotel Warszawa**~~ — Built from `refs/hotel_warszawa/` on the Mac (Commons photos, the ortho, REPORT.md) and LoD2 (spec `hotel_warszawa.md`). Look check on the Mac or the phone against the photos: the hotel's front read as facing east onto the square (the portal on that side). Default built as listed. (Cedet, asked in the same entry, is answered below.)
  **Answered 2026-11-03 (F's look check):** the portal faces east onto Plac Powstańców; the stepped tower reads as the hotel; the wings now share one stone base with the shaft, the portal is refined and both cornices project further. Applied (look-check fixes PR).

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.

- ~~**2026-11-02 · landmarks · Royal Castle pass 2 and the gardens** (spec `docs/landmarks/specs/zamek.md`, refs in `refs/zamek/` on the Mac) — Mac look check with LoD2 and the real terrain: does LoD2's own Clock Tower or turret top poke through the new copper helms; is there a salmon band between the cream Vistula front's cornice (17 m over the courtyard) and the roof; do the arcades' top and gravel walk meet the terrace, and do the tubs and the Upper Garden fountain stand on it; which way the tower's gate faces and whether it has four dials. Built default: tower gate on the square side, dials on all four faces, turrets to 31 m.~~
  **Answered 2026-11-03 (F, landmark look check, `/mnt/project-files/look-check-answers.md`):** the Clock Gate faces west toward Plac Zamkowy and the tower has four clock faces (both kept as built); the game showed a salmon section above the pale river front where it meets the roof, and the copper helms were to be checked in a close unlit render for grey tower geometry. Fixed: LoD2's steep roof slopes take the roof tile, its walls along the river front the front's cream, and LoD2's Clock Tower is cut under the model's cornice (it stood 3.5 m past it, with its helm as a salmon mass to 46.7 m, out of the copper helm on every side); the turret caps were clean. The arcades and tubs on the real terrain were not part of the answer: BACKLOG Z1.
- **2026-11-03 · landmarks · Most Poniatowskiego's Powiśle viaduct and north stairs** — ~~Built from the report's viaduct section (photos 17, 19, 20, 32 are on the Mac only, so the cloud had the text, not the pictures) and OpenStreetMap: the arcade along both edges with pilasters every ~19 m placed clear of every street and footway under it, big arches over Kruczkowskiego (24 m), Solec (50 m) and Wybrzeże (43-57 m) between the mapped pier buildings, ribbed spandrels, light grey #b8b6b0; the north groups' switchback stairs on the mapped walls (flight, half-round turn, flight back), with lanterns. Open: (1) how many arches does the real viaduct have and are they open or filled with shops (default: open arches, the Arkada and the mapped buildings show through); (2) on Al. 3 Maja (s 296-430) the street runs under the deck's south edge, so the arcade stands back under the deck there: right?; (3) the stairs' look (turn direction, parapet height). A look on the Mac or the phone, or photo 17/19/32 described, settles it. Default built: as above.~~
  **Answered 2026-11-03 (F):** 27 arched spans plus four spans supported differently (engineering study of the
  viaduct, OPK 1/22), in two rows of reinforced-concrete arches under a steel deck (Biliszczuk, Dni Betonu 2016);
  both open and enclosed: photo 19 shows open ribs with exposed struts up to the steel deck, photo 17 bays closed
  with walls, doors and windows. "The bigger fix is the profile." And: put bars there, "a lot of gastronomy, the
  K-bar and others". Rebuilt that way (open ribs, struts, steel girder; infill only in the closed bays; parody bars).
- **2026-11-02 · landmarks · Cedet** — ~~Krucza corner radius (5 m built), the east end (4 m built),
  the pavilion and wings, the storey height (4.6 m built), the loop's day colour (steel blue built)?~~
  **Answered 2026-11-03 (F, landmark look check):** "Use 10–12 m as the working Krucza radius. The east end
  also looks softened in the front photo, but its radius is unclear. Aim for 3.7 m glazed storeys, with a
  taller ground floor and a recessed roof pavilion. Use muted metallic grey-bronze for the loop. Restore the
  two upswept roof wings and their underside shadows first." Built 2026-11-03: r 11 m, the east end kept at
  4 m, 5 x 3.7 m storeys over a 6.7 m ground floor (meets the LoD2 eave, 26.7 m), the pavilion 2 m back under
  its plate, curved wings with dark undersides and shadows on the deck, a grey-bronze loop (blue neon at night).
- **2026-10-30 · content · MW-3** — Queues stand at the place's point and the nearest footway
  until MW-2's storefronts exist; Smoła's queue lands in a passage hidden by a block from
  `--club=smola`. Default built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-3** — Night buses (E23, E25) need a small bus API in `traffic.gd`
  (driving lane), e.g. `spawn_bus(route, sign)`. Default built: not built, BACKLOG.
  **Answered 2026-10-30 (F):** not built, BACKLOG (kept).
- **2026-10-30 · content · MW-3** — Dawn is the last entry of Settings → TIME (so saved settings
  keep their meaning); E15's "three different days" uses the real date without Live. Default
  built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — E31's reward was track 2, which is free from the start: it
  opens the next locked track instead. The 5 old eggs now pay +10 respect each. Default built:
  as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — Spacer (wander mode) is a row in Settings → JAZDA, offered
  once by a toast; FOTKA is a button in Settings → OBRAZ. Default built: there.
  **Answered 2026-10-30 (F):** there (kept).
- **2026-10-30 · content · MW-5** — Chapters 1–5 unlock tracks 3–7; chapters 6–9 unlock nothing
  yet (vision: a horn tune and the gold cover later). Default built: as said; BACKLOG.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-5** — Until you pick a station, the radio follows the clock:
  PÓŁNOC FM at night, KEBAB FM otherwise. Keep, or switch only at launch? Default built: follow.
  **Answered 2026-10-30 (F):** follow the clock (kept).
- **2026-10-30 · content · 3g-2** — Stopping by a guard ends in a caution in the joke notebook.
  The routine first contact takes no Podwózka star. Keep both? Default built: as said.
  **Answered 2026-10-30 (F):** kept. F is also thinking of renaming Podwózka (e.g. "zUber"): parked as its own question above.
- **2026-10-30 · landmarks/models** — Hotel towers are named by address, not brand (rule:
  brands only as parodies): the InterContinental's card says "Emilii Plater 49", the Hilton's
  "Grzybowska 63", the Westin's "Jana Pawła II 21", the Novotel's "Marszałkowska 94/98".
  Default built: as said. Options: keep /
  parody names for the hotels.
  **Answered 2026-10-30 (F):** **parody names** for the hotel towers, not addresses (changed; landmarks lane's item).
- **2026-10-30 · content · MW-1 (the notebook)** — The minimap shows "?" for undiscovered
  places within 400 m of the car, because districts don't exist yet. Switch to "in a discovered
  district" once DEMO 6.3's districts land? Default built: 400 m.
  **Answered 2026-10-30 (F):** 400 m kept. F also wants the minimap to open full screen: BACKLOG "From loop MW-1" (HUD item).
- **2026-10-30 · content · MW-1** — Venue cards hide the street address (a venue's real address
  can name the real club, e.g. "Jasna 1" is on the denylist). Add a designer-written "safe to
  show" address per place? Default built: no address on venue cards.
  **Answered 2026-10-30 (F):** no address (kept).
- **2026-10-30 · content · MW-1** — The settings tab is ZESZYT · notebook, and the card's title
  becomes MOJA WARSZAWA on that tab (the full name doesn't fit as a fifth tab on the iPhone SE).
  Keep? Default built: ZESZYT.
  **Answered 2026-10-30 (F):** ZESZYT kept (it means "notebook").
- **2026-10-30 · content · MW-1** — Stadion Narodowy (115 m from any road) and Most
  Śląsko-Dąbrowski (65 m) can't be found by car with today's anchors: wider radius, or wait for
  the map lane's bake resolution? Default built: nothing changed; BACKLOG "From loop MW-1".
  **Answered 2026-10-30 (F):** wait for the map lane's bake (kept).
- **2026-10-30 · content · MW-0 (Moja Warszawa data)** — Where is the real "Apteka" bar you
  meant? Options: name the street / keep the default. Default built: APTECZKA in a Nowy Świat
  22/28 courtyard pavilion, marked `guess` in `game/data/places.json`. If the "Apteka" came from
  the song with "apteką" in its title, say so and it gets an invented name instead. Where: PR (MW-0).
  **Answered 2026-10-30 (F):** APTECZKA in the Nowy Świat courtyard (kept).
- **2026-10-30 · content · MW-0** — The then-and-now cards start in 2010 (the demo's "time
  tape"), so vision.md's 2009 blue hall and the 1990s items wait for later. Allow the blue hall
  as an exception? Default built: 20 cards from 2010 to 2024 (`game/data/then_cards.json`).
  **Answered 2026-10-30 (F):** from 2010, no blue-hall exception (kept).
- **2026-10-30 · content · MW-0** — Historic hall names "Hala Koszyki" and "Hala Gwardii" are
  kept as place names (they are also the halls' trade names); the new tower and museum are
  never named. Rename the halls descriptively ("Hala na Koszykowej")? Default built: kept.
  **Answered 2026-10-30 (F):** kept.
- **2026-11-02 · gameplay · G12** — Rescues are on the HELI line in the spec, but most calls are street/park rescues the ambulance car does well. Default built: rescue calls follow the vehicle (flying: roof/sandbar, driving: street/park/shore, heli-only ones in violet); the full map's ZADANIA card lists them since 2026-11-02 (G12 part 2). Make every rescue heli-only and give the car only jobs? Default built: no.
- **2026-11-02 · gameplay · G12b** — On the full map's ZADANIA card the pad takes the picked row with Y, because A is the teleport hold. Default built: X tab, D-pad pick, Y take. Alternative: a short A press takes the row and only a held A teleports.
- **2026-11-02 · gameplay · G10** — START KURS appears within 25 m of the waiting passenger and boards at once (the car is not auto-braked). Phone check: is a tap enough, or should driving through the ring start it too?
- **2026-11-02 · landmarks · Warsaw Spire** — Rebuilt from F's three photos and the map alone, so these are guesses to check on the Mac: (1) which rim the roof fin stands on (built: the east rim, peaking over the north half); (2) the entrance side (built: north, towards the plaza between the wings); (3) the canopy's size and the V legs' spread; (4) how much narrower the lobby is (built: 0.74 of the roof plan); (5) the wings' colour and top storey. Default built: that. Alternative: move the fin or canopy to the side the photos show.

- Mac look check (food-hype leftovers, 2026-11-02): the five fans stand behind Mrożulo's van along
  its local -Z; confirm they are on the pavement, not the road, at the four van spots; and the
  egg `easter_mlask` wording. Default built: as is.

- **2026-11-02 · landmarks · Dobra and Tamka tenements** — Dressed from OSM and LoD2 alone (no photo): plasters from a sooty pastel palette, a two-step cornice, a first-floor string course and shop-glass bays with a fascia on street-facing walls (spec docs/landmarks/specs/dobra_tamka.md). Mac photo check wanted: the real plasters, which houses are really shops, where houses are missing or rebuilt. Default built: those. Alternative: plaster only, no shop fronts.
- **2026-11-06 · landmarks · Staszic Palace and Świętokrzyski bridge (batch 3)** — Photo reports (`docs/landmarks/photo-reports/staszic.md`, `swietokrzyski.md`) say the Staszic front is a rusticated arcade with an avant-corps and a shallow green dome (no 4-column portico), and that Copernicus stands about 75 m from where the model puts him, on a round brick plaza at about (-413, -466); the ortho suggests the front facing the statue may not be the straight run the model uses. Default built: only the colours (cream wall, green copper roof). Needs an in-game orientation check before moving the front or the statue. Bridge: the pylon should be an A-frame (two legs 26 m apart along the deck, joined about 80 m up, foot near (747, -915)) with a denser stay fan; default left as the single leaning shaft.
