# Schodki nad Wisłą: the concrete seating steps (site `schodki_wisla`)

Written 2026-11-19 from the plan (Opus, /schodki/PLAN.md), the Panoramax walk at Kopernik
(refs/schodki, no frame shows the steps themselves) and measurements of `centrum.json` (`steps`,
`shore`) and `terrain.json`. F: the boulevard steps must look and live like the real ones, people
sitting in groups on them. OSM maps only 12 narrow walking flights perpendicular to the river and
the 10 m grid between them is a smooth slope; it read as a ramp with ladders. Step count, rise and
tread of the real steps are in no source found: the 0.41 m rise is the plan's, kept on purpose
(seat height); the drop (4.1 m) is the grid's. Mac photo check open (QUESTIONS).

## 1. Identity

One continuous band of wide grey concrete steps along the Vistula, ~195 m, between the upper
promenade and a lower granite quay at the water; narrow walking stairs cut into it every 15-25 m;
timber seat boards on some stretches; people sitting in groups all over it (crowds.gd). Low
lamp posts along the top edge.

## 2. Massing

Local frame: C (445, -862), along-river u (0.665, 0.747), water v (0.747, -0.665). Two SUNKEN
entries (map_builder.gd) because the shore turns at u -36..-55 (v 7 to 2): `schodki_wisla` u -36..+104,
`schodki_wisla_w` u -95..-36. Top edge v = -5.9 + 0.039 (u + 10) (the OSM flights' tops; grid -17.7
to -17.9 m east, -18.2 to -18.4 m west). `ha` the grid at `a` (u 25) = about -17.75 m, `hb` -21.9 m
(the grid at the shore line is -21.9..-22.2; the river, which the ground draws, -23.1: the quay 1.2 m
over the water). Ten rows (`rows`) of ~0.41 m, 1.0-1.2 m deep (`a`-`b` 11.7 m east, 10.2 m west, normal
to the band). Past `b` the ring is the quay, 2-3.3 m, its water edge the shore line 0.4 m inland.
Floor: the plane `a` to `b`, `sunk_floor` wins only where lower than the grid.

## 3. Facade (the steps' faces)

Each row a prism from the ground to its top; riser faces `#a29f98`, tread `#b9b6ae`, a nosing
`#cdcac2` 0.14 m along the front. Timber seat boards `#a37a52`, 0.06 m thick, 0.45 m deep on the front
of the tread, 6-8 m long on rows 2, 3, 5, 6 of every third piece. Walking stairs: 2.4 m wide along each
OSM flight's line (SCHODKI_FLIGHTS, frozen from `steps` so the crowd's static plan cuts the same
gaps), small 0.15 m steps `#a7a49d`, risers `#8f8c86`.

## 4. Roof

None. Top edge: a 0.5 m concrete coping `#c4c1b9` to 0.12 m over `ha`; a low lamp post every ~25 m 1 m behind it
(3.5 m post, a 0.7 m arm, a lit head in M_LAMP).

## 5. Colour and material

As above, calmed from grey in-situ concrete. Everything in M_STONE and M_LAMP, the city's one building surface.

## 6. Ground and night

The OSM flights inside the rings are no longer drawn as flights (`_stair_skipped`: an end in a SUNKEN
ring); the grid's slope inside is replaced by the plane. Lamp heads glow at night (M_LAMP), no new light.
Crowd: Landmarks.schodki_plan (river.gd) gives seats on every row except within 1 m of a stair, groups of
2-7 about 0.6 m apart with 1-3 m gaps, facing the water; quay standers; the guitarist on row 5.

## 7. Detail level and budget

L2 band, triangle budget 3600 (built 2805) at most (an exception to L2's 3000: the band is ~195 m long); in `check_mesh_quality.gd` (each tread row is merged
between the stairs into one prism). No new material, no new MultiMesh: +0 draw calls (the site's mesh per
sector); the crowd's STEPS_MAX 80 to 180 stays one MultiMesh per cell.
Shots: the turntable `tools/turntable.sh schodki_wisla`, the steps by day, dusk and night, both city paths.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| rows | prism per row between stairs | 10 rows, ~0.41 m rise, 1.0-1.2 m tread | the band, top edge to `b` | M_STONE concrete | the seat steps |
| nosing | flat strip | 0.14 m | each tread's front | M_STONE lighter | lighter nosing |
| boards | thin prism | 0.06 x 0.45 x 6-8 m | rows 2, 3, 5, 6, some pieces | M_STONE timber | seat boards |
| stairs | small steps | 2.4 m wide, 0.15 m risers | at each OSM flight | M_STONE darker | walking stairs |
| coping | slab | 0.5 m wide | the top edge | M_STONE | the upper edge |
| lamps | beam + arm + head | 3.5 m, every ~25 m | behind the coping | M_STONE, M_LAMP head | night lamps |
| quay | slab | 2-3.3 m wide, flat at `hb` | foot line to the shore | M_STONE granite | the lower quay |
