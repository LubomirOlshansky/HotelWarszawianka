# Instagram teaser (5 s Reel)

F, 2026-11-19: a ~5 second Reels teaser, a few one-second game shots (a car on Most
Świętokrzyski, views around Warsaw), then "stay tuned" with the iOS and Android availability,
and a game logo on a synthwave Warsaw background. Tease, do not reveal: the full trailer comes later.

## Plan

1080x1920, 30 fps, 5.0 s, cut on the music's beats (120 bpm, a beat every 0.5 s; the music is
5 s of the trailer's take 4, 29.0-34.0 s, so the final hit lands at 3.0 s). Instagram's own UI
covers the top ~250 px and the bottom ~420 px, so all words sit in y 250-1500.

| s | shot | why |
| --- | --- | --- |
| 0.0-1.0 | `hook`: night, rain, low behind the car racing down Marszałkowska toward the lit Palace | motion and neon in the first frame stops the scroll |
| 1.0-2.0 | `bridge`: dusk, the car crossing Most Świętokrzyski toward the pylon, the Vistula below | the shot F asked for; says "real Warsaw" at once |
| 2.0-3.0 | `skyline`: golden hour, the helicopter over the Palace with Varso and Złota 44 | scale, and a hint that you also fly |
| 3.0-5.0 | end card on the hit: AROUND WARSAW, STAY TUNED, iPhone TestFlight / Android Google Play | the payoff; the cover frame |

Kept back for the trailer: the HUD, jobs, police, races, characters, the boat, the Old Town.
Spare shots in case one does not land: `stadium` (Stadion Narodowy at night) and `river` (the
helicopter low over the Vistula at dawn).

## Shots (tools/clip.sh, skill shoot-video)

```zsh
# Portrait needs --lines = the video height: the style draws a fixed line count (Sharp 480), so
# 1080x1920 without it is a 270x480 image blown up 4x (F, 2026-11-19: "why the quality so bad?").
# zsh: flags in an array, a string is not split.
Q=(--nohud --no-touch --no-ghost --quality=experimental --lines=1920)
tools/clip.sh hook    1080x1920 3 -- --at=-1113,-263 --heading=160 --demo --time=night --weather=rain --pitch=-24 --size=34 $Q
tools/clip.sh bridge  1080x1920 3 -- --at=560,-770 --heading=52 --demo --time=dusk --pitch=-28 --size=60 $Q
tools/clip.sh skyline 1080x1920 3 -- --heli --at=-1180,-60 --heli-stick=0,1 --heli-alt=120 --time=live --clock=18:15 --date=20260915 --palace-lights=gold --pitch=-38 --size=260 --sectors=all $Q
tools/clip.sh stadium 1080x1920 3 -- --heli --at=1150,-600 --heli-stick=0.6,0.4 --time=night --pitch=-32 --size=300 --sectors=all $Q
tools/clip.sh river   1080x1920 3 -- --heli --at=1000,-180 --heli-stick=-0.3,-1 --heli-alt=40 --time=dawn --pitch=-26 --size=90 $Q
```

The Mac run's framing fixes replace these lines (the commands that worked are the record).

## Logo, card and cut

The art copies the game's title screen (F, 2026-11-19: "I like how my loading screen looks"):
`tools/reel/card.html` ports `game/shaders/title.gdshader`, the palm from `title.gd` and the chrome
wordmark (`chrome.gdshader`, Open Sans like Godot's default font). Change the title screen and the
art follows only if the port is updated too.


```zsh
node tools/reel/render.mjs build/reel/art                   # logo + background + card stills
node tools/reel/render.mjs build/reel/art --card-frames=2   # the animated card
docs/teaser/cut.sh build/clips build/reel/art build/reel/teaser-1080x1920.mp4
SHOTS="hook:0.4 bridge:1.2 stadium:0.5" docs/teaser/cut.sh ...   # another pick, no re-render
```

`music-5s.m4a` is 29.0-34.0 s of the beta trailer's music take 4 (original, made for the game;
CC BY-NC like the game's other sound), faded out over its last 0.5 s.

## F's notes on the first draft (2026-11-19)

- 7 s, five one-second shots, then the 2 s card (`music-7s.m4a` until the ElevenLabs track).
- Open on the car gliding past the palm at Rondo de Gaulle'a; no Marszałkowska hook.
- No bridge shot until the bridge rework from another thread lands.
- The card shows the platforms only: iOS and Android icons, no "open beta" words.
- New order: palm, skyline (the Palace, golden), wola (dusk), hook2 (Rondo Dmowskiego, night rain), stadium (night).

## Music (7 s)

`music-7s.m4a` (F, 2026-11-19: "use 11labs to generate the teaser sound"): ElevenLabs Music
(eleven_music_v2_5, 4 takes of a 120 bpm synthwave sting, take 3 used for 0-5 s) and an ElevenLabs
sound effect (eleven_text_to_sound_v3, a synth impact) on the card's hit at 5.0 s with an echo
tail of the groove, loudness -14 LUFS (Instagram's level). Made on F's ElevenLabs account for
the game; the raw takes are in the project files (teaser/music). `music-5s.m4a` is the older
5 s cut from the trailer's take 4.
