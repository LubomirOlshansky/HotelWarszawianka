# Gmach Główny Politechniki Warszawskiej (Plac Politechniki 1): spec

Site key `politechnika` (`SKINS` entry in `game/scripts/landmarks/fronts.gd`, `_build_politechnika`
in `game/scripts/landmarks/srodmiescie.gd`). Written 2026-11-15 in a cloud thread from F's photos
(`refs/_f/warsaw-needed-photos/top-50/T20/` in the shared store: the front from the square, the
front at night, a side, a detail, the hall's glass roof from inside; reference only, never
shipped) and the LoD2 mass. The mass, the rounded corners and the courtyard hall come from LoD2,
which already has them right; this build recolours the mass and adds the front's details on
LoD2's flat east face toward the square.

## 1. Identity

1. A pale, almost pinkish white neo-Renaissance block on a triangular plot, its corners rounded
   (the front photo, the side).
2. The middle of the front on Plac Politechniki: three tall arched windows between four pairs of
   columns, over three arched doors on a rusticated base (the front photo).
3. The attic over the middle with POLITECHNIKA on a plaque, an urn on each corner pylon and the
   figure group on top, a standing figure with a raised arm between seated ones (the front photo).
4. The stairs to the doors, held by a low curved stone kerb, with two dark stone pillars carrying
   clusters of white globes (the front photo, the night photo).
5. The courtyard hall's glass roof over the middle of the block (the roof photo).

## 2. Massing (heights over the ground at the front)

LoD2's mass, unchanged: about 23 m to the eave at the front. The middle bay stands 0.6 m proud of
LoD2's flat wall, 17.5 m wide (LoD2's flat stretch, -898.1,1493.8 to -905.6,1509.6), to 21.4 m;
the attic rises to 27.2 m and the figure group to about 34 m.

## 3. Facade, base to top

- **Skin**: the whole LoD2 mass in pale stone #ece6d8 (M_MONUMENT, so the shader draws its windows
  and cornice), roofs zinc grey #8b9094.
- **Base**: rusticated #ddd6c6 to 7.2 m, a white string course #f4f1e9 at 7 to 7.5 m.
- **Doors**: three arched doors, 2.3 m wide, 0.6 to 4.4 m to the spring, dark wood #5b3a2a.
- **Windows**: three arched windows over them, 2.7 m wide, 9.2 to 16.2 m to the spring, #2c333a.
- **Columns**: eight, in four pairs, 0.72 m thick, 7.5 to 20.6 m, white.
- **Balcony** under the windows at 8.3 to 8.8 m; the entablature and cornice at 20.6 to 22.4 m
  with a shaded underside.

## 4. Roof

- **Attic** over the middle, 22.4 to 27.2 m, with the name plaque (a darker panel; no text), its
  own cornice, two pylons with urns at the ends.
- **Figures**: a pedestal, a standing figure about 5 m tall with a raised arm, two seated
  figures, all in pale stone #d3cec4.
- **Hall roof**: the skin leaves LoD2's glass roof over the courtyard hall as it is (`keep`, a
  rectangle round the hall), so it does not turn zinc.

## 5. Colour and material

Skin wall #ece6d8 (M_MONUMENT), roof #8b9094; front stone #ece6d8, base #ddd6c6, white
#f4f1e9 (M_STONE); glass #2c333a and doors #5b3a2a (the kit's arched window); figures #d3cec4;
lamp pillars #5a5048; globes #fbf3dc (M_LAMP). No new material.

## 6. Ground and night

Three steps across the front, a low curved stone kerb round them (eight segments, 1 m high) with a
stone ball at each end. Two lamp pillars on the stair cheeks between the doors. Collision is the
middle bay's box; the mass's collision is LoD2's. At night the globes are lit; the shader's
windows light the rest.

## 7. Detail level and budget

L2 (a big civic landmark on a square the drive passes, from Nowowiejska and Noakowskiego). About
760 triangles, budget 950 (check_mesh_quality BUDGET "politechnika"); no draw call, no shader
change (building.gdshader stays 501 of 505).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 recolour | the whole mass | the block | M_MONUMENT #ece6d8 | 1.1 block |
| hall roof | LoD2 kept | the hall | the courtyard | LoD2 glass | 1.5 hall |
| risalit | box | 17.5 x 0.6 m, to 21.4 m | the east face | M_STONE #ece6d8 | 1.2 middle |
| base | box | to 7.2 m | the risalit | M_STONE #ddd6c6 | 1.2 middle |
| doors | arched windows | 2.3 m, to 4.4 m spring | u -4.4, 0, 4.4 | #5b3a2a | 1.2 middle |
| windows | arched windows | 2.7 m, 9.2 to 16.2 m spring | u -4.4, 0, 4.4 | #2c333a | 1.2 middle |
| columns | prisms | 0.72 m, 7.5 to 20.6 m | four pairs | M_STONE white | 1.2 middle |
| cornice | boxes + soffit | 20.6 to 22.4 m | over the risalit | M_STONE white | 1.2 middle |
| attic | box + plaque + cornice | 22.4 to 27.2 m | the middle | M_STONE | 1.3 attic |
| urns | pylons + prisms | to 30.4 m | the attic's ends | M_STONE | 1.3 attic |
| figures | prisms + beam | to about 34 m | the attic's middle | M_STONE #d3cec4 | 1.3 attic |
| steps | three boxes | 1.35 m deep | across the doors | M_STONE | 1.4 stairs |
| kerb | eight prisms | 1 m high | a half ellipse round the steps | M_STONE | 1.4 stairs |
| lamps | pillars + globes | to 6 m | u -2.2 and 2.2 | M_STONE, M_LAMP | 1.4 stairs, 6 night |

## 9. Not built, and what only the phone can show

- The 1899 and 1901 cartouches on the pylons, the reliefs over the windows, the curved wings' own
  columns and windows (the shader's windows stand in), the balcony's balusters, the plaque's text.
- The other fronts on Noakowskiego, Nowowiejska and Koszykowa keep LoD2's shape with the skin.
- Phone: whether the front reads pale and not grey in the afternoon shade, and whether the
  figure group reads against the sky.
