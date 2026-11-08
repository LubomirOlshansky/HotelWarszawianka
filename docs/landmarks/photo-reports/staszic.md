# Pałac Staszica + Copernicus monument (Krakowskie Przedmieście 72) reference report
Files: refs/staszic/ (2 photos: 1 the front with the statue and its round plaza in snow, 2 close-up of the attic;
ortho.jpg 153 m square). Game coords: projection of `tools/bake_osm.py`; ortho frame (north up): **x = -459.9 + px*0.0700, z = -475.7 + py*0.0700** (px, py on the 2185 px file). Gathered 2026-11-06 on F's Mac; licences in SOURCES.md; positions ±3 m (tall things lean away from the image centre in the ortho).

## What the photos show (the model is wrong on these)

- **No free-standing portico.** The front is one long block with a **rusticated arcade on the ground floor** (11 round arches
  with dark openings, pale stone, about 6 m tall) and above it **giant engaged Corinthian pilasters and half-columns** (about
  9 m, paired at the centre) across the whole front, two window rows (the upper row 2.2 x 1.4 m, rectangular, white frames),
  and a plain frieze + dentil cornice. The centre is a **projecting avant-corps** (about 1.2 m proud, 5 window bays) carrying
  an **attic**: a half-round (fan) window about 6 x 3 m in a lunette, two relief **winged victories** either side, the inscription
  SOCIETAS SCIENTIARVM VARSAVIENSIS in black capitals under it, and on the stepped side blocks **two pairs of griffins with an hourglass vase**
  (about 1.5 m high, white). There is **no triangular pediment and no oculus**; the spec's pediment + oculus is wrong.
- **A green copper dome** (shallow, about 12 m across, a thin lightning-rod spike, #5f8f84 weathering to pale green) sits on the roof **behind the
  attic**, drum hidden. The ortho shows it as a cyan dome in a square well at the roof's north end: centre at about **x -409, z -433**.
- **Colour**: warm cream / ivory (#ece2c8), pilasters and trim a shade whiter (#f4eedb), plinth rustication a little darker (#d8cdb0); the roof is
  green-oxidised copper (#78968a) on every slope (ortho: green, not grey); the arch reveals dark (#3b3b3c). The spec's wall #e2d6b8 is slightly too ochre; the
  roof #5f6f6a too dark.
- **Copernicus**: seated bronze (dark green-brown) on a **tall stepped red-granite pedestal**: three wide low steps (granite, grey-red), a plinth about 3 m, a die
  about 2 m, the figure about 3.5 m seated, an armillary sphere in his right hand. He stands at the centre of a **round plaza about 26 m across**, paved in dark
  red-brown brick with **pale concentric orbit rings** (the planetary orbits; five rings, with small boulders for the planets) and a low pale-stone kerb. Centre
  in the ortho: **x -413, z -466** (about 20 m north of the palace's north end). A dark green-grey stone block stands at the plaza's west edge (photo 1, left).
- **Street furniture seen**: black ornate Warsaw double lamp posts (3 in view, 5 m), grey granite bollards on the pavement edge (0.9 m, every 6 m), square planters.
- **The palace is a courtyard (hollow) block**: ortho shows the green-roofed ring around a paved inner court (about 38 x 38 m) with a small round lawn at its centre.

## Positions read off the ortho (game metres)
| Thing | x | z |
| --- | --- | --- |
| Palace footprint (bbox) | -429..-345 | -446..-353 |
| Dome | -409 | -433 |
| Copernicus + orbit plaza | -413 | -466 |
| Inner court centre | -395 | -405 |

## Gaps against the current model (docs/landmarks/specs/staszic.md, `_build_staszic`)
1. The statue stands at u 14, v 15 off the west front, about (-428, -389); the ortho puts it at **(-413, -466)**, about 75 m away. The photo shows the
   statue on a round plaza in front of the **dome-carrying avant-corps** (the front that faces the plaza), so the main front probably faces the plaza and not
   the straight west run. A Mac in-game check of which front is which is needed before moving anything.
2. Portico (stylobate, 4 free columns, entablature, pediment, 3 doors, oculus) does not exist; replace with the arcade, pilaster order, avant-corps attic, fan
   window, griffins and dome.
3. Real centre of the avant-corps is at the middle of the front (u about 26), not u 14.
4. Missing: arcade ground floor, dome, orbit plaza and pedestal steps, lamps and bollards.

## Sources (photos stay on F's Mac in refs/staszic/, gitignored)
- 1.jpg: https://commons.wikimedia.org/wiki/File:Pa%C5%82ac_Staszica_Warszawa_01.jpg, Аимаина хикари, CC0
- 2.jpg: https://commons.wikimedia.org/wiki/File:Pa%C5%82ac_Staszica_Warszawa_03.jpg, Аимаина хикари, CC0
- ortho.jpg: GUGiK orthophoto (geoportal.gov.pl WMS), 2185 px, ~153 m, fetched 2026-10-31, open data.
Panoramax search at the site returned 0 photos (no Mapillary token on the Mac).
