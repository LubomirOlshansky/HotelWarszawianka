# Road design rollout: every street on the map (F, 2026-11-06)

F, after areas 1-2: "continue with the next areas... make the plan to unslop all the roads in my map,
the backlog for it and some visualisation of progress with % done and area done."

## What is being replaced

The map's streets come from OSM ways baked as ribbons, one per way, each sized from its own lane
count. The road design system (docs/design/road-design-system.md, tools/road_design.py) rebuilds a
street from one axis and its cross-sections measured on the GUGiK orthophoto, and builds each
junction from its arms. Unslop's objects (barriers, lamps, signals, shelters, benches, trees) stay;
only the road surface inside a design's footprint is replaced, and objects left on the new asphalt
move behind the new kerb.

Scale (tools/road_progress.py on main's map): 242 km of street ribbon outside service ways, of which
the main streets (trunk, primary, secondary, tertiary) are the part that gets hand-designed first.
Service ways (209 km: driveways, yards, car parks) are not designed; they keep their ribbons and get
a mouth where they meet a designed kerb.

## The areas (docs/plan/road-areas.json)

- **Tier A, the core (12 areas, 1-2 done).** Hand-measured on the ortho, one area per thread round,
  each closing onto the done ones so no free end is left in the middle of a block. Order: 3
  Marszałkowska north, 4 Świętokrzyska east, 5 Jerozolimskie east, 6 Rondo Dmowskiego, 7
  Marszałkowska south, 8 Emilii Plater south and Chałubińskiego, 9 Rondo ONZ and Świętokrzyska west,
  10 Królewska and Plac Małachowskiego, 11 Jerozolimskie west, 12 Plac Trzech Krzyży and Ujazdowskie.
- **Tier B, the arterials (10 corridors).** Jana Pawła II north, Solidarności, Krakowskie
  Przedmieście and Nowy Świat, Powiśle, Jerozolimskie to the bridge, Solec and Czerniakowska, the
  Wola edge, Śródmieście south, Praga's riverside, the Ochota edge. Same method, bigger steps: the
  seed tool drafts each street, the ortho corrects it.
- **Tier C, everything else.** A 500 m grid, nearest the Palace first. Local streets are simple
  (one carriageway, parking lanes), so a cell is mostly seed + check, with the ortho for the
  junctions only.

## The loop for one area

1. Ortho tiles for the box (Mac: GUGiK WMS into refs/road_design2/, mosaic).
2. `tools/road_design_seed.py` drafts each street from the map's ribbons; measure every section,
   crossing and junction arm on the ortho (`road_design_plot.py unroll` / `flat --ortho`).
3. `road_design.py AREA --check` (0 problems), apply to a copy of the map: continuity 0, lane drive
   bot on every street both ways and into the side roads.
4. In-game shots of the same spots on main and on the design; a before/after page for F.
5. `tools/road_progress.py` updates the % per area; the area's status moves in road-areas.json.

## Gates (every area)

The quality bar is docs/design/road-design-quality.md (every lesson from F's reviews). `--check` 0 problems; continuity 0 (paths meet crossings both ways); `check_lane_drive.gd` passes;
`check_map_data.py` counts recorded on purpose; the phone bench before the first area goes into the
shipped map (the carriageway comes in 8 m pieces).

## Progress page

`python3 -I tools/road_progress.py` prints the table and writes build/road_progress.html: the map
with every area coloured by status and its % of main streets and of all streets done. A metre is
done when a design in docs/roads/ covers it, applied to the map or not.

## Open questions

- Decided (F, 2026-11-06): the design replaces the OSM ribbons in the shipped map after area 6
  closes the core around the Palace with no free ends, with a phone bench first (BACKLOG).
- The traffic lane graph still follows the OSM ways moved onto the designed lanes; a graph built
  from the spec's lanes is its own item.

## Area log

- **3, Marszałkowska north to Królewska** (2026-11-06, docs/roads/krolewska.json): measured on
  refs/road_design2. Marszałkowska keeps three lanes each way. The inner northbound lane becomes a
  plain strip between two solid lines (`"k": "gap", "plain": true`), and there is a west parking
  lane from Rysia. The tram-stop median is ~9 m for 50 m, so area 1's `m_north` was corrected to
  the same photo (palace v3). The junction zebras are 6-6.6 m wide, with cycle crossings on the
  junction side. Królewska west is one carriageway with no median, and Królewska east has a
  fenced 1 m island. Continuity 0. The lane-drive bot passes Marszałkowska, Królewska and
  Świętokrzyska both ways.
- **4, Świętokrzyska east to Nowy Świat** (2026-11-06, docs/roads/swietokrzyska.json): the street
  starts on area 1's `s_east` end with the same cross-section. West of Jasna: one lane west, a
  hatched area opening into a second lane east, a cycle lane, and a parking-bay strip. Further east:
  one lane each way, parking, the south cycle lane. From Czackiego: cycle lanes on both sides, two
  lanes west and one east. Mazowiecka junction `j_sm` (8 m zebra on Mazowiecka). Mazowiecka stops
  short of Kredytowa. Two mid-block OSM footways across Mazowiecka are `open_ends` (no zebra on the
  photo). Continuity 0; lane drive passes, with Mazowiecka driven by `--route` (the street filter
  finds no Mazowiecka lanes, on main too).
- **6, Rondo Dmowskiego** (2026-11-06, docs/roads/rondo.json): the generator learned roundabouts
  (`ring` on a junction). The island follows the landmark's edge (landmarks.gd `_rondo_r`, 25.2 m
  at the tram cross, 26.8 m on the diagonals) and is left to the landmark. The ring has three dashed
  lane lines (28.6, 31.9 and 35.0 m), broken over the tram cross. The outer edge is a 44 m circle,
  met by each arm's kerbs in 10 m fillets. The arm medians end at 39 m with a stop line at 40.5 m.
  Arms: Marszałkowska north (west carriageway 3 lanes, then 4 lanes widening to the ring; it steps
  out square round the metro stairwell at 61-57 m; the northbound carriageway bends east round the
  green median; zebra 8 m and cycle crossing at 129/122 m), Marszałkowska south (4 lanes out, 3 in),
  Jerozolimskie east (the south green to 62 m), and area 1's Jerozolimskie end to the west.
  Generator additions: per-kerb `l_at`/`r_at` steps, `shift` for carriageways that move sideways,
  and `greens` (grass strips in a tram median). Continuity 0; check 0; the lane-drive bot passes
  12 routes (both streets both ways plus every straight and right turn through the ring).
- **5, part 1: Jerozolimskie east to short of Rondo de Gaulle'a** (2026-11-06,
  docs/roads/jerozolimskie_e.json): it starts on area 6's east arm end, with the same section. Its
  axis bends 0.7 degrees so it runs down the tram tracks to the de Gaulle centre. North
  carriageway: three lanes, -13.3..-3.8 m. Tram bed in the middle. South carriageway: three lanes,
  3.6..15.2 m (in the towers' shadow on the photo; checked against the parked-car rows and main's
  kerb). There is an 8 m zebra 32 m past the rondo arm. The Krucza junction `j_kr` has 8-9 m zebras
  on all four arms; Krucza north has an island median, Krucza south is one five-lane carriageway.
  Bracka is a south-side mouth. The street stops with a free end 55 m short of the de Gaulle
  centre. Continuity 0; check 0; lane drive passes 9 routes (both streets, all turns at Krucza).
