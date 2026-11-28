#!/usr/bin/env node
// Live reference renders of one building from Google Photorealistic 3D Tiles (Map Tiles API),
// viewed in CesiumJS in headless Chromium: N orbit views plus a top-down, saved to the gitignored
// refs/<slug>/3dtiles/ with a SOURCES.md line each.
//
//   node tools/tiles3d/render.mjs --lat=52.2465 --lon=21.0153 --slug=st_anne [--radius=35]
//   node tools/tiles3d/render.mjs X Z --slug=NAME              (game metres, +x east, +z south)
//   node tools/tiles3d/render.mjs --building="Ufficio Primo" --slug=NAME   (name in game/map/centrum.json;
//                                                               centre and radius from its footprint)
// Turntable pairing: heading = (360 - turntable yaw) % 360; --angles=8 --pitch=-25 matches its low ring.
// Options: --angles=6 (orbit views, evenly spaced from --heading0=0, 0 = looking north)
//          --pitch=-28 (orbit camera pitch, degrees) --range=R (camera distance; default 2.6 x radius)
//          --no-faces (skip the 4 square-on face views at pitch -10, fitted to the full height;
//          on by default, aligned to the footprint's longest edge with --building) --height=H (m)
//          --area=R (a square or street front: 8 orbits at pitch -35 plus the top, no faces, radius R)
//          --no-top (skip the top-down view) --size=1600x1200 --timeout=150 (seconds per view)
//          --out=DIR (default refs/<slug>/3dtiles)
//
// Key: CESIUM_ION_TOKEN first (Google's tiles through Cesium ion asset 2275207: Google blocks 3D Tiles
// for EEA-billed Cloud projects since 28 Nov 2026, HTTP 403 "not available for your account and
// region"), else GOOGLE_MAPTILES_KEY, else GOOGLE_STREETVIEW_KEY (the same restricted key with Map
// Tiles API added). An environment secret, never in a file, never printed. Setup: docs/design/tiles3d-setup.md.
//
// Google's Map Tiles terms: view live only. Nothing here caches, exports or traces the mesh: the tiles
// live only for one run (a fresh temporary browser profile, deleted at exit) and only
// screenshots with Google's attribution on them are saved, as local modelling references (refs/ is
// gitignored; never committed, shipped, traced or used as textures). One run is one root tileset
// request (the billable unit; free monthly tier, then paid), however many views.
//
// Needs Node, the playwright package with a Chromium (the cloud has both; on a Mac
// `npx playwright install chromium` once) and CesiumJS, which the first run installs from npm into
// build/tiles3d_deps/ (gitignored, ~20 MB of the Cesium build used).
import { execFileSync } from "node:child_process";
import { appendFileSync, existsSync, mkdirSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const CESIUM_VERSION = "1.123.1";
const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "..", "..");
const args = process.argv.slice(2);
const opt = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.slice(name.length + 3) : dflt; };
const flag = (name) => args.includes(`--${name}`);
const die = (msg) => { console.error(`tiles3d_render: ${msg}`); process.exit(1); };

