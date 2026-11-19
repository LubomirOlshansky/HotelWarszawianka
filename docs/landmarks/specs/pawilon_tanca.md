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

A long white box on the upper promenade with big swirl murals in pink, yellow, blue, green and
purple on both long sides; TANIEC in big pink letters over the entrances, lit at night; at the
south-east river-side corner PALOMKA, a small timber terrace under white triangular sails with
tables and bulbs; a row of dark container kiosks (GOFRY, LODY, PIWO, ZAPIEKANKI, KAWA among the
mapped LEMONIADA ones) in front along the boulevard, each with a lit hatch. Parody names only
(PALOMKA for Paloma); TANIEC is the institution's own word, a dance, not a brand.

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
TANIEC letters light, the hatches glow, the kiosk words and PALOMKA burn in neon and the sails'
bulbs light (M_LAMP).

## 7. Detail level and budget

L2, triangle budget 1800 for the site `pawilon_tanca` (built 1428); `bulwary_bary` goes from 1760 to 2800
(2282 with the five extra kiosks, +820). Both budgets are entries of `check_mesh_quality.gd`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | box + plinth band + parapet | 56.6 x 19.8 x 8 m | the outline's box | white plaster, pale roof | the long white box |
| units | five boxes + two skylights | 1.2 to 3 m | on the roof | grey metal, glass | the small units on the roof |
| murals | five ribbons + a disc each, three panels | 15 to 17 m x 5.8 m | both long faces | `BBC_SWIRL` | the swirl murals |
| bays | glass quads + iron mullions + canopy | 12 to 14 m x 3.5 m | river face | M_PAVILION | the glazed entrance and Palomka's front |
| lettering | font pixels as lit faces | 0.45 m pixels, ~16 m wide | both long faces, top at 7.7 m | M_LAMP pink | the TANIEC sign |
| terrace | timber deck | 18 x 9 x 0.18 m | the south-east river corner | timber | Palomka's terrace |
| sails | eight masts, six two-sided triangles | 3.3 to 4.6 m | over the terrace | white | the white triangular sails |
| tables | table + two benches | 2 x 3 | under the sails | timber, cushions | the café tables |
| kiosks | container + hatch + flap + counter + chairs + neon word | 8 x 2.6 x 2.6 m | five, along the boulevard | dark paint, M_LAMP | the dark kiosk row |
