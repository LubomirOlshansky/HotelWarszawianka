# Our entry for the Slop Cities list

[Slop Cities](https://github.com/zz85/slop-cities) is zz85's list and world map of city sims in the
spirit of mrdoob's Slop New York. Entries go through a pull request on its `cities.yml` (read
2026-10-30 with its `CONTRIBUTING.md`; re-read both before opening the PR, the format may have
moved on). **Nothing has been sent: opening the PR is the user's call.**

Warsaw is already listed (Tiny Warsaw first, then Isometric Warsaw and Szczęśliwe Bielany), so
ours is another take on that city: a new item at the end of Warsaw's `takes`, with a `tag`.

## The entry

Under `cities.regions` → `Europe` → `- city: Warsaw` → `takes:`, after the last take
(Szczęśliwe Bielany), at the same indentation as the other takes:

```yaml
          - tag: Around Warsaw
            source: (repo link withheld; the repo is not linked publicly)
            by: LubomirOlshansky
            desc: A small-car arcade drive and a helicopter through the real centre, with gentle police, side jobs, a car radio and Warsaw humour; Godot 4.7 for iPhone and Android, from OSM and GUGiK data.
            flags: [source only, isometric, own engine]
            screenshot: screenshots/warsaw-around.jpg
```

- No `play` link: there is no web build (the ROADMAP plans one after the demo; add `play:`
  then, and drop `source only`).
- `by: LubomirOlshansky` is a bare name, so the list links it to github.com/LubomirOlshansky.
  Use `by: "@handle"` instead if you'd rather it linked an x.com account; add `tweet:` with a
  post's link (no `?s=` tracking parameters) if you announce the game.
- `own engine`: the game is not built on Slop New York's code (Godot), so the map draws no arc
  from New York. `isometric`: an isometric view. `source only`: no live demo yet.
- The screenshot is `docs/media/slop-cities-around-warsaw.jpg` (1280 × 720 JPEG, 416 KB, the
  Palace from the helicopter at golden hour, no HUD). Their `CONTRIBUTING.md` sets no size;
  copy it into their `screenshots/` as `warsaw-around.jpg`.

## How to open the pull request (when you decide to)

1. On github.com/zz85/slop-cities, press **Fork**.
2. Clone your fork and make a branch:
   `git clone https://github.com/<you>/slop-cities.git && cd slop-cities && git switch -c add-around-warsaw`
3. Paste the entry above into `cities.yml` (Warsaw's `takes`, last), and copy the screenshot:
   `cp <this repo>/docs/media/slop-cities-around-warsaw.jpg screenshots/warsaw-around.jpg`
4. Rebuild the lists (Node 18 or later, nothing else): `node map/build/build.mjs`. It rewrites
   README.md and `map/data/cities.json` and names the field if something is wrong;
   `node map/build/build.mjs --check` should then report both up to date.
5. Commit `cities.yml`, README.md, `map/data/cities.json` and the screenshot together, e.g.
   "Add Around Warsaw (Warsaw, Godot)", push, and open the pull request against `zz85/slop-cities`
   `gh-pages` (its default branch, the one the map is served from). A short description is
   enough: what it is, that it is source only for now, and that the repo is MIT.
