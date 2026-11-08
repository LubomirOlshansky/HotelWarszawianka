# 11 Listopada: the 15-second video, how to direct it

Status: BUILT except sound and the Mac capture (2026-11-08): items 1-4 and 6 below are in the game (`--cinematic=event`, `--event-t=SEC` for stills, `--clock=16:10|16:40|17:10` for the grade). Recorded on an iPhone 17 Pro or an M4 Pro Mac, so performance is not a limit for the take.
One continuous camera move in three beats, no cuts, so it reads in a feed with the sound off. Neutral and civic: colours,
flags, light and crowd only, no words except the title card. Our own music only.

## The three beats

| Time | Beat | Camera | On screen | Event pieces it needs |
| --- | --- | --- | --- | --- |
| 0.0-1.0 s | Black to the Palace | Static wide from the north-east, dusk, the skyline | The Palace of Culture dark | Clock locked to 16:40 |
| 1.0-4.5 s | The towers light | Slow push in on the Palace | The Palace lights tier by tier from the bottom (red), then the white top; Złota 44 follows with its gradient | A light cascade (today all bands switch on at once) |
| 4.5-9.5 s | The rondo, hero shot | Glide down and forward to the crowd over Rondo Dmowskiego, ends low | Flags, flares, the pink fog thickening, lamps through the mist | Fog density ramp 0 to full over 5 s, flares igniting in turns, flag sway |
| 9.5-13.0 s | Along the march to the bridge | Fast glide east along Al. Jerozolimskie, then over the Poniatowski bridge | The crowd below, the banner flags, the bridge full of people, flares on the four towers | The bridge crowd (built), the road is already closed |
| 13.0-15.0 s | Pull back, end card | Rise and turn back west over the river: the whole lit skyline | The Palace and Złota 44 white-red behind the smoke; the title fades in at 13.5 s: "11 LISTOPADA", under it "Around Warsaw · za darmo" | Title card (Polish with English subtitle, the game's own font) |

The same take also gives the 9:16 and 1:1 crops: keep the Palace, the title and the bridge inside the middle 70 percent.

## What has to be built (in this order)

1. **The camera path, `--cinematic=event`.** The opening flyover already runs a keyed path (`camera_shots.gd`, `OPEN_KEYS`: ground point,
   height, view size, turn, pitch, one eased curve). The event path is a second key table of about 8 keys over 15 s, HUD hidden, no car, no
   toast. Cheap, and the same code the game ships.
2. **A locked clock and a script for the beats**: `--event-day --time=dusk` already works; add `--event-scene` that starts the 15 s clock,
   ramps the fog, lights the towers in sequence and fires the flares in turns.
3. **Flag sway.** Flags are still today: a wind term in `actor.gdshader` for the flag part, a few lines.
4. **The light cascade** in `_build_bands` (a per-band reveal time instead of one switch).
5. **Sound** (the one thing the picture cannot carry): a crowd bed that swells, flare hiss, a low drum, then our own music over the end. No chants,
   no anthem, no recordings.
6. **The title card**: Polish with English, drawn by the game (not added in an editor), so every take has it.
7. **Capture**: Godot's Movie Maker (`--write-movie take.avi --fixed-fps 60`) at 4K on the M4 Pro, High quality mode (see
   `/mnt/project-files/research/graphics-options.md`), then H.264 with ffmpeg. On the iPhone, screen recording of the same take for the
   "it runs on a phone" proof.

## Risks and how to take them

- The renderer is slow in the cloud (10-15 min a frame set), so the take is shot on the Mac; the cloud only checks the path with stills at
  fixed times (`tools/shots.sh` style).
- The fog is see-through blobs: at the camera's low end of the glide it must not white-out the crowd: a density cap on the last 2 s.
- The bridge is 515 m: the glide has to cover it in about 3.5 s, so the path is fast there; flares and fog on the bridge give it speed lines.
- Take three versions of the clock: 16:10 (warm), 16:40 (blue-pink, the pick), 17:10 (darker, more glow). The grade is chosen on the Mac.

## Alternates

6 s teaser: beat three only, as a loop. 9:16 story: beats two and three with the title at the end.
