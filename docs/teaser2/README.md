# Teaser 2: "Warsaw 3 a.m." (10 s Reel)

F, 2026-11-19: "this view" (the website hero: the Centrum metro pavilions, Marszałkowska and the
Rotunda at Rondo Dmowskiego), at night in the rain, Experimental quality, people walking under
umbrellas (modelled in the game: `Models.umbrella_mesh`, shown in every rain), the words
"Warsaw 3 a.m.", ElevenLabs rain and city-centre ambience, "like a video on the reel, live vibe",
in the website's pixel font (Pixelify Sans).

## Plan (F's second note, 2026-11-19 17:24 UTC)

1080x1920, 30 fps, **5 s, one shot**, `metro`: the entrance to the Centrum metro (the Patelnia
square and the pavilions) and the Rotunda in one frame, at night in the rain, people going in and
out of the metro under umbrellas, the city's life. The only text is "Warsaw / 3 a.m." typed in at
the bottom of the safe area. No LIVE badge, no clock, no title or STAY TUNED, no store plates.
A slight push-in (PUSH=1.03). The sound is the ambience alone, faded out over the last 0.8 s.

## Shots (tools/clip.sh, skill shoot-video)

```zsh
Q=(--nohud --no-touch --no-ghost --quality=experimental --lines=1920 --governor=off --time=night --weather=rain --crowd=2)
tools/clip.sh metro 1080x1920 6 -- --cam=X,Z --yaw=0 --pitch=-32 --size=120 $Q   # the metro entrance and the Rotunda both in frame (the hero is -845,415)
```

The Mac run's framing fixes replace these lines (the commands that worked are the record).

## Overlay, sound and cut

```zsh
node tools/reel/render.mjs build/reel/art --live-frames=5   # build/reel/art/live/f_0000.png ...
docs/teaser2/cut.sh build/clips build/reel/art build/reel/teaser2-1080x1920.mp4
SHOTS="metro:1:5" docs/teaser2/cut.sh ...           # another pick, no re-render
```

`ambience-10s.m4a`: ElevenLabs sound effects (eleven_text_to_sound_v3, flow cL8xacMOlAJYfvedMjiw):
take 1 of "steady night rain on a city street" and take 4 of "distant city centre at night, tyres on
a wet road, a far tram, people", mixed, faded, -16 LUFS. The raw takes are in the project files
(teaser/music/teaser2). Made on F's ElevenLabs account for the game; CC BY-NC like its other sound.
