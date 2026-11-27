- The metro stairs all over the centre now really go down: 37 entrances at Metro Centrum's north end on Marszałkowska, Rondo ONZ, Rondo Daszyńskiego, Ratusz Arsenał, Nowy Świat-Uniwersytet, Politechnika and Centrum Nauki Kopernik, each built like the real one: granite or rough stone parapets on the old line, dark granite and glass on the new one, with Rondo ONZ's teal, Rondo Daszyńskiego's red and Nowy Świat's violet glass canopies, and Politechnika's glass barrels over the escalators.

## Backlog
- fixed: the 44 flights OSM tags as going down under the street were painted strips at street level; now 37 sunken wells (map_builder SUNKEN `mw_*`, a site per station `mw_cen` ... `mw_cnk`, landmarks/centre.gd METRO_WELLS_BOXES), rings from the mapped walls, OSM's canopy roof parts (Rondo ONZ, which drew as floating teal slabs) or the flights and Google 3D Tiles, the drop from the flights' steps (0.165 m risers, at most 0.55 of the run and 5 m)
- fixed: new well looks in `_build_sunken`: `glass` (granite upstand, frameless glass, steel cap), `canopy_glass` (M2's coloured glass wedge, `roof`), `tile` (a well's own inner wall colour), handrails down every flight, and a car stop on every metro mouth (the handrail posts and a 1.2 m collider: the car can't drive down a station stair)
- found: Ratusz Arsenał's flight 931 by Andersa (16 steps on a 2.4 m way, inside the irregular wall 2371) and the stair 2091 by Dworzec Wodny (not a metro well; the boulevards' stair) were left as they were
- found: Politechnika's two south escalator barrels are not in OSM (3D Tiles shows four); only the two mapped ones are built
- found: flights tagged n=40 on 4-8 m ways at Rondo ONZ and Ratusz (1628) count both the open and the covered part; the drop is capped by the run
- found: Rondo Daszyńskiego's wells have no mapped walls: ring = the flight, 9 m from the mouth, as the canopies measure on 3D Tiles; check against the Mac's GUGiK ortho
- found (OPEN, cause unknown): CI's `firstlife` step sometimes hangs at exit after its "first life: OK" line (#1145's EXIT HANG row): this branch 2 of its last 4 runs (85f1529, a66c700 hung; cfb26ce, cdf33b9 passed), main about 1 in 8 (27 Nov 02:43); it quits in 1 s here on 2 cores. Main suspect: the wells' walk paths (47 walkers on the start's pavements, main 43). Next step: the metro-wells owner reads #1149's backtrace printed in the job output on the next EXIT HANG and fixes what it names

## Roadmap
- added (done): every metro entrance in the centre sunk and built from photos (after Rondo Dmowskiego's)
