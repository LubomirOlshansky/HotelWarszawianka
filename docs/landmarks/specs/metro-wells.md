# The metro stations' open wells (2026-11-26)

F (2026-11-26, after Rondo Dmowskiego's wells): "can we make the others we have on the map",
"sink them and adapt them to the real stairs that are there". Every flight that OSM tags as going
down under the street (`steps` with `down`, 44 flights) is now one of 37 wells, map_builder.gd
SUNKEN `mw_<station>_<n>`, one landmarks site per station (`mw_cen`, `mw_onz`, `mw_dasz`,
`mw_ratusz`, `mw_nsu`, `mw_poli`, `mw_cnk`; landmarks/centre.gd METRO_WELLS_BOXES). Detail level:
street-camera; what reads from the game's camera is the hole, its rim and its roof.

## References (refs/metro_wells, gitignored)

- Street View: one still per entrance, looking at it (2015-2026), `sv/g00..g36`.
- Google 3D Tiles (2026-11-26): four views and a top-down of Rondo Daszyńskiego, Nowy
  Świat-Uniwersytet, Politechnika, Rondo ONZ, Centrum Nauki Kopernik and Ratusz Arsenał.

## Per station

| Station | Wells | Look (from the photos) | Ring from |
| --- | --- | --- | --- |
| Metro Centrum north, Marszałkowska | 4 | M1: 1.1 m grey granite parapet, pink marble inside (`parapet`, `tile` #c2a294) | the mapped balustrade U round each |
| Rondo ONZ | 11 | M2: dark granite, teal glass canopy, a long low wedge (`canopy_glass`, `roof` #4f9e97); the west well under Prosta open with a glass balustrade (`glass`) | OSM's roof parts (inset 0.4 m) or the mapped precast U |
| Rondo Daszyńskiego | 6 | M2: red glass canopies (`roof` #9a2a33) | the flights, 9 m from the mouth (3D Tiles: ~8-9 m canopies), 3.4-4 m wide |
| Ratusz Arsenał | 7 | M1: grey granite parapet, green handrails; the two by the Plac Bankowy tram stop glass with a steel cap (`glass`) | mapped balustrades or the flights |
| Nowy Świat-Uniwersytet | 3 | M2: violet glass canopies (`roof` #4a3f86) | the flights, 3.6 m wide |
| Politechnika | 4 + 2 barrels | M1: rough stone parapet (`tile` #a89f8f); the escalators under grey glass barrels (the Patelnia's `_glass_barrel`, POLI_BARRELS) | the mapped stone walls or the flights |
| Centrum Nauki Kopernik | 2 | M2: dark granite, glass balustrade (`glass`) | the flights / the mapped walls |

Every well: the floor from the street at the mouth (`a`) down to the foot (`b`, 1.2 m short of
the far end), `drop` = the flights' steps x 0.165 m, at most 0.55 x the run and 5 m; treads, coping,
retaining faces, the railing or glass, collision on every edge that drops, handrails down each
side (and the middle of a flight over 3 m), the passage's dark mouth in the far wall, walkers in
and out (`walk`). The mouth: the handrails' posts and a 1.2 m car collider (no car goes down).

## Left out

- flight 931 at Ratusz (Andersa): 16 steps on a 2.4 m way in an irregular wall, unclear.
- flight 2091 by Dworzec Wodny: the boulevards' stair, not a station's.
- Politechnika's south escalator barrels: not in OSM.
