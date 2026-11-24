# Sienkiewicza 3, the block opposite (site `sienkiewicza3`)

Photo: `/mnt/project-files/refs/sienkiewicza/f-sienkiewicza2-streetview.png` (never shipped). The
photo's arcade fits the OSM building centred at (-761,-26) (h 20.8, mh 3.3, with its 4.3 m base and
the east wing), the south side of the street opposite no. 4.

## Identity
A 1950s socialist-classicist block: a grid of sandstone piers with deep windows, reddish stone
panels in some pier bays, a long balustraded balcony over a recessed arcade with square pillars,
steps up to it and a passage through to the south.

## Massing
Replaces the three mapped outlines. The upper floors stand 2.2 m behind the front line; the balcony
slab and arcade fill the gap. A 4.4 m wide passage (u 11.6-16.0 from the east end) cuts the whole
depth of the ground floor. Front 27.5 m from the east end of the wing to the west party wall.

## Facade
Base: three steps, an arcade floor at 0.6 m, six pillars (two end blocks), doors and grilled
windows on the back wall, a slab with fascia at 3.7-4.3 m and a balustrade to 5.3 m. Middle: 13 bays,
fourteen full-height pilasters (every third in the reddish stone), five floors, sills 4.6, 7.9,
11.2, 14.5, 17.8 m, ledges under the windows. Top: a deep cornice at 20.2-20.8 m.

## Roof
Flat gravel at 20.8 m.

## Colour and material
Sandstone #d6c3a0, light stone #e3d4b5, pillars #c4ae86, red panels #b98471. Windows kit panes.

## Ground and night
Steps and platform in grey granite; the passage is open. Panes light by chance at night.

## Detail level and budget
L2, 2633 triangles (budget 3200, an exception to the L2 limit of 3000: 14 piers, 65 windows and the arcade), +0 draw calls.

## Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| ground | prism with passage | 4.3 m | mapped ring, front back 2.2 m | M_STONE | street level |
| floors | prism | 16.5 m | over the ground | M_STONE | five floors |
| arcade | slab, soffit, steps | 27.5 x 2.2 m | in front, 0-4.3 m | M_STONE | balcony over arcade |
| balustrade | kit_attic BALUSTRADE | 27.5 x 1 m | 4.3 m | M_STONE | long balustrade |
| pillars | boxes | 0.9 m square | u 4.9, 10.4, 17.2, 22.0 and ends | M_STONE | square pillars |
| piers | kit_pilaster | 0.9 x 15.7 m | 14 piers | M_STONE | pier grid, red panels |
| windows | kit_window SILL | 1.1 x 1.7 m | 13 bays, 5 floors | M_PANE | deep windows |
| cornice | kit_cornice | 27.5 m | 20.2 m | M_STONE | top |
