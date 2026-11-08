# Music and voices

**For now (F, 2026-11-02): music only, no words.** The beta ships the two stations' 16
instrumentals (`docs/MUSIC.md`, "The beta radio"); the opening theme, the announcer's voice,
jingles and vocal songs below are the plan for later.

F (2026-11-02): the beta's sound. One place for every song, voice line and style, so they can
be arranged first and generated in one go (ElevenLabs, with its MCP connector). The prompt
library with the first ideas for every station is `docs/MUSIC.md`; this page is the plan the
beta follows.

## 1. What plays when

| Moment | What you hear | Status |
| --- | --- | --- |
| The opening (title and flyover; the first start and after a new game only, never on every launch) | **The opening theme**: its own gentle piece with the city's sounds in it, nothing from the radio | to generate; the game plays the radio there today |
| The first seconds of driving | The announcer's greeting (her voice), then the radio | the greeting is text on the ticker today; voice clips to generate |
| Driving | KEBAB FM (vaporwave) or MORDOR FM (minimal techno), RADIO cycles them and Off, ▶▶| skips | built (PR #304); one synth loop each until the songs come |
| Between songs | Station idents, the host's jokes (ticker) | idents to generate |

## 2. The opening theme

**Separate from everything else in the game**: it plays only under the title and the opening
flyover, on the first start and after a new game (F, 2026-11-02), never on a normal launch; then fades into the city as the car gets control, and the radio starts after it.
Gentle, warm, a little wistful: the city waking up. The reference F gave (a YouTube Short)
couldn't be played from the cloud; the description below is from F's words ("gently music with
city sounds").

| | |
| --- | --- |
| Length | 1:30 to 2:00, an ending that can fade at any bar |
| Feel | soft piano or Rhodes, warm pads, a slow pulse, no drums or only a brushed one; hopeful |
| City inside it | tram bell, birds, distant traffic, a church bell far off, footsteps, a pigeon flutter |
| Not | vaporwave, techno, vocals, anything from the radio stations |

ElevenLabs Music prompt (instrumental):

```
Gentle cinematic ambient piano, warm Rhodes and soft string pads, slow and hopeful, a city waking up at sunrise, Warsaw field recording woven in: tram bell, birds, distant traffic, far church bell, footsteps on cobbles, no drums, no vocals, 70 bpm, 1:45 long, soft fade-out ending
```

If the city sounds come out too loud or too few, generate the music without them and lay the
game's own beds under it (`game/audio/sfx/city_day.wav`, `birds_a.wav`, `church_bell.wav`; the
tram bell in `sfx.gd`), or make them with ElevenLabs Sound Effects:

```
Early morning city ambience in Central Europe, a tram passing with a two-tone bell, birds, distant light traffic, footsteps, calm, 30 seconds, loopable
```

## 3. The announcer

**The opening line (F, 2026-11-02): one clip, the same every time, on the first start and after a new game only** (the launches that get the opening flyover; a normal launch goes straight to the radio), short (about 12 s), sunny, with
one city joke, over the opening only (F picked the roadworks one; no laughing tag); the weather variants below are for later.

```
[cheerfully] Dzień dobry, Warszawo! Pogoda na dziś: słonecznie i przyjemnie ciepło. Na Marszałkowskiej nowy remont, [playfully] czyli wszystko po staremu. [warmly] A naszym słuchaczom, jak zawsze, życzymy miłego dnia!
```

### Later: the full set

One woman's voice for the greeting at the start: a radio presenter, warm and smiling. She does
**not** name the station (F, 2026-11-02): just Warsaw, the weather and a good wish. The
temperature stays on the ticker (the game picks it for the month and hour), so her clips fit
any day.

**Voice Design** description:

```
Polish female radio presenter, early 30s, warm and smiling, bright morning-radio energy, clear standard Polish diction, slightly playful, confident and friendly, close studio microphone, no background noise.
```

Preview text: `Dzień dobry, Warszawo! Pogoda na dziś: słonecznie i przyjemnie ciepło. Życzę miłego dnia!`

**Clips** (Text to Speech, Eleven v3, one file each; file names as listed):

| File | Line |
| --- | --- |
| `hello_morning.mp3` | `[cheerfully] Dzień dobry, Warszawo!` |
| `hello_day.mp3` | `Dzień dobry, Warszawo!` |
| `hello_evening.mp3` | `[warmly] Dobry wieczór, Warszawo!` |
| `hello_night.mp3` | `[softly] Witamy wszystkich, którzy nie śpią.` |
| `weather_warm.mp3` | `Pogoda na dziś: słonecznie i przyjemnie ciepło.` |
| `weather_mild.mp3` | `Pogoda: trochę chmur, trochę słońca. W sam raz na przejażdżkę.` |
| `weather_cold.mp3` | `Pogoda na dziś: chłodno. Ciepła kurtka wskazana.` |
| `weather_rain.mp3` | `[laughs] Pogoda: pada. Wycieraczki w rytm muzyki!` |
| `bye_morning.mp3` | `[cheerfully] Życzę miłego dnia!` |
| `bye_day.mp3` | `Miłego dnia!` |
| `bye_evening.mp3` | `Miłego wieczoru!` |
| `bye_night.mp3` | `[softly] Spokojnej nocy za kółkiem!` |

The game plays hello + weather + bye for the hour and the weather (the same choice the ticker's
text makes, `dialogue.gd` `greeting`), the music ducked under her. Files go in
`data/raw/voice/`. Built (F, 2026-11-05): on every launch AFTER the first (not the first start or a new game, which keep the opening line) KEBAB FM's host plays hello + weather + bye over the radio turned down, `greeting_clips.gd`; files in `game/audio/voice/radio/`.

## 4. KEBAB FM 87,3: vaporwave

Eight instrumentals: slowed 80s pop and mall funk, warm detuned synths, tape wobble,
pink-and-cyan Warsaw at sunset. Prompts: `docs/MUSIC.md`, "The beta radio" (KB1 to
KB8, instrumental). Nothing sung or spoken names a station (F, 2026-11-02): the name is only on screen.

## 5. MORDOR FM 108,8: minimal techno

Eight instrumentals: dark, hypnotic minimal techno for the office towers at night,
deep rolling kick, clicky hats, metallic percussion. No
artist names in prompts (the tools refuse them). Prompts: `docs/MUSIC.md` (MD1 to MD8, instrumental).

## 6. Making them

- **Plan**: ElevenLabs Creator (F, 2026-11-02; $11 the first month): commercial licence for
  music and speech. Free plans are non-commercial and a free-plan file stays that way after an
  upgrade, so every final take is made on the paid plan.
- **MCP**: ElevenLabs' hosted connector, `https://api.elevenlabs.io/v1/mcp`, OAuth sign-in (no
  API key in any file). In claude.ai: Customize → Connectors → add custom connector; a new
  thread then sees it and can generate the whole list above in one pass. On the Mac:
  `claude mcp add --transport http elevenlabs https://api.elevenlabs.io/v1/mcp`, then `/mcp` to
  sign in (local only; never a project `.mcp.json`).
- **Order**: the voice first (design it, approve the preview), then the opening theme, then
  KEBAB FM, then MORDOR FM. Two takes each, keep the better.
- **Into the game**: songs in `data/raw/music/<station>/` with a sidecar `.txt` (`licence:
  ElevenLabs Creator, commercial`, title, artist), then `python3 -I tools/add_music.py
  --station=<id>`. Remove a station's synth loop from `radio.json` once its songs are in.
- **Credits**: CREDITS.md "Music" names the tool and plan for each set.