// Game X/Z -> lat/lon, the same projection as tools/bake_osm.py (ORIGIN, M_PER_DEG_*).
const ORIGIN = [52.2340, 21.0240];
const M_LAT = 110574.0, M_LON = 111320.0 * Math.cos(ORIGIN[0] * Math.PI / 180);
let lat = Number(opt("lat", NaN)), lon = Number(opt("lon", NaN));
let xz = args.filter((a) => !a.startsWith("--")).map(Number);
let autoRadius = NaN, autoHeight = NaN, faceBearing = NaN;
const building = opt("building", "");
if (building) {
	// The footprint from the baked map: its bounding-box centre and half its longest side.
	const mapFile = join(root, "game", "map", "centrum.json");
	if (!existsSync(mapFile)) die("--building needs game/map/centrum.json (tools/setup_map.sh)");
	const map = JSON.parse(readFileSync(mapFile, "utf8"));
	const hits = [...map.buildings, ...map.landmarks].filter((b) => (b.name || "").toLowerCase() === building.toLowerCase());
	if (!hits.length) die(`no building or landmark named "${building}" in centrum.json`);
	const p = hits[0].p;
	const xs = p.filter((_, i) => i % 2 === 0), zs = p.filter((_, i) => i % 2 === 1);
	const [x0, x1, z0, z1] = [Math.min(...xs), Math.max(...xs), Math.min(...zs), Math.max(...zs)];
	xz = [(x0 + x1) / 2, (z0 + z1) / 2];
	autoRadius = Math.max(x1 - x0, z1 - z0) / 2 + 5;
	autoHeight = Number(hits[0].h) || NaN;
	// The longest footprint edge sets the face ring's square-on headings (+x east, +z south).
	let best = 0;
	for (let i = 0; i < xs.length; i++) {
		const dx = xs[(i + 1) % xs.length] - xs[i], dz = zs[(i + 1) % zs.length] - zs[i];
		const len = Math.hypot(dx, dz);
		if (len > best) { best = len; faceBearing = ((Math.atan2(dx, -dz) * 180 / Math.PI) % 90 + 90) % 90; }
	}
	console.log(`tiles3d_render: "${building}" at game ${xz[0].toFixed(0)} ${xz[1].toFixed(0)}, radius ${autoRadius.toFixed(0)} m`);
}
if (xz.length === 2) { lat = ORIGIN[0] - xz[1] / M_LAT; lon = ORIGIN[1] + xz[0] / M_LON; }
if (!Number.isFinite(lat) || !Number.isFinite(lon)) die("give X Z or --lat= --lon=");
const slug = opt("slug", "");
if (!/^[a-z0-9_-]+$/.test(slug)) die("--slug=NAME (lowercase letters, digits, _ -)");
const area = Number(opt("area", NaN));                  // area mode: a square or street front, radius in metres
const radius = Number(opt("radius", Number.isFinite(area) ? area : Number.isFinite(autoRadius) ? autoRadius : 35));
const range = Number(opt("range", radius * 2.6));
const angles = Math.max(1, Math.min(12, Number(opt("angles", Number.isFinite(area) ? 8 : 6))));
const height = Number(opt("height", Number.isFinite(autoHeight) ? autoHeight : 25));
const faces = !flag("no-faces") && !Number.isFinite(area);
const heading0 = Number(opt("heading0", 0));
const pitch = Number(opt("pitch", Number.isFinite(area) ? -35 : -28));
const [W, H] = opt("size", "1600x1200").split("x").map(Number);
const timeoutMs = Number(opt("timeout", 150)) * 1000;
const out = resolve(opt("out", join(root, "refs", slug, "3dtiles")));
const ion = process.env.CESIUM_ION_TOKEN || "";
const key = ion || process.env.GOOGLE_MAPTILES_KEY || process.env.GOOGLE_STREETVIEW_KEY || "";
if (!key) die("CESIUM_ION_TOKEN (or GOOGLE_MAPTILES_KEY / GOOGLE_STREETVIEW_KEY) not set; see docs/design/tiles3d-setup.md");

// CesiumJS from npm, once, into the gitignored build/ (the CDNs are blocked from the cloud).
const deps = join(root, "build", "tiles3d_deps");
const cesium = join(deps, "node_modules", "cesium", "Build", "Cesium");
if (!existsSync(join(cesium, "Cesium.js"))) {
	console.log(`tiles3d_render: installing cesium@${CESIUM_VERSION} into build/tiles3d_deps (once)`);
	mkdirSync(deps, { recursive: true });
	if (!existsSync(join(deps, "package.json"))) appendFileSync(join(deps, "package.json"), '{"private":true}\n');
	execFileSync("npm", ["install", `cesium@${CESIUM_VERSION}`, "--no-audit", "--no-fund", "--silent"], { cwd: deps, stdio: "inherit" });
}

// A tiny local server for the page and Cesium's static build (workers need http, not file://).
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json",
	".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml", ".wasm": "application/wasm", ".ktx2": "image/ktx2" };
const server = createServer((req, res) => {
	const path = decodeURIComponent(new URL(req.url, "http://x").pathname);
	const file = path === "/" ? join(here, "page.html")
		: path.startsWith("/cesium/") ? join(cesium, normalize(path.slice(8)).replace(/^(\.\.[/\\])+/, "")) : "";
	if (!file || !file.startsWith(path === "/" ? here : cesium) || !existsSync(file) || !statSync(file).isFile()) {
		res.writeHead(404); res.end(); return;
	}
	res.writeHead(200, { "Content-Type": types[extname(file)] || "application/octet-stream" });
	res.end(readFileSync(file));
});
await new Promise((ok) => server.listen(0, "127.0.0.1", ok));
const port = server.address().port;

