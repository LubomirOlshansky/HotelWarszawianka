# Kamienica Maksymiliana Harczyka (site `harczyk`)

Photo: `/mnt/project-files/refs/sienkiewicza/f-harczyk-corner.png` (never shipped).

## Identity
A brilliant white neo-baroque corner tenement of the 1910s on Jasna and Sienkiewicza: a chamfered
corner stacked with balconies, a mansard with red-brick dormers under white ornate gables along
both fronts, arched windows on the first floors, a tall ground floor of large shop windows (parody
names REJNA and LIMONKA), a grey plinth.

## Massing
OSM building "Kamienica Maksymiliana Harczyka", h 20.8, replaced. The mapped corner is a 3 m jog;
the model cuts a wide chamfer (5.5 m legs, 7.9 m across) so it reads as in the photo. Three fronts:
Sienkiewicza (26.6 m), the chamfer, Jasna (24.1 m). Collision stays on the mapped outline.

## Facade
Base: plinth 0.7 m, rustication grooves, shop bays 2.6 m wide, an arched door with the gold REJNA
plate at the third bay, LIMONKA at the east end. Middle: five floors, sills 5.1, 8.0, 10.9, 13.8,
16.6 m (hooded, arched, sill-and-head, sill, sill-and-head windows), stone balconies at the first
floor and the 2nd to 4th on the chamfer and on two bays of each front. Top: cornice at 18.4 m, the
mansard from 18.85 to 20.8 m, 2 m deep, with a dormer on every bay and a larger crown on the chamfer.

## Roof
Mansard slope in dark slate on the three fronts, flat gravel top behind it at 20.8 m.

## Colour and material
White #f1f0eb, trim #e4e3de, plinth #9ea0a1, dormer brick #a5523e, gold #c9ac6a, slate PAL_ROOF_DARK.
Windows are kit panes lit by chance at night.

## Ground and night
Shop bays are dark glass; the two sign words are neon (REJNA, LIMONKA in `neon_signs.gd`).

## Detail level and budget
L3, 5613 triangles (budget 6800), +0 draw calls.

## Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | per-edge walls | 20.8 m | mapped ring, corner chamfered | M_STONE | white mass |
| mansard | slope quads | 2 m deep, 1.95 m rise | the three fronts | M_STONE | the mansard |
| dormers | box, kit_window, kit_pediment | 1.6 m | every bay | M_STONE | red dormers, white gables |
| windows | kit_window HOODED, ARCHED, SILL_HEAD, SILL | 1.2-1.7 m | 18 bays, 5 floors | M_PANE | the rhythm |
| balconies | kit_balcony STONE | 1.9-2.6 m | chamfer stack, two bays a front | M_STONE | balcony stack |
| shops | kit_shop_bay, kit_door | 2.6 m | ground floor | M_STONE | REJNA, LIMONKA |
| bands | kit_ledge, kit_bands, kit_cornice | whole fronts | plinth, 4.4 m, 18.4 m | M_STONE | storey bands |
