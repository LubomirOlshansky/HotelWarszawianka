# The metro stations' open wells (2026-11-26)

F (2026-11-26, after Rondo Dmowskiego's wells): "can we make the others we have on the map",
"sink them and adapt them to the real stairs that are there". Every flight that OSM tags as going
down under the street (`steps` with `down`, 44 flights) is now one of 37 wells, map_builder.gd
SUNKEN `mw_<station>_<n>`, one landmarks site per station (`mw_cen`, `mw_onz`, `mw_dasz`,
`mw_ratusz`, `mw_nsu`, `mw_poli`, `mw_cnk`; landmarks/centre.gd METRO_WELLS_BOXES). What reads from the game's
camera is the hole, its rim and its roof.

## 1. Identity

Seven metro stations' open stair wells, each looking like its own station in the photos (M1
granite parapets, M2 coloured glass canopies). References in refs/metro_wells (gitignored):
Street View, one still per entrance (2015-2026, `sv/g00..g36`), and Google 3D Tiles views
(2026-11-26) of Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Politechnika, Rondo ONZ, Centrum
Nauki Kopernik and Ratusz Arsenał.

| Station | Wells | Look (from the photos) | Ring from |
| --- | --- | --- | --- |
| Metro Centrum north, Marszałkowska | 4 | M1: 1.1 m grey granite parapet, pink marble inside (`parapet`, `tile` #c2a294) | the mapped balustrade U round each |
| Rondo ONZ | 11 | M2: dark granite, teal glass canopy, a long low wedge (`canopy_glass`, `roof` #4f9e97); the west well under Prosta open with a glass balustrade (`glass`) | OSM's roof parts (inset 0.4 m) or the mapped precast U |
| Rondo Daszyńskiego | 6 | M2: red glass canopies (`roof` #9a2a33) | the flights, 9 m from the mouth (3D Tiles: ~8-9 m canopies), 3.4-4 m wide |
| Ratusz Arsenał | 7 | M1: grey granite parapet, green handrails; the two by the Plac Bankowy tram stop glass with a steel cap (`glass`) | mapped balustrades or the flights |
| Nowy Świat-Uniwersytet | 3 | M2: violet glass canopies (`roof` #4a3f86) | the flights, 3.6 m wide |
| Politechnika | 4 + 2 barrels | M1: rough stone parapet (`tile` #a89f8f); the escalators under grey glass barrels (the Patelnia's `_glass_barrel`, POLI_BARRELS) | the mapped stone walls or the flights |
| Centrum Nauki Kopernik | 2 | M2: dark granite, glass balustrade (`glass`) | the flights / the mapped walls |

## 2. Massing

Each well is a rectangle or a mapped U sunk into the pavement: the floor runs from street level
at the mouth (`a`) down to the foot (`b`, 1.2 m short of the far end); `drop` = the flights'
steps x 0.165 m, at most 0.55 x the run and 5 m, at least 2.6 m. Rings come from the mapped walls
or balustrades, OSM roof parts inset 0.4 m (ONZ), or the flight's own width (3.4-4 m).

## 3. Facade, base to top

Inside: treads, retaining faces (granite, pink marble at Centrum, rough stone at Politechnika:
`tile`), the passage's dark mouth in the far wall. Rim: coping, then the parapet (M1, 1.1 m) or
a 0.85 m glass pane with a steel cap (`glass`), handrails down each side and down the middle of a
flight over 3 m wide (steel on M2, green at Ratusz).

## 4. Roof

M2 canopies (`canopy_glass`): a glass wedge 2.6 m over the street at the mouth falling to 1.2 m
at the far end, steel frame beams and corner posts, glass sides except at the mouth; colour from
`roof` (ONZ teal #4f9e97, Daszyńskiego red #9a2a33, Nowy Świat violet #4a3f86). Politechnika's
escalators under the Patelnia's grey glass barrels. M1 wells are open.

## 5. Colour and material

Granite #33373b (M2), glass #9db5b9, steel #b9bec2, the existing SUNK_* parapet greys for M1,
`tile` colours inside (#c2a294 Centrum, #a89f8f Politechnika). Vertex colours, no new materials.

## 6. Ground and night

The street pavement runs to the rim; walkers go in and out (`walk`). Cars: every dropping edge
collides, and the mouth has a 1.2 m car collider drawn by the handrail posts (no car goes down);
closest kerb clearance 0.3-0.4 m (Daszyńskiego, ONZ). At night the city's lamps light them; no
new lights.

## 7. Detail level and budget

L3, triangle budget 7200 per site (the largest, mw_onz with 11 wells; measured 5530). Measured
per site: mw_cen 1622, mw_onz 5530, mw_dasz 2916, mw_ratusz 3048, mw_nsu 1470, mw_poli 2353,
mw_cnk 824 (check_mesh_quality BUDGET). No new draw calls.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| floor | stepped treads | well length x width, drop 2.6-5 m | inside the ring, mouth to foot | granite | the stairs going down |
| walls | retaining faces | ring perimeter x drop | ring edges that drop | granite / tile | the hole read from above |
| rim | coping + parapet or glass | 0.3-1.1 m high | on the ring | granite / glass, steel cap | station look (M1 or M2) |
| rails | posts + bars | 0.9 m high | mouth edges ±0.25 m, sides, middle over 3 m | steel / green / SUNK_RAIL | handrails, draws the mouth collider |
| canopy | glass wedge + frame | 2.6 m to 1.2 m over the well | over M2 wells | glass in `roof` colour, steel | ONZ teal, Daszyńskiego red, NŚU violet |
| mouth | dark quad | passage width x 2.4 m | far wall at the foot | dark | the way into the station |
| barrels | half cylinders | 3 x 10 m | Politechnika (POLI_BARRELS) | grey glass | escalator covers like the Patelnia |

## Left out


- flight 931 at Ratusz (Andersa): 16 steps on a 2.4 m way in an irregular wall, unclear.
- flight 2091 by Dworzec Wodny: the boulevards' stair, not a station's.
- Politechnika's south escalator barrels: not in OSM.
