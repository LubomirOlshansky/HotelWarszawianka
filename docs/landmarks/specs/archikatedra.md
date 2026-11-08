# Archikatedra św. Jana (St John's Archcathedral): spec

Site key `archikatedra` in `game/scripts/landmarks.gd` (`_build_archikatedra`). Written 2026-11-01
in a cloud thread from the OpenStreetMap outline in `centrum.json` (no photo, no LoD2 detail
here). The nave and chancel stay the kept LoD2 mass in brick (`M_GOTHIC`); the model adds the
west front. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Brick Gothic church of the Old Town (14th century, rebuilt after 1944). Defining:

1. **A stepped brick gable** over the front, narrowing in tiers with stone copings and pinnacles.
2. **A tall pointed window** in the middle of that gable.
3. **A pointed portal** in a small gabled porch.

## 2. Massing

Frame: origin (-741.3, -1633.0) (the front's west corner), u along the 27.6 m front (axis
(0.685, 0.729)), +v out of the front to the street (south-west). The outline's front is
buttressed: the wall sits at v about -0.4, the buttress tips at v about +1.0. Porch: u 9.2..18.4,
v -0.6..2.4, 8.5 m to the eave, a gable to 11.5 m. Gable screen: four tiers at v -0.25..1.35,
half-widths 12.8, 9.4, 6.0, 2.6 m up to 18.5 / 24 / 28 / 31 m, cross to 35 m *(photo check)*.

## 3. Facade

Stone plinth under the porch; brick walls with the Gothic shader's pointed lancets; the great
window (4.2 x 8 m, with a pointed head to 25.4 m) in the second tier; stone copings 0.45 m
thick on every tier.

## 4. Roof

Porch gable in dark roof tone; the nave roof stays LoD2's. Pinnacles (stone, pointed caps) on
the tier corners and the front's two buttresses; a stone cross on the top step.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Brick walls, tiers | #9a4b38 | M_GOTHIC |
| Copings, plinth, pinnacles, cross | #c8b393 | M_STONE |
| Window, portal | #262a2e | M_GLASS |
| Porch gable slopes | #5e3a30 | M_STONE |

No new material or draw call.

## 6. Ground and night

The porch is solid for the car. Card kept: "Archikatedra św. Jana", PL "Gotycki kościół z cegły
na Starym Mieście.", EN "A Gothic brick church in the Old Town." Open *(photo check)*: the real
gable height and step count, the window's shape, whether the tower stands at the front.

## 7. Detail level and budget

L3 for the front, L1 elsewhere; budget 1100 (`check_mesh_quality.gd`). Shot:
`--at=-735,-1622 --yaw=313 --pitch=-48 --size=50 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| porch | box with a gable | u 9.2-18.4, v -0.6-2.4, eave 8.5 m, gable 11.5 m | the front's middle | M_GOTHIC, M_STONE | 2 massing |
| gable | four stepped tiers | half-widths 12.8 / 9.4 / 6.0 / 2.6 m, to 18.5 / 24 / 28 / 31 m | v -0.25-1.35 over the front | M_GOTHIC | 3 facade |
| copings | slabs | 0.45 m thick | on every tier | M_STONE | 3 facade |
| window | pointed panel | 4.2 x 8 m, head to 25.4 m | the second tier | M_GLASS | 3 facade |
| pinnacles | posts with pointed caps | tier height | tier corners, the two buttresses | M_STONE | 4 roof |
| cross | two bars | to 35 m | the top step | M_STONE | 4 roof |

## Update

Photo pass 2026-11-06 (refs/archikatedra 1 and 3, Commons photos): body 16 m of brick (M_GOTHIC) with three pointed windows in white splays (side ones 2 m wide to 13.4 m, middle 2.3 m to 14.2 m), two buttresses at m ± 5.5, a stone frieze at 16-17.2 m, then a gable of six levels (full width 26 m, each level 2.2 m narrower per side and 3.3 m taller, to 21 m over the frieze) with brick shafts and cream panels each holding a blind lancet, gilt cross; an octagonal copper bell turret on the ridge. Replaces the four-tier gable below.
