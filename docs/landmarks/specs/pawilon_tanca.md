# Pawilon Tańca i Innych Sztuk Performatywnych, Palomka and the kiosk row (site `pawilon_tanca`, kiosks in `bulwary_bary`)

Written 2026-11-19 for the Vistula boulevards phase C (F: "from Miami Wars to the end of the
boulevards, on the top add bars, a lot of them, details"). Sources: F's aerial photo of the
pavilion (a long white box with colourful swirl murals on the long sides, a flat grey roof with
small units, Paloma at its river-side corner under white triangular sails, a row of about ten
small dark container kiosks along the upper boulevard in front), the OSM outline `Pawilon Tańca`
(57 x 20 m oriented box, Wybrzeże Kościuszkowskie 22), BOULEVARD-INVENTORY rows 27, 28 and 30,
BOULEVARD-LORE items 16 and 17. No street photo of the front exists in the cloud: the Mac look
check is open (QUESTIONS): the real murals' motifs, which end the entrance is at, the height.

## 1. Identity

A long white box on the upper promenade with bold calligraphic line murals covering 60-70 % of each wall (F's photos; Phase D, 2026-11-19: lines 0.22-0.35 m, a red-teal starfish with a teal wire globe, red and blue net cones, springs, a red circle, a black flower); MUZEUM in solid 2.6 m letters, 0.25 m deep, on a steel frame standing 0.9 m over the roof (clear of the parapet, readable against the sky from the game camera), white by day, lit cool white-blue at night, both faces; at the
south-east river-side corner PALOMKA, a raised light-timber terrace at the end face with white metal chairs and small tables, LED bars on wires between dark poles and two or three low sails, a small timber bar; a row of dark container kiosks (GOFRY, LODY, PIWO, ZAPIEKANKI, KAWA among the
mapped LEMONIADA ones) in front along the boulevard, each with a lit hatch. Parody names only
(PALOMKA for Paloma); The roof sign says only MUZEUM (F's correction); the card keeps the name.

## 2. Massing

- The pavilion: the outline's smallest oriented box (about 56.6 x 19.8 m), its v axis to the river
  (`BULWAR_RIVER`), 8.0 m tall (F's photo: ~8 m; the bake's 14 m is a default), flat roof.
- Palomka's terrace: 18 x 9 m, 0.18 m deck, past the south-east end (-u) and out from the river
  face by 0.4 to 9.4 m; eight masts 3.3 to 4.6 m, six triangular sails.
- The kiosks: five 8 x 2.6 m containers, 2.6 m tall, on the line of the mapped group 2 (from
  236, -1033 along 0.78, 0.62, step 9 m), in groups 3 to 7 of `bulwary_bary`.

## 3. Facade

- Long sides: white plaster `#eeece4`, a pale plinth band 0.9 m up (0.25 m tall, 8 cm proud); murals
  at 1.5 to 7.3 m: river side u 8 to 25, street side u -27 to -12 and 14 to 27, each of five sine
  ribbons (0.75 to 0.95 m thick, 8 segments, each 3 cm further out) and a disc for the swirl's eye.
- River side: two glazed bays at 0.4 to 3.9 m, Palomka's front (u -25 to -11) and the entrance
  (u -7 to 5), dark glass (M_PAVILION, lit at night) with iron mullions every 2 m and a white canopy slab.
- Street side: a dark door (u 0, 2.8 m tall).
- Lettering TANIEC: font pixels 0.45 m, pink `#e23d78` in M_LAMP, centred on both long faces with
  its top at 7.7 m.

## 4. Roof

Grey flat roof (`PAL_ROOF_PALE`), a white parapet 0.5 m tall and 0.3 m thick all round, five small
units (plant, lift head, stair heads: 1.1 to 2.4 m) and two low glass skylights, counted from the
aerial photo's "small units", positions by eye.

## 5. Colour and material

White `#eeece4`, plinth `#b9b5ab`, roof `PAL_ROOF_PALE`, units `PAL_ROOF_GREY` / `PAL_ALUMINIUM`,
murals `BBC_SWIRL` (pink, yellow, blue, green, purple, orange), lettering `#e23d78`, glass
`PAL_GLASS_NAVY`, deck `PAL_TIMBER`, sails `#f8f6ee`. All in the one building surface (M_STONE,
M_PAVILION, M_LAMP): no new material, no new draw call. The kiosks: dark paint `#2d3238`, `#3b4046`,
`#283338`, `#3a3534`, `#2c3a36` (the aerial photo's dark kiosks).

## 6. Ground and night

Everything stands on the lowest ground under its box; the terrace deck on the highest under its
corners. Car collision round the pavilion's box and the kiosks. At night the glazed bays glow, the
MUZEUM letters light, the hatches glow, the kiosk words and PALOMKA burn in neon and the sails'
bulbs light (M_LAMP).

## 7. Detail level and budget

L2, triangle budget 3800 for the site `pawilon_tanca`, an exception to L2's 3000 (one site, three bold line-mural faces, solid 3D letters on a frame, 13 cafe sets; built 2724 in round 1, 3532 in Phase D, 2026-11-19); `bulwary_bary` goes from 1760 to 2800
(2282 with the five extra kiosks, +820). Both budgets are entries of `check_mesh_quality.gd`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | box + plinth band + parapet | 56.6 x 19.8 x 8 m | the outline's box | white plaster, pale roof | the long white box |
| units | five boxes + two skylights | 1.2 to 3 m | on the roof | grey metal, glass | the small units on the roof |
| murals | mitred line ribbons 0.22 to 0.35 m, twelve depths 3 to 26 cm proud (the probe's coplanar window is 2 cm) | three faces, 1.4 to 7.4 m up, 60-70 % of each wall | both long faces and the end face | red, teal, blue, black paint | the line murals |
| bays | glass quads + iron mullions + canopy | 12 to 14 m x 3.5 m | river face | M_PAVILION | the glazed door and the café windows |
| lettering | font pixels as solid boxes (0.25 m deep) on a steel frame: posts, two rails, X braces | 0.37 m pixels, 2.6 m tall, ~13 m wide, bottom 0.9 m over the roof | on the roof, 2.5 m in from the camera side's edge | M_LAMP cool white | the MUZEUM sign |
| terrace | raised light-timber deck | 7.6 x 15 m end deck and 12.4 x 5.6 m river deck, 0.3 m | the end face and the river face's first 12 m | timber | Palomka's terrace |
| sails and LED bars | five masts, three two-sided triangles; eight 3.6 m poles, ten wires with lit bars | 2.4 to 3 m | over the terrace | white, M_LAMP | the low sails and the hung LED bars |
| tables | white table + two chairs | 13 sets | the terrace | white metal | the café tables |
| kiosks | container + hatch + flap + counter + chairs + neon word | 8 x 2.6 x 2.6 m | five, along the boulevard | dark paint, M_LAMP | the dark kiosk row |

## People (Phase D, 2026-11-19)

Guests and barmen come from `Landmarks.bulwar_bar_plans` (river.gd, one static plan per builder: seat points at the chair, bench, leżak or sofa height, facing the table) through crowds.gd kind `bar`: they share the crowd cells' MultiMesh (+0 draw calls), at most 218 figures over all ten bar sites (`Crowds.BAR_MAX`), busiest 17:00-01:00, lunch moderate, thin in rain, the barges fuller on Friday and Saturday. A change to a builder's table layout must change its plan too.
