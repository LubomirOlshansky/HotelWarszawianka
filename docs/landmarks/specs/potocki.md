# Pałac Potockich (Ministry of Culture): spec

**v2, 2026-11-26 (Krakowskie Przedmieście rework for the trailer, F's go): the palace, its two
gates and the Kordegarda as one Codex build**, the palace whole (the kept skin dropped, `model:
true`), the Kordegarda per `kordegarda.md` with the v2 notes below. Refs (gitignored):
`refs/kp_potocki/3dtiles/` (3D Tiles: the U round a court of honour with two lawns and a path,
orange-red tile mansards with dormers, a second U behind round a garden court), Street View in
`refs/kp_sv/`, F's night photos of 2026-11-26 (pack 2: the north gate and the wing's end lit by
the street lamp; the Kordegarda's front at night, lit windows, its sculpture groups).

## v2 changes (what the rebuild fixes)

v1 is 692 triangles on a LoD2 skin. v2 is **L3, budget 6,500** (palace and gates; the
Kordegarda keeps its own site and budget, raised to 2,200).

1. **The palace**: three storeys (ground floor 4.6 m rusticated, two upper 4.0 m) to a cornice at
   12.4 m (v1), cream (#ede8dc) with white trim; under an **orange-red tile mansard** (#c5502f,
   lower slope steep 70°, curb at 15.2 m, upper slope low), a row of dormers every 3.8 m with white
   frames and small triangular pediments (`kit_window` in a dormer box); the court front's
   three-bay centre pavilion with pediment and oculus (v1) rises 1.2 m over the cornice.
2. **The wings' street ends** (the two "guardhouses" on Krakowskie, either side of the court):
   two storeys, three bays to the street, a hipped mansard in the same tile with one dormer, a
   white wall with quoins, the ground-floor windows arched.
3. **The court**: two rectangular lawns either side of a paved path from the Kordegarda to the
   centre pavilion (the map's lawn if there is one, else a flat green 0.05 m above the ground,
   no collider), a low clipped hedge round each.
4. **The gates**: each a pair of tall rusticated piers (1.2 x 1.2 m, 4.2 m) with an entablature
   and **a sculpture group on top** (a seated figure with a putto, as a block group to 6.2 m),
   **a gilt lantern** on the inner pier (M_LAMP warm, the photos' bright lanterns), and between
   them the ornate wrought-iron gate in black with gilt (M_GOLD) scrolls: bars to 3.6 m under an
   arched cresting to 4.6 m with a cartouche. A small arched pedestrian door in the wall next to
   each gate.
5. **The Kordegarda** (`kordegarda.md`, v2 notes): the photos confirm v1's arched windows and
   door; add the sculpture groups' bulk (central group of three figures 2.4 m high over the door,
   single figures and urns over the corners), the windows lit warm at night (gallery, M_PAVILION),
   the GALERIA board over the door as a lit white panel (no text needed).
6. **Night**: `potocki` and `kordegarda` are in `FLOODLIT_SITES`; walls M_STONE / M_MONUMENT;
   roofs dark; lanterns glow.

### v2 parts table (new rows)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| palace | U, three storeys, cornice | outline, cornice 12.4 m | the mapped outline | M_MONUMENT #ede8dc, M_STONE trim #f7f4ec | 1 U |
| mansard | tile mansard, curb | curb 15.2 m, steep lower slope | all ranges | M_STONE #c5502f | 4 roof |
| dormers | box, window, small pediment | 1.3 x 1.8 m every 3.8 m | all mansard slopes | M_STONE, kit_window | 4 roof |
| wing_ends | two storeys, quoins, arched gf | 3 bays to the street | both court ends on Krakowskie | M_MONUMENT, M_STONE | 1 street |
| court | two lawns, path, hedges | lawns 14 x 22 m | court of honour | M_STONE #6f8f4e, #cfc6b4 | 1 court |
| piers | rusticated, entablature | 1.2 x 1.2 x 4.2 m | both gates, both sides | M_STONE #ede8dc | 3 gates |
| groups | seated figure and putto | 1.6 m high | on each pier | M_STONE #e4ded0 | 3 gates |
| lanterns | gilt lantern | 0.5 x 0.9 m | inner pier of each gate | M_LAMP #ffd27a | night |
| gates | iron bars, arched cresting | 3.6 m, cresting 4.6 m | between the piers | M_STONE #1f2224, M_GOLD | 3 gates |


Site key `potocki` (a kept skin with a model) in `game/scripts/landmarks.gd` (`_build_potocki`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 5, photos 20-21.

## 1. Identity

Krakowskie Przedmieście 15, opposite the Presidential Palace: a U-shaped palace round its court of honour, the court opening east onto the street. On the street: the Kordegarda in the court's mouth (`kordegarda.md`), a stone-piered wrought-iron gate either side of it, and the two wings' ends (the photos' two-storey "guardhouses") with orange-red hipped mansard roofs.

## 2. Massing

The mass is the LoD2 model (kept skin: cream walls #ede8dc, orange-red roofs #c5502f; the first pass had ochre and grey-brown). Note: the report placed the front at z -800..-760 (x ~-545) in the ortho's censored block; the OSM outline (x -717..-622, z -985..-905) and the Kordegarda's place in its court put it here, which matches the photos (opposite the Presidential Palace), so the outline wins. Court front frame: origin (-683.3, -919) its south end, u north (-0.2, -0.98), +v east. Gates: north (-636.6, -974.4)-(-631.6, -963.6), south (-626.9, -946.6)-(-625.4, -935.2).

## 3. Facade, base to top

Court front (first pass, kept): plinth, string course at 5.6 m, cornice at 12.4 m, corner pilasters, a three-bay central pavilion with four pilasters, door and window, a pediment with an oculus. Gates: a cream pier at each end (1 x 1 x 3.4 m, cap, urn to 4.7 m) and an iron gate between them (two rails, bars rising in a shallow arch to 3.5 m).

## 4. Roof

The LoD2 roofs in the skin's orange-red; the court pediment's slopes the same.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls (skin), piers | #ede8dc | M_MONUMENT / M_STONE |
| Roofs (skin), pediment | #c5502f | M_STONE |
| Trim | #f7f4ec | M_STONE |
| Plinth, urns | #b3a994 | M_STONE |
| Iron | #25282a | M_STONE |

## 6. Ground and night

The court's paving is the map's. The car meets the closed gates and the court front's steps. Card "Pałac Potockich".

## 7. Detail level and budget

L2, triangle budget 760 (built 692).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | the outline | M_MONUMENT #ede8dc | cream palace |
| court front | boxes | 50 m long, 13.2 m | west side of the court | M_STONE | string course, cornice |
| central pavilion | boxes, pilasters, gable | 10 x 1.2 m | court front u 25 | M_STONE, M_GLASS | pediment |
| gate piers | box, cap, urn | 1 x 1 x 4.7 m | gate ends | M_STONE #ede8dc | piers |
| gates | rails, bars | 9-10 m x 3.5 m | either side of the Kordegarda | M_STONE #25282a | iron gates |
