---
name: shoot-video
description: Shoots Around Warsaw video clips (Instagram Reels, Shorts, TikTok, trailer shots, site loops) with tools/clip.sh on the Mac's Movie Maker at any size, makes the synthwave logo and end card with tools/reel/render.mjs, and cuts and encodes them for each platform. Use when asked for a teaser, reel, short, promo clip, trailer shot, video for social media or the store, or the game's logo art.
argument-hint: "[reel|trailer|site] [shot names]"
---

# Shooting video of the game

The picture always comes from the game itself, rendered offline with Godot's Movie Maker
(`--write-movie`), so the game's own frame rate never shows in the clip. It does NOT prove the picture moved: Experimental takes stall at random on the start camera and Movie Maker repeats that frame (about one take in two at 1080x1920 on 2026-11-22); clip.sh fails such a take and retries it by itself. Art that
is not the game (the logo, the end card, the background) is drawn in code: `tools/reel/card.html`,
a WebGL port of the game's title screen (title.gdshader, the palm, the chrome wordmark in Open Sans)
rendered by Chromium; F chose that look on 2026-11-19 over a separate synthwave design. No image generator.

## Who does what

- **Plan (Opus):** the shot list, what to show and what to keep back, the cut's timing, the
  acceptance of the draft. Write it in `docs/<piece>/README.md` with the exact flags per shot.
