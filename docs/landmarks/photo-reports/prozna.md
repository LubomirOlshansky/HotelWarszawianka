# Próżna reference report (F's photos, 2026-11-08)
Files: refs/prozna/ (13 photos P01-P10 + SOURCES.md, kept on F's Mac, gitignored). Licences and Commons pages in refs/prozna/SOURCES.md. Positions ±3 m, game coordinates (x east, z south; north is -z).

## The street (OSM, game coordinates)
One-way residential road, **6.3 m**, from Plac Grzybowski (-1371, -239) ENE to Marszałkowska (-1208, -306): centreline (-1371.1,-239.4), (-1361,-243.6), (-1279.1,-277.2), (-1217.2,-302.4), (-1208.1,-306.1), about 176 m. Building fronts stand **6 m** from the centreline, so the pavements are about 2.8 m wide.

## What the photos show
- **Road: granite setts kerb to kerb** (P05, P06, P07): small cubic setts about 10-12 cm, laid in arcs and fans, a warm grey with pink-brown stones among them; a straight band of larger setts where the cars cross. No asphalt, no lane lines.
- **Pavements: pale grey granite slabs** about 60 x 40 cm in running bond (P01, P06, P07) behind a **darker, wider kerb stone** (about 30 cm, a second band in P07); small inspection-cover rectangles; wet slabs read dark grey-brown.
- **Bollards** (P01, P05, P07): slim graphite posts about 90 cm with a pale cap, a pair or a single post every 3.5-4 m along the **south kerb** (P01 counts 18 in 70 m), singles on the north side near the Marszałkowska end. The sign posts (no-entry discs, blue square) stand in the same line.
- **Street lamps** (P05, P06): black cast-iron posts with a curved bracket and one or two glass globes, about 5 m, a pair at each end of the block.
- **South side (odd numbers), Próżna 7/9 and its neighbours** (P01, P02, P07): ivory **neo-renaissance** tenements of about 17-22 m; ground floor **rusticated, pale buff** (#d6cbab) with **round-arched openings** (3.4 m bay, 2.2 m wide, 4 m tall) over **dark brown lattice glazing** and a restaurant's name board in each arch (parody names only); **a string course**, then **three floors of tall windows** (first floor with **pediment hoods and stone-balustrade balconies** on brackets, the next two with plain hoods and sills), **an attic floor of small arched windows** under a **heavy cornice** (#f2ecd8 trim, #e7dfc7 wall); a dark zinc mansard behind. The corner at Plac Grzybowski (P02) has a **chamfered corner bay with a rounded oriel balcony**, the street plaques stack on the corner pier (P08: four enamel plates, a brass plate, a Cyrillic-era plate).
- **North side**: **Próżna 14 / 12 (P03, P04, P10, P09)** are the surviving pre-war row: raw **red brick** with arched windows and a brick ground floor under a canopy, portraits hung on the walls (the 2014-15 installation); archive photos, today wrapped or restored (P04, 2023: Próżna 12 is plastered grey art nouveau with **three round bay oriels** and a **stack of black iron balconies** on the east edge, Próżna 14 beside it under scaffold netting). East of 12, Próżna 10 and the buildings to Marszałkowska are **grey 1960s plaster blocks** with plain window grids (P05-from-Marszałkowska, P04).
- **Café gardens** (P04): **long black planters** with a clipped hedge in front of the ground floor of Próżna 12 (about 14 m x 0.6 m x 0.7 m), a timber terrace behind it; white round pots by the arcade (P02).
- **Plac Grzybowski corner**: pale paving continues from the square into the street mouth, with cars parked across the mouth (P05).

## Gaps and what the model does
| Photo evidence | In the game |
| --- | --- |
| setts and slabs (P06, P07) | `ground.gdshader` PZ_*: setts on the carriageway (PZ_LINE), slab pattern and a dark kerb band on the footways within 11 m |
| south tenements (P01, P02, P07) | `_pz_front` on the two OSM outlines (11 + 10 bays): arcade, string courses, hoods, balconies, attic, cornice |
| bollards (P01, P05, P07) | `_pz_bollards`: both kerbs, every 4.2 m, 14 m in from the junctions |
| café planters (P04) | `_pz_planters`: two troughs |
| Próżna 14 brick (P03) | already the photo front `b1399` |
| **missing: modern frontal shots of every house**, Próżna 12's front and the 1960s blocks | parked in docs/QUESTIONS.md (the 12 and 10 fronts, lamps, the Gessler name boards, the corner oriel) |
