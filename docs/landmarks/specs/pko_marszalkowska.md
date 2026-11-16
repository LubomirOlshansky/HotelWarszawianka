# PKO BP and Wolf Marszałkowska (Marszałkowska by Nowogrodzka): spec

Site keys `pko_marszalkowska` and `wolf_marszalkowska` (SKINS entries in
`game/scripts/landmarks/fronts.gd`, found by their OSM names "PKO BP" and "Wolf Marszałkowska").
Written 2026-11-16 in a cloud thread from eight Mapillary photos of the corner of Marszałkowska
and Nowogrodzka (2020 to 2026, CC BY-SA, `refs/pko_marszalkowska/street/SOURCES.md`); reference
only, never shipped. The two office blocks stand side by side on the west side of Marszałkowska,
PKO BP on the corner with the rounded end, Wolf Marszałkowska south of it.

## 1. Identity

1. PKO BP: light grey bands round every floor with **blue ribbon glazing** between them, wrapping
   the rounded corner (the photos' strongest feature from Marszałkowska and from Nowogrodzka).
2. Wolf Marszałkowska: a **glass tower with silver floor bands**, blue-grey glass, over a darker
   base.
3. Before this pass LoD2 gave them a dark punched block (Wolf) and a grey-blue box of punched
   windows (PKO BP): they read as two more anonymous blocks on the most-driven street.

## 2. Massing

The map's LoD2 masses kept as they are: the rounded corner, the setbacks and the roof boxes are
LoD2's own.

## 3. Facade

- PKO BP: the S_RIBBON skin, a white band over 30 % of every 3.2 m floor and a thin mullion every
  3 m, the glass in between tinted blue (#4f7db8).
- Wolf Marszałkowska: the S_BANDS skin, a silver band over 30 % of every 3.8 m floor and a mullion
  every 1.5 m, the glass blue-grey (#5f7a90).

## 4. Roof

LoD2's roofs, grey: PKO BP #8a9094, Wolf #596066 (the photos do not show the roofs; defaults).

## 5. Colour and material

| Part | Colour | Material |
| --- | --- | --- |
| PKO BP glass | #4f7db8 | skin (M_SKIN, S_RIBBON) |
| PKO BP bands | the shader's white | skin |
| PKO BP roof | #8a9094 (a default) | skin |
| Wolf glass | #5f7a90 | skin (M_SKIN, S_BANDS) |
| Wolf bands | the shader's silver | skin |
| Wolf roof | #596066 (a default) | skin |

No new material, no shader change (building.gdshader stays at 501 of 505), no draw call.

## 6. Ground and night

The blocks' collision is unchanged. At night the skins' own lit panes show (S_RIBBON lights a
little more than S_BANDS). No sign words, no floodlights.

## 7. Detail level and budget

L1, triangle budget 0 (skins only: no triangles of their own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with city
before/after shots by day and at night, runtime and prebuilt.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pko_mass | the map's block | the outline | Marszałkowska x Nowogrodzka | skin S_RIBBON | 1.1 bands and blue ribbons |
| wolf_mass | the map's block | the outline | south of PKO BP | skin S_BANDS | 1.2 glass with silver bands |

## 9. Not built, and what only the phone can show

- The grey bands are as tall as the windows in the photos; the skin's bands take 30 % of a
  floor, so the glass reads a little stronger than the real front. Wolf's dark stone base and the
  PKO BP ground-floor shop fronts are not built.
- Only the phone shows whether PKO BP's ribbons read as bands round the rounded corner at phone
  zoom (PHONE-CHECK 15e).
