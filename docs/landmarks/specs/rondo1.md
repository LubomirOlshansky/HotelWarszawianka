# Rondo 1 (Rondo ONZ 1): spec

Site key `rondo1` in `game/scripts/landmarks.gd` (`TOWERS` entry, built by `_build_rondo1`). Written 2026-11-08 in a cloud thread from the top-50 photo set F gathered on the Mac (`warsaw-needed-photos/top-50/T03`, Wikimedia Commons photos, reference only, never shipped): T03-01 and T03-02 the roof from Varso, T03-03 and T03-06 the tower by night from Rondo ONZ, T03-05 the tower from the roundabout by day, T03-07 the skyline from the Palace, T03-08 the stepped back from Śliska. Massing from the OpenStreetMap parts in `centrum.json`. Brand as the parody EJ; the clinic's ENELMEDIK kept.

## 1. Identity

1. A long slab with a rounded north end turned to the roundabout, in silver-blue glass with light floor bands (T03-05, T03-08).
2. Its glass runs on above the roof as a screen of open framing, tallest over the rounded end (T03-02, T03-05).
3. A narrow graphite slab on the west side, flat-topped, the tenant's name on it with a yellow stroke (T03-02, T03-05; by night only the name burns, T03-03).
4. The back steps down to the south-west in glass (T03-08).
5. The red-and-white antenna to 192 m (T03-02, T03-05).

## 2. Massing

From the mapped parts: the slab with the rounded end, 159 m; the west block, about 12 x 10 m, 159 m (+1 m parapet); the steps 146, 125, 125 and 80 m; the 20 m base and, in the outline, the car park and the low neighbours in their mapped colours. The antenna's foot on the slab's long axis, 6 m south of its centre.

## 3. Facade, base to top

Base: the 20 m parts in darker glass (#7c8e9a), the car park in its mapped teal. Middle: the slab and the steps in silver-blue glass, S_BANDS. Top: the screen, 12 m of open framing (S_FRAME) over the rounded north end falling to 4 m at the south end, along the slab's whole edge; the west block's graphite (S_DARK) to 160 m, EJ and the yellow stroke on its north and south faces 3 to 9 m under the top.

## 4. Roof

The slab's roof pale grey inside the screen, a plant box (5 m in, 3 m), a 3 m lattice to 171 m, then the antenna in six red and white pieces to 192 m with a red lamp; parapets on the steps' roofs; three red aviation lamps.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Slab and steps | #8aa3b5 | M_SKIN S_BANDS |
| Screen | #b9c2c8 | M_SKIN S_FRAME |
| West block | #3b4147 | M_SKIN S_DARK |
| Base | #7c8e9a | M_SKIN S_BANDS |
| Roofs | #a9b3b9 | M_STONE |
| Antenna | #c8302a / #ecebe6 | M_STONE |
| Name, stroke | white, #ffdb1a | neon signs |

No new material or draw call.

## 6. Ground and night

The base, the slab, the block and the steps carry the car walls. At night the glass lights by the skin's rule, the west block stays dark with EJ and its stroke lit, ENELMEDIK over the ground floor, red lamps on the roof and the antenna.

## 7. Detail level and budget

L2; budget 900 triangles in `check_mesh_quality.gd` (769 measured; the rounded end has 20 facets, each walled twice, glass and screen).

Shots: `--solo=rondo1 --solo-look=lit --at=-1640,220 --yaw=320 --lift=90 --size=280` by day; the city from the south by day and night.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| slab | mapped outline, rounded north end | 75 x 22 m, 159 m | middle | S_BANDS glass | 1 |
| screen | walls on the slab's edge, sloped top | 12 m to 4 m | over the roof | S_FRAME | 2 |
| block | prism 0.15 m proud | 12 x 10 m, 160 m | west side | S_DARK | 3 |
| name | neon EJ and a stroke | share 0.55 and 0.4 | block, north and south | sign | 3 |
| steps | mapped outlines | 146, 125, 80 m | south-west | S_BANDS glass | 4 |
| base | mapped outlines | 20 to 32 m | ground | glass, car park teal | 1 |
| antenna | lattice and six pieces | 162 to 192 m | slab's axis | S_FRAME, red and white | 5 |
