# Kościół św. Jacka (Dominikanów), Freta 8/10: spec

Site key `church_jacek` in `game/scripts/landmarks.gd` (`_find_churches` finds it, `_build_church`
hands it to `_build_jacek`): the whole church, its tower, the dome chapel and the tenement wing
beside it are one model that replaces the kit church and the LoD2 mass inside the OSM outline
(43 points; the front line is 31.5 m, the block 31 m deep and 65 m long). Written 2026-11-14 from
F's Commons photos of the front, the tower and the portal (old-town E23, top-50 `140-*`) and the
OSM outline. Heights are estimates from the photos (scale from the door, about 3.2 m): the LoD2
numbers were not usable (its heights are sparse and cover the whole complex).

## 1. Identity
Baroque church of 1603-1639, front and tower of the 1750s, rebuilt after 1944. What makes it read
as itself:
1. A **white stepped front**: double pilasters, a porch with a pediment over the door, a great
   arched window with an iron rail, a gable with a slit window and three statues, scrolls down to
   the aisles and two white obelisks on the left aisle.
2. A tall **tower to the right** with a cornice between two stages and a **dark slate bell stage**
   with a belt, an onion, a patina spire and a cross.
3. A low **green dome chapel** behind the left aisle.
4. A pink three-storey tenement with a red-tile roof beside the tower (part of the same OSM outline).

## 2. Massing
Frame: origin at the front's north-east end (-989.0, -1957.1), u along the front (+u to the
viewer's right, axis (-0.6763, 0.7366)), +v out to Freta. Aisle fronts at v = 0, the church's front
wall at v = 0.35.

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| church mass (aisles, chapel, apse) | the outline for u <= 31.5 | 7.7 m, lead flat roof, cornice |
| nave | u 8.7 to 26.1, v -0.9 to -31.4 | eaves 11.8 m, ridge 14.8 m, cross to 17 m |
| front screen | u 8.7 to 26.1 | cornice 8.4 m, gable base 14.3 m, apex 17.0 m, statue to 18.9 m |
| porch | u 14.2 to 20.6, v to 1.65 | cornice 6.2 m, pediment apex 8.4 m |
| tower | u 22.5 to 31.5, v -8.5 to 0.35 | stage cornice 10.1 m, belfry cornice 18.4 m, spire 28.3 m, cross 30.2 m |
| dome chapel | circle r 3.6 at (-1.0, -18.8) | drum 8.6 m, dome to 11.3 m |
| tenement wing | the outline for u >= 31.5 | eaves 11.2 m, hip to 14.5 m |

## 3. Facade
Front (white plaster): plinth, a lower storey with three double and single pilasters (0.85 m wide,
7.3 m tall), an entablature at 8.4 m, an upper storey with a panel, a 4.0 x 3.7 m arched window
over an iron parapet, three-step scrolls either side, a 9.8 m wide pediment 2.7 m tall with a slit
window. Porch: 6.4 m wide, door 1.8 x 3.2 m with jambs, a bronze plaque. Aisle: arched window,
pilasters, a plinth for two obelisks (4.1 and 4.3 m). Tower: corner pilasters, a framed window, an
arched portal, tall arched windows on three faces, louvres in the bell stage. Nave: four tall arched
windows on the east wall, a big arched window in the back wall. Wing: storey bands, a cornice and
three rows of flat lit panes.

## 4. Roof
Nave: red-brown sheet gable roof (#97594a), an iron cross on the rear ridge. Aisles and chapel
base: lead grey flat roofs. Tower: dark slate bell stage (#4c5654), patina green onion and spire
(#6f9a8a). Dome chapel: patina green dome. Wing: red tile hip.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e9e5d6 | M_STONE |
| Trim | #f1eee2 | M_STONE |
| Tenement | #d9a898 | M_STONE |
| Plinth | #b9b2a2 | M_STONE |
| Nave roof | #97594a | M_STONE |
| Bell stage | #4c5654 | M_STONE |
| Copper | #6f9a8a | M_STONE |
| Windows | PAL_GLASS_DARK | M_PANE (kit) |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`). Card kept: "Kościół św. Jacka". No floodlights.

## 7. Detail level and budget
L3, triangle budget 2800 (measured 2550, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_jacek`, then in the city `--at=-1000,-1950 --heading=315`.
Open photo checks: the exact heights (photo scale only), the back and the east side (no photos),
the tower's NE and SW windows (guessed from the front), the round bay's real shape, the chapel's
real size and dome height, the wing's windows and shop doors, the Ionic capitals (plain boxes),
the scroll curves (stepped boxes), the nave's real length.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| church mass | prism on the outline, lead roof, cornice ring | 7.7 m | outline u <= 31.5 | M_STONE | 1 massing |
| nave | box, cornice, gable roof, iron cross | 17.4 x 30.5 m, 11.8 m, ridge 14.8 m | u 8.7 to 26.1, v -0.9 to -31.4 | M_STONE | 1 front |
| front screen | boxes, scroll steps, cornices | 17.4 m wide, to 14.3 m | u 8.7 to 26.1 | M_STONE | 1 front |
| pilasters | 8 kit_pilaster | 0.8 m wide, 7.3 and 5 m | u 9.4, 10.9, 13.1, 21.7 | M_STONE | 1 front |
| window and rail | kit_window ARCHED, kit_balcony PARAPET | 4.0 x 3.7 m | c 17.4, y 9.8 m | M_STONE / M_PANE | 1 front |
| gable and statues | kit_pediment, slit window, 3 statues | 9.8 m wide, 2.7 m | y 14.3 m, c +-3.6 | M_STONE | 1 gable |
| porch | box, cornice, kit_pediment, kit_door, plaque | 6.4 x 6.2 m | u 14.2 to 20.6 | M_STONE | 1 porch |
| aisle and obelisks | pedestal, 2 pinnacles, window, 2 pilasters | obelisks 4.1 and 4.3 m | u 1.8 to 6.6 | M_STONE | 1 obelisks |
| round bay | 8-sided prism, cornice | r 1.85 m, 3.6 m | (25.3, -0.2) | M_STONE | 2 tower |
| tower | 2 stage boxes, 2 cornices, pilasters, windows, door | 9 x 8.5 m, 18.4 m | u 22.5 to 31.5 | M_STONE / M_PANE | 2 tower |
| bell stage and spire | 8 stacked frustums, louvres, cross | 6.5 m wide, to 30.2 m | tower centre | M_STONE | 2 bell stage |
| dome chapel | 12-sided drum, cornice, 4-ring dome, cross | r 3.6 m, 11.3 m | (-1.0, -18.8) | M_STONE | 3 chapel |
| side windows | 4 arched on the nave wall, 2 on the aisle | 2.9 m | east wall | M_STONE / M_PANE | 1 nave |
| back wall | arched window | 2.2 x 5.2 m | v -31.4 | M_STONE / M_PANE | 1 nave |
| tenement wing | prisms on the outline, hip roof, bands, 17 panes | 11.2 m, hip 14.5 m | u >= 31.5 | M_STONE | 4 tenement |
