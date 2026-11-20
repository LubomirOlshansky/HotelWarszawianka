# Port Praski (the district and its basin): spec

Site keys `port_praski` (the tenement blocks, Krowia 6, the Minter hotel, a courtyard deck) and
`pp_basin` (the lock, its control tower and pump houses, the pier's sheds, the boulevard, the
docks' hoarding) in `game/scripts/landmarks/praga.gd` (`_find_port_praski`). Written 2026-11-20
from 90 Mapillary street photos of 2019 to 2025, three aerial photos of Sierakowskiego 1-3 and the
basin, the OSM outlines and GUGiK's LoD2 (refs/port-praski, REPORT.md: the building table, the
lore and the photo index; never shipped). F asked for the whole district "with our best approach",
lively, with people, cyclists and jokes (2026-11-20).

## 1. Identity
1. A **new quarter of tenement-like blocks** (2015-2024) between Okrzei, Sierakowskiego and the
   basin: each block cut into 10-12 m sections, each section its own face (dark clinker, grey-brown
   brick, cream limestone with ledges, copper loggias, red brick, sandstone), a broken skyline of
   parapets, glass balconies, green roofs.
2. **Krowia 6**, the restored red-brick works: three storeys of arched windows, a white-framed glass
   storey set back on top, a new block behind.
3. The **Minter tenement** on Okrzei (now a hotel; our parody **HOTEL AHOJ**): warm plaster, a
   heavy cornice.
4. The **basin**: a lock (2017-2020) with striped gates, a red-brick control tower with a glass top,
   two pump houses, white sheds with blue window bands on the south pier, a pontoon with two boats.
5. The **boulevard** in front of Sierakowskiego 1-3 (opened October 2024): grey paving, a
   herringbone square, hooked lamps, benches and timber seating steps down to the water.
6. The **Docks are not built**: a black and blue hoarding in signal-flag colours, PORT PRASKI on
   it, our joke STATKI WKRÓTCE ("ships soon") on the water side.

## 2. Massing
Each block is its OSM outline (bent outlines through their convex hull for the zone), height from
LoD2 (h 18-27 m, 6-8 storeys), ground the lowest terrain under it. Krowia 6: strips 13 m deep along
the edges facing the photo corner (552.6, -1623) are the old works (13.8 m + 3.6 m glass storey),
the rest the new block. The Minter: 18.2 m. Basin: tower 10.9 m, pump houses 4.5 m, sheds 7.6 m.

## 3. Facade, base to top
Sections: the ordinary facade shader's windows (its seed per look: storey height and window
spacing), shops on the ground floor; piers between sections; ledges every second storey and a
cornice on limestone; frames at every slab on copper loggias; glass balconies (kit_balcony PARAPET in glass) in every third bay of some brick
sections. Krowia 6: arched windows on three floors (facade kit), a ledge at 4.6 m, a cornice slab.

## 4. Roof
Flat roofs at the block's height; sections lift their parapet 0, 0.9 or 1.8 m; a plant room and a
green patch on big roofs; a green courtyard deck (the podium of 7169).

## 5. Colour and material
Clinker #8a4434, grey-brown brick #857565, limestone #d9d0c0, copper #a0663f, red brick #a8553d,
sandstone #c9b79a, heritage brick #a34f39, Minter plaster #d8c39a; hoarding #151a22 and blues
#0e3b75 to #5ab7ea; paving grey, herringbone red-brown, timber #8a5a3a.

## 6. Ground and night
Lamps on the boulevard glow (M_LAMP); the tower's glass top and the glass storey are lit cool
(M_PAVILION + 0.5); windows light by the shader's seed like the city's. People sit on the steps and
along the boulevard (crowds.gd PORT_PRASKI, talk "port_praski"), the riders double near them.

## 7. Detail level and budget
L3, triangle budget 25000 for `port_praski` (an exception: a whole district of 13 buildings, about
1900 per building) and 8800 for `pp_basin` (check_mesh_quality BUDGET).

## 8. Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| blocks | OSM outline in 11.5 m sections | 18-27 m high | Okrzei to the basin | facade seeds, stone trims | broken skyline, loggias, balconies |
| works | brick strips + glass storey | 13.8 + 3.6 m | Krowia 6 (546, -1661) | heritage brick, glass | arched windows |
| minter | outline prism + cornice | 18.2 m | Okrzei (453, -1647) | warm plaster, typed tenement | HOTEL AHOJ sign |
| garden | podium 1.1 m | courtyard | 7169's yard (682, -1682) | green top | three trees |
| tower | brick + glass prism | 10.9 m | the lock (500, -1504) | brick, cool glass | lit control room |
| pumps | brick prisms | 4.5 m | by the lock | brick, grey roof | none |
| sheds | merged outline | 7.6 m | south pier | white render | blue window bands |
| lock | walls, gates, walkways | 56 m x 10.4 m | (492, -1494) to (548, -1506) | concrete, yellow-black | striped gates |
| pontoon | slab + two boats | 18 m | (556, -1524) | grey, red and blue | boats |
| walk | draped paving | x 620-686 | in front of Sierakowskiego 1-3 | grey, herringbone | lamps, benches, timber steps |
| hoarding | 2.5 m panels, 3 m high | two runs | round the Docks' site | signal-flag blues | PORT PRASKI, STATKI WKRÓTCE |
