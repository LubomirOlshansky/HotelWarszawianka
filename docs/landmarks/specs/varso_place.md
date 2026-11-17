# Varso Place: plaza, terraces and the sky garden (Krajobraz K3): spec

Sites `varso` (the tower, `_build_varso`, its sky garden added) and `varso_place` (new:
`_find_varso_place`, `_build_varso_place`) in `game/scripts/landmarks.gd`, and the PLACE `varso`
in `tools/planted_trees.py`. Written 2026-11-02 in a cloud thread. Wikimedia Commons, the GUGiK
orthophoto and krajobraz.com.pl answer 403 from the cloud, so no photo was opened: the facts come
from the developer's and the suppliers' published pages (sources below) and the OSM parts, and
the layout of each roof's planting is an estimate marked *(photo check)*. The Mac pass (QUESTIONS)
puts `refs/varso_place/` photos and `ortho.jpg` beside the shots.

Wings (2026-11-17, F's eight photos in the thread: an in-game shot of the empty plaza, two
street views from the south-west and south, three aerials and the top-down drone shot of Varso 2's
roof): parts W1-W6 below. Kept in the thread, never in the repo.

Sources: HB Reavis "Sky garden at Varso Tower is taking shape" (2021: the garden on the 205 m
roof, 16 single-stem hawthorns *Crataegus monogyna* up to 6 m and over 2 t each, spherical crowns,
by RS Architektura Krajobrazu, planted by Hadart; the second deck at 230 m); ZinCo's Varso Place
reference (~4,000 m² of green on the garage slabs and roofs, 2022; 9 m olive trees in the lobby;
robust perennials, dwarf pines under small trees, benches with timber); HB Reavis' Varso Place
brochure 05.2024 (Varso 1: 81 m, 19 floors, a 7th-floor roof terrace; Varso 2: 90 m, 21 floors,
"green terraces"; Varso Tower 310 m, 53 floors, the public deck at ~230 m); Wikipedia "Varso"
(new pavements, lamps, benches, bike stands, shrubs and trees round Chmielna; a 60 t glacial
erratic found on the site to stand by the tower's entrance); Eurobuild CEE "Chmielna zyska przy
Varso" (almost 200 m of Chmielna rebuilt: wider pavements, a raised crossing on the entrance's
axis to Złota, marked bays, new lamps).

## 1. Identity

What makes it Varso Place rather than three glass boxes, seen from the street and from the
helicopter:
1. green on the tops: a grove of round-crowned hawthorns on the tower's 205 m step, under the
   230 m top; planted terraces on Varso 1 and 2;
2. a green street front on Chmielna: a tree in each bed along Varso 1 and 2;
3. the low cream stone wings the towers rise out of (W1-W6): an even grid of deep windows,
   a dark set-back top floor, terraces with planters and small trees; Varso 2's glass atrium
   against its tower;
4. the corner plaza by Al. Jana Pawła II: the name on a low granite plinth (the parody
   **VERSO PLACE**, never the real mark or lettering) and the big erratic boulder.

## 2. Massing

The wings (W1-W6, `_varso_wings`): each of the Varso I and Varso II outlines less every mapped
part 5 m tall or more standing in or by it (grown 5 cm), jogs under 0.6 m smoothed, pieces of
150 m² or more: Varso 1's east of its tower towards Varso Tower, Varso 2's west of its tower.
Each is eight storeys (a 5 m glazed ground floor + 7 x 3.9 m = 32.3 m; the photos count eight
rows of windows), a set-back ninth (3.6 m dark glass + a 0.5 m stone cornice) 7 m in from every
face; Varso 2's atrium is a 26 x 21 m rectangle against the 80 m part's face that looks into the
wing (photo 7), cut out of the wing, leaving it a C.

The terraces, all from the OSM parts (`centrum.json`), nothing new is tall:
- the tower's 205 m part (1,392 m²) minus everything that starts at or under 206 m and rises
  above it (the 230 m top, the dark spines to 209 and 234 m, the 207-209 m parapets): an open
  step of about 600 m² on its north-west half (G1);
- Varso 1: the 71 m part (1,051 m²) minus the 81 m top: ~500 m² open (T1);
- Varso 2: the 80 m part (1,270 m²) minus the 90 m top: ~600 m² (T2), and the 72 m part
  (150 m²) whole (T3);
- open pieces under 60 m² carry nothing.

