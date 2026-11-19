# Teaser 2: "Warsaw 10 p.m." (7 s Reel)

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
No zoom (F: "no need for zoom in video"; PUSH=1.0). The sound is the ambience alone, faded out over the last 0.8 s.

F, 20:19 UTC (final): "10 p.m." instead of "3 a.m.", a bit fewer cars, ride-hail cars (Podwózka
on a Tesla-Y-like crossover, the city taxi on a Prius-like liftback), a tram crossing, more people
on Pasaż Wiecha and around (the WIECHA_NIGHT crowd sites, `--crowd=2`), Zodiak's sign on its
front and bigger (PR #944).

F, 17:33 UTC: not busy, "calm, the vibe of night Warsaw, meditative": the normal crowd (no --crowd=2), the words typed slowly, the sound rain with the city far away.

## Shots (tools/clip.sh, skill shoot-video)

```zsh
Q=(--nohud --no-touch --no-ghost --quality=experimental --lines=1920 --governor=off --time=night --clock=22:00 --date=20261120 --weather=rain --traffic=low --crowd=2 --promo-at=-851,400,7)
tools/clip.sh metroF 1080x1920 16 -- --cam=-851,400 --yaw=0 --pitch=-32 --size=280 $Q   # 16 s: cut the 5 s with a tram crossing   # F 19:54 UTC: exactly A2-frame.png, the rondo in the centre, the Rotunda right, the metro left
# cut: SHOTS="metroF:2:7" (F 21:04 UTC: 7 s, the words still, not typed in; a tram crosses from 2 s) docs/teaser2/cut.sh build/clips build/reel/art build/reel/teaser2-1080x1920.mp4
```

The Mac run's framing fixes replace these lines (the commands that worked are the record).

## Overlay, sound and cut

```zsh
node tools/reel/render.mjs build/reel/art --live-frames=7   # build/reel/art/live/f_0000.png ...
docs/teaser2/cut.sh build/clips build/reel/art build/reel/teaser2-1080x1920.mp4
SHOTS="metro:1:5" docs/teaser2/cut.sh ...           # another pick, no re-render
```

`ambience-10s.m4a`: ElevenLabs sound effects (eleven_text_to_sound_v3, flow cL8xacMOlAJYfvedMjiw):
take 1 of "steady night rain on a city street" and take 4 of "distant city centre at night, tyres on
a wet road, a far tram, people", mixed with the city low and far (lowpass 2.5 kHz, half volume: calm, F), faded, -16 LUFS. The raw takes are in the project files
(teaser/music/teaser2). Made on F's ElevenLabs account for the game; CC BY-NC like its other sound.

`ambience-7s.m4a` (F 21:22 UTC: "ambient music, quiet, on the rain drops, and the city sound very
delicate"): rain1 at -20 LUFS, a new ElevenLabs ambient pad (eleven_music_v2_5, take 2 of "meditative
late-night city ambient: warm slow synth pads, soft drone, electric piano with long reverb", same flow)
at -27 LUFS under it, city4 low-passed at -33 LUFS, faded in 0.6 s and out over the last 0.8 s, -16 LUFS.
Raw pads in the project files (teaser/music/teaser2/pad1.mp3, pad2.mp3). `AMBIENCE=ambience-10s.m4a`
brings back the old mix.
`ambience-7s-vapor1.m4a`, `-vapor2.m4a` (F 21:23 UTC: "ambient retrowave synth music, vaporwave,
more melancholy"): two ElevenLabs takes (eleven_music_v2_5, melancholic ambient vaporwave, same flow)
at -23 LUFS under the rain at -21, the city at -33; raw in teaser/music/teaser2/vapor1.mp3, vapor2.mp3.
`AMBIENCE=ambience-7s-vapor1.m4a docs/teaser2/cut.sh ...`

F 21:46 UTC: "why does the rain drop at the 5 second, and the rain should be quieter". The takes fade
inside their 10 s (the prompt asked for a soft ending) and the per-stem loudnorm rode them. Remixed
with `docs/teaser2/mix.sh MUSIC START OUT` (static gains, no loudnorm on the stems): the music levelled
with dynaudnorm at -25 LUFS, the rain 6 dB under it at -31, the city at -38, the bed at about -17 LUFS;
the level now stays within ~2 dB until the planned fade at 6.2 s.
