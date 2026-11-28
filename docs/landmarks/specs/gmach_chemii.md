# Gmach Chemii Politechniki Warszawskiej (Noakowskiego 3)

Site key `gmach_chemii` in `game/scripts/landmarks/srodmiescie.gd` (`_find_gmach_chemii`,
`_build_gmach_chemii`). Modelling queue v2 row 16 (F, 2026-11-27: buildings with no model first),
Gemini lane, together with Instytut Techniki Cieplnej (spec `instytut_techniki_cieplnej.md`).
Today it is the map's plain 10.9 m prism.

Sources: Google Street View, 2026-11-28 (`refs/gmach_chemii/streetview/`: the three `cg4...` frames
show the Noakowskiego front up close; the three `jKN...` frames from 2018 look past the building's
north end at a different white building with a pediment, so ignore them); reference only,
gitignored, never copied. No 3D Tiles orbit (the day's cap was spent): the courtyard side and the
roofs follow the outline and the usual form of the type. OpenStreetMap: landmark "Gmach Chemii"
(building 12676, 10.9 m, 56 nodes, about 100 x 100 m on the diagonal); find it by name.

## Identity

The Chemistry building of the Warsaw University of Technology (1899-1901), a big neo-renaissance
block on Noakowskiego across from the campus. What makes it read as itself from the iso camera:
1. A long, dark-sandstone ochre front #b3a27f along Noakowskiego, three tall storeys: a grey
   rusticated ground floor #8f8c85 with heavy banded piers and big wooden double doors up a few steps,
   then two upper storeys with tall round-arched windows (white frames) between giant pilasters.
2. Projecting risalits: at the corners and at the entrances the wall steps forward about 1 m and
   carries paired giant pilasters through both upper storeys, a heavy cornice and a low attic over them.
3. A strong crowning cornice with a frieze at about 18 m, and a dark grey hipped roof #5b5f63 behind
   it.
4. Long side wings with plainer rhythms of the same windows, closing round an inner courtyard
   (render #c9bd9f), seen only from the air.

## Massing

The landmark outline; ground = `_ground_under`. The front is the long run along Noakowskiego on the
outline's north-east side, roughly from (-1038, 1325) to (-986, 1374), with its small steps
(risalits); work it out from the outline itself and simplify only short wiggles (under 1.5 m).
- Ground floor 0-5.5 m (rusticated), then two upper storeys to 17.0 m, frieze and cornice to
  18.0 m, a 1.0 m attic over the risalits.
- Risalits: the outline's forward steps on the front and the corners; 1.0 m forward where the
  outline shows none at an entrance.
- Courtyard: the wings are about 14 m deep round an inner courtyard holding a central T-shaped
  inner wing projecting from the Noakowskiego front wing (about 25.6 m wide, neck 14.0 m wide,
  same 18.0 m height), creating two large SE/NW light wells and a narrow SW courtyard strip.
  (As built from 3D Tiles, 2026-11-28: orbits show this central courtyard block at the same height
  dividing the court into two light wells, and flat-ish low dark grey roofs ~1.4 m tall instead of
  4.0 m hips.)
- Roof: flat-ish low dark grey roofs (1.4 m rise with broad flat tops) over all four outer wings
  and the central inner block (with a small rooftop skylight box); low flat attic tops over the
  risalits.

## Facade

Kit parts only. kit_window_grid on every outer face (upper windows 1.6 x 3.2 m round-top where the
kit allows, white frames #efece4, glass #4a5660, bays about 3.8 m); kit_bands for the rusticated
ground floor (#8f8c85); kit_ledge string courses at 5.5 m and between the upper storeys;
kit_cornice_ring at 17.0-18.0 m; kit_pilaster paired giant pilasters on the risalits; kit_door for
the entrances (wood #5a3e2a, three doors on the main risalit, with steps); kit_attic on the
risalits. Courtyard faces: kit_panes with sill ledges.

## Roof

Flat-ish low dark grey roofs #5b5f63 (1.4 m rise with broad flat tops) over all outer wings and
the central inner courtyard block (plus a small central skylight box on the inner block); risalit
attics flat with coping #b3a27f; no dormers. (As built from 3D Tiles, 2026-11-28: lowered wing
roofs to flat-ish dark grey profiles and added the central courtyard block roof.)

## Colour and material

Front #b3a27f, ground floor #8f8c85, trim #efece4, courtyard #c9bd9f, roof #5b5f63, glass #4a5660,
doors #5a3e2a. All M_STONE. No new material, light or node: one site mesh. No signs, plaques or flags.

## Ground and night

Collision follows the outline. At night the entrance doors glow warm (M_PAVILION or M_LAMP lamp,
existing codes); the rest stays dark.

## Detail level and budget

L3 (one of the great buildings of the Politechnika campus, a long front on a main campus street).
Budget 7,500 triangles; set `"gmach_chemii": 7500` in both game/tools/check_mesh_quality.gd BUDGET
and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| gc_walls | wings round a courtyard, rusticated base, cornice | 0-18.0 m | outline | M_STONE #b3a27f | 1 |
| gc_windows | round-top window grid, string courses | 3.8 m bays | outer faces | M_STONE / glass | 1 |
| gc_risalits | forward steps, paired giant pilasters, attic | 0-19.0 m | front ends and entrances | M_STONE #b3a27f | 2 |
| gc_doors | three wooden doors with steps | 2.2 x 4.0 m | main risalit | M_STONE #5a3e2a | 1 |
| gc_cornice | frieze and crowning cornice | 17.0-18.0 m | all outer faces | M_STONE #efece4 | 3 |
| gc_roof | flat-ish low dark grey roofs + inner skylight box | 1.4 m rise | over outer wings and inner block | M_STONE #5b5f63 | 3 |
| gc_court | courtyard perimeter and central inner block with panes | 0-18.0 m | inside courtyard (two light wells) | M_STONE #c9bd9f | 4 |
| collision | outline | full height | outline | (collider) | 4 |
