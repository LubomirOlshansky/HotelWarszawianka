# Cepelia and Zodiak (the pavilions by the Palace): spec

Site keys `cepelia` and `zodiak` in `game/scripts/landmarks.gd` (`_build_cepelia`, `_build_zodiak`,
helpers `_pav_frame`, `_ubox`, `_urect`, `_usign`). Rebuilt 2026-11-08 from F's photo set
(`warsaw-needed-photos/pkin-surroundings`, folders S3-cepelia and E1-zodiak; shared copy in the
project files under `pkin-surroundings/photos/`). Photos are references only and never shipped.

## 1. Identity

Two low modernist pavilions on the Palace's edge. **Cepelia** (Marszałkowska 99/101, 1960s,
now the bookshop, ours EMPIRYK): a long two-storey box on a granite plinth, its upper storey a
ribbon of dark teal glass between ribbed silver bands, the ground floor set back, a white stair
core with fins at the south end and a teal mosaic on the parking side. **Zodiak** (Pasaż Wiecha,
2015): a white-framed glass pavilion with a green roof terrace, a slatted pergola and its name
in cool white neon, facing the square to the west.

## 2. Massing

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Cepelia plinth | outline grown 0.6 m, two steps | 0 to 0.45 m | photos |
| Cepelia ground floor | outline set back 1.6 m | 0.45 to 3.6 m | photos |
| Cepelia upper storey | the outline | 3.6 to 8.0 m (band 4.9, glass to 7.1) | photos, OSM h 8 |
| Cepelia stair core | 5.5 m at the south end | 0 to 8.6 m | photos |
| Zodiak ground glass | the outline | 0 to 3.4 m | photos |
| Zodiak slab | outline, proud at the front | 3.4 to 4.2 m | photos |
| Zodiak glass room | set back 3.2 m from the front | 4.2 to 7.1 m | photos |

## 3. Facade, base to top

Cepelia: granite steps, a dark recessed shop front with mullions every 2.4 m, a soffit, the
ribbed silver band, the teal glass ribbon (mullions every 1.6 m), a ribbed fascia. Zodiak:
floor-to-ceiling glass in a white frame (mullions every 1.7 m), a white slab edge, a glass rail
and grass strip on the terrace, the set-back glass room, a white roof.

## 4. Roof

Both flat. Cepelia's grey roof behind the fascia; Zodiak's white roof with the slatted pergola
(a beam and slats about every 0.8 m) over the terrace.

## 5. Colour and material

Cepelia: glass #3f5866 and frames #33383d (M_PAVILION, lit at night), silver #c3c7cb, ribs
#a9aeb3, edges #e8e8e4, roof #80858a, core #e7e3da, granite #b9b6ae, mosaic #2b7a86.
Zodiak: white frame, concrete slab, glass #5f7782 (M_PAVILION), rail, grass.

## 6. Ground and night

Both shop floors glow at night (M_PAVILION). Signs: EMPIRYK in white on Cepelia's north end
and east front (parody of the bookshop chain); ZODIAK in cool white over Zodiak's terrace,
facing the square.

## 7. Detail level and budget

L1, triangle budget 1100 for Cepelia (built 970) and 720 for Zodiak (built 620), in
`game/tools/check_mesh_quality.gd`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| cep_plinth | two prisms | outline +0.6 m, 0.45 m | the outline | M_STONE #b9b6ae | granite steps |
| cep_shop | prism and mullions | outline -1.6 m, 3.15 m | ground floor | M_PAVILION #3f5866 | recessed glazing |
| cep_mosaic | box | 7 m x 2.6 m | west front | M_STONE #2b7a86 | teal mosaic |
| cep_core | box and fins | 5.5 m x 8.6 m | south end | M_STONE #e7e3da | stair core |
| cep_band | box | outline, 1.3 m | 3.6-4.9 m | M_STONE #c3c7cb | ribbed silver band |
| cep_ribbon | prism and mullions | outline, 2.2 m | 4.9-7.1 m | M_PAVILION #3f5866 | glass ribbon |
| cep_fascia | box | outline, 0.9 m | 7.1-8.0 m | M_STONE #a9aeb3 | ribbed fascia |
| cep_signs | 2 neon words | 1.2 m letters | north end, east front | sign | EMPIRYK |
| zod_glass | prism and mullions | outline, 3.4 m | ground floor | M_PAVILION #5f7782 | glass front |
| zod_slab | box | outline, 0.8 m | 3.4-4.2 m | M_STONE white | slab edge |
| zod_terrace | strip and rail | 3.2 m deep | front of the roof | M_STONE green, glass | roof terrace |
| zod_room | prism | set back 3.2 m | 4.2-7.1 m | M_PAVILION | glass room |
| zod_pergola | beam and slats | 0.8 m pitch | over the terrace | M_STONE white | pergola |
| zod_sign | neon word | 1.0 m letters | back of the terrace | sign | ZODIAK |