const { chromium } = createRequire(import.meta.url)("playwright");
const launch = { args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--disk-cache-size=1"] };
if (process.env.CHROME) launch.executablePath = process.env.CHROME;
const browser = await chromium.launch(launch);
let failed = false;
try {
	const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
	page.on("pageerror", (e) => console.error(`tiles3d_render: page: ${String(e.message).replaceAll(key, "KEY")}`));
	// The key rides in the fragment, which browsers never send to the server.
	await page.goto(`http://127.0.0.1:${port}/#${ion ? "ion" : "key"}=${encodeURIComponent(key)}`);
	await page.waitForFunction(() => window.status_ && (window.status_.ready || window.status_.error), null, { timeout: 60000 });
	const err = await page.evaluate(() => window.status_.error);
	if (err) die(`tileset did not load: ${err.replaceAll(key, "KEY")} (${ion ? "is the ion token valid?" : "is Map Tiles API enabled and allowed on the key? An EEA-billed project gets 403: set CESIUM_ION_TOKEN"})`);

	// Find the ground: look from above first so tiles load, then sample the mesh at the point.
	await page.evaluate(([la, lo, r, t]) => window.shoot(la, lo, 120, 0, -89.9, r * 4, "", t), [lat, lon, radius, timeoutMs]);
	// The street, not the roof: the lowest sample of the centre and four points just outside the footprint.
	const off = (radius + 8) / M_LAT, offLon = (radius + 8) / M_LON;
	const spots = [[lat, lon], [lat + off, lon], [lat - off, lon], [lat, lon + offLon], [lat, lon - offLon]];
	const samples = [];
	for (const [la, lo] of spots) samples.push(await page.evaluate(([a, b, t]) => Promise.race([window.ground(a, b), new Promise((ok) => setTimeout(() => ok(null), t))]), [la, lo, 40000]));
	let ground = samples.filter((h) => h !== null).reduce((m, h) => Math.min(m, h), Infinity);
	if (!Number.isFinite(ground)) ground = null;
	// The mesh's own roof height beats the map's when the map's is lower (and no --height was given).
	const roofH = samples[0] !== null && ground !== null ? samples[0] - ground : 0;
	const faceHeight = opt("height", "") ? height : Math.max(height, roofH);
	if (ground === null) { console.warn("tiles3d_render: no ground sample, using 140 m"); ground = 140; }
	const aim = ground + Math.min(radius * 0.35, 15);   // a little up the facade, not the pavement

	mkdirSync(out, { recursive: true });
	const day = new Date().toISOString().slice(0, 10);
	const views = [];
	for (let i = 0; i < angles; i++) views.push({ name: `h${String(Math.round((heading0 + i * 360 / angles) % 360)).padStart(3, "0")}`, heading: (heading0 + i * 360 / angles) % 360, pitch, range });
	if (faces) {
		// Square-on face ring: low pitch, range fitted so the whole height and width are in frame
		// (Cesium's 60 degree fov spans the wider side; 4:3 leaves ~47 degrees vertically).
		const vfov = 2 * Math.atan(Math.tan(Math.PI / 6) * Math.min(W, H) / Math.max(W, H));
		const fit = Math.max((faceHeight * 1.6 / 2) / Math.tan(vfov / 2), (radius * 2.1 / 2) / Math.tan(Math.PI / 6));
		const b0 = Number.isFinite(faceBearing) ? faceBearing : heading0;
		for (let k = 0; k < 4; k++) {
			const hd = (b0 + k * 90) % 360;
			views.push({ name: `face${String(Math.round(hd)).padStart(3, "0")}`, heading: hd, pitch: -10, range: fit, aim: ground + faceHeight * 0.42, far: fit * 4 });
		}
	}
	if (!flag("no-top")) views.push({ name: "top", heading: 0, pitch: -89.9, range: range * 1.15 });
	for (const v of views) {
		const what = v.name === "top" ? "top-down, north up" : `${v.name.startsWith("face") ? "face, " : ""}camera looking ${Math.round(v.heading)}°`;
		const label = `${slug} · ${what} · Google 3D Tiles, reference only`;
		const res = await page.evaluate(([la, lo, h, hd, p, r, l, t, f]) => window.shoot(la, lo, h, hd, p, r, l, t, f),
			[lat, lon, v.aim ?? aim, v.heading, v.pitch, v.range, label, timeoutMs, v.far ?? 0]);
		const file = join(out, `${slug}_${v.name}.png`);
		await page.screenshot({ path: file });
		appendFileSync(join(out, "SOURCES.md"), `- ${day} ${slug}_${v.name}.png: Google Photorealistic 3D Tiles (Map Tiles API), live render, `
			+ `target ${lat.toFixed(6)},${lon.toFixed(6)} ground ${ground.toFixed(1)} m, heading ${v.heading.toFixed(0)}, pitch ${v.pitch}, range ${v.range.toFixed(0)} m`
			+ `${res.settled ? "" : ", TIMED OUT (partly loaded)"}. Reference only: not committed, shipped, traced or textured.\n`);
		console.log(`tiles3d_render: ${file} (${(res.ms / 1000).toFixed(1)} s${res.settled ? "" : ", timed out, partly loaded"})`);
		if (!res.settled) failed = true;
	}
} finally {
	await browser.close();
	server.close();
}
console.log(failed ? "tiles3d_render: done, some views timed out (raise --timeout)" : "tiles3d_render: OK");
