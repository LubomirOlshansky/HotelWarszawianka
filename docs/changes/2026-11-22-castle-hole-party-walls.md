- Plac Zamkowy no longer has a hole in the square above the W-Z tunnel mouth: the paving runs on to the tunnel's top.
- No more tall windowed walls sticking up over the roofs of Krakowskie Przedmieście and the Old Town: house fronts are no longer drawn on the walls two houses share.

## Backlog
- fixed: a pit in Plac Zamkowy over the W-Z tunnel's east portal (the tunnel apron's inner 4 m held the ground at road level under the square); map_builder now lays a lid of the area's own surface over every tunnel apron's inner part, at the portal's top
- fixed: a free 27 m slab with windows over Krakowskie Przedmieście 14 and 16/18 (F, 2026-11-22): 418 of the 1245 photo street fronts (277 houses) stood on party walls; tools/photo_fronts_party.py took them off, verify step `photofronts` keeps them off
- found: bake_structures.py place_aprons lowers the ground over a tunnel's inner apron under whatever stands on the roof; the lid covers it at runtime, the bake itself still does it
- found: beside the W-Z east portal's right post the trench walls (110, 112, 964, 965) are low (-1.9 to -5 m) and the apron taper leaves a ragged sloped face
- found: photo fronts were read per outline edge without looking at the neighbour; the same fronts' heights (31.4 m on 15-21 m houses) came from a taller building nearby

## Roadmap
- adds: "Plac Zamkowy and Krakowskie Przedmieście: no holes or stray walls (phone check 14za)"
