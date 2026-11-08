# Stacja Muzeum, Nocny Targ and Kolejowa 8/10 (sites `stacja_muzeum`, `nocny`, `kolejowa`)

F's ask (2026-11-07): improve Kolejowa, the night market and the railway museum, from the estate to
the railway, with the pinball museum and the clubs.

## Sources

- The Mac's 19 Commons photos of Stacja Muzeum (`~/Documents/warsaw-needed-photos/stacja-muzeum{,-claude}/`):
  the hall's front head-on and from Towarowa, the yard from above (both ends), the engines (Ty2, Tr203,
  Ty42, Ol49, the streamlined Pm3), the old shed, the water crane.
- F's 27 photos (`~/Documents/warsaw-needed-photos/kolejowa/`, SOURCES.md): Nocny Market's platforms by
  day and night, kiosks, a food truck, the Drugi Peron; Kolejowa's warehouses from the street and the
  footbridge; the pinball museum at 8a; Odessa (8/10) and Space (37/39).
- OpenStreetMap: the hall's L at Towarowa 3, the long strip off it and the `warehouse` outlines (the
  market's canopies), Kolejowa 8's address point. The museum's sidings from the map's rails.

Brand rule: the market's name is the parody NOCNY TARG, the pinball museum's FLIPEROWNIA, the club's
ODESSKA. WARSZAWA GŁÓWNA is the station's name, as on the building.

## 1. Identity

The old Warszawa Główna station (the temporary main station of 1945-75), now the railway museum: a
cream hall with a segmental-arch gable to Towarowa and gold letters, a long low wing along the street,
and a yard of steam engines. West of it the old platforms are the night market: two long canopies of
rusty corrugated roofing with the track bed between them as the court. On Kolejowa the old railway
warehouses: dark brick 8/10, the grey plastered pinball museum, the teal club.

## 2. Massing

Frame SM_O/A/B: u along Towarowa (south) from the hall's north corner, v west into the yard. The
barrel hall u 0..19, v -1..25: walls 9 m, the arch 3.5 m more. The Towarowa wing u 19..58, v 0..25,
5.6 m walls under a 3 m hipped roof. The yard arm u -7..14, v 25..49.5, 4.6 m. The market's frame
NT_O/A/B: u west along the platforms, v north; the south canopy u 1..92 over v -7..10, the north
canopy u 62..226 over v 31..59. Kolejowa: the four OpenStreetMap outlines, 4.6 m (the club 4.2 m).

## 3. Facade

Hall front: eight pilasters (the outer two from the ground, the rest above the canopy), three upper
windows, four ground floor windows and the door, a 13 m canopy, four wide steps, WARSZAWA GŁÓWNA in
gold over the canopy. The wing: a row of shop windows and a row of small high ones every 3.3 m. The
yard arm: red-framed windows on the courtyard side. Market: a back wall of kiosks painted in graffiti
colours with lit hatches to the court; stalls down the north canopy's middle. Kolejowa: loading doors
on the brick fronts to the street, blind arches and arched windows on the pinball museum, a black
banner across the club.

## 4. Roof

Hall: a barrel of ten facets, dark grey. Wing and arm: dark hipped roofs. Market: the south canopy one
pitch from 4.5 m at the back to 3.5 m at the court; the north canopy two gables side by side (eaves
3.7 m, ridges 5.4 m) on two rows of posts. Kolejowa: flat roofs with a 0.7 m overhang.

## 5. Colour and material

Hall cream #e6dcbf (arm #d3c8a6), roof #55595d, glass #353c40, canopy #6e3026, gold letters. Engines:
black #1c1e20 with red frames and wheels #a8312a, tank engines' green #3f8a6a, the Pm3 and EU20 green,
coaches #d6d1c3 under grey roofs. Market rust #86492f, underside #4a3a32, graffiti and stall colours,
tubes blue, green, orange, pink, white. Kolejowa brick #6e3d2e, plaster #a6a49e, teal #1d9da3, roofs
#5d6164.

## 6. Ground and night

Engines stand on the sidings' ground; each market piece stands on its own terrain sample. The car
collides with the hall, the market's back walls and stall row, and the Kolejowa buildings. At night the
letters, the tubes, the lit hatches, the bulb strings, the platform lamps and the two neon names glow.

## 7. Detail level and budget

L3 with a named exception: three sites, a hall and seventeen vehicles in one. Triangle budget 9000 for `stacja_muzeum` (the build is 3432), 7000 for `nocny` (3246), 2500 for
`kolejowa` (364), the sites' entries in `check_mesh_quality.gd`. No new materials.

## 8. Parts table

| Part | Shape | Size | Position | Material | Feature |
| --- | --- | --- | --- | --- | --- |
| Barrel hall | walls, segmental gable, faceted barrel | 19 × 26 m, 9 + 3.5 m | u 0..19, v -1..25 | cream plaster, dark roof | the arched front with the gold letters |
| Towarowa wing | box, hipped roof | 39 × 25 m, 5.6 m | u 19..58, v 0..25 | cream plaster | shop windows to the street |
| Yard arm | box, hipped roof | 21 × 24 m, 4.6 m | u -7..14, v 25..49.5 | cream plaster | red-framed windows |
| Engines and coaches | boxes, boiler tubes, wheel discs | 10-24 m each | the four sidings from their ends | black, red, green, grey | Ty2, Ol49, tank engines, Pm3, EU20, coaches |
| Water crane, lamps, fence | tubes, beams, wall | 4.2 m crane, 4.6 m lamps, 1.9 m fence | the far platform, along D | iron, white | the yard's furniture |
| South canopy | kiosk wall, posts, one pitch | 91 × 17 m | NT u 1..92, v -7..10 | rust, graffiti colours | lit hatches, coloured tubes |
| North canopy | posts, twin gables, stalls | 164 × 28 m | NT u 62..226, v 31..59 | rust | stalls back to back, tubes |
| Court | benches, tables, food truck, bulb strings | 20 m wide | NT v 10..31 | painted benches | NOCNY TARG on a post |
| Kolejowa warehouses | outline prisms, eaves | 4.6 m | Kolejowa 8/10, 8a | brick, plaster, teal | doors, blind arches, FLIPEROWNIA, ODESSKA |