## 3. Facade, base to top

The wings (W1, W2): a dark glass body (`M_SKIN` S_DARK: its lobby glass under 4.5 m and lit
bays at night) behind a cream stone frame: square piers 0.9 m wide, 0.45 m proud, every ~3.3 m
(the ends at the corners), from the ground to the parapet; spandrel bands 0.4 m proud, 1.25 m
tall, over every floor line (the first is the ground floor's head at 5 m); the parapet band
0.75 m tall and 0.5 m proud over the piers' heads. The bands run mitred round the whole ring (no
two tops on one plane); the piers stand only on faces that show (not in the atrium, not inside
a tower part; over the 10 m link they start at its roof). No shader change: the building
shader's lite copy is at its Adreno budget.

Unchanged: the tower is `_build_varso` (M_GLASS slabs, spines, the lit crown); Varso 1 and 2 stay
the map's extrusions. The only thing on a facade line is the glass balustrade round each planted
roof (1.1 m, lit glass `M_PAVILION + 0.5`, as the Forest's terrace), the terraces' edge seen from
the street.

## 4. Roof

The wings (W3-W6): a timber deck (the body's roof), a glass balustrade (1.1 m, `M_PAVILION + 0.5`,
lit at night) 0.2 m out of the parapet's line; the set-back top storey with a pale roof and one
4.4 m plant box; planters (4 x 1.8 x 0.6 m granite boxes, perennials, lawn or grasses on top)
in two rows, 2.4 m in from the parapet and 2 m short of the top storey, one every 5.5 m where
the top storey, the atrium and the towers leave room, a small round-crowned tree (4.2 m ±10 %,
crown radius 1.6 m) in every other one and a dwarf pine in the rest; Varso 2's atrium roof a
low glass pyramid (`M_GLASS_ROOF`, #9fc0d8) from 1.6 m under the parapet to 0.6 m over it.

Each open piece (G1, T1-T3) the same way, `_varso_garden`:
- a timber deck 0.12 m over the roof, 0.5 m in from the edge, inside the glass balustrade;
- one raised bed 2.5 m in from the edge (granite sides, 0.43 m high), its top perennials, lawn or
  grasses in turn;
- trees on a grid inside the bed a metre in: G1 16 hawthorns, 5.8 m (± 10 %), crown radius 2.0 m,
  4.6 m apart (the 16 the article counts); T1-T3 up to 9 small trees each, 4.6 m, radius 1.6 m,
  5.2 m apart *(photo check: how many, and whether Varso 1's terrace has trees at all)*;
- dwarf pines (1.35 m cones) in the grid's gaps: 10 on G1, 4 on each terrace;
- timber benches (2 x 0.5 m, seat 0.43 m) along the bed's longest edges: 4 on G1, 2 on each
  terrace.
All of it is out of the roof grid (`_no_roof`), so the helicopter, the cassette and the deck's
crowd (`crowds.gd` `varso_deck`, on the 230 m top) read the roofs as before. Not built: Varso 1's
7th-floor terrace (no step at ~25 m in OSM) *(photo check)*.

## 5. Colour and material

All `M_STONE` (plain, in the city's one building material) unless named.

| Part | Colour | Material code |
| --- | --- | --- |
| hawthorn and small-tree crowns | #5f7f45, the lower half 12 % darker, top 8 % lighter | M_STONE |
| trunks | #5b4b3d | M_STONE |
| dwarf pines | #3d5b3b | M_STONE |
| beds' tops | #7b8c4e / #6c8f4f / #8a8a58 in turn | M_STONE |
| beds' sides, the plinth | granite #8e8a82 | M_STONE |
| deck, benches | timber #a58a69 (benches' sides 25 % darker) | M_STONE |
| balustrade | #c9dcdc | M_PAVILION + 0.5 |
| erratic | #867f74, upper half 6 % lighter | M_STONE |
| wings' stone frame | cream #e4ddcd (sides 8 % darker, tops 4 % lighter) | M_STONE |
| wings' glass body | #2c3946 | M_SKIN S_DARK |
| top storey | dark glass #2a3038, roof #d3d4cf | M_SKIN S_DARK / M_STONE |
| atrium roof | #9fc0d8 | M_GLASS_ROOF |
| VERSO PLACE | warm white (0.97, 0.94, 0.86) | neon sign (`signs`) |

## 6. Ground and night

- S1 street trees: `planted_trees.py` PLACE `varso`, the south pavement of Chmielna from Al. Jana
  Pawła II to Varso 2's west end. OSM maps 13 beds there as grass (10-38 m²); the 2023 scan has 15
  trees there, all 11 m or more (planted with the buildings), and leaves 6 beds bare: one young
  maple, plane or bird cherry each (5.8-7.3 m). The tower's own front (no mapped beds; 6 scanned
  trees, the bike racks) is left as it is.
- P1 the name sign at (-1597.5, 553.5), on the corner plaza between the tower's north-east corner
  and Al. Jana Pawła II: a granite plinth 0.9 m deep, 1.2 m high, as long as the word + 1 m,
  parallel to the avenue; VERSO PLACE in 0.7 m letters on its avenue face (the landmark signs
  glow day and night). The car stops at it.
- P2 the erratic at (-1600.5, 541.5): about 60 t (~22 m³), a rounded eight-sided block 4.2 x
  3.2 m, 2.1 m high. The car stops at it.
- Night: the balustrades' lit glass rings the tops; the sign glows.
- Both spots are clear of the pavement's solids (`bake_street_pois.Solids`: kerbs, the crossing,
  bike racks, paths, the tower).
- Not built: the 12 *Bucida* (black olive) trees inside the lobby (behind the tower's opaque
  glass), the raised crossing to Złota.

## 7. Detail level and budget

L2 for the plaza and the roofs (the tower stays L3). Triangles (`check_mesh_quality`): the tower
with G1 2,182 (budget 1,680 → 2,500); T1-T3, the sign and the erratic 901; with the wings (L2) 6,846 (`varso_place`, budget
8,200, 2026-11-17). No new node, material, light or draw call: everything is the city's building surface
(UV2 landmark codes) and the trees' existing MultiMesh. Shots: the sky garden from the helicopter
(`--at=-1622,583 --yaw=225 --pitch=-40 --size=90`), the terraces (`--at=-1730,630 --size=90`),
the corner plaza (`--at=-1590,560 --size=40`), day and dusk, both city paths.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| G1 garden | `_varso_garden` | ~600 m² | tower 205 m roof minus the parts above it | as section 5 | 1 |
| G2 hawthorns | trunk + two 6-sided frusta | 5.8 m, r 2.0 m, x16 | grid 4.6 m in G1's bed | M_STONE | 1 |
| G3 pines | 5-sided cone | 1.35 m, r 0.7 m, x10 | G1's grid gaps | M_STONE | 1 |
| G4 benches | box | 2 x 0.5 x 0.43 m, x4 | G1 bed's longest edges | M_STONE | 1 |
| T1 Varso 1 terrace | `_varso_garden` | ~500 m² | 71 m roof minus the 81 m top | as section 5 | 1 |
| T2 Varso 2 terrace | `_varso_garden` | ~600 m² | 80 m roof minus the 90 m top | as section 5 | 1 |
| T3 Varso 2 low terrace | `_varso_garden` | 150 m² | the 72 m part | as section 5 | 1 |
| S1 street trees | `trees3d` entries | 6 young trees | Chmielna's bare beds by Varso 1 and 2 | tree MultiMesh | 2 |
| P1 sign | granite plinth + neon word | ~9 x 0.9 x 1.2 m | (-1597.5, 553.5) along Al. Jana Pawła II | M_STONE + sign | 3 |
| W1 wing bodies | dark glass prism | 8 storeys, 32.3 m | each outline less its parts | M_SKIN S_DARK | 3 |
| W2 stone frame | piers 0.9 x 0.45 m, mitred bands | every ~3.3 m; 8 bands | the faces that show | M_STONE | 3 |
| W3 balustrade | glass ring | 1.1 m | 0.2 m out of the parapet | M_PAVILION + 0.5 | 3 |
| W4 top storey | dark glass + cornice | 4.1 m | 7 m in from the faces | M_SKIN S_DARK, M_STONE | 3 |
| W5 planters | granite box + tree or pine | 4 x 1.8 x 0.6 m | two rows round the terrace | M_STONE | 3 |
| W6 atrium roof | glass pyramid | 26 x 21 m | against Varso 2's 80 m part | M_GLASS_ROOF | 3 |
| P2 erratic | two 8-sided frusta | 4.2 x 3.2 x 2.1 m | (-1600.5, 541.5) | M_STONE | 3 |
