# Katedra Polowa Wojska Polskiego (Field Cathedral of the Polish Army): spec

Site key `church_katedra_polowa` in `game/scripts/landmarks.gd` (`_find_churches` finds it, `_build_church`
hands it to `_build_katedra_polowa`): the whole cathedral is a model that replaces the kit church and the
LoD2 mass inside the OSM outline (49 points, 27.6 m wide, 40 m deep). Written 2026-11-14 from F's three
photos (top-50 T32: the front by day, an 1840s painting of the square, an oblique with the Uprising
Monument) and the GUGiK LoD2 heights in the map pack (ground 4.9 m): pediment with statue 21.5 m, towers
35 m with spires, wings 13 m, chapels 6 m, lantern 23 m.

## 1. Identity
The baroque Piarist church of 1701-1735 on Długa 13/15, rebuilt after 1944. What makes it read as itself:
1. A cream-white front with **four giant pilasters in two pairs** and big capitals, a triangular pediment
   with a pedestal and the statue of the Virgin.
2. A tall **arch over a stained-glass window**, two free columns and a bronze door under a small pediment.
3. **Twin square belfries** with green copper bulb caps, needle spires, gold balls and iron crosses.
4. **Two low wings** with an arched door, a window over a balustrade, a scroll up to the front and an urn.

## 2. Massing
Frame: origin on the front line (the giant pilasters' face), u across, +v out to Długa (axis
(-0.6247, 0.7809) from (-1175.4, -1655.8)). Main wall at v = -0.8.

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| front block | u +-9.4, v -0.8 to -17 | cornice 17.4 m, gable ridge 23.4 m |
| nave and presbytery | u +-9.4, v -17 to -37.5 | eaves 14 m, ridge 18.2 m |
| wings | u 9.4 to 13.8, v -0.9 to -17 | cornice 10.3 m, hipped to 13.3 m |
| chapels | u 9.4 to 13.1, v -30 to -37.5 | 6.5 m, hipped |
| apse block | u +-9.6, v -37.5 to -39.8 | 12 m |
| belfries | u +-6.7, v -7.6 (5 x 5.5 m) | shaft 20.8 to 26.6 m, cap 29.3 m, spire 34.8 m, cross 38 m |
| lantern | u 0, v -32 | to 23.2 m |

## 3. Facade
Plinth 0.9 m in sandstone; pedestals to 3 m, pilasters 2 m wide to 13.6 m, capitals to 15.2 m; architrave
and frieze, cornice at 17.4 m; pediment 14.4 m wide, 2.8 m tall; pedestal and statue to 26.2 m. Arch
(8.5 m wide, crown 14.7 m) with a shadowed field, window 2.3 m wide from 6.2 to 11.8 m, columns at +-3.7,
door 2.2 x 3 m, small pediment at 4.5 m. Wings: door, balustrade, window, cornice, three-step scroll, urn.
Belfries: base block to 20.3 m, louvred arch, oculus, corner pilasters, cornice at 26 m.
Nave sides: pilasters every 6.3 m, three arched windows, cornice.

## 4. Roof
Green copper on the gable roofs, hips and caps (the photos show green roofs beside the church).

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ece6d6 | M_STONE |
| Trim | #f2eee2 | M_STONE |
| Plinth, pedestals | #cfc19b | M_STONE |
| Copper | PAL_PATINA_COPPER | M_STONE |
| Windows | PAL_GLASS_DARK, stained window PAL_GLASS_BLUE | M_PANE |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`). Card kept: "Katedra Polowa Wojska Polskiego". Windows are
the kit's `M_PANE`, lit by chance at night; floodlights are not built.

## 7. Detail level and budget
L3, triangle budget 3200 (measured 2917, `check_mesh_quality.gd`). Shots: the turntable
(`tools/turntable.sh church_katedra_polowa`), then in the city `--at=-1170,-1650 --yaw=245 --pitch=-25
--size=45 --no-ghost`, on both city paths.
Open photo checks: the roof colour of the nave, the apricot walls of the 2008 photo vs today's cream,
the volutes (stepped boxes), the spires' shape, the back and sides.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| masses | 7 prisms, 6 hips, 2 gable roofs, eaves bands | see Massing | outline | M_STONE | 1 front |
| giant order | 4 pedestals, 4 kit_pilaster, 4 capital blocks | 2 m wide, 15.2 m | u 5.6, 8.3 | M_STONE | 1 front |
| entablature | architrave, frieze, kit_cornice | 19 m wide | 15.2 to 17.95 m | M_STONE | 1 front |
| pediment and statue | kit_pediment, pedestal, 2 scrolls, statue | 14.4 m, 7 m | 18 to 26.2 m | M_STONE | 1 front |
| central bay | 2 arch panels, kit_window, 2 kit_column, kit_door, kit_pediment | 8.5 m arch | v -0.8 | M_STONE / M_PANE | 1 front |
| wings | 2 x (door, balustrade, window, cornice, pilaster, scroll, urn) | 4.4 m | u 9.4 to 13.8 | M_STONE | 2 wings |
| belfries | 2 x (base, shaft, 4 pilasters, window, oculus, 3 side arches) | 5 x 5.5 m, 26.6 m | u 6.7, v -7.6 | M_STONE | 3 belfries |
| caps and spires | 2 x (5-ring bulb, needle, ball, cross) | r 3.15 to 0.1 | 26.6 to 38 m | M_STONE | 3 belfries |
| nave sides | 2 x (plinth, 4 pilasters, 3 windows, cornice) | 20.5 m | u +-9.4 | M_STONE | 1 front |
| lantern | kit_lantern | r 1.25, 5 m | v -32 | M_STONE | 4 roof |
