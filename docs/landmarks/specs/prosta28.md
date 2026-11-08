# Prosta 28 (ul. Prosta 28, Wola): spec

Site key `prosta28` in `game/scripts/landmarks.gd` (`_find_prosta28`, `_build_prosta28`,
`_p28_base`, `_p28_terrace`, `_p28_hedge`). Built 2026-11-06 from F's six photos (the tower
square-on from Prosta, a close-up of the X-braced base, two aerials of the stepped top from the
north-east and the north-west, an aerial from the south-east with Prosta 32 and Łucka City, a
night render), and the OSM parts in P28_BOX (unnamed). GUGiK LoD2 (2018) still has the old
29 m office here, so the game showed that until now. A tenant's small red logo is never written:
the east face says PROSTO, a parody.

## 1. Identity

1. **The green glass tower** on Prosta, about 92 m, taller than Prosta 32 next door by about a
   quarter (photos and render).
2. **The X-braced base**: a double-height base of dark steel columns with silver X braces, the
   lobby's dark glass set back behind them.
3. **The stepped top**: the tower steps down to the north (towards Łucka) in terraces planted with
   small trees, under a pale stone crown.
4. **The stone stack**: a grey stone-clad strip on the west end, in two steps a little under the top.

## 2. Massing

From the mapped parts: the tower part (OSM 13.2-73.6 m, about 33 x 42 m) and its upper part
(72.6-80.2 m over the south three quarters). OSM's heights are from the build; the photos give
about 92 m, so the levels are scaled: the north terrace at 82 m, the upper glass to 89 m, the stone
crown to 93.5 m. The stone stack: the part of the outline west of the Prosta face's west corner,
to 72 m, its inner 4.5 m to 76 m. The annex towards Łucka (OSM 40.6 m) and the 24.1 m wings (what
of them the tower and the annex don't cover).

## 3. Facade, base to top

- Base 0..13.2 m: lobby M_SKIN S_DARK #33424a, 1.2 m in from the outline; on the glass line of the
  south and east faces, steel columns 0.8 m square #2c3034 every ~4.8 m, an X of two silver
  beams #c4c8cc (0.3 m) in each bay, a dark beam 0.8 m deep over them.
- Shaft 13.2..82 m (and the upper part to 89 m): M_SKIN S_FINS #5b8a82 (mullions, floor lines).
- Stack: M_SKIN S_PUNCHED #8f8a84 (stone with narrow windows).
- PROSTO in red, scale 0.6, 4 m under the north terrace's level on the east face.
- Annex: M_SKIN S_BANDS #4f7c78 to 34 m, then two steps of 3.3 m each set in 3.5 m, a hedge on
  each ledge. Wings: the same glass 8 % lighter, to 24.1 m with a parapet.

## 4. Roof

- North terrace at 82 m and the crown's step at 89 m: a hedge of planters 0.5 m in from the edge
  (0.7 m), a small tree every ~6 m along the open edge (planter 1.2 m square, trunk, five-sided
  crown to 4 m), a glass rail on the 82 m edge.
- Stone crown #c9bca5, 1.5 m in from the upper part and kept to its south 24 m (a second step
  open to the north).
- Annex: a plant box 5 x 5 x 2.2 m on its top step; green roofs on its ledges and the wings.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tower glass | #5b8a82 | M_SKIN S_FINS |
| Lobby | #33424a | M_SKIN S_DARK |
| Columns, beam | #2c3034 | M_STONE |
| X braces | #c4c8cc | M_STONE |
| Stack | #8f8a84 | M_SKIN S_PUNCHED |
| Crown | #c9bca5 | M_STONE |
| Annex, wings | #4f7c78 | M_SKIN S_BANDS |
| Planting | #5f8f45 and leaf greens | M_STONE |

## 6. Ground and night

The lobby is open glass behind the base's frame; the pavement and the low neighbours stay the
map's. At night the shaft's skin lights its windows; PROSTO is a neon word. Car walls: the
tower's, the annex's and the wings' outlines (`_collide`, handed to `pocket_rings`).

## 7. Detail level and budget

L2, triangle budget 1400 (1089 measured plus about 25 %). Shots: `--at=-2415,305 --yaw=0` (from
the south-east, as the aerial), `--yaw=40` (from Prosta, as the square-on photo).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lobby | inset prism | 0..13.2 m | tower outline - 1.2 m | M_SKIN S_DARK | 2 base |
| columns | square prisms | 0.8 m, 13.2 m | south and east glass line | M_STONE | 2 base |
| braces | 2 beams a bay | 0.3 m | between columns | M_STONE | 2 base |
| shaft | prism | 13.2..82 m | tower east of the stack | M_SKIN S_FINS | 1 tower |
| upper | prism | 82..89 m | OSM upper part | M_SKIN S_FINS | 1 tower, 3 steps |
| crown | inset prism | 89..93.5 m | upper - 1.5 m, south 24 m | M_STONE | 3 steps |
| terraces | hedges and trees | trees 4 m, every 6 m | 82 m and 89 m ledges | M_STONE | 3 steps |
| stack | 2 prisms | 72 m and 76 m | west of the face | M_SKIN S_PUNCHED | 4 stack |
| sign | neon word | scale 0.6 | east face, 78 m | neon | 1 tower |
| annex | 3 stepped prisms | 34, 37.3, 40.6 m | OSM 40.6 m part | M_SKIN S_BANDS | 1 tower (setting) |
| wings | prisms | 24.1 m | OSM 24.1 m parts | M_SKIN S_BANDS | 1 tower (setting) |
