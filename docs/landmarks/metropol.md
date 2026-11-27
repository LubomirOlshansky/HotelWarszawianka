# Hotel Metropol (Marszałkowska 99a): log

Site key `metropolsign` (no card), built by `landmarks.gd` `_build_metropol_sign`.

## 2026-11-07: rebuilt from F's four photos (cloud thread)

- Before: the map's plain extrusion, and the parody name METROPOLKA floating on the middle of an outline edge
  (over the courtyard notch, mirrored from the north).
- References: F's four photos (dusk from the north-east, an aerial from the east, the roof sign by day, the
  front by day); parts from centrum.json (the slab h 34.5 over a dark 3.5 m ground floor, roof structures at
  34.5 to 36.5 and 40).
- After: the zone is the outline's convex hull (the slab's centre falls in the courtyard notch, so a centre
  test missed it). The slab's long faces use the S_SLAB loggia skin in cream; the ends and wings plain; the
  3.5 m ground-floor part is dark glass; the street faces get a dark glazed base, a cream canopy at 4.5 m with
  a lit strip; the roof structures stay as mapped; the name stands on two posts over the roof structures
  (white light box, 20 m, green letters, parody METROPOLKA) over the middle street face.
- Street faces are found as the outermost long faces facing the same way as the outline's longest edge.
- Checks: check_sites OK; day and dusk shots from the roof and the street.
- Open: BACKLOG "Hotel Metropol rebuilt".

## 2026-11-19: "fixed so many times, still wrong" (cloud thread)

- Root cause: two models of the hotel. #495 (2026-11-07, the 512 modelled street blocks) gave the city a
  block `blk_28759009` on exactly this outline, the same day the hotel was rebuilt here; both were drawn.
  The block's triangles included a white frame round a dark green panel at the roof edge, standing in
  front of the light box's lower half and over the letters, in the runtime city and the prebuilt one
  alike. A site-alone render (turntable, `--solo`) never shows a block, so every fix looked right there.
  Now `_find_blocks` skips it (`MP_BLOCK`, as Centrum Marszałkowska's `CM_BLOCK`).
- Two faults in the sign itself: the light box was plain stone (M_STONE), so at night it went as dark
  as the roof and only the green letters showed, floating; and the letters were placed by the box's
  middle while map_builder takes a sign's point as the letters' bottom, so they rode 0.75 of a row high
  over the box's top. Now the box is M_LAMP in a light grey (#a8aca6: lit white at night without
  blooming over the letters; by day its east face is in shade and reads grey) and the letters sit in
  its middle, 0.03 m in front of its face.
- F's report itself came from the teaser's Mac render of an older build (the pre-#639 sign on the
  outline's bounding box). Render teasers from current main with a fresh prebuilt city.
- Guard: `game/tools/check_metropol.gd` (verify step `metropol`, CI quick): no street block on the hotel,
  one METROPOLKA facing the street on the real outline (not its box), over the roof on a lit box, the
  letters inside the box's face. It fails on the old code (no lit box) and with the block back.
- Found: 17 more street blocks stand inside other modelled sites (jerozolimskie57 x4, prosta28 x2,
  asbud x2, equator, equator2, grzybowska77, pepeo_tower, torwar, kino_muranow, powstancow_blue,
  dom_chlopa, marszalkowska99); each may be the same double model. Not changed here.
  Settled 2026-11-26 (each looked at in the city): 11 blocks skipped (fronts.gd LM_BLOCKS), the
  Pekao and Equator towers keep the block and add only their sign (TOWERS `on_block`), Torwar, Dom
  Chłopa and Kino Muranów dress their block by design (check_sites DRESSES_BLOCK).
