# Rondo de Gaulle'a, Dom Partii and the food-hype lore

F's ask (2026-11-01, three photos: the de Gaulle statue from the south, the Party House's corner
with QUERCUS on top, an aerial of the block with its courtyard and bars): the de Gaulle statue on
the roundabout; the Party House with its inner square and bars; the Loreta bar and its hotel as the
bar where dating-app dates go; a dating-app parody ("Timber") with jokes about dating in Warsaw;
coffee chains as parodies (Costa, Green Caffè Nero); queues at Manekin and other hyped cafés,
because Warsaw loves to queue; a food blogger parody, **Mrożulo** (for Książulo), whose review
makes the queues, with a mission (order at a new place, bring it to him, he reviews it in his way
and gives you his sticker to hand to the café) and his pizza lore.

Rules that hold for all of it (warsaw-tone): real places by name, real businesses, brands and
people never (only our parodies, in `brand_denylist.json` so the checks fail if one slips through);
affectionate, the joke is the hype and the queue, never the people. No catchphrase is copied:
Książulo's "muala" becomes our own sound **MLASK** (a lip-smack).

## 1. What is real (checked 2026-11-01)

| Thing | Fact | Source |
| --- | --- | --- |
| The de Gaulle statue | Jean Cardot's marching bronze in uniform and kepi, a copy of the Paris one; unveiled 15 May 2005; stands by the roundabout in front of Nowy Świat 6/12; the monument with its plinth about 4 m (F's photo: a tall dark granite block, the general walking west, a low granite cone on a cobbled circle, curved steps and lawn on the south-east) | Wikipedia "Charles de Gaulle Monument (Warsaw)" |
| The Party House | Nowy Świat 6/12, on the south-east corner of the roundabout; today Centrum Bankowo-Finansowe; a white stone block of four wings round one courtyard with a fountain, its north and south wings on pillars over the ground floor; a QUERCUS sign on the roof (an investment firm: a brand, so ours is **ROBUR**, Latin for the oak species); bars on its edges: newonce.bar (south side), Zamieszanie cocktail bar (north-west corner), Zagrywki (board-game bar, the next block south) | F's photos; OSM (`Centrum Bankowo-Finansowe`, mapped in 3D parts) |
| Loreta | the rooftop bar of the **PURO Warszawa Centrum** hotel, ul. Widok 9; a terrace with a bubblegum-pink neon, greenery, low seats, cocktails | Warsaw Insider "Loreta"; purohotel.pl; OSM outline `Puro Warszawa Centrum` (27.4 m) at (-607, 307) |
| Książulo's pizza | "Muala na grubo", sold at Żabka from 7 Oct 2026, two kinds: Fat Peppa (pepperoni) and Fat Cheese (cheese and jalapeño), 24,99 zł; sold out in many shops within days, fans hunting it | wiadomoscihandlowe.pl, 16 Oct 2026 |
| Manekin | a crêpe chain known for long queues in Warsaw | common knowledge, F |
| Costa Coffee, Green Caffè Nero | chains; OSM maps a Green Caffè Nero pavilion at (-745, 96) | OSM |

## 2. The parody names

