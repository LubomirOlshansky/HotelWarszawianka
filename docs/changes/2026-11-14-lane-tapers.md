- Where a street goes from two lanes to one, the road now narrows along a long, smooth taper like a real street (about 1:15), instead of a step or a short wedge; the kerbs and edge lines follow and the dashed lane line ends where the lane closes.

## Backlog
- fixed: abrupt lane drops (F, 2026-11-14, top of Nowy Zjazd): 111 places steeper than 1:5 → 41 (`tools/lane_tapers.py`, verify step `tapers`, docs/design/lane-drops.md)
- found: 41 lane drops stay abrupt, on squares (Plac Bankowy, Plac Narutowicza, Plac Teatralny) and where a wall, tram platform or cycle track stands at the change (Targowa, Anielewicza, Aleja Solidarności, top of Nowy Zjazd until its wall stub goes); they want paint (RT-4) or the road design areas
- found: city-street lane drops should end in paint (P-21 hatched wedge, P-9 arrows) with a straight kerb (RT-4, parked in TD-23)

## Roadmap
- added and ticked: "Lane drops tapered like real streets (F, 2026-11-14): 1:15 tapers through the street's ways, kerbs and lines follow (`tools/lane_tapers.py`)"
