# Najwyższa Izba Kontroli, ul. Filtrowa 57

Site key `nik`. The address point at 52.218406° N, 20.999064° E projects to
x/z (−1700.05, 1724.29) using the map origin and `M_LAT = 110574`. It falls inside the named
`Najwyższa Izba Kontroli` outline in `centrum.json` → `landmarks`, which is also in the prebuilt
index. The `buildings` array has no outline at the point, and this checkout has no matching
GUGiK LoD2 run or photo front. The whole-building SKINS entry reserves the mapped footprint for
the model. [Wikimedia Commons coordinates](https://commons.wikimedia.org/wiki/Category:57_Filtrowa_Street_in_Warsaw)

## 1. Identity

Built in stages for the Warsaw Voivodeship Office from the 1930s, the building has housed NIK
since 1986. Two long wings frame a wide, open forecourt on Filtrowa. A shallow pediment and
four tall columns mark the entrance behind the court. The wings have pale stone walls, strong
cornices, raised attics and arched passages at the street end.
[NIK building history](https://www.nik.gov.pl/aktualnosci/noc-muzeow-w-nik-poznaj-historie-gmachu-przy-filtrowej-57.html),
[NIK headquarters history](https://bip.nik.gov.pl/o-nik/historia-nik/siedziby-najwyzszej-izby-kontroli.html)

Street references are in `refs/nik/web/`. Mapillary `north-1.jpg` and `north-2.jpg` establish
the wing ends, ground-floor arches and attic proportions. `south-1.jpg` and the west views
show the regular side and rear ranges. The frontal Commons photo shows the three arched doors,
the four columns and the eagle in the tympanum.
[Commons entrance photo](https://commons.wikimedia.org/wiki/File:Siedziba_NIK_-_front.jpg)

## 2. Massing

The map extent is x −1727.3 to −1660.1, z 1683.6 to 1787.4 m (67.2 × 103.8 m).
The named record carries no height. The model uses a 19.3 m roof edge and 20.5 m pediment peak,
scaled from the four visible rows and basement in the street photos and checked against a
published 20.5 m height. The datum is the lowest terrain sample on the outline. The plan origin
is (−1724.1, 1702.8). u follows Filtrowa east-southeast along (0.99912, 0.04193) and positive
v goes into the site, south-southwest. Each facade takes its own outward-facing kit frame.
[Filtrowa building heights](https://cleanwhale.pl/budynki/ulica/filtrowa)

| Block | Local plan in metres | Height above datum |
| --- | --- | --- |
| Solariego wing | u ≈ −0.4–15.3, v −19.2 to 82.6, with the mapped 3.3 m inner projection at the north end | 19.3 m roof edge |
| Krzywickiego wing | u ≈ 47.8–63.7, v −19.2 to 82.6, with the mapped 3.4 m inner projection at the north end | 19.3 m roof edge |
| Entrance cross-range | Joins the wings from v ≈ 22.4 to 45, with the centre projecting to v 14.9 across u 21.7–41.1 | 19.3 m roof edge, 20.5 m pediment |
| South range | Closes the rear of the mapped outline, including its stepped returns, behind the internal court | 19.3 m roof edge |

The front court opens 25.8 m wide at the street and runs 34.1 m to the entrance. The exterior
ring retains the mapped setbacks and removes sub-metre survey jogs. An internal court at
u 18.5–44.1, v 45.0–58.5 approximates the difference between the map's 5,266 m² exterior ring
and the published 4,926 m² covered area. Its exact position and proportions are estimates.
[Address and building register summary](https://sprawdzadres.pl/mazowieckie/warszawa/filtrowa/57)

## 3. Facade, base to top

- The grey base reaches 1.45 m above the datum. Four bays face Filtrowa on each wing end, with
  light mullions and shallow vertical strips between them. Three tall rows start at 2.55,
  6.45 and 10.55 m, with typical openings 1.45 × 2.4 m. The attic row has shorter windows.
- The long side and court fronts repeat bays about 3.6 m apart. Dark grey-blue panes and pale
  trim follow the heavier wing-end windows, with split panes on the longest faces. A continuous
  cornice starts at 15.45 m and projects 0.42 m. The attic row starts at 16.5 m.
- Three openings over each 11.7 m inner return form the low arcades just inside the forecourt.
  A single dark arch turns toward Filtrowa on each wing end.
- The entrance takes the 19.4 m centre projection. Three arched doors sit below four pale columns
  framing the two rows above. A short cornice and shallow pediment with a 1.7 m eagle cap the portal.

## 4. Roof

Muted slate-grey low roof, treated as a level surface behind the attic edge. Both courts
remain open above. The wing roofs read as one connected complex. Street photos show the
attic and roofline. Roof pitch and small fittings were outside their coverage.

## 5. Colour and material

Warm pale-grey plaster `#d5cbb7`, light limestone trim `PAL_CREAM_STONE`, a grey base
`PAL_GREY_GRANITE` and slate-grey roof `#777a7b`. Glass is `PAL_GLASS_DARK` with light stone
sashes on the prominent bays. The portal has darker bronze doors. All use the existing stone
and kit pane codes.

## 6. Ground and night

The walls start below terrain level and the front court exposes the ground. Collision follows
the outside ring and the enclosed court perimeter. The site straddles the current map's
southern edge at z = 1736 m. Window panes use the standard night effect.

## 7. Detail level and budget

L3, triangle budget 5000. Use modeled kit windows and sashes on the Filtrowa ends and
entrance, and flat kit panes on the long ranges. Use the existing landmark mesh.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| massing | Walls and capped ring with a hole | 64 × 102 m in the local frame | Both wings, the cross-range and the south range | M_STONE plaster | Open forecourt and rear court |
| shell | Kit windows, panes, pilasters and cornice | Four visible rows above a 1.45 m base | Across the street and court faces | Limestone and kit panes | Regular bays and raised attic |
| arcades | Masonry piers and arched spandrels | Three bays across each 11.7 m inner return | Filtrowa ends of both wings | M_STONE plaster, dark recess | Passage arches at street level |
| portal | Kit doors, columns and pediment | 19.4 m wide, peak 20.5 m | Middle of the Filtrowa court | Limestone and bronze | Formal three-door entrance |
| roof | Low roof and edge | Edge at 19.3 m | Over the connected ranges | M_STONE slate-grey | Flat silhouette behind the attic |

## 9. Left out

The eagle is a flat silhouette. Lettering, dentil blocks, roof equipment, guard barriers
and courtyard furnishings are omitted. The interior court dimensions and level roof
approximate areas with limited views.
