# Academy of Fine Arts, Wybrzeże Kościuszkowskie 37: spec

Site key `asp37` in `game/scripts/landmarks.gd` (`_find_asp37`, `_build_asp37`). Written 2026-11-13
from the mapped outlines and sixteen Commons photos of Nos. 37 and 41 (gathered on the Mac into the
gitignored refs/asp37/, with its REPORT.md). Reference only, not in the repository. Not the
Krasiński-Czapski palace on Krakowskie Przedmieście (that is `czapski`). Dimensions are estimates
from the photos.

## 1. Identity

The Powiśle campus of the Academy: the 1911-14 school (Alfons Gravier) in cream-peach render with
white columns and cornices under a dark zinc roof, and JEMS Architekci's four-storey wing running
along its side, cream render bands alternating with tall reflective glass strips under a grey zinc
top floor. What makes a passer-by say it: the warm old front next to the glass-and-cream wing.

## 2. Massing

The mapped outlines. The old school three storeys to 12.4 m with a roof stepping in twice to 15.4 m;
the new wing four storeys, 16.2 m.

## 3. Facade, base to top

Old school: dark plinth 1 m, cream-peach render with punched windows, a white cornice 0.6 m, then
two zinc steps. New wing: dark reflective glass up to the top floor, a cream band 0.9 m at each of
the three floor lines, a dark plinth, the top floor 3.8 m in grey zinc.

## 4. Roof

Old school: dark zinc, two inset steps, flat grey cap. New wing: zinc to the flat grey cap.

## 5. Colour and material

Render #e2cbae, cream #e6d8be, zinc #596066, glass #4d6670, plinth #625d55.

## 6. Ground and night

Both collide. Windows follow the building shader's night rule.

## 7. Detail level and budget

L2, budget 1300 triangles (measured with the mesh-quality check). One surface with the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| school | prism of the mapped outline | 12.4 m | old building | render, punched skin | the 1914 school |
| roof | two inset prisms | 3 m, 1 and 3.2 m back | over the school | zinc | dark zinc roof |
| wing | prism of the mapped outline | 12.4 m of glass | JEMS wing | reflective glass | glass strips |
| bands | three offset bands | 0.9 m | floor lines of the wing | cream render | render bands |
| top | prism | 3.8 m | over the wing | zinc | grey top floor |
| plinth | band | 1 m | both | dark stone | base |

## 9. Driving

Both buildings collide as mapped.

## Open

- The two white columns and the arched window over the school's door, the back of the school and the
  roof from above are not modelled (no photo of them yet).
