# Żyletkowiec (Marszałkowska 82): spec

Site key `zyletkowiec` (`_build_zyletkowiec` in `game/scripts/landmarks/works.gd`). Written
2026-11-16 in a cloud thread from photos: F's T15 set (`refs/_f/warsaw-needed-photos/top-50/T15/`
in the shared store: the two street fronts from the corner, with the Novotel behind, twice, and
the arcade along the ground floor); reference only, never shipped. The building is OSM way
30241286 ("Żyletkowiec", 7 levels, 1952, wikidata Q60862404).

Warsaw has two buildings called Żyletkowiec. This is the one on Marszałkowska 82. The
`photo_fronts.json` block named "Świętej Barbary (żyletkowiec)" is a different building and is
unchanged.

The mass is the street block that already stood on the outline
(`game/data/street_blocks/30241286.bin`, its own site `blk_30241286`): the U round the courtyard,
open to the north; the cream walls with their windows and thin pilasters; the dark glass ground
floor to 3.7 m; the coping at 26.1 m. This site dresses it and draws no walls of its own.

## 1. Identity

1. A deep white fin on every window bay of the street fronts, from the first floor to the roof,
   making bands of light and shadow: the "razor blades" (T15-01, T15-02).
2. The dark roof lid that overhangs every front, with a thin dark edge (T15-01, T15-02).
3. The ground floor behind a row of granite piers: the arcade (T15-03, and the
   ground floor in T15-01).

## 2. Massing (heights over the block's ground, the lowest under its outline)

The block's, unchanged: the ground floor to 3.7 m, the cream floors and the coping to 26.1 m. The
lid's edge runs from 25.9 m to 26.3 m, 1.6 m out from the wall line; its slope rises to 26.9 m
over the ring 1.5 m inside the wall line.

## 3. Facade, base to top

- **Fins**: one over each of the block's own pilasters (their places measured from the block's
  mesh: per outline edge the first pilaster's centre, the pitch and the count, in `ZYL_FINS`),
  0.36 m wide, from 0.1 m inside the wall line to 0.95 m out, from 3.7 m up into the lid. Street
  fronts only: the long east and west fronts (34 bays each), the south front (24), the north
  ends of the two arms (3, 3 and 2). The courtyard keeps the block's pilasters.
- **Piers**: one under each fin, 0.5 m wide and 1.1 m deep, granite grey, from under the ground to
  3.7 m (the photos' piers are dark granite with paler sides; one colour reads the same from the
  game's camera and keeps the budget).
- **Lid**: see section 4.

## 4. Roof

A dark lid over the whole U: a 0.4 m edge band on the ring 1.6 m outside the wall line (a mitre
offset of the outline, the same 12 corners), a pale underside over that ring, a shallow slope from
the edge up 0.6 m to the ring 1.5 m inside the wall line, and a flat top there. The block's own
roof and coping are under it; its rooftop boxes still stand through it.

## 5. Colour and material

Fins #f2f2ee; piers #9a9c9b; lid edge #4a4f53, slope #6f7478, top
#7c8185, underside #d6d6d1. All M_STONE. No new material, no shader change (building.gdshader
stays at 501 of 505), no neon row, no sign words.

## 6. Ground and night

The block's collision is unchanged. The piers stand within 1.0 m of the wall line, on the
pavement, with no collision of their own; nothing of this site stands in a lane. At night the
block's lit windows show between the fins; the fins and the lid are unlit.

## 7. Detail level and budget

L2 (a big building on Marszałkowska, seen from above at an angle). 2068 triangles of its own,
most of them the 100 fins and their piers; budget 2300 (check_mesh_quality BUDGET "zyletkowiec");
no draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | street block | the whole building | the outline | its own | 2 massing |
| fins | boxes | 0.36 x 1.05 m, 3.7 to 26.1 m | over every pilaster of the street fronts | M_STONE #f2f2ee | 1.1 fins |
| piers | boxes | 0.5 x 1.1 m, to 3.7 m | under every fin | M_STONE #9a9c9b | 1.3 arcade |
| lid edge | band | 0.4 m tall | 1.6 m out round the whole outline | M_STONE #4a4f53 | 1.2 roof lid |
| lid underside | flat | the lid's ring | 25.9 m | M_STONE #d6d6d1 | 1.2 roof lid |
| lid slope and top | slope, flat top | 0.6 m rise over 3.1 m | from the edge to 1.5 m inside | M_STONE #6f7478, #7c8185 | 1.2 roof lid, 4 roof |

## 9. Not built, and what only the phone can show

- The blank white panels at the corners of the fronts (T15-01), the deep arcade itself (the
  ground floor stays the block's, the piers stand in front of it), the courtyard fronts' fins,
  and the Ekspozytura next door.
- Only the phone shows whether the fins read as blades with shadow between them at phone zoom,
  rather than a striped texture (PHONE-CHECK 15d).
