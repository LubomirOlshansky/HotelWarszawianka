# Beta trailer

The beta announcement trailer (F, 2026-11-10): a 38 s cut and a 30 s cut, an 80s feel, day to
night, ending on JOIN THE BETA. The picture comes from the game's own scripted takes,
`--trailer=palace_time|heli_dive|palace_drift|card` (game/scripts/trailer.gd), captured with
Godot's Movie Maker on a Mac (Metal) at 1920x1080, 60 fps.

`music-take4.mp3` is the music, original and made for the game (ElevenLabs, take 4 of 4,
120 bpm; CC BY-NC like the game's other sound). The first beat is at 0.48 s, the theme comes in
at bar 9 (16 s after the trim) and the final hit is at 32 s.

- 38 s: trim 0.48 s, keep 38 s, fade out the last 1.5 s.
- 30 s: trim 0.48 s, cut out 4-10 s (three bars), so the theme comes in at 10 s and the final hit
  lands at 26 s; fade out the last 1.2 s.

```zsh
ffmpeg -ss 0.48 -i music-take4.mp3 -t 38 -af "afade=t=out:st=36.5:d=1.5" music-38s.wav
ffmpeg -ss 0.48 -i music-take4.mp3 -filter_complex "[0:a]atrim=0:4,asetpts=PTS-STARTPTS[a];[0:a]atrim=10:36.1,asetpts=PTS-STARTPTS[b];[a][b]acrossfade=d=0.03:c1=tri:c2=tri,atrim=0:30,afade=t=out:st=28.8:d=1.2[o]" -map "[o]" music-30s.wav
```

## Quick rounds

`tools/trailer.sh live TAKE` plays a take in a window in real time (no recording);
`tools/trailer.sh preview TAKE` renders it at 960x540 (about 4x faster);
`tools/trailer.sh final TAKE` at 1920x1080 with the trailer's best picture;
`tools/trailer.sh cut preview|final` cuts both trailers from that folder with `cut.sh`.
A cut alone takes seconds: change shot order and timings in `cut.sh` without re-rendering.

Since F's note on the first cut (2026-11-10: slow, only flyovers, the day-two version was funnier)
the cut is mostly gameplay takes with the HUD and the game's own jokes (kebab job, taxi ride, the
kebab pullover, the boat race, the Vistula dive, chase, roadblock, racing club, drag, the helicopter
at the stadium), a shot every 1.5-3 s, two captions, the flyovers sped up 2-4x (`take:start:len:speed`).
