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

## Second iteration (F, 2026-11-11)

F on the first cloud cut: every shot was close up, with no Palace, no city centre and no Old Town;
the stadium shot was weak; the HUD should show in some shots so it reads as a real game, but
curated, not overloaded; the drift scene should have the car parked in the ring next to the
drifting car; a police chase and a boat moment by the Bulwary; the time and the weather changing on
a landmark; music take 4. The cut is `cut-v2.sh` (38 s, on take 4's bars):

| s | shot | take |
| --- | --- | --- |
| 0-4 | Royal Castle, Zygmunt's Column and the Old Town from over the Vistula (caption THE REAL WARSAW.) | `old_town_fly` |
| 4-8 | The towers at Rondo Daszyńskiego, over Rondo ONZ to Złota 44 and the Palace, warm light | `skyline` |
| 8-11 | Kebab job with the HUD: the job card (GORĄCY, metres), the minimap, one customer joke | `kebab2` |
| 11-14 | Boat race by Kopernik and the Bulwary: the ramp jump, the race card, Szymek's line | `boat2` |
| 14-18 | The helicopter in from Most Poniatowskiego to Stadion Narodowy, pulling out to the whole bowl (the theme comes in at 16 s) | `heli_stadium` |
| 18-23 | Time-lapse on the Palace with Złota 44 and Varso: day, golden hour, dusk, night, then rain (DAY. NIGHT. RAIN.) | `time_lapse` |
| 23-26 | Police chase down Marszałkowska at night, 100 km/h, the chase banner, sirens and the patrol's radio line (GENTLE POLICE. NEVER GAME OVER.); palace_drift's raid kept its patrols on the roads round the square, out of frame | `chase2` |
| 26-29 | Night racing club: the player's car parked in the ring, Lena drifting in the middle, her line | `club2` |
| 29-32 | The Old Town at night in the rain | `castle_night` |
| 32-38 | End card on the final hit: AROUND WARSAW, JOIN THE BETA | `card` |

New flags (trailer.gd, main.gd): the flights `--trailer=old_town_fly|skyline|time_lapse|heli_stadium|castle_night`
(`FLIGHTS`: keys, light, a time scrub, rain, a helicopter path); for `--trailer=play`:
`--trailer-cam=SIZE,YAW,PITCH[,SPIN[,LEAD[,OX,OZ]]]` (the trailer's own camera; SPIN 900 = behind
the vehicle), `--trailer-look=X,Z`, `--trailer-hud=clean[,toast][,banner][,status]`,
`--trailer-bubble=NAME|none`, `--trailer-hold`, `--trailer-boat=LI` (the boat race jumps to line
point LI), `--trailer-rain-at=S`; and from the first cloud cut `--trailer-at=X,Z,HEADING`,
`--trailer-view=M`, `--trailer-clean`.

Render notes: wide flights need `--sectors=all` (the streamer otherwise drops sectors a wide view
still shows and their proxies draw: a dark red block beside the stadium); that is about 5 GB a
process. The cloud render (software Vulkan, `tools/trailer_cloud.sh`) runs at about 3 s a 1080p
frame with three takes at once, so a flight the cut plays at 2.5x is rendered at 12 fps. MSAA off
(`--trailer-aa=0`) for dusk and night under llvmpipe.
