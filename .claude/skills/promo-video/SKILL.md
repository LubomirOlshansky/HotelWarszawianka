---
name: promo-video
description: Turns F's Promo Mode frames (the phone's COPY flag line) plus his written notes ("wider", "lower", "more people") into finished silent video takes with every quality setting built in (tools/promo_clip.sh), checks a still first, shoots the takes on the Mac, and stages them for F. Use whenever F sends a COPY line or frames and says shoot, make a clip, a take, a video of a place (Jarmark, the palm, the stadium), or "make it better".
argument-hint: "NAME \"COPY FLAGS\" [notes]"
---

# Promo video from F's frames

F frames a shot on his iPhone in Promo Mode (Settings → DEV → Promo mode), taps COPY, and pastes
the line into the thread with a note. This skill turns that into a take. It sits on top of
`shoot-video` (read it for platform specs, the card and the cut); this one is the shooting loop.

## The loop

1. **Read F's message.** Per take: the COPY line (`--cam= --yaw= --pitch= --size= --game-clock --clock=
   --date= [--weather=rain]`) and the note. No line, no shot: ask once, park the rest.
2. **Mac check.** Rendering is Mac-only (Movie Maker needs Metal; cloud lavapipe is only a rough
   framing check). `pgrep -fl godot`, `build/autopilot.lock`, and whether another thread (the teaser
   thread) holds the Mac. Busy: tell F, keep the commands ready, do not wait for him.
   Work in a worktree of the branch (`git worktree add build/<name>-wt <branch>`), copy the derived map files
   (game/map index.*, sectors/, proxies.scn, shared/, lod2.*, terrain.json, game/.godot) instead of
   re-baking. After a landmark change: `python3 -I tools/bake_sectors.py` and the city bake, then
   shoot with `--prebuilt --sectors=all` (the helper does). The checkout must hold the thing F
   frames: `git log --oneline | grep -i <name>` (the Jarmark is on main, #980; a teaser-branch checkout
   needs main merged in).
3. **Check still first** (about a minute, half size):
   `tools/promo_clip.sh NAME "COPY" --at=X,Z --still` → `build/clips/NAME.still.png`. Look: same
   framing as F's phone frame (his yellow 9:16 guide), car/people/props where they should be, no
   holes, no grey proxy blocks, light right for the clock. Show F the still when the framing is a
   judgment call; otherwise go on.
4. **Takes.** `tools/promo_clip.sh NAME "COPY" --at=X,Z [--secs=3] -- EXTRAS` (60 fps, master CRF 14, silent).
   One take per frame; for F's notes shoot variants side by side (NAME-a, NAME-b), never overwrite a
   take he saw.
5. **Look at `NAME-sheet.png`** for every take (horizon level, motion, nothing streaming in late,
   crowds and rides moving), then re-shoot what is wrong. Say what you changed.
6. **Stage** to `/mnt/project-files/teasers/<piece>/` (new subfolder per piece, file `NAME-vN.mp4`),
   attach the MP4s in the reply with the sheet and the exact command that rendered each. The Mac
   cannot push files from the thread: stage through `device_stage_files` when this thread has it,
   otherwise tell F where on the Mac the files are (`build/clips/` in the worktree, copy to
   `~/Documents/aroundwarsaw-teaser/`).

## What the helper builds in (do not drop these)

`--governor=off` (without it the governor steps down and the view goes top-down and zoomed),
`--lines=<video height>` (otherwise blown-up blocks), `--quality=ultra`, `--prebuilt --sectors=all`,
`--nohud --no-touch --no-ghost`, 60 fps, silent, the window always on top (clip.sh: macOS stops
drawing a hidden window and the clip repeats frames), and **the size rule: Promo VIEW is the whole
phone screen height, a 1080x1920 clip shows VIEW x 0.818** (2347/2868; F's first takes showed 18%
more than his 9:16 frame). `--view-scale=1` for 16:9 and 4:5. The general rule: size = VIEW x
(height of F's yellow 9:16 frame in px / phone screen height in px); the palm's VIEW 143.4 gave
117.3, and F then asked for a wider 135 (use `--wider=` on top, or `--size` directly with `--view-scale=1`).

**Water gotcha:** a focus over water (the Vistula, the stadium bank) spawns the car under the camera,
it falls in and is towed, and the shot moves. Always pass `--at=X,Z` on a road within about 300 m.

## F's notes → flags

| F says | Do |
| --- | --- |
| wider, more around it | `--wider=15` (grows --size 15%); tilt up to show more horizon: edit `--pitch` toward 0 |
| closer, tighter | `--closer=15` |
| lower / more cinematic angle | `--pitch=-18` (COPY pitch is negative, steeper = more top-down); keep above -12 or buildings hide the subject |
| turn it | `--yaw=` ± 20-40°, one change per variant |
| more people, busy | `-- --people=60` (never above the game's cap) |
| trams, a bus | `-- --promo-at=X,Z[,T]` (they reach that point T s after the start) |
| scooters | `-- --scoot-gang=X,Z[,T[,DIR]]` |
| a second helicopter | `-- --promo-heli=X,Z,TX,TZ,ALT[,SHARE]` |
| green trees | `-- --season=summer` |
| golden hour, evening | change `--clock=` (18:30 in autumn; `--grade=golden` for the look); date `--date=YYYYMMDD` |
| night, rain | `--clock=21:00`, `--weather=rain` (keep rain out unless F asks) |
| longer, calmer | `--secs=5`; the cut picks its second, no re-render |
| smoother | already 60 fps; 30 fps in the cut for Reels |

Several notes in one message: apply them all in the first take, then offer one variant per note
that was a guess. One change per variant is the only way F can say which one he likes.

## The whole workflow (how the teaser thread worked, 2026-11-19..21)

F's round trip, every time: **frame + note → scene fixes → rebake → check stills (before/after) → takes A/B/C → F picks → cut.**

1. **Scene fixes come first when the note is about the world, not the camera.** "No mopeds at the
   entrance", "buses keep their lane", "add a police car", "people chilling inside", "lights by the
   stairs" are code or data changes (promo-only flags like `--promo-at`, `--scoot-gang`, `--people`,
   `--promo-heli` are the pattern: a shot-only switch, never a change for players unless F asks).
   Do them in the cloud on the piece's branch; the architecture rules apply (one owner, change note).
   Model from F's photos (skill `model-from-photos`); a shot-only prop must not cost players frames.
2. **Cloud check render before the Mac** (catches broken code, ~15 min): Godot 4.7.2 + xvfb + lavapipe,
   660x1170, one still. Never judge looks on it, only "does it run and is the thing there".
3. **Before/after stills on the Mac, same camera.** Shoot the BEFORE stills on the old bake *before*
   fetching the new commit, then update, import (`godot --headless --path game --import --quit`),
   `python3 -I tools/bake_sectors.py`, `godot --path game --resolution 320x180 --script
   res://tools/bake_city.gd` (with a renderer), then the AFTER stills with the identical cameras.
   **One camera per run**: with several `--cams` in one run the clock advances and later cameras change
   light. Sheets: `tools/promo_sheet.sh BEFORE AFTER` (before left, after right). If a camera has to
   move, re-shoot both sides with the new one.
