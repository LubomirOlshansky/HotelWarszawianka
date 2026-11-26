# Google Photorealistic 3D Tiles as a reference source

Tool: `tools/tiles3d/render.mjs` (Map Tiles API, viewed live in CesiumJS in headless Chromium).
It renders one building from N orbit angles (default 6) plus a top-down into the gitignored
`refs/<slug>/3dtiles/`, with a `SOURCES.md` line per image. Every image carries Google's logo
and data attribution (Cesium's credit bar) and a label saying it is a reference.

```zsh
node tools/tiles3d/render.mjs --lat=52.24635 --lon=21.01530 --slug=st_anne --radius=35
node tools/tiles3d/render.mjs 512 -120 --slug=NAME          # game metres (+x east, +z south)
node tools/tiles3d/render.mjs --building="Ufficio Primo" --slug=ufficio_primo   # by name in centrum.json
#   --angles=6 --heading0=0 --pitch=-28 --range=R --no-top --size=1600x1200 --timeout=150 --out=DIR
```

`--radius` is roughly the building's half-size in metres; the camera sits at 2.6 x radius.
`--building` takes the name from `game/map/centrum.json` (buildings or landmarks) and sets the
centre and radius from its footprint, the easiest way to aim.
The first run installs CesiumJS from npm into `build/tiles3d_deps/` (gitignored). Rendering is
software WebGL (SwiftShader), so a view takes 10-70 s in the cloud (a 7-view run about 5 min); on the Mac it is
the same command (Node + `npx playwright install chromium` once).

## Terms (Google Maps Platform)

- View live only. No caching, exporting, scraping or tracing of the mesh, and nothing from it
  goes into the game, the repo or the bakes. The tool loads tiles in a fresh temporary browser profile,
  deleted at exit, and saves only screenshots.
- Screenshots are local-only modelling references that never leave `refs/`: not in the repo,
  posts, PRs or artifacts, never shipped, traced or used as textures. Google's attribution stays visible on them.
- We read shapes from them by eye and write values into the spec (model-from-photos skill).

## Key and costs

- Key: `GOOGLE_MAPTILES_KEY` if set, else `GOOGLE_STREETVIEW_KEY`. The existing restricted key
  (Google Cloud project "Around Warsaw release", "Maps Platform API Key") allows Street View
  Static API and Map Tiles API only, so the one environment secret serves both tools. Never in
  a file, never in chat.
- Billing: one run makes one root tileset request (the billable unit of Photorealistic 3D Tiles;
  the tiles of that session are not billed separately). There is a free monthly tier, then paid;
  check current pricing in the console. The project's daily quota cap on Map Tiles and the
  budget alert stop runaway use.

## One-time setup (done 2026-11-26)

1. console.cloud.google.com, project "Around Warsaw release" > APIs & Services > Library >
   "Map Tiles API" > Enable (needs the EEA Terms of Service accepted by the account owner).
2. Credentials > "Maps Platform API Key" > API restrictions: add Map Tiles API next to
   Street View Static API. Save.
3. Map Tiles API > Quotas & system limits: cap the 3D root tileset requests per day low.
4. Billing budget alert: the existing one covers it.

## Reachability

`tile.googleapis.com` is reachable from the cloud containers (checked 2026-11-26), so cloud
threads can render. If a future network policy blocks it, run the same command on the Mac.
