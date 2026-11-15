- Torn roads mended across the centre: on Trasa Łazienkowska in its cutting, the Wisłostrada by Bednarska, Miodowa, Plac Powstańców Warszawy, Piękna, the riverside boulevards and 20 more places the ground no longer pokes through the asphalt in beige diamonds and wedges.

## Backlog
- fixed: roads draped on the blurred 10 m ground grid beside an embankment, cutting or retaining wall showed the ground through the asphalt (Trasa Łazienkowska, Wisłostrada at Bednarska, the Nowy Zjazd pattern found elsewhere; F, 2026-11-14): 29 places get their own ground profile from one table (tools/road_profiles.py), the torn-street score drops from 92 to 25
- added: tools/road_profiles.py --scan finds every place where the drawn ground stands over a road's mesh by more than its depth bias (matches the renders); verify step `roadprofiles` is a count-down ratchet (26 street, 73 service-road places left)
- found: 26 street places left, the worst Oboźna by Hanuszkiewicza, Aleja „Solidarności” at Kapucyńska and Wybrzeże Szczecińskie at 1024,-950 (their profiles break check_roads C1/C11 at side links and carriageway areas: next round), plus 73 on service roads
- found: each fixed place costs 1 m ground sub-cells (695 -> 1282 cells city-wide); a coarser sub-cell for these profiles would let the rest in for less

## Roadmap
- adds: "Torn roads, round 2: the 26 street and 73 service-road places left by tools/road_profiles.py --scan"
