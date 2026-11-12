# Dom Partii (Centrum Bankowo-Finansowe), Nowy Świat 6/12: spec

Site key `dom_partii` in `game/scripts/landmarks.gd` (`_find_dom_partii`, `_build_dom_partii`).
Written 2026-11-12 from F's photos (2026-11-11: the front from the plaza with its roof boards, the
corner with the de Gaulle statue, Nowy Świat's Street View, a corner from the back, the courtyard
fountain by night). The photos are reference only and are not in the repository. Card: "Dom
Partii" (`CARDS`). Brands on the roof are parodies only.

## 1. Identity

The Party House (1948-1952), today Centrum Bankowo-Finansowe: a ring of white stone round one
courtyard. Before this pass the game drew the mapped LoD2 block (a flat 30 m box) in a white
window skin, plus a separate site with a small octagonal fountain; F expected the real fronts.

## 2. Massing

Frame: u east along the front (Al. Jerozolimskie's side) from the outline's north-west corner
(-161.1, 294.6), axis (0.959, -0.283); v south into the block (Nowy Świat's front is u = 0).
Heights over the plaza before the front's middle.

| Volume | Plan (u, v) | Height |
| --- | --- | --- |
| West wing (Nowy Świat) | 0..14.2 by 0..90.6 | 30 m (LoD2), cornice at 28.8 |
| East wing (the back) | 61.3..75.5 by 0..90.6 | 30 m |
| Front body | 14.2..61.3 by 2..16.4 (2 m behind the wings' ends) | 26 m, on a 6.6 m colonnade |
| Back body | 14.2..61.3 by 74.2..88.4 | 26 m, on a 6.6 m colonnade |
| Courtyard | 14.2..61.3 by 16.4..74.2 | open, paved |

The wings' ends read from the avenue as the two corner towers a storey over the front body.

## 3. Facade

- **Wings**: a ledge at every storey (6.6, then every 3.8 m), five window rows, an attic of small
  square windows under the cornice; on the towers' fronts three windows a storey and a door; on the
  long street faces three windows at each tower end and twenty bays of paired windows between, shop
  windows on the ground floor; on the courtyard faces eighteen bays of pairs, portals in dark iron
  with stone frames and a lamp each side in every third bay.
- **Bodies**: a colonnade of five bays (square piers at u 24.3, 33.3, 42.3, 51.2), glass lobbies in
  the second and fourth bay (OSM's 7.6 m parts), the middle bay open through to the courtyard; over
  it a row of tall French windows, three rows of paired windows and a frieze of small squares under
  the cornice; a pilaster in every one of the fifteen bays; a balcony slab with a railing over the
  front colonnade.

## 4. Ground and night: the courtyard

Pale granite slabs with a dark key border; the fountain round the mapped pool, a long rounded shape
whose sides swing in one wave, a granite rim 0.6 m high, a warm strip under the rim and its glow
on the slabs at night, five jets lit at night; four planters with clipped shrubs.

## 5. Roof and signs

Lift houses on the wings. ROBUR (the oak in Latin, for the real oak-named tenant) over the
north-west tower; PEPEO ŻUBR in red on a white board on the north-east tower; WISTULA in blue
letters on the front body.

## 6. Colour and material

White stone #ebe8df, ledges and cornices #f4f1ea, plinth and shadows #cfcbc1, roof #8e9091; window
glass #36414b (each pane lit on its own at night), the lobbies' glass #4a5a63 lit warm at night,
doors #2c2b2a, the railing #55595e; courtyard slabs #cfcbc2 with a #8c8983 key border and a #bfbab0
field; fountain granite #c9c6bf, water #3f6670, the warm strip #f6dc9a and its glow #d8cdb0.

## 7. Detail level and budget

L3, budget 6200 triangles (measured 5202), an exception to L3's 8000 not needed. One surface with
the city's buildings: no new draw call.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wing_w | box with ledges, cornice, parapet | 14.2 × 90.6 × 30 m | u 0..14.2 | white stone | Nowy Świat front, NW tower |
| wing_e | box with ledges, cornice, parapet | 14.2 × 90.6 × 30 m | u 61.3..75.5 | white stone | back front, NE tower |
| body_n | box on a colonnade | 47.1 × 14.4 × 19.4 m from 6.6 m | v 2..16.4 | white stone | front body, balcony, WISTULA |
| body_s | box on a colonnade | 47.1 × 14.2 × 19.4 m from 6.6 m | v 74.2..88.4 | white stone | back body |
| piers | square piers | 1.3 × 1.3 × 6.6 m | u 24.3, 33.3, 42.3, 51.2, both faces of each body | white stone | colonnade |
| lobbies | glass boxes | 7.5 × 11.2 × 6.6 m | u 25..32.5 and 43..50.5 | lit glass | glass lobbies |
| panes | quads | 0.7..2.4 m wide | every face | glass, lit by chance | windows, frieze, shops, doors |
| fountain | wavy pool, rim, strip, jets | 7.2 × 20 m, rim 0.6 m | courtyard middle (37.7, 45.2) | granite, water, lamp | the lit fountain |
| boards | box and tube letters | 12 × 0.5 × 3.4 m | NE tower roof; NW tower; front body roof | white board, neon | PEPEO ŻUBR, ROBUR, WISTULA |

## 9. Driving

The wings, piers, lobbies and the fountain's rim collide; the colonnade's open bays let the car
drive into the courtyard. 5,202 triangles, one surface with the city (no new draw call).

## Open

- Phone look check by day and night (sizes of the boards and letters, the fountain's glow).
- Mac orthophoto check of the pier positions and the courtyard faces' window count.
