# Kościół Wszystkich Świętych + Plac Grzybowski reference report
Files: refs/wszystkich/ (3 photos: 1 view from the Palace of Culture, 2 front and side from the south-east, 3 the front from the square; ortho.jpg 144 m square).
Ortho frame (north up): **x = -1468.7 + px*0.0700, z = -195.9 + py*0.0700** (2057 px file). Gathered 2026-11-06 on F's Mac; licences in SOURCES.md; positions ±3 m.

## What the photos show
- **Towers**: two **square, four-stage** towers: a tall shaft with pilaster order, arched niches with saints, a round window, windows and cornices; a
  **belfry stage with two open round-arched bell openings per face** (dark, louvred) under a heavy cornice; above it a **smaller second stage, open
  arcade with a balustrade (west tower) / paired arches (east tower)**; then a **pointed copper-green spire** (a bulb with ball, cross at the top, small
  corner finials). **No domes.** The towers are the same height (their crosses reach about 55 m); lower shaft about 30 m, belfry to about 40 m, upper stage to 46 m, spire to 55 m.
- **Front**: a three-bay central block between the towers: **one large arched central portal** (about 4 m wide, 8 m tall, in a rusticated pier-framed arch
  with a pedimented window above), flanked by **two smaller arched doors**; above the cornice a large arched window with a balustrade balcony; the **triangular
  pediment is low and wide** (about 3 m rise), carrying a relief; the inscription "CHWALCIE PAŃSKI W ŚWIĘTYCH JEGO" in the frieze. A **broad flight of
  granite steps** (about 10 steps) spans the whole front.
- **Arcaded galleries**: a low **open arcade with round arches** (7 m high, pale stucco, rusticated piers, wrought-iron gates) runs from each tower along the
  square, east and west. The ortho shows both wings reaching about 20 m out from the towers. The model has none.
- **Colour**: a weathered **sandy ochre / yellow-grey stone** (#c6b186 in sun, #a8977a in shade) with darker brown-grey staining, trim a little lighter; the
  arcades are a cooler cream (#d9d0bb). The spec's #ddcfaa plaster is too light and too pink-cream; it is dirtier and darker.
- **Roof**: **green copper** over the whole nave, a **Latin-cross roof** (nave with transept), and a **crossing drum**: a round drum (about 12 m across) with a ribbed
  copper dome and lantern, about 40 m high, near the rear. The ortho shows the drum at **x -1375, z -106** and the transept bars across the nave at z -118..-95.
- **Plac Grzybowski**: paved in grey granite slabs with a low dark-granite planter wall and bench (a long curved black wall in photo 3), small trees and bollards
  along the street edges (pairs of black bollards every 4 m), a pedestrian crossing and tram tracks at the south-east, grass patches beside the east nave wall.

## Positions (ortho)
| Thing | x | z |
| --- | --- | --- |
| West tower centre | -1423 | -148 |
| East tower centre | -1383 | -163 |
| Crossing drum | -1375 | -106 |
| Nave length (front to apse) | about 62 m | |

## Gaps against the model (docs/landmarks/specs/wszystkich.md, `_build_wszystkich`, `_wsz_tower`)
1. Tower tops are octagonal domes with lantern (spec section 4); the photos show a **pointed spire on a second open arcade stage**. Replace.
2. No side arcade galleries; the ortho and photo 2 show them clearly.
3. No crossing drum/dome on the roof (the model's roof is the skin's).
4. Wall colour too light; roof (#6e8f7e) matches the copper-green well.
5. The central portal is one big arch plus two small arched doors, not three equal portals under pilasters; the pediment is lower (rise about 3 m, not 4.4).

## Sources (photos stay on F's Mac in refs/wszystkich/, gitignored)
- 1.jpg: https://commons.wikimedia.org/wiki/File:Warsaw_07-13_img35_View_from_Palace_of_Culture_and_Science.jpg, A.Savin, CC BY-SA 3.0
- 2.jpg: https://commons.wikimedia.org/wiki/File:Ko%C5%9Bci%C3%B3%C5%82_Wszystkich_%C5%9Awi%C4%99tych_w_Warszawie_2019.jpg, Adrian Grycuk, CC BY-SA 3.0 pl
- 3.jpg: https://commons.wikimedia.org/wiki/File:All_Saints_Church_in_Warsaw.JPG, Mbkv717, CC BY-SA 4.0
- ortho.jpg: GUGiK orthophoto, 2057 px, ~144 m, fetched 2026-10-31, open data.
