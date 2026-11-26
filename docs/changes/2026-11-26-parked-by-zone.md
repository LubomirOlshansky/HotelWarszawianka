- Parked cars now follow the district: the estates and the old tenement streets stay packed, while the Wola office belt, MDM's avenues, the embassies of Ujazdów and the shopping blocks by the Ściana Wschodnia have more empty kerb.

## Backlog
- fixed: parked cars were spread the same everywhere, whatever the district
- found: this only thins the bake's spots (219 of 4,821 fewer); filling the estates fuller would need new spots from the bake (tools/bake_osm.py), left for PR 4 of house types
- found: eggs.gd still treats a removed car's cell as taken (harmless: a prop just avoids an empty spot)

## Roadmap
- ticks: "House types: cheap wins: parked cars by zone" (no new mesh, draw call or material; fewer instances)
