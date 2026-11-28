# City Gate (Wola)

Site key `city_gate`, a whole-building model in `game/scripts/landmarks/wola.gd`.
The six local obliques in `refs/city_gate/3dtiles/` show the curved north wall,
the folded south elevation and the round plant enclosure on the low east wing.

## 1. Identity

City Gate runs along Wolska just west of the roundabout. White floor bands
frame a wide, bowed dark curtain wall on the road side. On the south side the
glass reads turquoise, with a multi-faceted bay through the middle. The low east
wing ends in a round rooftop enclosure.

## 2. Massing

The named OSM ring (centrum building 7355) spans x −2896.5 to −2782.3 and z
−392.3 to −344.8. The local origin is (−2839.4, −368.55), with u east along
the main south wall, vector (114, −32) normalized, and v perpendicular south.
The plan is about 119 m long and 28 m deep in this frame. The upper body ends
at u ≈26 m and the low east wing continues to u ≈59 m. The central roofhouse
runs roughly u −39 to 8 m. The curve follows the mapped north edge. The
small south-facing folds retain the direction changes visible in the obliques.

The map tag is 47.2 m. GUGiK run 1015 puts the east wing roof at y ≈38,
the main roof at y ≈63.2 and the central roofhouse at y ≈67.7. With local
ground near y 11 the model uses +27, +52.2 and +56.7 m, respectively.
The buildings north and south of the east wing have separate map outlines.

## 3. Facade, base to top

- **Base and east wing.** A 4.6 m dark glazed ground floor with a south entry.
  Six upper rows at about 3.7 m pitch. Pale horizontal bands follow the
  curved east wing and the lower bow on Wolska.
- **Upper body.** Seven rows at 3.6 m pitch above the wing roof. Pale projecting
  ledges frame the taller glazing across the centre of the north wall. On the
  south side, white bands alternate with teal strips and taller dark glazed
  rows at the folds. Mullion spacing is represented by roughly 3–3.7 m bays.
- **Roofhouse.** Light grey cladding and a short glazed strip above the south
  curtain wall.

## 4. Roof

Dark flat decks with pale coping. The tallest roof carries clustered air
handlers and two short stacks. The east wing carries a roughly 12 m diameter
drum with a recessed dark centre and a low pale rim, reaching about 33.5 m.
Equipment sizes and positions are read approximately from the obliques.

## 5. Colour and material

Cool white slab edges, dark blue-grey backing and coal-grey roof use
`M_STONE`. Kit panes use `M_PANE` in blue-grey on the north, with teal and
a few greener strips on the south. The round enclosure has a dark glazed foot.

## 6. Ground and night

Use one terrain datum and sink the walls 0.7 m to cover the ground under
the footprint. Collide the mapped outline. The kit varies the lit panes at
night and the flat roof surfaces feed the roof grid.

## 7. Detail level and budget

L3, triangle budget 3500. Use flat shared-kit panes and omit the individual
mullion profiles. Reserve the silhouette detail for the bent curtain wall,
the stepped deck and the circular enclosure.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | two joined prisms | 119 m x 28 m, roofs at 27 and 52.2 m | mapped ring | M_STONE | bowed main block and low east wing |
| glazing | kit panes, ledges and doors | 4.6 m base, 13 upper rows | all outer faces | M_PANE / M_STONE | turquoise glass, white ribbons and dark central bow |
| crown | tier and slit | 47 m long and 4.5 m high | centre of the main deck | M_STONE / M_PANE | raised grey roofhouse |
| plant | boxes, stacks and a round rim | drum 12 m across, plant up to 59 m | on the three roof levels | M_STONE / M_PANE | mechanical equipment and recessed eastern rotor |

## 9. Left out

Tenant signs, individual roof grilles and the rotor's fine radial fins. Small
glazing folds, coping depth and plant layout are estimated from the obliques.
