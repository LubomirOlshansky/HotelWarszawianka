# Meridian (Wola)

Site key `meridian`, a whole-building model in `game/scripts/landmarks/wola.gd`.
The seven local obliques in `refs/meridian/3dtiles/` show the open court, the
balconies and the difference between the two roof levels.

## 1. Identity

Meridian wraps two pale wings around a court open to the southeast. The lower
western wing turns a chamfered corner on the street and has a gently curved
court side. A taller bar turns into the east wing with a broad blank wall at
its court-side tip. The glazing and balcony rhythm reflect the mapped
building's apartment use.

## 2. Massing

The named OSM ring (centrum building 7387) spans x −2691.2 to −2623.7 and z
−348.2 to −263.0. The origin is (−2657.45, −305.6), u runs along the north
bar (52, −30) normalized and v runs perpendicular south. The envelope is
about 70 m by 68 m in this frame. The western wing is ~20 m deep and the
eastern wing ~17–23 m deep. The court widens towards the open end, following
the mapped bow in the western wing.

GUGiK run 689 gives primary roof elevations y ≈37.4 and 43.4, or about 26.2
and 32.4 m above local grade. The map tag is 30.7 m. The higher volume
splits from the low roof on a diagonal from u −15.6, v −25.4 to u −16.4,
v −10.1, then along the north side of the court. The replacement zone
includes the LoD2 run centre in the air above the court opening.

## 3. Facade, base to top

- **Street base.** A roughly 4 m tall ground floor with darker stone and
  large glazed shop bays, including a door on the low chamfer.
- **Lower wing.** Seven floors at about 3.2 m pitch. White balcony edges run
  across the long elevations and around the chamfer, with pale piers in the
  gaps between paired dark openings. The court side follows its curve.
- **Higher wing.** Nine upper floor rows in total. Pale stone frame,
  shadowed balcony bays and narrower punches against the court. The wall
  at the tip and the side of the upper step are largely blank.

## 4. Roof

Warm-grey membrane with thin pale copings. Both levels carry small vent
clusters. A higher service room, about 6 by 4 m, sits inside the northeast
roof, along with smaller plant. The court stays open from top to ground.

## 5. Colour and material

Warm ivory for main walls, pale cream slab edges, warm grey-beige roof and
dark grey-brown for the recesses. Walls and ledges use `M_STONE`, window
and storefront bays use `M_PANE`, and the lower balcony fronts have muted
brown-grey guards in `M_STONE`.

## 6. Ground and night

The mapped ring supplies street collision, including its court returns.
Use one terrain datum, bury the foot 0.7 m, and use the kit's pane lighting.
The roof grid follows the stepped wings.

## 7. Detail level and budget

L3, triangle budget 3500. Use individual pane quads and put ledge depth on
the long balcony runs and the lower wing's chamfer.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | U-shaped body with an L-shaped upper step | about 70 x 68 m, roofs at 26.2 and 32.4 m | mapped outer ring and court returns | M_STONE | open court and two roof heights |
| glazing | kit panes, ledges and doors | 7 or 9 rows above the ground floor | street and court walls | M_STONE / M_PANE | varied bays, deep balconies and pale slabs |
| plant | parapets and boxes | equipment up to 2.8 m high | both roofs | M_STONE | pale roof rims and clustered vents |

## 9. Left out

Individual balcony contents, rail fixings, shop signage and rooftop vent
ductwork. Balcony and bay sizes are inferred from the visible facade rhythm.
