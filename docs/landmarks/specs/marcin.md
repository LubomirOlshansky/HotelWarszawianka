# Kościół św. Marcina, Piwna 9/11: spec

Site key `church_sw_marcin` in `game/scripts/landmarks.gd` (`_find_churches` finds it, `_build_church`
hands it to `_build_marcin`): the whole church and its tower are one model that replaces the kit
church and the church's LoD2 inside the OSM outline (64 points, 23 m wide, 55.6 m deep from Piwna).
The tower stands outside the outline, in the monastery's LoD2 block: `_marcin_tops` cuts that LoD2
tower 12 m over the ground (`lod2_tops`, as the Royal Castle's Clock Tower) and the model's own
tower stands over it. Written 2026-11-14 from F's Piwna photos (old-town E13: the tower over Piwna
from Plac Zamkowy), his Plac Zamkowy photo (the nave's side wall, roof and tower) and drone photo
(E05: roofs, the gable end, the tower's place), three Mapillary photos (Podwale, little use) and
GUGiK's LoD2 (heights over its ground at 3.0 m: nave eaves 21.3, ridge 26.5, aisles 12.7, front
5-9, tower shaft 26.4, its dome to about 35). Commons has 81 photos of the church but is blocked
from the cloud: the Piwna front is built from LoD2, the outline and the drone view (QUESTIONS).

## 1. Identity
Gothic church of the Augustinians (14th-15th c.), remodelled 1744-1769 (front by Karol Bay, rococo),
burnt in 1944 and rebuilt 1952-1959. What makes it read as itself:
1. A long, tall **ochre nave under a steep green copper roof**, its gable to Piwna and a hip at the
   east end, standing high over the Old Town's red roofs (the drone and Plac Zamkowy views).
2. The **tower beside the chancel** (south side): ochre stages with corner pilasters and arched
   openings, a cornice, a broad **green bell dome**, an open lantern, a small bulb and a spire with a
   ball and cross, seen down Piwna from Plac Zamkowy.
3. On Piwna a **low ochre front** with an arched portal and a curved attic with a statue, the
   gable rising behind it.

## 2. Massing
Frame: origin at the kit's front point on Piwna (-822.8, -1556.1), u along the front (axis
(0.6866, 0.7270), +u to the tower's side, south), +v out to Piwna. Heights over the ground.

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| front block | the outline for v > -11.9 | 8.6 m, copper flat roof, cornice ring |
| aisles and chapels | the outline for v < -11.9 | 12.7 m, copper flat roof, cornice ring |
| nave | u -7.3 to 7.3, v -11.9 to -55.0 | eaves 21.3 m, ridge 26.6 m, cross to 28.6 m |
| Piwna front | the outline's forward run u 1.4 to 11.1 | cornice 8.2 m, attic 11.6 m, pediment 12.8 m, cross 14.2 m |
| tower | u 14.65 to 21.85, v -49.0 to -55.8 | brick to 12 m, stages to 26.4 m, cornice 27.1 m, dome 31.9 m, lantern 34.0 m, bulb 36.8 m, spire 40.2 m, cross 41.9 m |

## 3. Facade
Nave gable (v -11.9): four pilasters (0.9 m, 8.8 to 21.1 m), a ledge at 11.2 m, a great round-headed
window 3.0 x 6.6 m, the eaves cornice, an oculus (r 0.75 m) in the gable, urns at the corners.
Piwna front: plinth, four pilasters, two arched windows and two small framed ones, the portal (an
arched oak door 2.1 x 4.0 m in a frame with a small pediment), the cornice at 8.2 m; the attic:
a stepped, scrolled screen 5.2 m wide with a niche, a statue, a cornice, a pediment and a cross.
North aisle: six tall arched windows between plaster lesenes. Nave: six arched clerestory windows
each side over the aisles' roofs. East end: one tall arched window. Tower: corner strips on both
stages, two lesenes on the bell stage, an arched window on the lower stage and a dark arched
opening on the bell stage, on all four faces. Windows are flat arch panels (trim and dark glass).

## 4. Roof
Nave: green copper gable roof (#6f9e90), ridge along v, a gable to Piwna, a hip at the east end,
an iron cross on the gable. Aisles, chapels and front block: copper flat tops. Tower: green copper
bell dome (8 sides, widest 4.0 m), the darker lantern (#5f7672) with iron openings, a bulb, a spire,
a gilt ball and an iron cross.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6c98e | M_STONE |
| Trim | #f1e3c0 | M_STONE |
| Copper | #6f9e90 | M_STONE |
| Lantern | #5f7672 | M_STONE |
| Tower brick | #9a5a46 | M_STONE |
| Plinth | #b9b2a2 | M_STONE |
| Windows | PAL_GLASS_DARK | M_PANE (lit by chance) |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`); the tower stands in the monastery's courtyard
block, out of reach. Card kept: "Kościół św. Marcina". No floodlights.

## 7. Detail level and budget
L3, triangle budget 2400 (measured 2043, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_sw_marcin`, then in the city `--at=-790,-1590 --heli --heli-alt=30 --size=45` and
`--at=-796,-1576 --heli --heli-alt=45 --size=70`.
Open photo checks: the Piwna front (plane, height and the attic's rococo curves: no straight-on
photo yet), the tower's brick (seen on one side), the north aisle's window count, the east end
(hip or apse), the dome's exact profile and the lantern's openings.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism on the outline | 1.5 m | outline | M_STONE | 1 massing |
| front block | prism, copper top, cornice ring | 8.6 m | outline v > -11.9 | M_STONE | 3 front |
| aisles | prism, copper top, cornice ring | 12.7 m | outline v < -11.9 | M_STONE | 1 massing |
| nave | box, cornice, gable roof, hip, cross | 14.6 x 43.1 m, eaves 21.3 m, ridge 26.6 m | u 0, v -11.9 to -55 | M_STONE | 1 nave |
| gable front | 4 pilasters, ledge, arch window, cornice, oculus, 2 urns | 14.6 m wide | v -11.9 | M_STONE / M_PANE | 1 gable |
| Piwna front | plinth, 4 pilasters, cornice, 4 windows | 9.9 m wide, 8.2 m | u 1.4 to 11.1 | M_STONE / M_PANE | 3 front |
| portal | frame, arched door, pediment | 3.4 x 4.7 m | front middle | M_STONE | 3 portal |
| attic | stepped screen, cornice, pediment, niche, statue, cross | 5.2 m wide, to 14.2 m | over the portal | M_STONE | 3 attic |
| side windows | 6 aisle arches, 12 clerestory arches, 1 east arch | 1.7 to 2.4 m wide | north aisle, nave walls, east end | M_STONE / M_PANE | 1 nave |
| tower shaft | box in brick, box in ochre, 3 ledge rings | 7.2 x 6.8 m, 26.4 m | (18.25, -52.4) | M_STONE | 2 tower |
| tower faces | corner strips, lesenes, 2 arches per face | 4 faces | tower | M_STONE / M_PANE | 2 tower |
| crown | 8-sided bell dome, lantern, bulb, spire, gilt ball, cross | r 4.0 m, to 41.9 m | tower centre | M_STONE | 2 dome |
