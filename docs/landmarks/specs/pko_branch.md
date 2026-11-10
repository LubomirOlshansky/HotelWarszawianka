# I Oddział PKO, the first branch on Marszałkowska at Sienkiewicza: spec

Site key `pko_branch` in `game/scripts/landmarks.gd` (`_find_pko_branch`, `_build_pko_branch`).
Written 2026-11-09 from F's street photo (polska-org.pl, the granite front seen from the
south-west) and a Google aerial of the block. Unnamed: no card, not on the picking grid. The
bank's name is a parody (BANK POLSKA), never the real one.

## 1. Identity

A 1990s bank block: a dark red-brown polished-granite slab on Marszałkowska, nine floors, whose
tall glass bays run in one stroke over a two-storey base, a raked glass top floor above; behind
it paler plain wings round an open paved courtyard. What the game had before: about 26 overlapping
OpenStreetMap parts, a LoD2 courtyard drawn as hollow walls with no roof, and two generated fronts
(a brick "Rotunda block" in `data/street_blocks/index.json` and `data/photo_fronts.json`).

## 2. Massing

Frame: u along Marszałkowska towards Sienkiewicza (south), v east, origin (-984, -30), u axis
(0.337, 0.941). Heights above the lowest ground under the zone.

| Volume | Plan (u, v) | Height |
| --- | --- | --- |
| Slab | 0..56 by 0..14 | 34.5 m (granite to 31 m, raked glass above) |
| Wings (north, south) | 0..56 by 14..64 less the courtyard | 25 m |
| East wing | 14..40 by 52..64 | 28.5 m |
| Courtyard | 14..40 by 14..52 | open, paved at ground |

The zone is the frame's box grown 3-4 m: every part, LoD2 run and generated front whose centre
lies inside is replaced.

## 3. Facade, base to top

- **West front** (to Marszałkowska): granite base to 8 m with two bands of glass between 3.6 m
  piers (0.9..4.1 and 4.9..7.2 m) and blue fascias at 4.15..4.85 m with BANK POLSKA; a granite
  spandrel; then 23 bays of 2.4 m, each an inset glass pane 1.5 m wide (9.4..30.5 m) between
  piers; a granite ledge at 31 m; raked glass 31..34.5 m leaning back 2.3 m.
- **Slab ends**: plain granite. **Wings**: pale pinkish-brown stone with punched windows
  (S_PUNCHED). **Courtyard faces**: the same punched stone.

## 4. Roof

Flat grey #77736d over the slab (from the rake's top), the wings ring (a cap with the courtyard cut
out) and the east wing's higher roof. The courtyard floor is a dark paving cap at ground level.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Granite ends, base, ledge | #64362e | M_STONE |
| Piers, spandrel | #7a4a3d | M_STONE |
| Glass bays, ground-floor glass, rake | #5f87a3 | M_GLASS |
| Wings | #a07f6e | M_SKIN + S_PUNCHED |
| Fascias | #1f4f8f | M_STONE |

No new material or shader skin (+0 draw calls).

## 6. Ground and night

The car stops at the slab and wing walls (one collider over the whole block). The courtyard is
closed on the map side: no way in.

## 7. Detail level and budget

L2. Triangle budget 220 (`check_mesh_quality.gd` BUDGET; built 162).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| slab_walls | granite end walls, spandrel | 56 x 14 m, to 34.5 m | u 0..56, v 0..14 | M_STONE #64362e, #7a4a3d | 1 front |
| bays | 23 glass panes | 1.5 x 21 m | west face, 8 m up | M_GLASS #5f87a3 | 1 front |
| base_glass | 2 x 15 panes | 2.6 m wide | west face, 0.9..7.2 m | M_GLASS | 1 front |
| fascia | two blue bands, sign | 18 and 16 m long | west face, 4.15..4.85 m | M_STONE #1f4f8f | 2 sign |
| rake | one raked quad | 56 x 3.6 m | 31..34.5 m | M_GLASS | 1 front |
| wings | ring walls and roof cap | 56 x 50 m, 25 m | v 14..64 | M_SKIN S_PUNCHED #a07f6e | 3 plain |
| east_wing | higher block | 26 x 12 m, to 28.5 m | u 14..40, v 52..64 | M_SKIN S_PUNCHED | 3 plain |
| courtyard | paving cap | 26 x 38 m | u 14..40, v 14..52 | M_STONE #6f6a64 | 3 plain |
