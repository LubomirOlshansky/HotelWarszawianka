# Unique Tower (Grzybowska 51, Wola)

Site key `unique`, a whole-building model in `game/scripts/landmarks/wola.gd`. The
Street View sequence in `refs/unique/streetview/` was reviewed in full. The 6YmWZ, Oo6fdnms
and DLTbaA6 views show the complex. Street and elevated photos show the crown, stepped
terraces and south block. The older tiles in `refs/unique3/3dtiles/`
show the plot and its neighbours before construction. The `refs/unique/3dtiles/` set is
centred farther west and also predates the tower. [Street photos](https://www.hamiltonmay.pl/inwestycja/Inwestycja-Unique-Tower-Mieszkanie-Grzybowska-Wola,13363.html), [elevated photo](https://hamiltonmay.s3.amazonaws.com/n/njckaKZb5NFkCfctQ.jpg).

## 1. Identity

1. An apartment tower at Grzybowska 51 with a rounded northwest corner, a slim champagne
   accent and a dark, nearly flat crown. It also houses the Royal Tulip apartments.
2. White slab edges follow the bends of the tower, in front of anthracite cladding, blue-grey
   glazing and glass balcony guards.
3. An attached mid-rise shoulder and a separate-looking south block share a five-storey
   street base. The roofs step down towards the south.

The contractor's catalogue lists 29 above-ground storeys and 91.3 m, and gives 96.3 m overall.
The model divides those heights between the occupied roof and the screened rooftop plant.
The architect describes the rounded modernist corner, horizontal slabs, five-storey base
and champagne accents. [Contractor's catalogue](https://www.unibep.pl/images/Dla_mediow/katalog/2024/UNIBEP_katalog_handlowy_-_07_2024_-_EN.pdf), [architect's description](https://www.uniquetowerwarszawa.pl/artykul.html).

## 2. Massing

Frame origin `(-2358.5, 5.3)` at the rounded corner's west tangent. The local axis u
(`_a`) points east along the frontage near Grzybowska, `(0.96, -0.28)` normalized.
Axis v (`_b`) points south into the block, perpendicular to u. Positive game x is
east and positive z is south. Heights share one terrain datum under the podium ring.

| Block | Local plan in metres | Heights above datum |
| --- | --- | --- |
| Joined podium | u 0–31, v −3–87, with the open west recess at v 40–63 | −0.65 to 17.2 m |
| North block and shoulder | u 0.7–30.2, v −2.3–39.5, rounded at the northwest and notched on the north | 17.2 to 55.6 m |
| Upper north tower | u 0.7–30.2, v −2.3–22.2, matching the north profile below | 55.6 to 91.3 m, screen and plant to 96.3 m |
| South block | u 0.8–26.4, v 64.1–86.1, lightly chamfered | 17.2 to 57.4 m, plant to 59.3 m |

Centrum outlines 7250 and 7249 are both tagged 91 m. The former contains the tower, shoulder
and podium connector, and the latter is the south block. Both are in `lod2.json`'s
`keep_osm` list. No LoD2 footprint centre belongs to either outline. The nearby LoD2
runs 992 and 232/313 instead match JM Tower and the buildings east of the complex.
The low west runs 334/335/1160, and the north runs 311/312, are across the drive or
beyond the north end. Register by an interior point in each of the two mapped outlines,
with a 3 m margin for replacement. The streamed index omits both outlines, so it uses the
authored podium ring with the same margin. Street block 905863487 matches outline 7250
and is excluded by the whole-building replacement list.

## 3. Facade, base to top

- **Podium**. Recessed dark lobby glass and broad bays between warm piers. The 5 m
  ground storey sits below four 3.05 m levels. Shallow slab ledges band all four floors.
  The entry doors sit on the street side of each block.
- **Shoulder and south block**. Twelve levels above the podium at pitches of 3.2 m and
  3.35 m. The white ledges project 0.78 m over the darker core. Blue-grey guards rise
  0.83 m off the ledges on the courtyard and street faces. Flat lit openings sit in bays
  about 3.35 m across, separated by dark wall strips.
- **Upper tower**. Eleven floors at about 3.24 m above the shoulder. The bands continue
  around the rounded northwestern corner. Champagne picks out that stack and the crown.

## 4. Roof

The completed aerial views show flat roofs, a charcoal equipment screen on the tallest
tower, and smaller screened equipment on the lower blocks. The main roof sits at 91.3 m,
with a champagne strip across the rounded corner of the 2 m crown and set-back plant
inside. The shoulder roof steps down south of the main shaft and leaves a planted
terrace. The south block has a smaller flat roof and charcoal rooftop plant.

## 5. Colour and material

Read by eye from the completed daylight photos and adjusted for the game. Slab fronts
`#f2f2ed`, cladding `#393e45`, champagne metal `#b7a080`, stone piers
`PAL_WARM_GRANITE`, roof `#92948f`, rooftop screen `#41464d` all use `M_STONE`.
Glazed openings use `#62798b` and `M_PANE`. Balcony glass uses `#536979` and
`M_GLASS`. Planting in the terrace uses muted olive `#69704c` in `M_STONE`.

## 6. Ground and night

The podium ring stops cars at pavement level. Lower the walls 0.65 m under the datum
to meet the sloping ground. The roofs enter the shared roof grid for helicopter flight
and tapping. Apartment and lobby panes use the shared night variation.

## 7. Detail level and budget

L3, triangle budget 7000 (6888 measured). Slab and soffit geometry carries the horizontal profile and
corners. The facade kit uses single quads for apartment openings. Review all sides and
the tops in the turntable, then check the city replacement.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| podium | continuous prism, kit door, piers and glazing | 31 x 90 m at extents, 5 storeys | joined outlines 7250 and 7249 | M_STONE / M_PANE | connected street base |
| blocks | stepped prisms with flat roofs | 11 and 12 upper floors per tier | north, shoulder and south above podium | M_STONE | three-part silhouette |
| bands | kit ledge rings with slab soffits and glass guards | projections up to 0.78 m, white edges 0.64 m | podium and apartment floors | M_STONE / M_GLASS | white horizontal bands and balcony depth |
| glazing | kit panes over recessed wall faces | about 3.35 m per bay | floor rows on all three volumes | M_PANE | dark ribbon windows |
| crown | parapet with metallic corner strip | 2 m high | north roof edge | M_STONE | champagne accent and flat roofline |
| terraces | inset roof planting beds | broad bands of low planting | shoulder roof south of upper tower | M_STONE | stepped roof terraces |
| plant | dark equipment enclosures | up to 5 m tall | set back on each top | M_STONE | stepped rooftop silhouette |

## 9. Left out

Brand lettering, individual balustrade fasteners, apartment interiors and the exact HVAC
layout. Floor setbacks, equipment sizes and the least visible back elevations are estimated
from the outline and oblique photographs.
