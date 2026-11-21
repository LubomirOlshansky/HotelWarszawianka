# aroundwarsaw.app

The game's landing page. English at `/` (the default), Polish at `/pl/`, the privacy policy at
`/privacy/`, support (both languages, the stores' support URL) at `/support/`. Static files, self-hosted fonts, one small script (forms, slider, hero loop, phone sticky bar; under 6 KB), no cookies, no
tracking scripts. Visits come from Cloudflare's own traffic numbers, store-button clicks from
`worker.js` (below).

| File | What |
| --- | --- |
| `src/index.html` | the landing's template, `{{key}}` placeholders |
| `src/strings.json` | all the copy in `en` and `pl`, plus the data the page is built from: `hero` (the poster's image name, as before), `hero_video` (`ver`, poster size), `chapters` (the four city chapters: image, size, `side`, optional `clip`, texts), `dn` (the day/night pair), `quests` (the frame and the five rows; a row's optional `crop` is `none` for the whole wide shot, or `left`/`right` to keep that side of a shot whose card or bubble sits there when the phone crops it), `join_bg`, `author` (raw HTML, for the link), `topics`, and the Google Play slot (`android_live`, `android_url`) |
| `public/progress/index.html` | **built**: what was added or improved each day (`tools/changelog.py` from `docs/CHANGELOG.md` and ROADMAP's progress log) with links to the backlog; run `python3 -I tools/site_build.py` before every deploy so it is current |
| `public/index.html`, `public/pl/index.html`, `public/privacy/index.html`, `public/support/index.html` | **built**, never edited by hand: `python3 -I tools/site_build.py` (the privacy page comes from `docs/privacy.md`, support from `docs/support.md`) |
| `public/styles.css` | all styles; colours and fonts are tokens on `:root` |
| `public/site.js` | the two forms (feedback and the Android "tell me when": check, post to Formspree in place, say how it went; without JavaScript they still post), the day/night slider, the hero loop and chapter clips, `data-os` on `<html>`, the phone sticky bar |
| `public/img/game/` | screenshots, `<name>.webp` (1920 px wide) and `<name>-960.webp` for phones; `img/og.jpg` is the 1200×630 link preview |
| `public/fonts/` | Pixelify Sans (display) and Manrope (text), WOFF2, OFL licences beside them |
| `public/video/` | the hero loop and chapter clips (not in git until they exist; see "Video") |
| `public/_headers` | security headers (a CSP that allows only this site and Formspree), caching (`/video/*` one year, immutable) |
| `worker.js` | the Worker in front of the static files: only `/go/ios` and `/go/android` run it (count the click, 302 to the store, or, while `IOS_URL`/`ANDROID_URL` in `wrangler.jsonc` are empty, to the page's own card in the visitor's language: `/#android` or `/pl/#android`, `/#beta` or `/pl/#beta`) |
| `wrangler.jsonc` | the Cloudflare Worker that serves `public/` and owns the custom domains |

Design notes: the world is the game's night city (sodium lamps, one pink neon, the car radio).
The page reads: top bar (the Join button always in it) → hero (the Rotunda in the rain, framed as it
always was; the loop plays on top of the same crop once its files exist) → Kebab FM ticker → "The
real centre of Warsaw": four full-bleed chapters (Centrum, Stare Miasto, Wisła with the day/night
slider, Wola) → "Things to do tonight" (the game's QUESTS list: one frame, five rows; a scroll-snap
strip on phones) → "New every day" (built from `tools/changelog.py`, the same source as /progress/:
the newest day's date and its first three lines) → "Come for a drive" (two equal platform cards, a QR
code on desktop only, the folded "Write to me" form) → about the author → footer. No wiki links, no
licence line, no tester quotes, no invented numbers: every figure on the page is checked against
game/data or game/scripts (the places are "more than 70", the notebook has 79; 21 km² is the demo box
with the map-north strip, 21.2 km²; seven first steps, `first_steps.gd`; six rivals, `ladder.gd`; four
bridges and the jet ski, `boat_race.gd`). One moving part besides the ticker and the loop. The Impeccable
skill (`.claude/skills/impeccable`) guided the craft floor (contrast, type, focus, motion).

The QR code is made at build time by a small encoder inside `tools/site_build.py` (byte mode, error
correction M, versions 1-3, so up to 42 bytes) and points to `https://aroundwarsaw.app/go/ios?src=qr`.
It shows from 900 px wide only.

## Change the copy or the screenshots

1. Edit `src/strings.json` (both languages) or `src/index.html`.
2. `python3 -I tools/site_build.py`
3. Look at it: `cd site/public && python3 -m http.server 8765`, then http://localhost:8765 and
   http://localhost:8765/pl/ at phone and desktop width.

New screenshots: render them with `--nohud` at 2868×1320 (`tools/shots.sh`, README "flags"),
save each as WebP at 1920 px and 960 px wide (quality about 82), put them in
`public/img/game/` and name them in `strings.json` (`hero`, `chapters[].img`, `quests`, `dn`, `join_bg`): swapping a picture is a data change.

## The form

Both forms post to the Around Warsaw project's own Formspree form "Website beta signup" (`xjyweqgn`;
the in-game feedback card posts to "In-game feedback", `maeodgey`, see `game/scripts/feedback.gd`). The feedback
form sends the subject `Around Warsaw: <topic>` and `source: aroundwarsaw.app (en|pl)`, so the messages are
easy to filter. Topics: feedback, something broke, an idea; the phone type rides along. The beta signup
("notify") posts the email, `platform` (iPhone or Android, preselected from the visitor's phone) and the
`_subject` "Around Warsaw: open beta, notify me". Free plan: Formspree caps submissions per month. If a form is
restricted to certain domains, add `aroundwarsaw.app`.

## Deploy

The site is a Cloudflare Worker with static assets only. `wrangler deploy` uploads `public/`
and attaches `aroundwarsaw.app` and `www.aroundwarsaw.app` as custom domains (the zone is in
the same Cloudflare account; Cloudflare makes the DNS records and the certificate).

**By hand, from the Mac:**

```zsh
cd site
npx wrangler@4 deploy        # npx wrangler@4 login first if it asks
npx wrangler@4 rollback      # back to the previous version if something is wrong
```

**Automatically, from GitHub**: `.github/workflows/site.yml` checks that the privacy and support pages match
`docs/privacy.md` and `docs/support.md`, rebuilds the landing (its "New every day" strip follows the changelog) and /progress/, and deploys on every push to `main` that touches the site,
once the repository has two secrets (Settings → Secrets and variables → Actions). Until then the workflow skips the deploy, and the site is deployed by hand from a checkout of `main` with wrangler logged in (`python3 -I tools/site_build.py && cd site && npx wrangler@4 deploy`):

- `CLOUDFLARE_API_TOKEN`: Cloudflare → My Profile → API Tokens → Create Token → template
  "Edit Cloudflare Workers"; under Zone Resources include the `aroundwarsaw.app` zone.
- `CLOUDFLARE_ACCOUNT_ID`: shown on the Cloudflare dashboard's Workers & Pages overview.

## Google Play slot: flipping it when Google approves

One value drives it at build time. **Now** (`"android_live": false` in `src/strings.json`): the hero
and sticky-bar Android button is an outlined link to `#android` ("Google Play, opening soon"), the
Android card has one email field ("Tell me when", one promised email), and `ANDROID_URL` in
`wrangler.jsonc` is empty so `/go/android` lands on that card (counted all the same).

**When the open test is live:**
1. Check the Play listing from a Google account that was never a tester, on a phone and on a desktop.
2. `src/strings.json`: `"android_live": true` (`android_url` stays `/go/android`).
3. `wrangler.jsonc`: put the Play URL into `ANDROID_URL`.
4. `python3 -I tools/site_build.py`, deploy. The Android buttons become filled and equal to the iPhone
   ones, the card shows the button and "The phone needs Vulkan.", the email field is gone.
5. Send the one promised email to everyone who signed up (the Formspree inbox, subject "Android beta, notify").

## Video

The page works with the poster alone and leaves the `<video>` out while the files are missing (the build
prints a note). Put the files in `public/video/` (long cache, so change the `ver` when a file changes):

| File | Size | Used for |
| --- | --- | --- |
| `hero-<ver>.webm` / `.mp4` | 1920x1080, 30 fps, about 8 s loop, no audio, ~2.5 MB | the hero on wide screens |
| `hero-phone-<ver>.webm` / `.mp4` | 720x900, same, ~1 MB | the hero on phones (up to 700 px) |
| `<clip>.webm` / `.mp4` | 1280x720, 5-8 s, up to ~1.2 MB | a chapter, if its `clip` key in `strings.json` names it; desktop only, plays while on screen |

`hero_video.ver` in `strings.json` sets `<ver>`; the poster stays the `hero` image. The loop starts only
without reduced motion, Save-Data or a 2g link, pauses off screen and in a hidden tab, and has a pause
button (WCAG 2.2.2). Encode WebM (VP9) first and H.264 (`yuv420p`, `+faststart`) second, audio stripped.

## The phone's sticky bar

JavaScript only: it appears once the hero has left the screen and hides while the join section is
visible. `site.js` sets `data-os="ios|android|other"` on `<html>` (an iPad says "Macintosh", so a Mac with
touch points counts as iOS); "other" shows TestFlight.

## Visitors and store clicks (no cookies, no scripts)

- **Visits**: dashboard.cloudflare.com -> pick the account -> **Websites** -> `aroundwarsaw.app`
  -> **Analytics & Logs** -> **Traffic** (unique visitors, requests, countries, top pages;
  server-side, so no script on the page). If it is empty, the zone is not proxied: **Web
  Analytics** -> **Add a site** also works but needs a beacon script (and a CSP change).
- **Store clicks**: dashboard -> **Workers & Pages** -> `aroundwarsaw` -> **Logs** (Observability):
  one `store_click` line per click with `button`, `lang`, `country`; group by `button` to count.
  The same clicks go to the Analytics Engine dataset `aroundwarsaw_clicks`; query it with
  `curl https://api.cloudflare.com/client/v4/accounts/$ACCOUNT/analytics_engine/sql -H "Authorization: Bearer $TOKEN" -d "SELECT blob1 AS button, blob3 AS country, SUM(_sample_interval) AS clicks FROM aroundwarsaw_clicks GROUP BY button, country"`
  (token with Account Analytics: Read).
- **When the apps are listed**: put the URLs in `vars` in `wrangler.jsonc` (for Android also the
  `android_live` flip above), `python3 -I tools/site_build.py`, deploy. QR joins arrive as `/go/ios?src=qr` in the logs' URL.