| Real | Ours (on screen) | Why it works | Gloss |
| --- | --- | --- | --- |
| QUERCUS (the roof sign) | **ROBUR** | the oak again, in Latin, same white letters, a different word | — |
| newonce.bar | **NEWTWICE** | once → twice | — |
| Zamieszanie | **ZAMĘT** | a synonym (stir → turmoil) | turmoil |
| Zagrywki | **PRZEGRYWKI** | "plays" turned into "losing streaks": the board-game bar (F, 2026-11-01; was PIONEK) | losing streaks |
| PURO hotel | **HOTEL PIURE** | *piure* is how Polish spells purée | mash |
| Loreta (the rooftop bar) | **LORETKA** | the diminutive, F's own pick (2026-11-01; was LUŹNO): the first-date bar | little Loreta |
| Tinder | **TIMBER** (F's pick) | the falling-tree shout; "swipe" becomes *rąbnij* (chop); a pine-cone mark, brown and green, never the flame or its red-orange | — |
| Costa Coffee | **KOSZTA COFFEE** | *koszta* = the costs; dark red-brown tube, our own cup mark | Costs Coffee |
| Green Caffè Nero | **GREEN CAFFE NERWO** | *nerwy* = nerves; the 5×7 font has no È | Green Caffe Nerves |
| Manekin | **KUKŁA** | a synonym (mannequin → dummy), "naleśniki" under it | the Dummy |
| Książulo | **Mrożulo** (F's pick) | the cringe in the name; a type, never the real man's face, voice, logo or words | — |
| "muala" | **MLASK** | a lip-smack: his top grade, on his sticker | smack |
| Muala na grubo · Fat Peppa · Fat Cheese | **MROŻULO PIZZA · TŁUSTA PEPA · SEROWY GRUBAS** | at Frogs (our Żabka) | Fat Pepa, Cheesy Chonk |

The real names go into `brand_denylist.json` in the first PR (`loreta`, `puro`, `manekin`,
`książulo`, `muala`, `fat peppa`, `costa coffee`, `caffè nero`, `caffe nero`, `tinder`,
`newonce`, `zamieszanie`, `zagrywki`, `quercus`). `rejected`: `mrozulo pizza na grubo`,
`muala` spellings, `tinderek`.

## 3. The items, one PR each

### G1 · The de Gaulle statue (map/landmark model, Opus) — site `gaulle`
At about (-171, 273), the lawn's curved cut-out north-west of the Party House's north wing
(F's aerial; checked against a top-down shot). Built by hand like Sigismund's Column:
- two curved granite steps (r 8.6 and 7.8 m, 0.18 m each) with cobbled rings between them on the
  west and south (the lawn takes the east), a cobbled disc r 5.4 m;
- the low granite cone, r 4.4 → 3.2 m, 0.55 m tall, its top cobbled;
- the plinth: dark granite (#4a4b4e), 2.7 × 1.8 m, 4.2 m tall, its long side along the walk
  (east-west), faint joint lines, "CHARLES DE GAULLE" in small pale letters on the south face;
- the general in dark bronze, 3.3 m, walking west: legs apart in stride, a long coat, the right
  arm swinging back, the left forward, a kepi; ≤ 400 triangles for the figure.
- Card: "Pomnik generała de Gaulle'a · Maszeruje Alejami od 2005 roku. Kopia tego z Paryża." /
  "The de Gaulle statue · Marching down the Avenues since 2005. A copy of the one in Paris."
- A line for the Palm's neighbour (dialogue `gaulle`): "Generał idzie na Nowy Świat. Od 2005 roku.
  Jeszcze nie doszedł." / "The General is walking to Nowy Świat. Since 2005. Not there yet."

### G2 · Dom Partii (landmark skin and extras, Opus) — sites `dom_partii`, `dom_partii_extras`
- The mapped massing stays (OSM parts on the cloud, GUGiK LoD2 on the Mac: the wings, the pillars
  under the north and south wings) as a **skin** (M_MONUMENT, white stone #e9e6dd, roof #8e9091),
  the way the Teatr Wielki and the Sejm are drawn: tall windows between piers.
- Extras: **ROBUR** in white letters on the roof's north-west corner, on both faces; the
  courtyard's stone paving with the Greek-key border and its long eight-sided fountain with jets
  (lit at night); one card: "Dom Partii · Biały gmach z 1952 roku. Kiedyś partia, potem giełda,
  dziś biura i bary." / "The Party House · A white block from 1952. Once the Party, then the stock
  exchange, now offices and bars."
- The bars: three venue neons (storefronts.gd `CAFES`-style table `GAULLE_BARS`): **NEWTWICE**
  (white) on the south face, **ZAMĘT** (amber) on the north-west corner, **PRZEGRYWKI** (teal) on
  the next block south; a small terrace crowd at NEWTWICE on Thu-Sat evenings.

### G3 · HOTEL PIURE and LORETKA, the TIMBER date bar (content + small model, Sonnet/Opus)
- HOTEL PIURE on the Puro outline's crown (like CHILTON); on its roof the terrace: a pink neon
  **LORETKA** (bubblegum #ff7ac8 is Wiralek's: use #ff9fd6), planters, low seats, string lights.
- Dates: from 18:00 to 01:00 a dozen figures in twos on the terrace (crowds.gd site `loretka`,
  roof height from the outline), lines `timber_date` (16) when the car is near the hotel door or
  the helicopter hovers over the roof: "Na zdjęciach był wyższy. I miał psa." / "He was taller in
  his photos. And he had a dog."; "Trzecia randka w LORETCE w tym tygodniu. Barman już mi kibicuje."
  / "Third date at LORETKA this week. The barman is rooting for me now."
- TIMBER itself: a billboard (signs group), two column posters, radio host lines, and Podwózka
  passengers with the `timber` tag going to LORETKA (lines about the match, the profile, "6'2 i
  Mordor"). No real app look; the mark is a pine cone.

### G4 · Coffee chains and the queues (content + crowds, Sonnet)
- Neon venues: **KOSZTA COFFEE** ×3 and **GREEN CAFFE NERWO** ×2 (one on the real pavilion at
  (-745, 96)), **KUKŁA naleśniki** ×2 (Marszałkowska by Królewska, Nowy Świat).
- KUKŁA's queue (crowds.gd, like PISTACJA's): 8 at opening, 30 at lunch and on Sunday
  afternoons, never under 5 while open (the joke: there is always a queue); lines `kolejka` (18):
  "W Warszawie kolejka to recenzja." / "In Warsaw a queue is a review."; "Stoję, bo ktoś stał.
  Ktoś stał, bo ja stałem." / "I'm queuing because someone was. They were because I was.";
  "PRL nauczył, Instagram utrwalił." / "The old days taught us. Instagram made it stick."
- KOSZTA and NERWO lines (`kawa_sieciowa`): the price of a latte, the name spelled wrong on the
  cup, the laptop office; a notebook card "Kolejki" (chapter trendy).

### G5 · Mrożulo, his review and his pizza (gameplay + content, Opus for the job's design)
- **Mrożulo** is a food reviewer on wheels: a cream van with a big lens on the roof ("MROŻULO
  TV" on its side, our own mark: a smacking mouth), parked at one of four spots by the day
  (Plac Zbawiciela, Hala Koszyki, the Palm, Powiśle's station), 11:00-21:00.
- **The job "Mlask"** (trend_job.gd, sixth activity, one at a time like every job):
  1. Stop by his van: "Siema, tu Mrożulo! Nowe miejsce, nikt jeszcze nie był. Weź mi coś,
     tylko szybko, ma być ciepłe." The new place is the nearest open Wiralek slot on its days
     1-3 (or KUKŁA if none).
  2. Stop 2 s at the place ("na wynos dla Mrożula": the queue lets you through).
  3. Back to the van within 5 min (the food cools: a thermometer on the card, like the kebab).
  4. His review (a card): a mouthful, three lines in his manner, a grade on his own scale, e.g.
     "Ciasto chrupie, sos jest, ser się ciągnie jak kredyt. Siedem i pół MLASKA." / "The crust
     crunches, there's sauce, the cheese stretches like a mortgage. Seven and a half SMACKS.";
     cold food gets "Letnie. Jak moja kariera w TV. Trzy MLASKI." and a smaller sticker.
  5. Bring the **MLASK sticker** to the place within 4 min and stop at the door: the owner's
     line ("Mrożulo nas polecił? Zamawiam drugą kasę."), the pay (40 zł + 10 zł a km, +15
     respect *guess*), and the **Mrożulo effect**: that place's queue jumps to its max for the
     rest of the game day, with the `mrozulo_fani` lines ("Stoję od szóstej. Mrożulo dał
     dziewięć mlasków." / "Been here since six. Mrożulo gave it nine smacks.").
- **Lore**: MROŻULO PIZZA at every Frogs (a poster in the window: TŁUSTA PEPA, SEROWY GRUBAS),
  "WYPRZEDANE" on most of them (the `rechotka` till lines: "Pepy nie ma od wtorku. Pytają co
  pięć minut."); the radio host's news (`radio_host`, `only: mrozulo`): "Pilne: Mrożulo zjadł
  pierogi na Mokotowie. Kolejka sięga już Puławskiej."; fans (`mrozulo_fani`) in his van's
  queue and at the reviewed place; an egg **E-mlask**: the car parked by the van for 10 s while
  he films: "Dzięki za cameo, kierowco. Dwa mlaski dla twojej fury."
- Flags: `--mrozulo` (the van by the car, the job offered at once), `--mrozulo-log`.
- Check: `check_mrozulo.gd` (the steps, the pay, the cooling, the effect's queue, the lines,
  the denylist) joins verify and CI.

### G5b · "Dżemini": Mrożulo's call (F, 2026-11-06; built)
F's ask: Mrożulo phones, you buy him a kebab at a newly opened place named like the AI agent,
bring it, he tries it and says "wjeżdżam w to", a Telegram-style message comes from him, his
sticker goes on the shop, and after that a huge queue stands there for good, with jokes.
- **DŻEMINI KEBAB** (a parody of the Gemini assistant; "KEBAB 24H", blue-violet tube): an
  invented shop on the north side of Świętokrzyska (Storefronts.HYPE `dzemini_kebab`,
  52.23595, 21.0105; the Mac look check parks its door). The meat is carved by an AI agent: the
  joke of every line.
- **The call** (trend_job.gd `offer_dzemini`): once per save, after 5 min of play, while his van
  is out (11:00-21:00), "📞 MROŻULO DZWONI": "Siema, tu Mrożulo! Na Świętokrzyskiej otworzyli
  DŻEMINI KEBAB, mięso kroi agent AI. Kup mi jednego i przywieź do vana, póki ciepły!" Skipped,
  he rings again 15 min later.
- **Pickup**: stop 2 s by the queue (the agent: "Na pewno kebab? Mogę też napisać o nim
  wiersz."); **delivery** to his van at today's spot in 5 min (warm).
- **His verdict** (a card): "*mlask* … Wjeżdżam w to." (cold: "Letni, ale… wjeżdżam w to."),
  60 zł + 10 zł a km, +25 respect, 20 zł tip *guess* (cold: half, no tip, no respect).
- **TYGRAM** (our messenger parody, a blue card): "DŻEMINI: MLASK! Naklejka już wisi na szybie.
  Jutro kolejka do Marszałkowskiej. Dzięki, kierowco!"
- **For good** (the save's `keep` `dzemini_mlask`): the MLASK sticker (yellow, pink edge, pixel
  letters) on the shop's wall beside its sign, and the longest line in town at its door
  (crowds.gd `dzemini_queue`: 40, 26 at 02-07; 3 before the call), with the `viral` "dzemini"
  jokes (generated sauce, hallucinated fries, a five-step plan for "spicy", a million-token
  context that remembers your sauce).
- "Muala" stays MLASK (our sound), as in section 2. "Wjeżdżam w to" is F's line: ordinary Polish
  slang, used once by Mrożulo and quoted by the fans.
- Test flag `--trend-job=8` (the car by the shop, the call at once); check `life` covers the pay,
  the queue rule and the sticker's triangles.

## 3b. What was built (2026-11-01)
G1 and G2 as specified (PR #185). G2's bars, G3 and G4 as neons in `Storefronts.HYPE`, LORETKA as
the hotel's crown sign; the dates are a line at HOTEL PIURE's door (waiting for the lift), not
yet figures on the roof. G5 lives in `trend_job.gd` (one activity at a time with the other jobs)
with the van as one mesh; `--trend-job=6` parks it by the car. Left: BACKLOG's G3-G5 leftovers.

F's follow-up (2026-11-01): the rooftop bar renamed LORETKA, the board-game bar PRZEGRYWKI. The
terrace is built: `landmarks.gd` `loretka_plan` (one plan for the model and the crowd) lays a
wooden deck on the west half of HOTEL PIURE's roof, planters with shrubs on its open edges, eight
low tables with two poufs each, four pink parasols, the bar's counter with a pink strip, the lift's
housing, string lights on six poles (930 triangles, +0 draw calls, out of the roof grid);
crowds.gd's `terrace` site seats couples there May-September on dry evenings, 17:00-01:00 (16 on
Friday and Saturday, 10 otherwise). `check_mesh_quality`'s ON_ROOF counts the deck as the site's
ground. WACZEK (F: the burger chain, another name, an upside-down M): five neons in
`Storefronts.HYPE`, a gold W over the name, at the real chain's central restaurants (their names
on Wolt; the corners approximate); the real names are in the denylist.

## 4. Order and cost
G1, G2 (Opus, landmark lane) → G3, G4 (Sonnet-sized content, one PR) → G5 (Opus design, then
content). Cost: G1 ≈ 1.5k triangles in the sector's building mesh (+0 draw calls); G2's extras
≈ 1k triangles and a fountain (+0, in the building mesh; the jets use the city's fountain
particles if near); the neons ride the venue MultiMesh (+0); queues and the terrace are still
figures in the sector's crowd MultiMesh (+0 to +1); Mrożulo's van one mesh (+1 when near).

## 5. Open (parked defaults)
- Statue spot (-171, 273) and its facing (west) from F's photo and aerial: a Mac look with the
  orthophoto confirms. The plinth's exact size is not published; ours is from the photo.
- TIMBER: F's pick; an English word, and the real app's look is avoided. A register check
  before TestFlight, like the other parodies (parodies.md 10).
- Mrożulo is a type of food reviewer, not the real man: no face, voice, logo or catchphrase of
  his; if F wants it further from the original, "Mlaskacz" is the fallback name.
- Real Manekin, Costa and Nero sites are not all mapped in OSM; our spots are on the streets
  where F knows them (Marszałkowska, Nowy Świat, Chmielna), a Mac check can move them.
