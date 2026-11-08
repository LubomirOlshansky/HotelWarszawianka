# Centrum Marszałkowska (Marszałkowska 126/134): spec

Site key `cmarsz` in `game/scripts/landmarks.gd` (`_find_cmarsz`, `_build_cmarsz`, `_cm_leds`).
Written 2026-11-08 from F's photo set (folder N1-marszalkowska: corner by day and by night, the
straight front, the aerial; shared copy in the project files under `pkin-surroundings/photos/`).
It replaces the photo-front entry b5494 and the street block 579369105 (`CM_BLOCK`), which drew
the same footprint with plain windows.

## 1. Identity

The 2015 glass office building on the corner of Marszałkowska and Świętokrzyska, opposite the
Palace. What makes it read: pale blue-green glass in tiers that step back towards the top, dense
upright aluminium fins on every face, and at night short white LED strokes on the fins in a
staggered dash pattern; a dark shop storey with the store's name; two office names on the top.

## 2. Massing

From the map's OpenStreetMap parts inside the landmark outline (parts with h > mh, area > 30 m²):
the podium 0 to 8.9 m, a tier to 17.8 m, the main tier to 34 m, the corner block to 40 m. A tier
starts no lower than the podium's top. The 4 m posts of the arcade are left out.

## 3. Facade, base to top

A dark shop storey (0 to 4.4 m, lit glass), then curtain wall (M_GLASS) with fins every 1.35 m
standing 0.18 m proud; every fourth fin carries a short LED stroke per 3.7 m storey, the strokes of
one storey two fins over from the one below.

## 4. Roof

Flat grey roofs on each tier; a 0.6 m parapet only where no higher tier stands on the top (two
coplanar faces flicker).

## 5. Colour and material

Glass #6f98a4 (M_GLASS), shop storey #2f3a42 (M_PAVILION), fins #c9d0d4 (M_STONE), LED strokes
#e6eef6 (M_LAMP, glowing at night), roofs #6f7477.

## 6. Ground and night

The shop storey glows; the LED strokes glow white; office windows come from the glass shader.
Signs (parodies): SEZON in cyan over the shops on the west front, HEJ! in blue and SPACJE in
white on the top tier's west and north edges.

## 7. Detail level and budget

L2, triangle budget 2200 (built 1913), in `game/tools/check_mesh_quality.gd`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism | podium part, 4.8 m | 0-4.4 m | M_PAVILION #2f3a42 | shop storey |
| podium | prism | podium part | 4.4-8.9 m | M_GLASS #6f98a4 | curtain wall |
| tiers | prisms | OSM parts | 8.9-40 m | M_GLASS #6f98a4 | stepped tiers |
| fins | quads | 0.14 m, every 1.35 m | every face | M_STONE #c9d0d4 | aluminium fins |
| leds | quads | 0.34 m x 2 m, every 4th fin | per storey, staggered | M_LAMP #e6eef6 | LED strokes |
| parapets | prisms | 0.6 m | uncovered tops | M_STONE #c9d0d4 | parapet |
| signs | 3 neon words | 1.4-2.4 m letters | shop band, top edges | sign | SEZON, HEJ!, SPACJE |
