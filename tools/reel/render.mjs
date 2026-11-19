#!/usr/bin/env node
// Renders Around Warsaw's synthwave logo, background and the Reels end card from tools/reel/card.html
// with Playwright's Chromium (no image generator: the art is SVG and CSS in that page).
//
//   node tools/reel/render.mjs OUT_DIR [--style=neon|tail|orbit|open]
//                                                   the stills: logo-wordmark.png and logo-wordmark-stacked.png (transparent),
//                                                       logo-square-1080.png, background-1080x1920.png,
//                                                       card-1080x1920.png
//   node tools/reel/render.mjs OUT_DIR --card-frames=SECONDS [--fps=30]
//                                                       the animated end card as OUT_DIR/card/f_0000.png...
//
// Needs Node and the playwright package with a Chromium (the cloud containers have both; on a Mac:
// `npx playwright install chromium` once). Fonts come from site/public/fonts.
import { mkdirSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// require(), not import: it also finds a global playwright (NODE_PATH), which ESM imports never do.
const { chromium } = createRequire(import.meta.url)("playwright");
const here = dirname(fileURLToPath(import.meta.url));
const page_url = pathToFileURL(join(here, "card.html")).href;
const args = process.argv.slice(2);
const out = resolve(args.find((a) => !a.startsWith("--")) || "build/reel/art");
const opt = (name, dflt) => { const a = args.find((x) => x.startsWith(`--${name}=`)); return a ? a.split("=")[1] : dflt; };
mkdirSync(out, { recursive: true });

// WebGL 2 in a headless browser: ANGLE on SwiftShader (software) works everywhere.
const launch = { args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] };
if (process.env.CHROME) launch.executablePath = process.env.CHROME;
const browser = await chromium.launch(launch);
async function open(mode, w, h) {
	const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
	page.on("pageerror", (e) => { console.error(`render.mjs: ${mode}: ${e.message}`); process.exitCode = 1; });
	await page.goto(`${page_url}?mode=${mode}&w=${w}&h=${h}&style=${opt("style", "neon")}`);
	await page.evaluate(() => document.fonts.ready);
	await page.evaluate(() => window.frame(99));
	return page;
}

const seconds = parseFloat(opt("card-frames", "0"));
if (seconds > 0) {
	const fps = parseInt(opt("fps", "30"), 10);
	const page = await open("card", 1080, 1920);
	mkdirSync(join(out, "card"), { recursive: true });
	const n = Math.round(seconds * fps);
	for (let i = 0; i < n; i++) {
		await page.evaluate((t) => window.frame(t), i / fps);
		await page.screenshot({ path: join(out, "card", `f_${String(i).padStart(4, "0")}.png`) });
	}
	console.log(`render.mjs: ${n} card frames in ${join(out, "card")}`);
} else {
	const shots = [
		["card", 1080, 1920, "card-1080x1920.png", false],
		["bg", 1080, 1920, "background-1080x1920.png", false],
		["square", 1080, 1080, "logo-square-1080.png", false],
		["wordmark", 2400, 600, "logo-wordmark.png", true],
		["wordmark2", 1600, 900, "logo-wordmark-stacked.png", true],
	];
	for (const [mode, w, h, file, transparent] of shots) {
		const page = await open(mode, w, h);
		await page.screenshot({ path: join(out, file), omitBackground: transparent });
		console.log(`render.mjs: ${join(out, file)}`);
	}
}
await browser.close();
