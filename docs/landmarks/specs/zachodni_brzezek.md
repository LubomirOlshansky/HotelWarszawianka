# Zachodni Brzeżek, a bar with a big terrace on Wioślarska (site `zachodni_brzezek`)

Written 2026-11-19 for the Vistula boulevards phase C: the parody of Zachodni Brzeg (BOULEVARD-INVENTORY
row 12). Source: F's photo (a wide timber-deck terrace before a grey concrete ground floor with
big white letters on its fascia, dark wooden tables and benches with blue cushions, many small
palms in wooden barrel planters, a glass balustrade along the roof edge above). **Open question
(QUESTIONS):** the inventory pins it at about (1085, 160) on Wioślarska 10 "ground floor of The Tides" (an
estimate, 30 to 60 m), but no outline stands there; the Tides' own model (`tides`) has no free river
face, and the nearest real wall is the rowing club's glass block (OSM `Warszawskie Towarzystwo
Wioślarskie`, 20.8 m, at 1099, 128) whose river-facing 31 m edge is dressed here. The Mac look
check settles which building the bar is in.

## 1. Identity

A low grey concrete ground floor along the block's river face with a pale fascia carrying
ZACHODNI BRZEŻEK in big white letters, glass doors between piers, a glass balustrade round its roof
terrace; before it a wide timber deck with dark tables, blue-cushioned benches and palms in wooden
barrels, bulbs on posts. A parody name (ZACHODNI BRZEŻEK for Zachodni Brzeg).

## 2. Massing

The block's edge facing the river (`_edge_facing` towards 0.86, -0.51; 30.9 m): a concrete box 4.2 m
tall, 4.1 m deep (0.2 m off the wall so it never shares the LoD2 wall's plane), the length of the
edge less 0.6 m; the deck 8.4 m deep and 2 m longer than the box, 0.25 m high, in front.

## 3. Facade

Five glass bays between 1.4 m concrete piers (0.3 to 2.5 m, M_PAVILION, dark glass) with a mid
transom and iron mullions; a pale concrete fascia band 2.5 to 4.05 m with the lettering (font
pixels 0.24 x 0.2 m, white `#f6f5ef`, M_LAMP: lit at night, ~23 m wide); no new window kit part.

## 4. Roof

A timber roof terrace on the box: a glass balustrade 1.1 m tall on the front and both returns
(pale glass, aluminium rail and posts every 3 m), four tables with cushioned benches and two palms.

## 5. Colour and material

Concrete `#a9a79f`, fascia `#b6b4ac`, glass `PAL_GLASS_DARK` / `PAL_GLASS_PALE`, timber `PAL_TIMBER`,
tables `#4b3a2e`, cushions `#2f6fb0`, barrels `#7a583a`, fronds `#4f8a46`. M_STONE, M_PAVILION, M_LAMP only.

## 6. Ground and night

The box on the lowest ground under its strip, the deck round it. Car collision on the box only. At
night the glass bays glow, the white letters light and three bulb strings glow over the deck.

## 7. Detail level and budget

L2. Budget 2500 (built 2016) in `check_mesh_quality.gd`: `zachodni_brzezek`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| box | box | 29 x 4.1 x 4.2 m | the block's river face | concrete, timber top | the grey concrete ground floor |
| doors | five glass quads + mullions | 4.6 x 2.2 m | the box's river face | M_PAVILION | the glass doors |
| letters | font pixels as lit faces | 0.24 x 0.2 m, 16 letters | the fascia | M_LAMP white | the big white letters |
| balustrade | glass quads + rail + posts | 29 m x 1.1 m | the roof's edge | pale glass, aluminium | the glass balustrade |
| deck | timber box | 31 x 8.4 x 0.25 m | before the box | timber | the wide terrace |
| tables | table + two benches | 2 rows x 6 + 4 | the deck and the roof | dark wood, blue cushions | the tables and benches |
| palms | barrel + trunk + six fronds | 2.1 to 2.7 m | the deck's edge and ends | wood, green | palms in wooden barrels |
| bulbs | wire + bulbs | 2 strings | over the deck's edge | M_LAMP warm | string lights |
