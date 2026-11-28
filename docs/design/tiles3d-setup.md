# Google Photorealistic 3D Tiles as a reference source

Tool: `tools/tiles3d/render.mjs` (Map Tiles API, viewed live in CesiumJS in headless Chromium).
It renders one building from N orbit angles (default 6) plus a top-down into the gitignored
`refs/<slug>/3dtiles/`, with a `SOURCES.md` line per image. Every image carries Google's logo
and data attribution (Cesium's credit bar) and a label saying it is a reference.

```zsh
node tools/tiles3d/render.mjs --lat=52.24635 --lon=21.01530 --slug=st_anne --radius=35
node tools/tiles3d/render.mjs 512 -120 --slug=NAME          # game metres (+x east, +z south)
node tools/tiles3d/render.mjs --building="Ufficio Primo" --slug=ufficio_primo   # by name in centrum.json
node tools/tiles3d/render.mjs --lat=52.2479 --lon=21.0137 --slug=plac_zamkowy --area=90   # a square: 8 orbits + top
#   --angles=6 --heading0=0 --pitch=-28 --range=R --no-faces --height=H --no-top --size=1600x1200 --timeout=150 --out=DIR
```

`--radius` is roughly the building's half-size in metres; the camera sits at 2.6 x radius.
A building run also makes a **face ring**: 4 square-on views at pitch -10, aligned to the
footprint's longest edge, the range fitted to the full height (the mesh's own roof height or
`centrum.json`'s, whichever is higher) and width, for storeys, bays and wall heights. Same run,
same single bill. `--area=R` is for a square or a street front: 8 orbits at pitch -35 plus the
top, no faces. Turntable pairing: heading = (360 - turntable yaw) % 360, and `--angles=8
--pitch=-25` matches the turntable's low ring.
`--building` takes the name from `game/map/centrum.json` (buildings or landmarks) and sets the
centre and radius from its footprint, the easiest way to aim.
The first run installs CesiumJS from npm into `build/tiles3d_deps/` (gitignored). Rendering is
software WebGL (SwiftShader), so a view takes 10-70 s in the cloud (a building run, 11 views, about 7-8 min); on the Mac it is
the same command (Node + `npx playwright install chromium` once).

## Terms (Google Maps Platform)

- View live only. No caching, exporting, scraping or tracing of the mesh, and nothing from it
  goes into the game, the repo or the bakes. The tool loads tiles in a fresh temporary browser profile,
  deleted at exit, and saves only screenshots.
- Screenshots are local-only modelling references that never leave `refs/`: not in the repo,
  posts, PRs or artifacts, never shipped, traced or used as textures. Google's attribution stays visible on them.
- We read shapes from them by eye and write values into the spec (model-from-photos skill).

## Key and costs

- **Since 28 Nov 2026 Google answers 403** "satellite tiles and 3D tiles are not available for
  your account and region" for our project: Google's EEA terms (since 8 Jul 2025) block
  Photorealistic 3D Tiles for Cloud projects whose billing account address is in the EEA (ours
  bills in zł). Street View and roadmap tiles still work.
- So the tool takes `CESIUM_ION_TOKEN` first: the same Google tiles through Cesium ion's asset
  2275207 (Cesium's own Google contract; free Community account, non-commercial, which fits a
  free fan game). Same terms as below; the Cesium ion and Google credits show on every image.
  F's token is an environment secret like the Google key, never in a file or chat.
  Hosts: `api.cesium.com`, `assets.ion.cesium.com` (allowed in the cloud environment 2026-11-28).
- Without it: `GOOGLE_MAPTILES_KEY` if set, else `GOOGLE_STREETVIEW_KEY`. The existing restricted key
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
