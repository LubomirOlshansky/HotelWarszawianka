# Teaser 2: "Warsaw 3 a.m." (10 s Reel)

F, 2026-11-19: "this view" (the website hero: the Centrum metro pavilions, Marszałkowska and the
Rotunda at Rondo Dmowskiego), at night in the rain, Experimental quality, people walking under
umbrellas (modelled in the game: `Models.umbrella_mesh`, shown in every rain), the words
"Warsaw 3 a.m.", ElevenLabs rain and city-centre ambience, "like a video on the reel, live vibe",
in the website's pixel font (Pixelify Sans).

## Plan

1080x1920, 30 fps, 10 s. A live street camera at 3 a.m.:

| s | shot | overlay |
| --- | --- | --- |
| 0.0-4.5 | `wide`: the hero view, the metro pavilions, the queue of cars, the Rotunda, rain | LIVE badge, "Rondo Dmowskiego", CAM 03, the clock 03:00:07 ticking, RAIN 6°C; "Warsaw / 3 a.m." typed in from 0.6 s |
| 4.5-7.0 | `crowd`: closer on the pavilions' square, the people under umbrellas | the same |
| 7.0-10.0 | `wide` again (its later seconds) | the screen darkens, "Around Warsaw", STAY TUNED, the iOS and Android plates |

A slow push-in over the whole cut (PUSH=1.06) is the camera's drift. The sound is the ambience
alone, no music: the rain close, the city far (tyres on the wet road, a tram, people).

## Shots (tools/clip.sh, skill shoot-video)

```zsh
Q=(--nohud --no-touch --no-ghost --quality=experimental --lines=1920 --governor=off --time=night --weather=rain --crowd=2)
tools/clip.sh wide  1080x1920 10 -- --cam=-845,415 --yaw=0 --pitch=-32 --size=190 $Q
tools/clip.sh crowd 1080x1920 4  -- --cam=X,Z --yaw=0 --pitch=-32 --size=70 $Q   # centred on the pavilions' square
```

The Mac run's framing fixes replace these lines (the commands that worked are the record).

## Overlay, sound and cut

```zsh
node tools/reel/render.mjs build/reel/art --live-frames=10 --end=7   # build/reel/art/live/f_0000.png ...
docs/teaser2/cut.sh build/clips build/reel/art build/reel/teaser2-1080x1920.mp4
SHOTS="wide:2:5 crowd:0:2 wide:7:3" docs/teaser2/cut.sh ...           # another pick, no re-render
```

`ambience-10s.m4a`: ElevenLabs sound effects (eleven_text_to_sound_v3, flow cL8xacMOlAJYfvedMjiw):
take 1 of "steady night rain on a city street" and take 4 of "distant city centre at night, tyres on
a wet road, a far tram, people", mixed, faded, -16 LUFS. The raw takes are in the project files
(teaser/music/teaser2). Made on F's ElevenLabs account for the game; CC BY-NC like its other sound.
