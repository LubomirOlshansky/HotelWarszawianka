# Academy of Fine Arts, Wybrzeże Kościuszkowskie 37: spec

Site key `asp37` in `game/scripts/landmarks.gd` (`_find_asp37`, `_build_asp37`). Written 2026-11-13
from the mapped outlines and published descriptions only: no photograph of this building could be
fetched in the cloud session, so the colours and the window rhythm are estimates *(photo check,
asked of F)*. Not the Krasiński-Czapski palace on Krakowskie Przedmieście (that is `czapski`).

## 1. Identity

The Powiśle campus of the Academy: the 1911-14 school (Alfons Gravier, a storey added after the
war, a new storey under a roof-like top in the 2013 rebuild) and JEMS Architekci's four-storey wing
that fills the gap in the Wybrzeże frontage, with an exhibition courtyard between them. What makes a
passer-by say it: the sand-coloured concrete street wing with its big windows next to the older
plastered school.

## 2. Massing

The mapped outlines. The old school 19.2 m to the eave plus a recessed top storey to 22.6 m; the new
wing 4 storeys, 16.2 m.

## 3. Facade, base to top

Old school: dark plinth, pale plaster with punched windows, a cornice, then the top storey in dark
zinc one metre back. New wing: sand-coloured concrete with punched windows to the street and the
side, glass to the courtyard (the faces turned south-west), plinth, cornice and a 0.5 m parapet.

## 4. Roof

Old school: dark zinc-grey top storey, flat grey cap. New wing: flat grey cap behind the parapet.

## 5. Colour and material

Plaster #d8d0bd, zinc #596066, concrete sand #cdbc9a, glass #3f525c, plinth #625d55.

## 6. Ground and night

Both collide. Windows follow the building shader's night rule.

## 7. Detail level and budget

L2, budget 1300 triangles (measured 1012). One surface with the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| school | prism of the mapped outline | 19.2 m | old building | plaster, punched skin | the 1914 school |
| top | inset prism | 3.4 m, 1 m back | over the school | zinc | new top storey |
| wing | prism of the mapped outline | 16.2 m | street wing | sand concrete | JEMS's wing |
| glass_front | wall faces | 16.2 m | wing faces to the south-west | glass | the courtyard front |
| plinth | band | 1.2 m | both | dark stone | base |

## 9. Driving

Both buildings collide as mapped.

## Open

- Photos of the street front and the courtyard (F's folder) to check the colours and the window grid.
