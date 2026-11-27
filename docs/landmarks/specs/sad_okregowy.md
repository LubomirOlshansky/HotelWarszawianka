# Sąd Okręgowy w Warszawie, al. Solidarności 127

Site key `sad_okregowy`. The named outline in `game/map/centrum.json` registers one whole-building model through `SKINS`. Plan and roof measurements use that outline and the matching GUGiK run in `game/map/lod2.bin` (metadata in `lod2.json`). The local `refs/sad_okregowy/3dtiles/` obliques show the roof breaks, court walls and street facades.

## 1. Identity

Bohdan Pniewski's Sądy na Lesznie were built in 1935–39 and rebuilt after the war. The shallow, pale stone front to Solidarności has a deep entrance gallery, tall narrow windows and a dark attic strip. The taller middle wings frame three sides of each open side court. The back block faces Ogrodowa with a closer grid of windows. [National Heritage Institute record](https://zabytek.pl/pl/obiekty/g-272226), [archival building record](https://www.warszawa1939.pl/obiekt/leszno-53)

## 2. Massing

The plan origin is the northwest corner of the mapped front at game x/z (−2237.1, −762.2). The u axis follows the long Solidarności wall toward the east along (69.3, −36.3). Positive v goes into the site toward Ogrodowa. The long side lines drift east by about 1.7 m over the site's depth, represented by a 0.014 u/v shear. At the facade, the kit takes its own outward frame from each edge. The building is approximately 86 m wide by 121 m deep in this frame.

Heights are above the lowest game terrain sample on the outline (about 13.9 m on the raw terrain grid, before local grading). The map's 24.1 m is a single fallback height. The GUGiK roof levels measure about 40 m absolute at the front, 44–45 m over the centre and 37–41 m at the rear.

| Block | Local plan in metres | Roof above datum |
| --- | --- | --- |
| Solidarności range | u 0–86, v 0.4–10.5, with the middle court starting at v 12.4 | 26.0 m |
| Entrance corner blocks | u 0–4.4 and 82.7–86, v 0–8.2 | 28.3 m |
| Front court dividing ranges | Between v 10.5 and 27.5, three open-to-sky courts at u 10–25, 35–50.5 and 61.5–77 | 26.0 m |
| Tall cross-range and middle wings | Full width v 27.5–36.5, then u 16.5–70 to v 77.8, around the court u 33.5–53.5, v 42.5–77.8 | 30.5 m |
| Rear cross-range and returns | Full width v 79.6–89, joined to the middle wings by v 77.8–79.6. The returns at u 0–9.5 and 76.1–86 run south to v 111 | 26.6 m |
| Ogrodowa range | v 105.5–121, over the long rear court's southern edge. Its ends rise slightly from v 111 to the street | 23.2 m, ends 24.6 m |

The other open-to-sky rear court is approximately 67 by 16.5 m between v 89 and 105.5. Both open side courts occupy the long setbacks in the outline between the front and rear blocks. The plan keeps the enclosed courts as holes between the roof planes.

## 3. Facade, base to top

- **Solidarności** has a 2.3 m recess beneath the upper front, with a shaded soffit and three groups of stone steps and doors. The gallery rises to about 5.4 m. Three tall rows of regularly spaced windows sit above it, with a close-spaced attic row in shadow beneath the broad cornice.
- **Ogrodowa** has a low stone base, a dense grid of narrower windows between shallow pilasters, horizontal courses and dark stair glazing at the ends. A rounded bay projects into its court. The tall middle wings and court elevations use the taller openings and a continuous upper ledge. The broad ends of the cross-ranges retain the mostly blank walls visible in the obliques.
- Windows, doors, ledges and cornices use the facade kit. Flat kit panes carry the repetitive court elevations and attic rows. Window dimensions, sill heights and gallery details are scaled estimates from the obliques and street photos. [Solidarności street facade](https://www.whitemad.pl/gmach-sadu-okregowego-w-warszawie-monumentalny-relikt-przedwojennej-stolicy/)

## 4. Roof

Dark grey, flat roof planes follow the GUGiK level changes. The tops leave the five interior courts open. Low vents and service housings break up the roof ridges over the cross-ranges and rear return.

## 5. Colour and material

Cream-grey wall stone `#dcd6c9`. Pale stone trim and base courses in `PAL_WHITE_STONE` and `PAL_WARM_GRANITE`. Roofs use `#7d7f8c` to match the blue-grey membrane in the game lighting. Window panels use `PAL_GLASS_DARK` and `PAL_GLASS_STEEL`, and door leaves use `PAL_BRONZE`. Existing `M_STONE` and kit pane codes.

## 6. Ground and night

The wall feet run just below the terrain datum. Car collision follows the named map outline. The courts expose the terrain. At night the kit panes can light up with the standard window effect.

## 7. Detail level and budget

L3, triangle budget 7000. Shared flat panes keep the high window count affordable and reserve geometry for the street elevations, steps and roof breaks. Geometry joins the city landmark surface.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| massing | Joined walls and roof planes | 86 × 121 m, 23.2–30.5 m tall | Named outline and five internal court openings | M_STONE cream-grey, dark roof | Stepped court plan and corner blocks |
| shell | Kit windows, panes and masonry courses | Typically 1.1–1.45 m wide, 1.8–2.4 m tall | Street, side and court faces | Kit panes, M_STONE trim | Tall window rhythms, attic strip and cornices |
| portal | Recess, soffit, steps and kit doors | 2.3 m deep and 5.4 m high, three entry groups | Solidarności ground floor | M_STONE warm granite, pale stone and bronze | Continuous shaded entrance gallery |
| rear_bay | Chamfered prism | 17.6 m wide, 2.8 m deep, 22.9 m tall | u 35.8–53.4 on the inner face of the Ogrodowa range | M_STONE cream-grey, grey roof | Rounded projection into the rear court |
| roof_fittings | Low boxes | About 2–5 m across, 0.6–1.2 m tall | On the front, middle and rear roofs | M_STONE grey | Service housings and vent stacks |

## 9. Left out

Fine stone joints, carved lettering, security fittings, courtyard furniture, the central court's low utility cover and individual roof pipes. The small rounded returns and shallow roof pitches are simplified into straight plan lines and level roof planes.
