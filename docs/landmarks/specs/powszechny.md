# Teatr Powszechny im. Zygmunta Hübnera

Site `powszechny` at ul. Jana Zamoyskiego 20 in Praga. The plan comes from the named building
in `centrum.json` and the corresponding GUGiK LoD2 run. The local 3D Tiles top, face and oblique
views in `refs/powszechny/3dtiles/` establish the roof layout, facade rhythms and finishes.

## 1. Identity

1. A late-modernist theatre with long white office wings, two rows of square lights above
   the service base, and flat grey roofs.
2. A white fly tower rises on the east side of the north-central stage roof.
3. The west front has a long charcoal name band. Warm cladding sits below its north end
   and dark screened foyer glazing marks the public entrance to the south.
4. An open light court in the south-east quarter brings daylight to the offices.

## 2. Massing

The plan frame starts at map `(1636.1, -1474.2)`, with `u` east and `v` south in metres. The
envelope follows the mapped 42.7 × 72.1 m outline with its north-end jogs. Collision uses
the original map ring. Heights are measured from the terrain at the west lobby.

| Block | Plan in metres | Roof height |
| --- | --- | --- |
| Office ring | Mapped outer ring around the light court | 10.9 m |
| North-east annex | North jog from u 20.4 to 36.5, back to v 10.0 | 12.2 m |
| Auditorium | u 4.5 to 20.0, v 10.5 to 31.5 | 12.5 m |
| Foyer roof | u 6.3 to 20.3, v 34.5 to 61.5 | 11.8 m |
| Stage and fly tower | Stage roof u 20.1 to 35.3, v 23.8 to 41.5. Tower u 20.3 to 35.0, v 24.2 to 34.4 | 11.5 m and 18.6 m |
| Open court | u 22.6 to 34.8, v 41.6 to 63.6 | Open to the paving at −0.4 m |

The LoD2 levels are about −3.8 m on the office roof, −2.6 m on the north annex and +4.0 m
on the fly tower in map elevation. The stage base and two western roof steps follow the
relative levels visible in the obliques. Walls extend below the surrounding terrain.

## 3. Facade, base to top

- The public west face reads from north to south in its own kit frame. The warm upper wall
  occupies roughly 25 m. A smaller canopy marks a doorway in this wall. The adjoining 26 m
  dark foyer is recessed 0.9 m from the main wall, with grouped glazed doors and a glazed
  screen above them. The dark fascia spans roughly 49 m over both sides, with pale capitals.
- The east and south elevations have two closely spaced rows of square windows at sill
  heights 4.8 m and 8.0 m. The ground floor combines shorter window runs, muted brick panels
  and service doors. The north elevation has more solid wall and four upper lights on the
  projecting annex, beside a tall service opening. Use facade kit parts for openings and
  horizontal trim.
- The east, south and north court walls continue the office rhythm. The wall below the
  foyer roof has lower punched openings and one dark upper ribbon of glazing.

## 4. Roof

Mid-grey flat roofs (`#b9babc` before the stone shading, which renders close to the top view's
roof grey; the first value `#8b8c8c` rendered dark brown-grey, audit 2026-11-27) with thin pale
edges, slightly lighter over the auditorium. Low silver
duct runs turn around the southern roof and serve the fly tower from the north. A long pair
of housings sits above the auditorium's south edge. Add the tower's pale roof housing and
retain the thin edge around the open court.

## 5. Colour and material

Use `PAL_WHITE_STONE` and `PAL_PALE_CONCRETE` for cladding and trim, `PAL_SANDSTONE` lightened
for the cream west panels, and subdued brick at the service base. Roofs are shaded from
`PAL_ROOF_PALE`, ducts are pale aluminium and the name band is dark steel with pale letters.
Stone, ducts and lettering use `M_STONE`. Office windows and the foyer glazing use the kit's
lit panes.

## 6. Ground and night

Follow the mapped outline for car collision and keep the entrance landing near street grade.
The facade kit lights individual windows after dusk. The letters are pale solid faces.

## 7. Detail level and budget

L3, triangle budget 6000. Allow up to 3400 for facade openings and trim, 850 for the masses
and court, 600 for rooftop equipment, and 700 for the west fascia and lettering.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | polygon walls with a recessed bay | 42.7 × 72.1 m, 10.9 m high | mapped envelope | M_STONE, white and cream | office wings and lobby recess |
| offices | kit openings, string courses and doors | 1 m square lights, two upper rows | east and south wings, north annex | M_PANE and M_STONE | repetitive modernist cladding |
| foyer | kit doors and glazing, landing and canopy | 26 m main screen | west, towards the south | M_PANE and M_STONE | public entrance |
| sign | slab and pixel capitals | 49 m fascia, letters 1.7 m high | west roof edge | M_STONE, dark steel and white | TEATR POWSZECHNY |
| court | inner walls, paving and kit openings | 12.2 × 22 m | south-east quarter | M_STONE and M_PANE | true roof opening |
| roofs | flat caps and raised roof blocks | 10.9 to 12.5 m high | office ring, foyer, auditorium and north annex | M_STONE, grey and white | stepped silhouette |
| tower | rectangular block and coping | 14.7 × 10.2 m, top 18.6 m | north-central stage | M_STONE, white and grey | fly tower |
| plant | rectangular housings, ducts and vents | 0.4 to 1.8 m high | stage, tower, auditorium and roof perimeter | M_STONE, aluminium and grey | rooftop services |

## 9. Left out

Interiors, individual advertising frames, lettering after the theatre name, courtyard furniture
and small mechanical fittings. The east face view is blocked by its neighbour and trees hide
parts of the entrance, so the obliques guide the rear bays and door spacing.