- **Shoot (Sonnet, on F's Mac through Remote Control):** run `tools/clip.sh` per shot, look at
  each `NAME-sheet.png`, re-frame and re-shoot what is wrong, report the commands that worked.
  The Mac is shared: one user at a time, check `pgrep -fl godot` and `build/autopilot.lock` first,
  work in a worktree of the branch (`git worktree add build/<name>-wt <branch>`), copy the derived
  map files from the main checkout (game/map index.*, sectors/, proxies.scn, shared/, lod2.*,
  terrain.json and game/.godot) instead of re-baking. No commits from the Mac.
- **Cut and encode (cloud or Mac):** `docs/<piece>/cut.sh`, ffmpeg only. Re-timing a cut never
  needs a re-render: clips are shot 2-3 s long and the cut picks its second.

## Shoot a clip

```zsh
tools/clip.sh NAME WxH SECONDS [--fps=30] [--skip=4] [--preview] [--grade=d] [--retries=2] -- GAME FLAGS
tools/clip.sh bridge 1080x1920 3 -- --at=560,-770 --heading=52 --demo --time=dusk --pitch=-28 --size=60 --nohud --no-touch --quality=experimental --lines=1920
```

Out: `build/clips/NAME.mp4` (CRF 14 master, no audio), `NAME-sheet.png` (8 frames), `NAME.log`.
`--grade=d` bakes F's trailer grade D into the master; `--retries=N` re-renders a frozen or short take
by itself (default 2 more tries). A take with the wrong frame size or a governor view change fails at once.

### Lessons from the stadium re-shoot (2026-11-22): never shoot by hand

Every hand-built take that night hit a mistake clip.sh already guards against. Use clip.sh, and if a
shot needs something it can't do, add it to clip.sh instead of writing a render loop.
- **1080x1920, not 2160x3840.** Two of two 2160x3840 supersampled takes froze (about 15 min each);
  F: "if it not work, it not worth to try". All teasers so far are 1080x1920 at 30 fps (landscape 1920x1080).
- **The window is the frame.** Movie Maker writes the window's size unless override.cfg sets
  `window/stretch/mode="viewport"`: a 540x960 window gave 540x960 PNGs. clip.sh sets window = viewport.
- **`--governor=off` always**, even with a trailer or Experimental flag: the log said
  "governor: view back in (65 m)" and the take showed a dark sky instead of the stadium.
- **Judge the written PNG or MP4, never the live window.** The first seconds on screen are the skip
  (loading), and actors placed at launch (the promo heli, trams) may not be in frame yet.
- **Look at a middle frame before encoding** (clip.sh's sheet does this): rain keeps every frame
  different, so a wrong view passes the md5 freeze guard.
- **Re-bake before a `--prebuilt` shot after any map change** (bake_sectors.py, then bake_city.gd),
  or old geometry shows (the Jarmark stills mixed the old layout in).
- **One Godot on the Mac at a time**, including stills; tell the next thread when the Mac is free.
SECONDS and --skip are whole seconds. **Always pass `--lines=` equal to the video height** (`--lines=1920` for
Reels): the style draws a fixed line count (Sharp 480), so a tall frame without it is blown-up blocks.
Also pass `--governor=off`: otherwise the frame governor drops Experimental to Ultra mid-render.
Use a flag ARRAY in zsh (`Q=(--nohud ...)`), never a string, or the flags are silently dropped. `--preview` renders at half size and High for framing rounds.
**Reels are 30 fps** (F, 2026-11-21: "for Instagram we need 30 only"): leave `--fps` at 30; 60 only for a trailer
that F asked for in 60. **One Godot on the Mac at a time** (ask the coordinator who holds the Mac); run each
take under `caffeinate -dimsu` with the Godot window uncovered: a covered or sleeping window makes Movie
Maker repeat the last frame, and two Godots at once froze whole takes.

Flags that make shots (full table: `grep '^| \`--' docs/archive/DEVELOPMENT-full.md`):
`--at=X,Z --heading=DEG` place the car (x east, z south, heading clockwise from north);
`--demo` the car drives itself straight for ~200 frames then weaves (with `--heli`: a slow circle);
`--heli --heli-alt=M --heli-stick=X,Z` the helicopter flying one way; `--cam=X,Y,Z --yaw --pitch
--size` a fixed camera (car hidden unless `--cam-car`); `--size=M` the view height in metres
(portrait shows 9/16 of that across); `--time=day|dusk|night|dawn|live --clock=HH:MM
--date=YYYYMMDD --weather=rain`; `--nohud --no-touch --no-ghost`; `--quality=experimental`;
`--sectors=all` for wide views (about 5 GB a process); `--palace-lights=gold`.

Known spots: Marszałkowska to the Palace `--at=-1113,-263 --heading=160`; the Palace from above
`--cam=-1206,100,244 --yaw=225 --pitch=-35 --size=230`; Rondo Dmowskiego night hero
`--cam=-845,415 --yaw=0 --pitch=-32 --size=105 --time=night --weather=rain`; Stadion Narodowy
`--cam=1320,-490 --yaw=140 --pitch=-30 --size=300`; the Vistula by helicopter `--heli --at=1000,-180
--yaw=20 --size=70`; Most Świętokrzyski west foot about (503,-725), the pylon (747,-915), deck
heading about 52°; Wola towers `--at=-2610,395 --heading=270 --yaw=90 --pitch=-26 --size=130`.

Shots F accepted (copy these, don't rediscover them):
- **Teaser 5, Stadion Narodowy at night with the helicopter** (v2, 2026-11-22):
  `--cam=1145.4,-22.9,-296.0 --yaw=139.2 --pitch=-16.4 --size=485.5 --at=1480,-790 --game-clock
  --clock=20:49 --date=20261120 --promo-heli=684,33,1226,-133,24,1.0,3 --quality=experimental`, skip 8 s,
  7 s, `--grade=d`. `--at` keeps the car off the river (it spawns under the camera otherwise).
- **Teaser 4, the palm at Rondo de Gaulle'a**: `--cam=-178.5,260.8 --yaw=237.2 --pitch=-27.6 --size=117.3
  --date=20261120 --clock=15:20 --season=summer --promo-at --scoot-gang`. A Promo Mode VIEW is the whole
  phone height: a 1080x1920 clip needs VIEW x 0.818 as `--size`.

## Platform specs (checked 2026-11-19)

| Use | Size | Encode |
| --- | --- | --- |
| Instagram Reels, Shorts, TikTok | 1080x1920 (9:16), 30 fps | H.264 High, yuv420p, CRF 17-18, maxrate 14M, AAC 48 kHz 192k stereo, `+faststart`, max 90 s for Reels |
| Feed post | 1080x1350 (4:5) | same |
| Trailer, YouTube | 1920x1080, 30 or 60 fps | same, CRF 16 |
| Site loop | 1920x1080 and 720x900 phone crop | H.264 CRF ~26 no audio + VP9 webm (the website thread's recipe) |

**Reels safe area (1080x1920):** Instagram's UI covers the top ~250 px, the bottom ~420 px
(caption, name, music) and the right ~120 px (buttons). Every word, logo and badge sits inside
x 60-960, y 250-1500. The grid crop of the profile shows the centre 1080x1440 (3:4): keep the
logo there too, and pick the end card as the cover.

**What works in a Reel:** motion in the very first frame (no logo, no fade from black), a cut on
every beat or two (0.5-1 s shots), sound on (music with a hit at the reveal), the payoff in the
last 1.5-2 s, and an ending that loops back into the first frame. A teaser shows places and mood,
not systems: no HUD, no missions or characters, no menus.

## Logo and end card

```zsh
node tools/reel/render.mjs OUT                        # logo-wordmark.png + logo-wordmark-stacked.png (transparent),
                                                      # logo-square-1080.png, background-1080x1920.png,
                                                      # card-1080x1920.png
node tools/reel/render.mjs OUT --card-frames=2        # the animated card, OUT/card/f_0000.png... (30 fps)
```

Needs Node + Playwright with Chromium (cloud: there; Mac: `npx playwright install chromium`).
The card's words and badges live in `card.html` (iPhone: TestFlight open beta; Android: Google
Play open testing). Store badges are plates in the title's button style, not Apple's or Google's artwork (their
badge rules do not cover TestFlight or open testing). Real platform names only as plain words.

## Check before showing F

1. Look at every clip's sheet: horizon level, the car visible, no streaming holes, no grey proxy
   blocks, no ghosting, light right for the time.
2. Contact sheet of the cut (`ffmpeg -i OUT.mp4 -vf "fps=6,scale=180:-2,tile=10x3" -frames:v 1 sheet.png`) and
   `ffprobe` the streams: 1080x1920, 30 fps, h264 + aac 48 kHz.
   **Frozen-frame check on every take** (a 30 s palm take came out static after 6 s and the sheet hid it):
   `ffmpeg -i TAKE.mp4 -vf "mpdecimate=hi=256:lo=64:frac=0.1,showinfo" -f null - 2>&1 | grep -c "Parsed_showinfo.*pts_time"`
   must be close to the frame count (30 s at 30 fps = 900); far below means re-shoot, never deliver.
3. Show F the draft (attach the MP4) before calling it final; name what only his phone shows
   (how Instagram's UI covers it, the sound).
