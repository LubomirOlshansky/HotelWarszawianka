# Biblioteka Uniwersytecka (BUW): log

Spec: [specs/buw.md](specs/buw.md). Site key `buw` (`landmarks.gd` `_find_buw`, `_buw_beds`,
`_build_buw`, `_buw_front`, `_buw_roof`).

## 2026-10-31: skin to model (cloud thread)

- Before: a skin (LoD2's massing in one green, `SKINS`), "no rooftop garden detail".
- After: L2 model from OpenStreetMap alone (no free photo, no network to Commons or GUGiK from
  the cloud): the glass block to the roof garden's mapped 10.9 m; on Dobra 12 copper plates
  with lines of text, the entrance under the middle two and the four philosophers on columns;
  a trellis post every 6 m on the other fronts; the roof garden from the 60 mapped lawns as
  beds on a pale deck (the paths between them); the long glass roof with its trusses, the
  second glass roof and the round lights as glass hips and cones (no flat top, so the cassette
  lands on the garden); three copper roof houses.
- Checks: `check_spec` OK; `check_mesh_quality` 0 defects, 1860 tris, budget 2250; the PR #115 cassette
  (`c01_buw`) placed on the garden (checked on that branch merged with this one).
- Scores: none yet (no photos in the cloud; art-director pass waits for the Mac).

## 2026-11-01: pass 2, the roof from the orthophoto (cloud, from the Mac's check)

- The Mac's first render lacked the roof parts: its index.json was split before this branch
  added the library to `bake_sectors.py` SITE_NAMES (fixed by the re-split; `_find_buw` now
  warns when the parts are missing).
- Redone from GUGiK's orthophoto, georeferenced on the game grid: the flat glass field and its
  tail along the Dobra side with the walkway, the flat second glass roof, the oculus in its
  ring path, the planted hump, the 6 m band round the edge (no parapet), six ventilators, the
  formal north garden with flowers and a plaza, the mound with the glass pyramid, white
  pavilions, the NW glass strip. Trusses and the steep pitches are gone; the flat glass stays
  out of the roof grid so the cassette still lands in the garden ((83, -982), checked with
  PR #115's code).
- `check_mesh_quality` 0 defects, 2144 tris, budget 2600.

## 2026-11-01: pass 3, LoD2's height and the south garden (cloud, from the Mac's re-check of main ba4a12d)

- The Mac's GUGiK LoD2: the deck is ~15 m over the 84.4 m base (64 % of the roof), the glass
  ridges 16-17 m, a lower 10 m part (6.5 %) the court in the south notch. The deck went from
  10.9 to 15 m and everything on the roof with it; the plates rise to 17.6 m.
- The mound is a solid dark green hill (22 x 34 m, to 18 m) with the teal glass pyramid on its
  flat top. The vents were missing: the old code looked for an edge that the outline's winding
  never gave; now the four mapped round parts on the north-east band are copper drums.
- The south garden: four 2.5 m paths split the lawns into beds of dark shrub, heather and lawn;
  five white pavilions, three by the glass tail; four small white domes on brown rings; the
  oculus's paved ring 4 m. The court (Collegium Iuridicum II) is part of the site: glass walls
  to 10 m, a green roof, a skylight. The walkway now runs from the field's west corner across
  to the pavilions, a second short one over the tail; the band over the notch is 3 m and
  greener, heather between it and the deck.
- `check_mesh_quality` 0 defects, 2431 tris, budget 2900. The cassette (PR #115's code)
  lands at (99, -958) on the hill by the pyramid, 18 m.

## 2026-11-13: pass 4, F's photos (cloud thread "Build the University Library and rooftop garden")

- F sent twenty photos (Dobra's copper front and the pink tower, the ivy fronts and drums from
  Street View, the vaults, the roof garden's walkways, the dome, the lower garden with its pond
  and steel trees, the drone view, no. 47's villa). Reference only, not in the repo.
- Dobra: a frieze along the whole copper front (10.8 m to 17.6 m), BIBLIOTEKA UNIWERSYTECKA in
  raised pixel letters across its top, lines of text under them, patina streaks; twelve pages
  under it (6.4 m apart, 4.4 m wide), a pair of round copper columns in each gap; the
  philosophers kept.
- The edge band is now a curved green glass vault (a quarter ellipse in four facets) with dark
  green ribs every 2.6 m, solid colour (the glass roof shader's white grid is Złote Tarasy's).
- The fronts: glass only behind the copper (dark green) and in the tall hall past it (blue);
  the rest off-white concrete, three storeys of teal-framed windows every 4.4 m, ivy between the
  bays and over some of them (a few red), the trellis posts kept. Collegium Iuridicum II's walls
  the same.
- The pink tower: OSM's 15 pink parts (#C34DC0) by Lipowa are dropped and drawn as an open
  magenta lattice, 11.6 m, posts and a ring of beams with cross beams every 2.9 m.
- The drums: all eight mapped round parts (four on the north-east front, four just outside the
  north front, which were the city's plain drums) are concrete drums to 3 m over the deck with
  a dark slit top and pale ribs; the one by the round east corner is a lookout with a railing
  and up to six people (crowds.gd `buw_lookout`, 8-20).
- The roof: the oculus is a ribbed silver-green glass dome (0.72 of its radius high), the
  walkways over the glass field have pale green mesh railings, benches along the south path,
  the formal beds in five flower colours.
- People: the 40 mapped footways wholly on the deck (away from the vault and the glass field)
  are walked 15 m up (map_builder `footway_lift` asks `Landmarks.garden_lift`), so the city's
  walkers stroll the roof garden.
- Collegium Iuridicum IV (Wybrzeże Kościuszkowskie 47): grey render, white plinth, string
  courses, corners and window surrounds, three storeys of windows, a cornice, a grey metal
  hipped roof with two glass pyramids, the square tower on the river side with a glass lantern
  and the tall glass spire to about 26 m.
- The lower garden: a four-step concrete cascade from the north tip into the stream's end, a
  pool with a concrete rim, three steel trees with square panels, three flower beds.

## Still differs / photo check on the Mac

- Which front the philosophers stand at (built on Dobra, before the copper pages; the
  orthophoto can't tell; the Mac check kept them).
- The south beds' plants are a hash of shrub, heather and lawn, not the real planting.
- The plates' count, width and how far they rise over the roof.
- The other fronts: how much is glass, how much trellis and greenery.
- The slope (F's photos): the lower garden's sloping lawn with its glass strip and stairs up to
  the roof is not built; the north wing stays flat at 15 m (no height data for it in the cloud).
- The tower's spire of no. 47: its height and which corner it stands at (from one Street View
  photo); the drums' radius (OSM says 1.4 m, built 1.5 m).
- The atrium's own curved glass roof over the hall (the vault runs over it as over the rest).
