# Muzeum Sztuki Nowoczesnej: log

Spec: `docs/landmarks/specs/msn.md`. Site `msn` in `game/scripts/landmarks/centre.gd`.

## v1, 2026-10-31

From the OSM parts and four Commons photos: one white box, a dark slot all round, two flush
city-room windows, the glass roof. 412 tris after the Mac photo check of 2026-11-01.

## v2, 2026-11-26 (F: "the real look, the windows")

- Sources: Google 3D Tiles still show the car park (no museum), so not usable. Street View
  panoramas of Marszałkowska from June 2026 and August 2024, measured by casting picture columns
  onto the facade plane from each panorama's spot and heading (±2 m); Commons 1.jpg-4.jpg; the
  ortho. All in the working copy's `refs/msn/` only.
- Found: `4.jpg` was from the south corner, not Świętokrzyska (the Palace on its left), so v1 put
  its windows on the wrong end; the "slot" is a seam where the upper box overhangs, glazed only in
  four ribbon runs; the lower box has windows; the ground floor is about 3.5 m, not 5; the light
  wells are glazed; the south part of the roof edge stands about a metre higher.
- Critique (Fable, photo first, before the build): agreed on the ribbons, the south pair and
  the misplaced window; its points on the ground floor, the step, the wells and the w1/entry/south
  window sizes went into the build.
- Built: 630 tris (budget 900), mesh check clean (no z-fight, float, degenerate).
- Still differs: the facade's panels shift in depth by up to a metre in many places (only the
  south-east panel and the roof step are modelled); the north end is unchecked (no daylight
  photo); the window mullions come from the material, not geometry.

## v2.1, 2026-11-26 (F's night photos)

- F: at night the roof is not lit. The real museum at night: a dark roof, floodlit white walls,
  warm windows and ribbons. Now: walls M_MEMBRANE + 0.5 (floodlit), the roof glass a new
  `glass_roof` variant (param 0.75: dark at night, a few faint cool panels), the wells dim.
- F's straight-on dusk photo of the Marszałkowska face moved the seam down to 12.5-13.6 m (OSM
  was close), the lower windows to 6.8-9.7 m and slightly along, the ribbons to u 18..51.0 and
  -45.5..-0.5, and showed that face's roof edge flat (its upstand removed). 618 tris.