- **5, part 2: Rondo de Gaulle'a** (2026-11-06, docs/roads/degaulle.json): a circular island
  (r 14.6 m, the palm) cut by the tram along Jerozolimskie (`tram_axes` "v", drawn as two raised
  halves with `island`), three lanes round it (lines at 18.4 and 22.2 m), outer circle 26 m, 28.6 m
  where Nowy Świat leaves north on a tangent. Arms: Jerozolimskie west from part 1's free end
  (widening to four lanes out; part 1 gained the north parking lane east of Bracka, s 162),
  Jerozolimskie east (stop line 50 m out behind a 16 m zebra on the photo), Nowy Świat north as two
  7 m one-ways (in straight down, out on a tangent: arms that need not point at the centre) and
  Nowy Świat south as a dual carriageway with a paved splitter island narrowing into a grass median.
  Generator additions: ring `radii` per corner, a plain kerb return where two arms' kerbs meet
  outside the circle, `halves` (the ring's asphalt cut in two along v, the outer edge crossing each
  arm at its fillet tangents) and `island`. Continuity 0; check 0; lane drive passes 13 routes.
  Left: the red cycle track round the ring is not in the map, so its crossings are left out; the
  Nowy Świat Y stays as mapped.
- **7, part 1: Marszałkowska south to Wilcza** (2026-11-07, docs/roads/marszalkowska_s.json): from
  area 6's south arm end, 640 m to short of Plac Konstytucji, on an axis along the tram midline
  (it drifts 4 m east between Żurawia and Hoża). Two carriageways of three or four lanes (the
  map's counts per block), the southbound side narrowing from four lanes to three before
  Nowogrodzka, grass strips by the tracks north of Nowogrodzka. Junctions Nowogrodzka, Żurawia,
  Wspólna, Hoża, Wilcza: one zebra across Marszałkowska each on its painted side, a stop line on the
  other where the cars queue; side arms one-way as mapped (Wspólna west two-way), each with its
  zebra, and the western arms with a cycle crossing for the west-side cycle track; Skorupki an
  east-side opening. Continuity 0; check 0; lane drive passes 15 routes. Left: angled parking bays
  stay pavement; side-street parking lanes guessed from widths; the rondo's east slip road as
  mapped. Part 2 is Plac Konstytucji to Plac Zbawiciela (the street bends east past Wilcza).

## Decision 2026-11-07: main as base, small fixes

F compared every area 3-7 page with main and found main better in each scene, and chose "main as
base, small fixes". The redesigns were taken out of docs/roads/ (their specs are in git history at
0cfc1ff); palace.json (areas 1-2, approved) stays as it was after round 2. Why the redesigns lost:
they were truer to the photo but emptier. They dropped OSM's turn arrows, cycle paths and their
crossings, grass medians the photo shows paved or not at all, islands, slip lanes and lay-bys, and
an auto-detected side-road mouth became a jagged hole (Marszałkowska at Nowogrodzka). From now on the
rest of the map keeps main's roads, and each area gets only the fixes for real bugs against the
photo, with a before/after for each.
