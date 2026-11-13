---
name: screenshot-review
description: Takes Around Warsaw screenshots at real phone sizes with tools/shots.sh (spawn, Marszałkowska, the Palace, the river, Rondo Dmowskiego, helicopter, settings; day, night, rain; runtime and prebuilt city) and judges them against the art bible for readability, consistency and defects. Use after any visible change, for before/after pairs, when reviewing 2D art in the game, and when asked "how does it look?" or "what looks worst?".
argument-hint: "[--set=core|quick|name,name] [--size=2532x1170] [--tag=before|after]"
---

# Screenshots at phone size, and how to judge them

## Take them

```zsh
tools/shots.sh $ARGUMENTS                       # core set, 2532x1170, into shots/review_<time>/
tools/shots.sh --set=quick --tag=before         # spawn by day (runtime) + night (prebuilt)
tools/shots.sh --size=2868x1320 --set=spawn_day # the user's 6.9" Pro Max
tools/shots.sh --set=river_night -- --quality=low --style=2   # extra game flags for every shot
tools/shots.sh --list                           # the named shots
```

Each shot opens a window for ~10-30 s (it needs a renderer), runs with `--nosave --free`, and
quits by itself. Shots go to `shots/` (gitignored); give files a loop prefix when they are
evidence for a report (`shots/loop3_*.png`). For a spot not in the list:
`cd game && godot --path . --resolution 2532x1170 --fixed-fps 60 -- --nosave --free --at=X,Z
--heading=DEG --shots=240 --out=$PWD/../shots/NAME` (DEVELOPMENT.md lists every flag: `--size=`
view height in metres, `--yaw=`, `--lift=`, `--nohud`, `--tap=X,Y`, `--settings`, ...).

**Before/after of a place: use the free camera, not the car.** `--cam=X,Z` (or `--cam=X,Y,Z` for a
height) puts the view on that world point, fixed, with the car hidden under it; `--yaw=`, `--pitch=`,
`--size=` orbit and zoom it, `--lift=` raises it, `--cam-car` keeps the car in the shot. Same flags on
the runtime and the `--prebuilt` city, so a before and an after differ only in what changed:
`tools/shots.sh --set=spawn_day -- --cam=-1290,170 --yaw=135 --size=60`. Many views in one run (a run is
~40 s): `--cams="palace:-1290,,170,135,-30,120+arcade:-1113,,-263,45,-30,60"` (NAME:X,Y,Z,YAW,PITCH,SIZE,
Y empty = ground, the last three optional) writes palace_0030.png, arcade_0030.png with `--shots=30 --out=DIR`.

- Before/after: same spot, same flags, same size; render the "before" from a copy of the old
  code if the change is already in (`cp -cR game game_before` on APFS; `game_*/` is gitignored;
  delete it afterwards).
- Both city paths: anything the map builder makes needs a `--prebuilt` shot too.
- Night, dusk and rain are separate looks (`--time=`, `--weather=rain`): check the one you touched.
- Phone sizes: 2532x1170 (6.1" iPhone 12-15), 2868x1320 (6.9" Pro Max). Loop 2e: a window the
  size of a known iPhone gets that phone's points and safe area (`game/scripts/screen_points.gd`;
  2868x1320 is 956x440 pt), any other window is taken as a phone 390 pt tall, so these shots
  show real HUD sizes. `game/tools/check_hud.gd` measures them (44 pt, 11 pt, overlaps).

## The turntable: the first look at a model

For one landmark or model, start with `tools/turntable.sh KEY` (about a minute, one PNG sheet:
lit from 8 sides at two heights, flat, silhouette, top view; the site alone, nothing else drawn)
before any single shots. Then take single shots only for the sides that need a closer look.

## Look at them (open every PNG with Read; never judge a shot you didn't look at)

Judge against `art-bible.md` (next to this file; read it first). In order:

1. **Defects**: z-fighting, floating or sunken objects, cars or trams inside buildings or
   bridges, holes in decks, stray lines, wrong-path lighting, text clipped or overlapping,
   a black or flat area where a texture should be.
2. **Readability at the default view** (80 m, the car ~58 px long on 1170 lines): can you tell
   the car, the road, where to go, what is tappable? Is any HUD text under ~11 pt or any
   touch target under 44 pt?
3. **Consistency**: does a new thing share the city's palette, outlines, pixel scale and
   light? Does night read as night (dark, calm, lit by its lamps and neon)?
4. **Warsaw**: would someone from Warsaw recognise the place in the shot?

Measure when you can instead of guessing: crop and compare mean luma of a region against a
reference ring (loop 1 did this for the occlusion ghost), count pixels, compare before/after
with a pixel diff.

## Report

For each shot: path, what it shows, verdict (good / fix / blocker) with the specific thing
and where on the image ("upper left, the deck's parapet stops 3 m short of the tower"). Then
a ranked list "what looks worst", each with the likely cause if you know it, and the shots
you still need (exact `tools/shots.sh` commands).
