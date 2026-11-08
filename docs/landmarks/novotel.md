# Novotel Warszawa Centrum (the 1974 Forum hotel): log

Site key `marszalkowska94` (card "Nowotel"), built by `landmarks.gd` `_build_novotel` (the TOWERS entry
carries `novotel: true`); its wall pattern is `building.gdshader` S_TILE's cool variant.

## 2026-11-07: rebuilt from F's five photos (cloud thread)

- Before: the TOWERS lump: the mapped parts as a plain white tiled box (no windows by day), the stacked
  NOWOTEL on the long faces, two setbacks at the top, the podium in the shaft's colour.
- References: F's five photos in the thread (the tower by day from the rondo side, the entrance and its
  canopy, three at night with the neon); outlines from centrum.json (the tower part and the podium with its
  canopies); heights from the LoD2 in the map pack (podium roof 8.8 m, the shaft's roof 92.2 m, the sign's
  frame to about 100 m over the pavement).
- After:
  - The shaft 55.8 x 15.6 m with a 3.1 m core bay on each narrow end (corners cut, as mapped). Long faces:
    white tiles with seams every 1.55 m and every floor (2.95 m), small dark windows 1.25 x 1.1 m in pairs
    in nine 6.2 m bays, the middle bay blank (the lift core), a share of the windows warm at night; the
    narrow ends blank. Floodlit cool white at night.
  - NOWOTEL in blue neon letter over letter down both core bays from two floors under the roof, an orange
    rule, ACORN and HOTELS under it (parodies of the brand and the chain).
  - The top storey's blue glass band over the north end's three bays (lit cool at night), a pale coping.
  - The roof: a dark plant room and a lift head, two white light boxes (26 m) at the long faces' edges with
    NOWOTEL and ACORN HOTELS in blue.
  - The podium: two glazed storeys out to Marszałkowska under a pale fascia with a lit strip, the mapped
    1.3 m canopies on its three street sides, plant boxes on its roof.
  - The entrance on the east face: the long cream canopy down the face, the bowed bay in two cream steps over
    the revolving door, the flat canopy with the blue board and NOWOTEL in white, a beige stone pier on its
    north side, two box planters.
- Checks: check_mesh_quality 490 tris (was 402; budget 590), 0 defects, check_sites, both city paths (bake_city), shots day, night,
  roof and entrance, bench.
- Still differs / open (BACKLOG "Novotel Warszawa Centrum from F's photos"): the entrance's side (built on
  the east face, where the canopy is mapped); the lift core strip's place along the faces; the podium's
  Marszałkowska front has no photo.
