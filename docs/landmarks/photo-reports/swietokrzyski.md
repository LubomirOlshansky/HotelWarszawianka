# Most Świętokrzyski (the cable-stayed bridge) reference report
Files: refs/swietokrzyski/ (4 photos: 1 the pylon from the bank, 2 the pylon from the water, 3 along the deck to the pylon, 4 wide side view; ortho.jpg 340 m square).
Ortho frame (north up): **x = 545.0 + px*0.1107, z = -1052.0 + py*0.1107** (3072 px file). Gathered 2026-11-06 on F's Mac; licences in SOURCES.md; positions ±5 m (the pylon leans in the ortho). Model: `_build_swieto` (landmarks.gd, SWIETO_*). No spec file.

## What the photos show
- **The pylon is an A-frame in the long direction, not one leaning shaft.** Photo 4 (side view from the river): two slim concrete legs rise from below the deck, spread
  about **26 m apart at deck level, taper and join at the top**, about **80 m above the deck**; above the join a short mast with the aviation light. The legs continue **below
  the deck as two piers** onto the bank. Each leg is about 3-4 m wide at the deck, 2 m at the top, pale grey concrete (#cfcdc6). The ortho shows the pylon slab
  as narrow across (about 3 m) and long along (the legs) with its base on the Praga bank near **x 747, z -915** (code: 737.5, -898.4; within about 15 m).
- **Stays**: a **fan of thin white parallel cables** (about 13 per side, 0.2 m) from the pylon's upper 35 m down to the deck edge, on the span side and the (shorter)
  back side, landing about every 12 m on the span. The ortho's shadow and cable lines suggest a plane on each side of the median; photo 4 cannot settle it. Check with an in-game shot. The code puts all stays in one plane in the 2.6 m median.
- **Deck**: a slender white-grey concrete box girder, about 2.5 m deep, with **regular diagonal struts under the cantilevered sidewalks** (every 4 m), a **white
  lattice railing** (1.1 m) along both sides and tall double-arm lamps every 30 m on the sidewalk side. The deck curves very slightly (crown at the mid-span).
- **River piers**: **rectangular twin-pier blocks** (about 3 x 6 m, concrete, a vertical groove) at the span joints; the deck over the bank is lower and heavier.
- Ortho: carriageway grey with red-brown cycle lanes at both edges; sandy bank and woodland on Praga; a small island south-east of the deck.

## Gaps against the model
1. A single leaning tapering shaft (7 m lean, 3.6 x 1.15 m foot) in the median: replace with **two legs 26 m apart (along the deck) joining above 60 m**, and piers below the deck.
2. Top at 70 m map y (about 78 m above the deck): photo scale gives about 80 m, matches.
3. Deck/ railings/ struts are map_builder's; the underside struts and white lattice railing are not modelled (map team).
4. Stays: 12 + 9 in one plane vs the photo's denser fan (about 13 per side) and a possible two-plane layout.

## Sources (photos stay on F's Mac in refs/swietokrzyski/, gitignored)
- 1.jpg: https://commons.wikimedia.org/wiki/File:Most_%C5%9Awi%C4%99tokrzyski_2011.jpg, Marcin Białek, CC BY-SA 3.0
- 2.jpg: https://commons.wikimedia.org/wiki/File:%C5%9Awi%C4%99tokrzyski_Bridge.JPG, Crusier, CC BY-SA 3.0
- 3.jpg: https://commons.wikimedia.org/wiki/File:Most_%C5%9Awi%C4%99tokrzyski_Warszawa_02.jpg, Аимаина хикари, CC0
- 4.jpg: https://commons.wikimedia.org/wiki/File:Most_%C5%9Awi%C4%99tokrzyski_w_Warszawie_2019.jpg, Adrian Grycuk, CC BY-SA 3.0 pl
- ortho.jpg: GUGiK orthophoto, 3072 px, ~340 m, fetched 2026-10-31, open data.