4. **Preview before every take set.** Run `--preview` (half size, High) and look at the contact sheet
   first: in the last hours two or three takes came out as the map screen or at the wrong time of day,
   and a re-run fixed them. Only then the full-size takes.
4b. **Takes as a batch.** `tools/promo_batch.sh docs/promo/PIECE.takes` (copy `example-palm.takes`):
   one COPY frame, shared options, one line per variant. A take F has seen is never overwritten: new
   name (A2 → A3). Say in the reply which note each variant answers.
5. **Always `godot --path game`** (a run without it popped a "no main scene" alert on F's screen).
   Every run `--nosave` and quits.
6. **Priority changes mid-run** (F reorders: "palm first, then stadium"): send the reorder to the
   running Mac session as a new instruction, say which step it finishes first, and keep the list in
   the checklist. Do not stop a render that is almost done.
7. **Mac etiquette.** One Mac user at a time: two threads cannot render at once (the GPU and the
   always-on-top window collide), so Mac shoots queue; ask the coordinator who has it. Takes land
   in `~/Documents/aroundwarsaw-teaser/<pieceN>/` named takeA3, takeB3 ... (new number per round). Do not touch other threads' worktrees or Xcode builds,
   and never kill a godot process that is not yours. Use the brief in `mac-brief.md`.
8. **Delivery.** While a Remote Control session runs, the thread's folder tools are withheld: end the
   session, stage the files (`/mnt/project-files/teasers/<piece>/`), attach them to the reply, and tell
   the coordinator "Mac free" so the next shoot can start.

## Jarmark Warszawski (Christmas market by PKiN, first use)

On Plac Defilad, south of the museum by Marszałkowska. Day and night, rides turning, crowds
(`--people=`), market lights at dusk. Reference photos: `/mnt/project-files/refs/jarmark-2026/`
(README there has the modelling notes). Shoot a day take and a night take from the same frame:
change only `--clock=` (e.g. 14:00 and 20:30) so F can compare. The market's rides and crowds live
in the game clock, so use `--game-clock` from F's COPY line and `--secs=5` to let a ride show motion.
If a frame shows something missing or wrong (a hut, a ride), that is a modelling item for the Jarmark
thread: report it with the still, do not paper over it in the take.

## Done means

A staged MP4 per take, its sheet, the command, and a one-line verdict of what you saw. Only the
phone shows how Instagram's UI covers it and how the sound lands: say so. Never write a device id
or home path into a tracked file.
