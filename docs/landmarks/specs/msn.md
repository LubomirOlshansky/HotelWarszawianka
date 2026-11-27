# Muzeum Sztuki Nowoczesnej (MSN): spec

Site key `msn` in `game/scripts/landmarks/centre.gd` (`_find_msn`, `_build_msn`). First written
2026-10-31 from the OpenStreetMap parts; **v2 2026-11-26** (F: "the real look, the windows") from
photos of the finished building. Google's 3D Tiles still show the old car park here (checked
2026-11-26), so v2 rests on: Street View panoramas of Marszałkowska from June 2026 and August 2024
(`refs/msn/streetview/`, measured by casting each picture column onto the facade plane from the
panorama's position and heading), the Commons photos `refs/msn/1.jpg` to `4.jpg` and the GUGiK
orthophoto `refs/msn/ortho.jpg` (all working-copy references, never committed).

v2 found two errors in v1: `4.jpg` was taken from the **south** corner (Marszałkowska by Złota:
the Palace shows on its left), not from Świętokrzyska, so the windows it shows are on the south
end; and the dark slot is not a ribbon all round but a seam where the upper box overhangs the
lower one, glazed only in a few long runs.

Critique before the build (Fable, photo first, 2026-11-26): agreed on the ribbon runs, the south
end's window pair and the misplaced w6; added the lower ground floor, the roofline step, the glazed
light wells and moved w1, the entrance cut and the south window. Open: the north end has no
daylight photo (w4, w5 from F's night photo).

## 1. Identity

Thomas Phifer's museum (opened October 2024) on Plac Defilad's east edge, its long side on
Marszałkowska, the Palace of Culture behind it. What makes a passer-by say its name:

1. **One long, low, plain white box**, 104 x 40 m and 26 m high, against the Palace's ornament.
   No cornice, no parapet: a clean edge at the roof.
2. **Two stacked boxes**: the upper box (15 to 26 m) overhangs the lower one (5 to 14 m) by
   0.4 m on every side, with a shadowed seam between them; in places the seam is a long, thin
   ribbon window.
3. **The box floats** on a glazed ground floor set back under a white soffit, behind deep white
   piers.
4. **Few, large, deliberate windows**, all different, punched into the white: the deep "city room"
   cut-out on Marszałkowska, the wide window towards the Palace, the tall entrance cut on Plac
   Defilad, a handful of single windows. Most of the wall is blank.
5. **A gridded glass roof** with two small light wells, glowing at night (the game's view).

## 2. Massing

Plan axes (local u, v in metres): origin (-1022.4, 100.15); u along the long side at 69.85°
(world direction (0.3445, 0.9388)): u < 0 is the north end (Świętokrzyska), u > 0 the south end
(Złota). v = (-0.9388, 0.3445): +v the Plac Defilad face (towards the Palace), -v Marszałkowska.

| Volume | Plan (local) | Heights above ground | Source |
| --- | --- | --- | --- |
| Glazed core (ground floor) | u -45.8..45.8, v -13.95..13.95 | 0 to 3.5 m | photos: people for scale give 3 to 3.5 m (OSM said 5) |
| Lower box | u -51.45..51.45, v -19.5..19.5 (0.4 m in from the outline) | 3.5 to 12.5 m | photos: the upper box overhangs (4.jpg, Street View) |
| Seam | u -51.05..51.05, v -19.1..19.1 (0.8 m in) | 12.5 to 13.6 m | F's dusk photo of the Marszałkowska face, straight on (2026-11-26): ribbon 12.3-13.3 m |
| Upper box | the outline, u -51.85..51.85, v -19.9..19.9 | 13.6 to 26.0 m | F's dusk photo (OSM's 12.5/13.8 were close) |
| South-east panel | u 51.85..52.25, v -19.9..-7.9 | 15.0 to 27.4 m | 3.jpg, 4.jpg: the east part of the south end stands proud and higher |
| Roofline step | upstands 0.4 m thick on the edge: +v u 8..51.85, the south end (F's dusk photo: the Marszałkowska edge is flat) | 26.0 to 27.1 m | Street View 2026 h252, 3.jpg, 4.jpg: the south part of the box is about a metre higher |
| Corner block | u -64.3..-51.85, v 16.5..27 | 0 to 25.0 m | OSM (unchanged) |

## 3. Facade, base to top

Ground floor (0-3.5 m): the glazed core, a flat white soffit at 3.5 m from the core out to
the lower box's edge, 29 piers (1.0 x 3.0 m) at the OSM positions: Marszałkowska face (v -17.4)
u = -50.4, -39.4, -26.4, -18.4, -10.4, 0.4, 7.4, 15.3, 26.4, 33.8, 40.8, 50.4; Plac Defilad face
(v +17.35) u = -50.4, -39.5, -32.5, -26.5, -18.5, -10.6, 0.4, 7.3, 15.2, 26.2, 33.7, 40.7, 50.3;
the ends turned 90° (north u -49.4, v 3.95 and -8.5; south u 49.4, v 6.3 and -8.55).

Lower box (3.5-14 m), upper box (15-26 m): blank white walls but for the openings below. The seam
(14-15 m): a white, shadowed band 0.8 m in, glazed only in the ribbon runs. A white ledge on the
lower box's top (14 m, 0.4 m) and the upper box's underside (15 m, 0.8 m).

Every window is set 0.4 m into the wall (deep reveals are the building's look: no flush glass),
the loggia and the entrance cut 3 m. Glass #8fa9b6 lit warm at night; the ribbons darker #526872.

| Face | id | Along (u or v) | Height | Depth | Evidence |
| --- | --- | --- | --- | --- | --- |
| Marszałkowska (-v) | loggia | u -4.2..9.8 | 15.7-20.9 | 3.0 | SV 2026 h252 (straight on), h215, h300, 4.jpg |
| Marszałkowska | win_mn | u -33.4..-30.3 | 15.5-19.5 | 0.4 | SV 2024 h256, 4.jpg far end |
| Marszałkowska | low_mc | u -7.7..-0.3 | 6.8-9.7 | 0.4 | SV 2026 h252, h300 |
| Marszałkowska | low_ms | u 16.0..23.4 | 6.8-9.7 | 0.4 | SV 2026 h252, h215, h250 |
| Marszałkowska | low_mn | u -32.4..-30.3 | 6.8-9.0 | 0.4 | SV 2024 h256 |
| Marszałkowska | rib_ms | u 18.0..51.0 | 12.6-13.5 | seam | SV 2026 h250, 4.jpg |
| Marszałkowska | rib_mn | u -45.5..-0.5 | 12.6-13.5 | seam | SV 2026 h252, h300; SV 2024 h256 |
| Plac Defilad (+v) | w1 | u -9.0..9.0 | 15.2-20.8 | 0.4 | 2.jpg (from the Palace), 3.jpg |
| Plac Defilad | entry | u 14.0..23.0 | 3.5-10.5 | 3.0 | 2.jpg (the MSN letters), 3.jpg |
| Plac Defilad | low_pc | u -9.0..3.0 | 6.8-9.7 | 0.4 | 3.jpg |
| Plac Defilad | low_pn | u -27.0..-24.5 | 7.3-9.5 | 0.4 | 2.jpg |
| Plac Defilad | rib_pn | u -43.0..-31.0 | 12.6-13.5 | seam | 2.jpg, 3.jpg |
| Plac Defilad | rib_ps | u 20.0..49.0 | 12.6-13.5 | seam | 2.jpg, 3.jpg |
| South end (+u) | win_s | v -7.5..-1.5 | 15.3-20.5 | 0.4 | 3.jpg, 4.jpg (three mullions) |
| South end | low_s | v -3.3..-1.5 | 6.3-10.4 | 0.4 | 3.jpg, 4.jpg (narrow, under win_s's west edge) |
| North end (-u) | w4 | v -15.0..-9.0 | 15.6-22.0 | 0.4 | F's night photo 2026-10-31 (no daylight photo yet) |
| North end | w5 | v -14.0..-11.5 | 6.8-9.3 | 0.4 | F's night photo |

v1's flush w3 (Plac Defilad, lower) and w6 (Marszałkowska, near the south end) are gone: no photo
shows them (w6 is win_mn, at the north end).

## 4. Roof

Flat at 26.0 m, no parapet, checked again against `ortho.jpg` (2026-11-26): one gridded glass
field (M_GLASS_ROOF, lit warm at night) inside a 2.2 m white edge (#d9d8d2), two square light
wells glazed flush with the roof in darker glass (#7d97a2; v1 cut them as open courts, the ortho shows glass), 8 x 8 m at (5, 4.9) and 7 x 7 m at (31.5, -0.6) (measured again on the ortho:
(5.4, 4.9) and (31.5, -0.8)). New: the plant, two fans in a grey housing at u -12.5, v 1.8
(3 x 6 m, 1.2 m high). The roof edge steps up 1.1 m over the south part (the upstands), the
south-east panel 1.4 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| White walls, piers, soffits, ledges, reveals | #ebe9e3 (reveals a step darker) | M_STONE |
| Seam band (unglazed) | #c9c8c2 (the shadow under the overhang) | M_STONE |
| Roof edge | #d9d8d2 | M_STONE |
| Ground-floor glass | #a9c3cd | M_PAVILION |
| Windows | #8fa9b6 | M_PAVILION (warm at night) |
| Ribbon windows | #526872 | M_PAVILION (warm at night) |
| Roof glass, corner block top | #cfd8dc | M_GLASS_ROOF |
| Light wells | #7d97a2 | M_GLASS_ROOF |
| Fan housing | #9a9d9e | M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

**Night (F's night photos, 2026-11-26):** the white walls, piers and soffit are floodlit (M_MEMBRANE
+ 0.5, a lit wall), the gallery roof is dark, not lit (M_GLASS_ROOF + 0.75: the grid by day, dark at
night with a few faintly lit cool panels), the light wells glow dimly (M_MEMBRANE), the windows,
ribbons and ground floor glow warm. The opening-night projections on the walls are not modelled.


Unchanged: the square's paving and planting round it (other items), the car stopped at the box's
outline. At night the ground-floor glass, the windows and the ribbons glow warm, the unglazed seam
stays a dark line, the white box takes the street light. Card: "Muzeum Sztuki Nowoczesnej", PL
"Biały gmach Thomasa Phifera przy Placu Defilad. Otwarty w 2024 roku.", EN "Thomas Phifer's white
museum on Plac Defilad. Opened in 2024." The Palace of Culture's site is next door: nothing here
leaves the museum's outline and the corner block.

## 7. Detail level and budget

L3 (a first-scene hero), triangle budget 900 (v1 412, v2 630 measured; v2 adds 15 recessed openings with reveals,
the ribbons, the cut walls round them, the panel and the fans), in `check_mesh_quality.gd`
BUDGET. Shots: the turntable (`tools/turntable.sh msn`), then in the city from Marszałkowska at
day and night.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| core | box, glass walls only | 91.6 x 27.9 x 3.9 m | u 0, v 0, y -0.4..3.5 | M_PAVILION #a9c3cd | 3 floating box |
| soffit | 4 downward quads, ring | outer 102.9 x 39.0, inner 91.6 x 27.9 | y 3.5 | M_STONE #ebe9e3 | 3 floating box |
| fins | 29 boxes | 1.0 x 3.0 x 3.9 m | listed in section 3 | M_STONE #ebe9e3 | 3 floating box |
| lower | box walls | 102.9 x 39.0 m | y 3.5..14.0 | M_STONE #ebe9e3 | 2 stacked boxes |
| ledge | ring top | 0.4 m wide | y 14.0 | M_STONE #ebe9e3 | 2 stacked boxes |
| seam | box walls, inset | 102.1 x 38.2 x 1.0 m | y 14.0..15.0 | M_STONE #c9c8c2 | 2 stacked boxes |
| under | ring underside | 0.8 m wide | y 15.0 | M_STONE #ebe9e3 | 2 stacked boxes |
| upper | box walls and roof | 103.7 x 39.8 m | y 15.0..26.0 | M_STONE #ebe9e3, roof #d9d8d2 | 1 white box |
| panel | box | 0.4 x 12 x 12.4 m | u 51.85..52.25, v -19.9..-7.9, y 15..27.4 | M_STONE #ebe9e3 | 2 stacked boxes |
| upstands | 3 boxes on the roof edge | 0.4 m thick, 1.1 m high | -v u 10.5..51.85, +v u 8..51.85, +u v -7.9..19.5 | M_STONE #ebe9e3 | 1 white box |
| loggia | recess, glass 3 m back, reveals, sill, head | 15.5 x 5.8 m | -v, u -5..10.5, y 15.2..21 | M_PAVILION #8fa9b6, M_STONE | 4 windows |
| win_mn | recess 0.4 m | 4 x 4 m | -v, u -33.5..-29.5, y 16.5..20.5 | M_PAVILION #8fa9b6 | 4 windows |
| low_mc | recess 0.4 m | 8.4 x 2.7 m | -v lower, u -10.2..-1.8, y 8.8..11.5 | M_PAVILION #8fa9b6 | 4 windows |
| low_ms | recess 0.4 m | 5.9 x 2.7 m | -v lower, u 19.6..25.5, y 8.8..11.5 | M_PAVILION #8fa9b6 | 4 windows |
| low_mn | recess 0.4 m | 2.1 x 2.5 m | -v lower, u -32.3..-30.2, y 9..11.5 | M_PAVILION #8fa9b6 | 4 windows |
| rib_ms | glass strip on the seam | 29.3 x 0.8 m | -v seam, u 20..49.3, y 14.1..14.9 | M_PAVILION #526872 | 2 stacked boxes |
| rib_mn | glass strip on the seam | 40 x 0.8 m | -v seam, u -46..-6, y 14.1..14.9 | M_PAVILION #526872 | 2 stacked boxes |
| w1 | recess 0.4 m | 18 x 5.6 m | +v, u -9..9, y 15.2..20.8 | M_PAVILION #8fa9b6 | 4 windows |
| entry | recess 3 m | 9 x 8.5 m | +v lower, u 14..23, y 3.5..12 | M_PAVILION #8fa9b6, M_STONE | 4 windows |
| low_pc | recess 0.4 m | 12 x 2.7 m | +v lower, u -9..3, y 8.8..11.5 | M_PAVILION #8fa9b6 | 4 windows |
| low_pn | recess 0.4 m | 2.5 x 2.2 m | +v lower, u -27..-24.5, y 9.3..11.5 | M_PAVILION #8fa9b6 | 4 windows |
| rib_pn | glass strip on the seam | 12 x 0.8 m | +v seam, u -43..-31, y 14.1..14.9 | M_PAVILION #526872 | 2 stacked boxes |
| rib_ps | glass strip on the seam | 29 x 0.8 m | +v seam, u 20..49, y 14.1..14.9 | M_PAVILION #526872 | 2 stacked boxes |
| win_s | recess 0.4 m | 6 x 5.2 m | +u, v -7.5..-1.5, y 15.3..20.5 | M_PAVILION #8fa9b6 | 4 windows |
| low_s | recess 0.4 m | 1.8 x 4.5 m | +u lower, v -3.3..-1.5, y 7.5..12 | M_PAVILION #8fa9b6 | 4 windows |
| w4 | recess 0.4 m | 6 x 6.4 m | -u, v -15..-9, y 15.6..22 | M_PAVILION #8fa9b6 | 4 windows |
| w5 | recess 0.4 m | 2.5 x 2.5 m | -u lower, v -14..-11.5, y 8.8..11.3 | M_PAVILION #8fa9b6 | 4 windows |
| corner | box, glazed top | 12.45 x 10.5 x 25.4 m | u -64.3..-51.85, v 16.5..27 | M_STONE #ebe9e3, top M_GLASS_ROOF | 1 white box |
| sky | flat glass field with 2 holes | 99.3 x 35.4 m | roof, y 26 | M_GLASS_ROOF #cfd8dc | 5 glass roof |
| wells | 2 flush glass squares | 8 x 8 and 7 x 7 m | (5, 4.9) and (31.5, -0.6), y 26 | M_GLASS_ROOF #7d97a2 | 5 glass roof |
| fans | box | 3 x 6 x 1.2 m | roof, u -12.5, v 1.8 | M_STONE #9a9d9e | 5 glass roof |
