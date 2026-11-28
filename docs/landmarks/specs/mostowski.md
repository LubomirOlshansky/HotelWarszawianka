# Pałac Mostowskich (Muranów)

Site `mostowski` covers the entire palace at Nowolipie 2 by al. Solidarności. The plan comes
from the named outline in `centrum.json` and the corresponding GUGiK run in `lod2.bin`
(footprint 1045 in `lod2.json`). The local `refs/mostowski/3dtiles/` face and orbit views
set the facade rhythm, roof profile and palette.

## 1. Identity

Corazzi gave the palace its neoclassical front in 1823. The front survived the wartime
destruction, and the palace was rebuilt after the war. It now houses the Warsaw Metropolitan
Police. The four Ionic columns stand above a three-arch base on the short southeast front.
Two long wings and two transverse ranges enclose three open courts.
[Warsaw Metropolitan Police history](https://ksp.policja.gov.pl/dzi/historia-pi/86696,Historia-Palacu-Mostowskich.html)

## 2. Massing

The southwest corner of the portico front is at game `(-1720.3, -1304.3)`. In plan, `u`
runs ENE along the front, `(0.853, -0.522)` in x/z, and `v` points SSE,
`(0.522, 0.853)`. The wings extend into negative `v`. Use terrain at the front entrance
as the common height datum. Sink the walls below the lowest ground under the ring.

| Block | Plan in metres | Height over entrance grade |
| --- | --- | --- |
| Main range | 51.1 wide, from v 0 back to about −12.6 | 13.35 eave, 17.2 ridge |
| Side wings | about 14–17 wide, from the main range to the angled back | 13.35 eave, 17.2 ridge |
| Cross ranges | between v −37.5 and −47.5, and −60.7 and −71.8 | 13.35 eave, 17.2 ridge |
| Rear range | about 18–20 deep, angled from v −124.2 to −116.2 at the back | 13.35 eave, 17.2 ridge |
| Front projection | u 13.1–37.9 at v 3.7, with the podium at u 19.0–32.4 out to v 6.0 | 17.75 shoulder, about 19.6 at the pediment |

The front court is about 23 × 25 m, the middle court about 19 × 13 m, and the rear
court widens from about 22 to 33 m and follows the skew of the rear wing. These dimensions
are rounded from the GUGiK court walls. Its ordinary eaves are around game y 22–23 m,
with the entrance grade near y 9 m and the front crest near y 29 m.

## 3. Facade, base to top

- Low stone plinth, then a rusticated main front and a projecting string course around 4.8 m.
- Three stacked window rows. At roughly 1.1, 6.0 and 10.4 m the openings are respectively
  about 2.5, 2.9 and 1.8 m tall. The first-floor windows have pale sills and heads, and the
  upper openings are compact. The two long exteriors carry about 30 bays apiece.
- The portico rises from a 4.8 m rusticated podium with three round-headed openings. Four
  columns at v 5.0 support the deep entablature and low pediment. Use the kit's flared
  capital as the Ionic silhouette. Narrow wings flank the colonnade, each with its own bay.
- Carry the three storeys, window rhythm and horizontal trim around the rear and into all
  three courts. The rear has seven close-set bays between two groups of four. Use flat
  panes for the smaller court openings and dark kit arches for the main doorways.

## 4. Roof

Low slate-grey roofs join at the two side ridges and the ridges of the transverse ranges.
Hip the outer corners and run the inner slopes down to all three courtyards. Give the
raised front projection its own shallow roof and place pale chimney stacks along the
main ridges. Roof apertures and seams are below the detail level.

## 5. Colour and material

Cream-yellow walls (#eee3c9), pale stone trim, a darker warm granite base and blue-grey roofs
(#9a9ba2; lightened from #818594 after a sampled 3D Tiles roof read #8f8e94 to #949093).
Use `M_STONE` for the walls, trim and roofs, and the kit's lit pane code for the windows.
Use pale sash on the larger openings and dark painted leaves for the doors.

## 6. Ground and night

Collide the mapped outside ring and the court edges. Keep each court open down to the
terrain. The palace uses the existing stone floodlit mode and the kit's night window lighting.

## 7. Detail level and budget

L3, triangle budget 7000. Reserve the detailed frames for the principal elevations and
the taller windows. All parts share the site's building surface.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shell | outer and inner walls | 51–52 × 116–124 m, eaves 13.35 m | mapped ring and three courts | M_STONE, cream plaster | continuous palace ranges |
| elevations | kit openings and horizontal trim | three storeys of openings | outer and court faces | M_STONE, M_PANE | regular neoclassical window bays |
| portico | podium, colonnade, entablature and pediment | 24.8 m projection, 13.4 m colonnade, crest about 19.6 m | centre of southeast front | M_STONE, pale trim | Corazzi's entrance |
| roofs | joined hips and pitched slopes | 3.85 m typical rise | around the three open courts and above the front projection | M_STONE, blue-grey | continuous roof silhouette |
| chimneys | masonry stacks and caps | about 1–2 m across | above the long ridges and cross ranges | M_STONE, pale trim | pale accents in aerial views |

## 9. Omitted details

Sculptural reliefs, the eagle, precise Ionic volutes, window hardware, roof seams and vents,
shallow exterior wall jogs, signage, courtyard objects and the neighbouring modern block.
Fine dimensions for facade trim, openings and chimneys follow proportions visible in the references.
