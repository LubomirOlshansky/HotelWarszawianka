# Hotel Saski (Plac Bankowy)

Site `hotel_saski` covers the mapped building `b12827` at Plac Bankowy 1.
The outer plan comes from the named ring in `centrum.json`. GUGiK footprint 3287
and its corresponding run in `lod2.bin` give the roof profile and courtyard.
The existing Hotel Saski photo front provides facade heights and a daylight palette.

## 1. Identity

The former Kossecka house gained its classicist front on Plac Bankowy in the 1820s.
Rebuilt as Hotel Saski after the war, it was later restored for office use. Its rounded
corner, arched street-level openings and dark roof distinguish it from the neighbouring blocks.
[Bankowy 1, Fotopolska](https://fotopolska.eu/Warszawa/b83004,Bankowy_1.html)
[Warsaw Architecture Award, renovation and street photos by Piotr Krajewski](https://www.nagroda-architektoniczna.pl/nominations/hotel-saski/)
[Plac Bankowy 1 renovation and courtyard, with comments from the designers](https://builder4future.pl/2018/05/09/metamorfoza-placu-bankowego-1/)

## 2. Massing

Plan coordinates are game metres east and south. The plan starts at the southwest
corner `(-1457.3, -846.4)`. On each face, start looking along the wall with the street
on the kit's positive-v side, so local u advances along the facade and v points out.
Take grade once at the middle of the 22.2 m Plac Bankowy face and sink the walls to
0.6 m below the lowest terrain on the ring. Heights below are above that grade.

| Block | Plan in metres | Height |
| --- | --- | --- |
| Plac Bankowy range | 22.2 m straight facade and a rounded 18 m return to the north | 16.1 m eave, 20.2 m roof shoulder |
| North range | 46.1 m angled run beyond the curve | same eave and shoulder |
| East range | about 42 m from the short northeast return to the south party wall | same eave and shoulder |
| South range | 59 m skewed wall, largely shared with the adjacent building | same eave and shoulder |
| Court | skewed void about 38 × 16 m at widest, with a shallow step on the north | open to grade, court walls to 20.2 m |

The mapped outline spans x −1457.3 to −1396.2 and z −889.1 to −844.1. Keep its full
ring for collision and simplify sub-metre wall offsets in the visible shell. The photo
front's eaves are 15.7–16.4 m. GUGiK gives y 24.9–25.6 m at the eaves and about y
29.45 m on the high roof around the court, above a base near y 9.3 m.

## 3. Facade, base to top

- Warm stone plinth about 0.45 m high, with shallow rustication below the first
  string course at 4.8 m. Use kit arches for the tall ground-floor openings on the
  street, including the principal entrance, and a dark arch for the passage into the court.
- The Plac Bankowy face has six bays. Continue with three turning bays and regular,
  approximately 3.8 m bays on the long north and east faces. Three upper registers
  have approximate sills at 5.55, 9.45 and 13.1 m. The first is tallest and gets
  more pronounced heads, with simple sills and shorter openings above.
- The common crowning cornice projects about 0.38 m. Give the square side pale
  pilasters and a shallow balcony. Keep the shared south wall mostly plain.
- Use simpler grouped windows on the court, with warm grey masonry and brick on the
  reconstructed inner range. The court-facing passage and the street entrance align visually.

## 4. Roof

Hip the dark grey street slopes into a broad upper deck that wraps the open court.
Use the GUGiK shoulder around 20.2 m and lower the eave to 16.1 m. Keep the rounded
west corner in the outer roof edge and put compact dormers on the square and north slopes.

## 5. Colour and material

Use pale cream plaster `#e6dfcd`, darker base `#cfc6b0`, pale trim `#f3eee0` and
dark blue-grey roof `#5f6468`, from the existing photo front palette. Use warm grey
stone and muted brick in the court and the kit's pale sash and dark glazing. Walls,
stonework and roof use `M_STONE`.

## 6. Ground and night

Collide the mapped outside ring and the court ring. Leave the court open through
the roof and show the passage as a dark arch. The kit supplies ordinary window
lighting at night.

## 7. Detail level and budget

L3, triangle budget 5000. Give the principal facade larger openings and more
pronounced surrounds. Keep court glazing flat and share the site's building surface.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shell | masonry wall ring | 61 × 45 m, eaves 16.1 m | named footprint | M_STONE, cream plaster | rounded street corner and continuous plinth |
| elevations | kit openings and bands | three upper registers above the ground floor | each street elevation and the two south returns | M_STONE, M_PANE | rusticated arches and rectangular windows |
| entrance | pilasters and balcony | principal bays on the 22.2 m face | Plac Bankowy | M_STONE, dark iron | classical entrance composition |
| court | inner walls with kit glazing | about 38 × 16 m, top 20.2 m | inside the roof opening | M_STONE, M_PANE | open-air court with brick inner range |
| roof | hipped slopes and upper deck | 4.1 m rise | from street cornices to court walls | M_STONE, blue-grey | low roof follows the bent footprint |
| dormers | small hipped roof openings | about 1.4 m wide | above the square and north facades | M_STONE, M_PANE | dark attic glazing |

## 9. Omitted details

Shop signs, sculpted brackets, roof seams, rooftop service units, the secondary
roof wells, courtyard stairs and furniture, interiors and the traversable passage.
Trim, the dormer section and the less visible bay spacing are estimates.
