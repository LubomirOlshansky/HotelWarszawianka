# Around Warsaw: development index

The full reference (every loop, every flag, the map-data chain; ~490 KB, 5,700 lines) was moved on
2026-10-31 to [`docs/archive/DEVELOPMENT-full.md`](archive/DEVELOPMENT-full.md) to stop agents reading it
whole. **Do not read it top to bottom.** Find a section below, then read only that range
(`Read` with `offset`/`limit`, or `grep -n "^## <name>" docs/archive/DEVELOPMENT-full.md`).
Earlier docs and code comments that cite `DEVELOPMENT.md "<section>"` mean that section of the archive.

## The few things to know without opening it

- **Architecture:** `docs/architecture/` is the map of the systems and where each kind of change plugs in (`extending.md`); start there before adding a system.
- **Run the game:** `cd game && godot --path . -- --nosave` plus a quit flag (`--quit-after N`, `--shots=`); flags are in the archive section "Test flags" (search `| \`--demo\``).
- **Release builds read no flags** (`game/scripts/release.gd`): only the debug export (Xcode Run, `device_run.sh`) and the editor binary take test flags; a TestFlight archive or the Play AAB ignores them (`check_credits`).
- **Verify:** `tools/verify.sh [--quick|--ios|--only=a,b]`; CI runs the no-map subset (`quick`) and the map steps (`map`, two halves) on the map pack.
- **Performance budgets:** the phone's frame grows with draw calls, not triangles; the numbers are in the section "Performance budgets" (the 2 KB table is the gate for anything per-frame).
- **Map:** derived files are not committed; `tools/setup_map.sh` makes them (without `data/raw` it fetches lod2/terrain as the map pack, `tools/map_pack.py`, a release asset); `python3 -I tools/check_map_data.py` after any re-bake ("Map data"). A full bake that changes lod2.* or terrain.json: `python3 -I tools/map_pack.py make`, publish the release it prints, commit `tools/map_pack.json`.
- **New behaviour or flag:** add a short note to the matching archive section (or a new one at the end), and a flag row to the flags table. Keep it brief; the PR is the changelog.

## Section index of the archive (line numbers at 2026-10-31; use grep, they drift)

- 101: Run it on your iPhone
- 114: Android (Google Play)
- 190: Run it on the Mac
- 194: Controls
- 256: Night and vaporwave
- 333: Rescue missions
- 353: A living city
- 388: Side jobs, the wallet and the city's chatter (v0.65)
- 451: Rivals and street races
- 481: Real roads (v0.75)
- 535: Landmarks (v0.8)
- 839: Water, weather and sound (v0.9)
- 976: Loop 1 (polish, 2026-10-28)
- 1007: Loop 2a: controls and settings (2026-10-28)
- 1118: Loop 2b: frame rate on the iPhone (2026-10-28)
- 1301: Loop 10a: the river is off-limits (2026-10-28)
- 1405: Loop 3a: roads I, the check and the bake (2026-10-28)
- 1521: Loop 2e: the HUD at phone size (2026-10-28)
- 1652: The first-minute look (2026-10-28)
- 1771: Camera loop: the follow camera (2026-10-28)
- 1874: Loop 3b: roads II, the builder (2026-10-28)
- 1963: Loop 2c: car models (2026-10-28)
- 2080: Loop 3b-2: map art and road details (2026-10-28)
- 2220: Loop G1: device tiers and the frame governor (2026-10-28)
- 2330: Loop G1b: a sharp picture with a fallback (2026-10-29)
- 2412: Loop 3g-1: the police, part one (2026-10-28)
- 2534: Loop 3g-2: the police, part two (2026-10-30)
- 2649: Sectors and streaming (loop 3c, 2026-10-29)
- 2729: Map review A: the bridges, flyovers and tunnels (2026-10-29)
- 2767: Map review B: the streets (2026-10-29)
- 2803: Loop 2d-1: Podwózka, the app-taxi side job (2026-10-29)
- 2906: Map round 2: the ground under structure ends, the night streets (2026-10-29)
- 2946: Map round 2b: river spots you can drive, the reviews' last items (2026-10-29)
- 2971: Loop 3d-1: the demo map, the 20.1 km² box (2026-10-29)
- 3047: Adding music (loop radio-playlists, 2026-10-29)
- 3102: Loop G0+: streaming and heat on the iPhone 11 (2026-10-29)
- 3187: The driving-feel loop: less sticky (2026-10-30)
- 3233: The roadworks loop: traffic and the helicopter knock the barriers (2026-10-30)
- 3245: The ram test: traffic was a wall to the car (2026-10-30)
- 3266: Loop 3d-2a: the ground, part one (2026-10-30)
- 3328: Loop 3d-2b: the map engine, part two: maps per sector, look-ahead, the load hitch (2026-10-30)
- 3436: Loop 3e: the structures of the demo map (2026-10-30)
- 3525: Moja Warszawa notebook (loop MW-1, 2026-10-30)
- 3583: The traffic loop: cars overlapping in junctions (2026-10-30)
- 3604: The traffic loop: trams and crossing cars (2026-10-30)
- 3631: The traffic loop: a brush is not a crash (2026-10-30)
- 3640: PÓŁNOC FM and the city's sounds (loop MW-5, 2026-10-30)
- 3710: Fotka, Spacer, KASETA and the eggs (loop MW-6, 2026-10-30)
- 3803: The night and the river (loop MW-3, 2026-10-30)
- 3914: Everyday life and trends (loop MW-4, 2026-10-30)
- 4053: Storefronts and parodies (loop MW-2, 2026-10-30)
- 4145: The courier race, the round-up, the payphone and the armchair man (loop jobs-2, 2026-10-31)
- 4211: The Pędzik couriers at the stands and on the kerb (loop couriers, 2026-10-31)
- 4275: The night buses, the bus stops and the horn (loop night-buses, 2026-10-31)
- 4345: The vintage tram and E39 (loop vintage-tram, 2026-10-31)
- 4396: The garage: Warsztat u Mirka and the paint jobs (the garage loop, 2026-10-31)
- 4474: The easy-driving loop: drive through the small props (2026-10-30)
- 4485: The follow-camera loop: Point turns with the car, and a saved zoom (2026-10-30)
- 4511: The loading fix: the view's sectors first, proxies that look like the city (2026-10-31)
- 4592: Map north: Rondo Radosława, Arkadia and Forest (2026-10-31)
- 4691: Content POIs: corner shops, metro entrances, bike docks and the Leżaks (2026-10-31)
- 4737: The L-shaped map in gameplay (2026-10-31)
- 4784: Save v2 and the districts (loop 3h slice 1, 2026-10-31)
- 4862: Syrenki (loop 3h slice 2, 2026-10-31)
- 4904: The rival ladder and the final "Trzy mosty" (loop 3h slice 3, 2026-10-31)
- 4974: Performance budgets
- 5108: Map data
- 5254: The website (aroundwarsaw.app, 2026-10-29)
- 5268: The design wiki (wiki.aroundwarsaw.app, 2026-10-30)
- 5283: Layout
- 5625: The web build (2026-10-30)
