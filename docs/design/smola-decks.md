# Za deckami: the DJ mix game inside Smoła

F's ask, 2026-11-26: "i want some dj mix ... based on the performance on desk the crowd is more
happy or less". Rave na Smolnej becomes the second featured quest on the phone (night meet, Rave
na Smolnej, TESŁO), so the club must give a new player something to play. F's decisions the same
day: the door stays as it is, everyone gets in, no dance-tapping game.

Design by Fable (this file), implementation plan by Opus (section 11), critique by Fable (section 12).

## 1. The fantasy in one line

The DJ needs five minutes. Mati shoves you into the booth: two decks, one room of people, three
mixes. Keep the kicks together and the floor goes off; let them gallop and forty people look at
their shoes.

## 2. Where it sits

- The door, the ticket and the pay at the door (rave.gd) do not change. Everyone gets in
  (`DOOR_STRICT` false stays).
- Inside the room (club.gd) the DJ is the game's door. On the first visit of a save the DJ calls
  the player over about 6 s after entering: a card, **ZA DECKI / NIE TERAZ**. After that, and on
  every later visit, a tile **ZA DECKI** stands on the booth and a tap on the DJ offers it.
- TAŃCZ stays as the small thing it is. The decks are the room's main thing.
- The set runs in the pixel look of padel and the Tapczan pong (a 216-row canvas over the whole
  screen, pixel_kit.gd), the city's and the room's 3D off while it plays.
- Leaving the set (the end or the ✕) returns to the room, and the room remembers how it went
  (section 7).

## 3. The screen

Landscape, 216 canvas rows.

- **Top 55 %: the floor seen from the booth.** The backs of the monitors, then the crowd in rows,
  the pillars, the bar's glow at the back, the truss lights. Mati front left, Pan Kołek by the
  pillar on the right, arms folded. The crowd is the score: you read it without a number.
- **Middle band: two wave lanes** scrolling right to left through a fixed NOW line a third from
  the left. Lane A (cyan, the track the room hears) and lane B (orange, the one you bring in).
  Kicks are solid blocks on the beat, every bar's "1" is taller, every 16 beats a gold bar (the
  phrase). The lanes are drawn from the beat grid plus a baked loudness envelope of the real
  track, so they look like the music.
- **Bottom 30 %: the desk.** Left: deck B's platter (the jog). Centre: the mixer with the
  crossfader and a four-box phase meter. Right: the pitch fader (a tall slider). Small chips top
  left: the track names, MIX 1/3. The ✕ top right.

## 4. The three controls

| Control | Touch | What it does |
| --- | --- | --- |
| **Jog** (talerz) | drag left or right anywhere in the left 40 % | bends deck B's speed while the finger moves: the orange lane slides against the cyan one. Let go and it keeps its place. |
| **Pitch** (tempo) | drag up or down on the right edge | sets deck B's tempo, ±4 %. Used from mix 2 on. A soft magnet holds it within 0.15 % of the right tempo. |
| **Crossfader** | drag along the bottom centre strip | A at the left, B at the right. |

Two thumbs at once must work (jog with the left, fader with the right). Every hit area is at
least 44 pt. Keys for the Mac and the checks: A/D jog, W/S pitch, Left/Right fader, Esc the ✕.

Both tracks really play. Before the blend, deck B is heard quietly and thin, as in one ear of
the headphones, so a bad match is heard as a gallop before the room hears it. Deck B's speed is
the player's pitch plus the jog's bend, as on vinyl: the sound and the lane are the same thing.

## 5. One mix

A mix is 64 beats of track A (29 s at 132 BPM).

1. **Cue, beats 0 to 32.** Track B appears in the orange lane, out of step. The room hears only
   A. Line the orange kicks up on the cyan ones. The phase meter's four boxes light as you close
   in, the orange lane turns gold and the phone ticks once when locked.
2. **Blend, beats 32 to 64**, a gold zone in both lanes. Push the crossfader from A to B. While
   both are in the room the crowd judges every beat (section 6). Landing the fader fully on B on
   a gold phrase bar is a clean hand-over: a cheer.
3. **Hand-over.** B becomes the room's track, its lane turns cyan, the next track loads orange.

If the fader is not on B when the blend ends, track A does not stop (no dead air, no hard
fail): its lane flashes TRACK ENDING, the crowd cools every beat until the fader lands.

The three mixes teach one thing each:

| Mix | New thing | Tempo of B | Drift |
| --- | --- | --- | --- |
| 1 | the jog and the crossfader, with a ghost hand and four words of help | matched | none |
| 2 | the pitch fader | off by 1.5 % | drifts until the pitch is right |
| 3 | the bass cut: hold BAS on the mixer through the last 8 beats of the blend, let go on the gold bar | off by 2.5 %, the other way | drifts faster |

The bass cut is the drop: held, the room loses the low end and the crowd raises its hands;
released on the bar, everything hits. Released early or late it is only a small miss.

A whole set: 6 s in, three mixes, 6 s out, about 100 s.

## 6. The crowd

One number, `hype`, 0 to 100, starts at 50. Judged once a beat.

| Situation | Hype a beat |
| --- | --- |
| Blend, locked (within 0.07 beat, about 32 ms) | +1.5, and a streak bonus up to +2.5 after 8 beats |
| Blend, loose (0.07 to 0.15 beat) | 0 |
| Blend, galloping (over 0.15 beat) | −3, the streak ends |
| One track in the room, nothing wrong | drifts to 55 by 0.25 |
| Track ending, fader not on B | −2 |
| Clean hand-over on the phrase bar | +8 once |
| Hard cut between tracks while galloping | −8 once |
| Bass cut released within a quarter beat of the bar | +10 once |

What the player sees and hears, by band:

- **0 to 25, cold.** People stand, three of them hold up lit phones, a couple walks to the bar,
  the lights sit still. Mati: a hand over his eyes. One whistle.
- **25 to 50, polite.** Heads nod, a few sway.
- **50 to 75, moving.** The whole floor bobs on the beat, hands come up on the bar.
- **75 to 90, hot.** Jumping, lasers on, the strobe on the beat, cheers on every phrase.
- **90 to 100, the oven (PIEC).** Everything, plus Pan Kołek: he nods. Once a set, at 95, he
  takes off the sunglasses for one second.

A gallop is heard for what it is (two kicks clattering); the crowd answers with a short "eee"
after four galloping beats. Under 10 hype for 8 beats the DJ comes back early ("Dobra, dobra,
oddawaj."): the set ends there with what it earned. Nobody is thrown out.

Strobe and flashes follow the game's reduced-flash setting (access.gd), as the room's do.

## 7. The end

A receipt in the pong's style: SET · the three mixes each with its grade, the longest lock in
bars, the floor's average, the tier, the tip and the respect. Then JESZCZE RAZ or NA PARKIET.

| Tier | Average hype | Respect | Tip |
| --- | --- | --- | --- |
| ŚWIETLICA (the youth club) | under 35 | 5 | 0 zł |
| ROZGRZEWKA (the warm-up) | 35 to 60 | 15 | 30 zł |
| DOBRY SET | 60 to 82 | 30 | 60 zł |
| PIEC (the oven) | 82 and over | 50 | 120 zł |

Paid once a visit; later sets that visit play for the grade only. The save keeps the best tier
and the number of sets. The first PIEC earns a line in the notebook and the DJ's "Ty, a ty
gdzie grasz?".

Back in the room, the room keeps the mood for the rest of the visit: the dancers' bob and the
lights' strength follow the set's average, and the crowd's lines come from `club_crowd_hot` or
`club_crowd_cold` when the set was hot or cold.

## 8. The music and the sounds (ElevenLabs, F's go 2026-11-26)

Four techno tracks of our own, named after the door's passwords: **BETON** (hard, industrial),
**MGŁA** (dubby, hypnotic), **SYRENA** (acid line), **TRAMWAJ ZERO** (rolling, a bell). Each a
16-bar loop at exactly 132.000 BPM (29.09 s), in or near A minor so any two sit together, a kick
on every beat from the first sample. A set draws four in a random order (three mixes).

ElevenLabs music does not promise an exact tempo, and the whole game stands on the grid, so the
tracks are conformed by a tool (`tools/make_deck_tracks.py`): measure the take's tempo and first
kick, stretch to 132.000, cut to 16 bars on a kick, make the seam loop, write the OGG and a small
envelope (8 values a beat) for the lanes. A take that cannot be conformed cleanly is thrown
away. If no take conforms, the same tool's fallback is a synthesised track from
`tools/make_club_loops.py`'s voices, which is on the grid by construction. The check fails if a
track's length is not 16 bars to the millisecond.

Sounds: a club crowd cheer (two takes), a short disappointed "eee", a vinyl spin-back for the DJ
taking the decks back. The rest are the game's own cues (tick, win, fail).

No real artist, label, track or club named anywhere.

## 9. The words

Polish with English, one language on screen (lang.gd). New groups in dialogue.json:
`club_decks_invite` (the DJ's offer), `club_decks_mati` (Mati during the set, by band),
`club_decks_dj_back` (the DJ returning, by tier), `club_decks_kolek`, `club_crowd_hot`,
`club_crowd_cold`. Help in the first mix is at most four words a step ("ZGRAJ STOPY", "TERAZ
FADER"). Tone: warsaw-tone skill; no drug jokes.

## 10. What it must not do

- No fail that sends a new player out of the club or costs money.
- No more than one new idea a mix.
- No number the player must read to play: the lanes, the phase boxes and the crowd say it all.
- No change to the door, the ticket, the quest's pay or the files the onboarding thread edits.
- No cost while the set is not on. While it is on: one 2D canvas, the 3D off, two music players.

## 11. Implementation plan (Opus)

The design is built as written, except for the points under "Design risks" at the end. Owners used: the sim and view pattern of pong (`pong_sim.gd` and `pong_match.gd`), `wallet.gd` `keep` for saved values, `dialogue.json` for words, `Sfx.SHOTS` and `tools/add_sfx.py` for one-shots, `Sfx.DUCKS` "club" (already held for the whole visit), `dev_flags.gd` for flags, and `GameCtx.city_drawn` to turn the 3D off.

### 11.1 Files
| File | Job | Size |
| --- | --- | --- |
| `game/scripts/decks_sim.gd` (new) | The pure rules. RefCounted, fixed 60 Hz, seeded, no nodes. Holds the bots (`bot_setup`, `bot_input`) and `static play_bot(skill, seed, tune) -> Dictionary` | ~600 |
| `game/scripts/decks_match.gd` (new) | The view. A 216-row SubViewport canvas on a CanvasLayer (layer 30) under club.gd (root viewport), multi-touch, the receipt, two music players and the audio sync | ~950 |
| `game/data/decks.json` (new, hand-written) | The tuning numbers: hype table, tiers, tips, respect, mix tempos, offsets, jog/pitch/fader gains | ~60 |
| `game/data/decks_tracks.json` (new, written by the tool) | Per track: id, name [pl,en], file, bpm 132.0, beats 64, frames, `env` (512 ints 0..255), source take or "synth" | ~4×600 numbers |
| `game/audio/club/decks/{beton,mgla,syrena,tramwaj_zero}.ogg` and `.import` (loop on) | The four tracks. They sit outside audio/sfx, so check_sfx's owner list needs no change | 4 × ~0.5 MB |
| `game/audio/sfx/crowd_cheer.wav`, `crowd_cheer_2.wav`, `crowd_eee.wav`, `vinyl_spinback.wav` | One-shots added with add_sfx.py (+ sources.json rows) | |
| `tools/make_deck_tracks.py` (new) | Conforms takes to the grid, plus the `--synth` fallback | ~450 |
| `game/tools/check_decks.gd` (new) | The check, plus its `--tune=N` mode | ~550 |
| `game/scripts/club.gd` | Invite, ZA DECKI tile, DJ offer, set start/stop, pay, saved values, mood | +~190 |
| `game/scripts/sfx.gd` | 3 SHOTS rows (+SHOT_RULES), `static func deck_buses()` | +~30 |
| `game/scripts/dev_flags.gd` | `decks_flag`, `decks_bot`, `decks_log` | +~12 |
| `game/scripts/pixel_kit.gd` | `var rects := 0`, counted in `rect()` (the check's budget) | +2 |
| `game/scripts/main.gd` | **One line**, see 11.5 | +1 |
| `game/data/dialogue.json` | 7 groups (11.6) | |
| docs, `tools/ci_steps.txt`, `tools/verify.sh`, `CREDITS.md` | 11.7 | |

### 11.2 The sim (`decks_sim.gd`)
**Units.** Beats and speed ratios. `BPM 132.0`, `HZ 60`, `TICK_BEATS = 132/60/60 = 0.036667`, `TRACK_BEATS 64`, `CUE 32`, `BLEND 32`, `INTRO 12` beats (5.45 s), `OUTRO 12`. All numbers in decks.json become `var`s set in `_init(seed, tune := {})`, so the tuning mode can override them.

**Decks.** Two decks, indices 0 and 1, never swapped. View player i is deck i. `room` is the index of the room's deck.
- Per deck: `track[d]`, `pos[d]` (beats into the track, in [0, 64)), `native[d]` (1 + the record's tempo error), `speed[d]`.
- The room deck runs at 1.0. The other deck runs at `native*(1+pitch) + jog_rate`.
- `order` is the 4 tracks shuffled by `rng`. Mix i plays `order[i]` into `order[i+1]`.

**Tempo error of B.** `native = 1 + [0, +s·0.015, −s·0.025][mix]`, where `s` = ±1 is drawn from the seed. The pitch fader starts at 0, so the right pitch is −error. Drift needs no extra term: the phase error grows by `(speed−1)` beats every beat (1.5 % gallops after ~10 beats, 2.5 % after ~6).

**Cue start.** B is cued at `floor(pos[room]) + off`, with `off` drawn from ±[0.25, 0.45]. All tracks therefore share the room deck's 16-beat phrase grid.

**Phases.** `INTRO → CUE → BLEND → (ENDING) → SOLO → … → OUTRO → DONE`, with `S` the mix's start beat (room beats):
- **CUE** runs `[S, S+32)` and **BLEND** runs `[S+32, S+64)`.
- **ENDING** starts at `S+64` if B has not landed.
- **Landing in BLEND** (fader ≥ `XF_LAND 0.98`) is the hand-over. The SOLO phase follows until `S+64`, and the next mix's `S' = S+64`.
- **Landing in ENDING:** `S'` = the next bar line of the room deck (`pos % 4 == 0`).
- **Landing in CUE** never hands over; there the fader only counts as "both in the room".
- **At hand-over** `room` flips. The new room deck's speed ramps to 1.0 over 2 beats (`native := 1`, `pitch := 0`, the fader-knob shows centre). `xf` snaps to 0, because the new room track is now "A".
- **End of the set:** mix 3's hand-over goes to OUTRO, then DONE after 12 beats. The early return goes straight to DONE.

**Jog.**
- The input is `in_jog_pt` (points dragged this tick, signed).
- `target = clamp(in_jog_pt * JOG_BEAT_PER_PT(1/200) / TICK_BEATS, ±JOG_MAX 0.10)`, then `jog_rate += (target − jog_rate) * (1 − exp(−DT/JOG_TAU 0.06))`.
- A first-order low-pass keeps the dragged distance (within the clamp), so after release the record "keeps its place". `jog_rate` decays to ~0 in 0.25 s.
- A 200 pt drag moves B by one beat.
- Keys A/D give a target of ±0.04.

**Pitch.**
- `pitch = clamp(pitch − in_pitch_pt * PITCH_PER_PT(0.04/90), ±0.04)`. Keys W/S move it ±0.02 per second.
- Magnet: when the finger is off and `|native*(1+pitch) − 1| < MAGNET 0.0015`, the residual decays with `MAGNET_TAU 0.25 s` to exactly 1.0.

**Crossfader.**
- `xf = clamp(xf + in_xf_pt / XF_SPAN_PT(150), 0, 1)`. Keys Left/Right move it 1.5 per second.
- Zones: `xf < XF_BOTH 0.12` means A only (B on pre-listen). `0.12 ≤ xf < 0.98` means **both in the room**. `≥ 0.98` means landed.
- Gains are equal-power: `gA = cos(xf·π/2)`, `gB = sin(xf·π/2)`.

**Error and lock.**
- `err = wrapf(pos[b] − pos[room], −0.5, 0.5)`.
- The meter's lit boxes are 4/3/2/1/0 at `|err|` ≤ 0.07 / 0.15 / 0.25 / 0.35 / more.
- `locked` turns on at ≤ 0.07 and off at > 0.09 (hysteresis). Its events drive the tick and the gold lane.

**Per-beat judging.** At each integer crossing of the room deck's beat (`_judge(n)`), in this order:
1. **Both in the room:** `|err| ≤ 0.07` gives `+1.5 + 2.5*min(streak,8)/8` and `streak += 1`. `≤ 0.15` gives 0. Otherwise −3, `streak = 0`, `gallop_run += 1`, and on `gallop_run == 4` the event `eee`.
2. **ENDING:** −2 (on top of rule 1 if both are in the room).
3. **Neither of the above:** hype moves toward 55 by 0.25.
4. **Cold run:** `cold_run` counts beats with hype < 10. At 8 the event `dj_back` fires and the set goes to DONE.

Hype is clamped to [0, 100] after every change.

Per mix the sim keeps `both_beats`, `locked_beats`, `longest` (in beats) and `clean`.

**Hand-over bonuses.**
- Clean: `+8` when the landing tick is within ±0.5 beat of a phrase bar (`pos[room] % 16`) at `S+48` or `S+64`, and `|err| ≤ 0.07`.
- Hard cut: `−8` when `|err| > 0.15` at landing.

**Bass cut (mix 3 only).**
- `in_bass` held sets `bass_cut`, which the audio follows.
- **Drop (+10, event `drop`):** the button was held since ≤ `S+57` (`BASS_FROM 8`, 1 beat of grace) and released within ±0.25 beat of `S+64`. The sim allows one drop a set.
- Released at another time, it gives the event `bass_miss` and no hype.

**Pan Kołek.** The event `kolek_nod` fires on each band entry ≥ 90. The event `shades` fires once a set, the first beat with hype ≥ 95.

**Average and grade.**
- `avg = hype_sum / max(192, judged_beats)`. Judged beats run from mix 1's beat 0 to the last hand-over. After an early return the beats not played count as 0 (see risk 1).
- Tiers: `[35, 60, 82]` → 0..3.
- Mix grade from `share = locked/max(1, both)`: CZYSTO (≥ 0.75 and clean), DOBRZE (≥ 0.5), KRZYWO (≥ 0.2), GALOP (below), "—" for a mix not reached.

**Input and output.**
- Before each `tick()` the view sets `in_jog_pt`, `in_pitch_pt`, `in_xf_pt`, `in_bass`, `in_pitch_touch`, `in_jog_touch`.
- Events go to `events: Array[Dictionary]`: `beat{n,bar,phrase}`, `cue{deck,track,pos}`, `blend`, `locked`, `unlocked`, `eee`, `ending`, `landed{clean,hard}`, `handover{room}`, `bass_on/off`, `drop`, `bass_miss`, `band{from,to}`, `kolek_nod`, `shades`, `dj_back`, `mix_done{i,grade}`, `over{tier,avg,grades,longest_bars,early}`.
- Read-only queries for the view: `gain(d)`, `thin()` (`xf < 0.12`), `bass_cut`, `meter()`, `band()`.

**Bots** (`bot_setup(skill, seed)`, own rng; `bot_input()` fills the `in_*` fields):
- `perfect`: reacts to `err` 9 ticks old. Jog P-gain `−err·50` pt per tick, clamped ±6. Pitch corrects to within 0.0005. The fader moves from beat 34 over 10 beats to 0.9 and lands on `S+48` (mix 3: holds the bass `S+56..S+64` and lands at `S+64`).
- `mid`: 21-tick delay, gain 0.3×, jitter σ 1.5 pt. Stops the pitch at a residual 0.002–0.004. Lands at a random beat 50–62. Releases the bass at ±U(0.2, 0.8).
- `none`: does nothing.

### 11.3 The view (`decks_match.gd`)
**Canvas.**
- `H 216`, `W = max(MIN_W 288, round(216·w/h))`: 467 at 19.5:9, 288 at 4:3.
- `MIN_W` is 288, not pong's 384, so the iPad sees the whole canvas and nothing is cropped.
- Built as in pong's `_build`: `disable_3d`, nearest filtering, `STRETCH_KEEP_ASPECT_COVERED`.

**Layout (canvas px):**
- **Floor, rows 0–118.** Truss 4–8 with 6 light heads. Back wall 8–44 with pillars at 0.18W/0.5W/0.82W (10 px). Bar glow at 0.62–0.95W, rows 30–44. Crowd feet on rows 58/72/88/104 (10/11/10/9 people, `Kit.mini` at the back, larger at the front). Monitor backs at rows 108–118 (two 40×10 boxes at 0.3W and 0.7W). Mati: `Kit.figure` at x = max(30, 0.1W), foot 118. Kołek: x 0.88W, foot 100.
- **Chips** at (6,4): "BETON → MGŁA", "MIX 1/3". The ✕ is a 14 px disc at (W−18, 4).
- **Lanes.** Lane A rows 121–133, lane B rows 136–148. NOW line at x = round(W/3). 24 px a beat (19.5:9 shows 6.5 beats back and 13 ahead; 4:3 shows 4 back and 8 ahead).
  - A beat k of deck d is drawn at `NOW + (k − pos_d)·24 / tempo_d`, where `tempo_d` is the speed without the jog. A wrong tempo therefore shows as a spacing that spreads away from NOW.
  - The envelope is 8 columns a beat (3 px wide), with height `env/255·13`.
  - Kick blocks are 3×7 px; the bar's "1" is 3×13. A gold 2 px line marks each phrase.
  - The blend zone is a gold tint behind both lanes.
  - B is drawn in `Kit.US`, turning `Kit.GOLD` when locked. A is `Kit.THEM`. TRACK ENDING flashes on lane A during ENDING.
  - **Latency:** both lanes are drawn at `pos − AudioServer.get_output_latency()·2.2·speed`, so what is seen at NOW is what is heard. The judging is relative and needs no correction.
- **Desk, rows 152–215.**
  - Jog platter: a disc at (0.17W, 184), r 26, with a groove mark turned by `pos[b]`.
  - Phase meter: 4 boxes 8×6 at row 158, centred at 0.5W, with a small ◀/▶ for early or late.
  - BAS: 34×16 at rows 170–186, dim before mix 3.
  - Crossfader: slot from 0.38W to 0.62W at row 200, knob 8×14.
  - Pitch: slot at x = W−24, rows 156–210, with a centre detent tick.

**Touch zones** (screen points, fractions of the safe rect; `static func zones(size_px, pt) -> Dictionary` so the check can measure them):
- ✕: a 44 pt circle at the top-right safe corner.
- Pitch: x ≥ 0.84, y ≥ 0.30.
- Jog: x < 0.40, all heights.
- Crossfader: 0.40 ≤ x < 0.84, y ≥ 0.80, ending 12 pt above the bottom inset (home indicator).
- BAS: same columns, y 0.62–0.80.
- The rest does nothing.

**Multi-touch.**
- `_zone_of: Dictionary` maps a touch index to the zone it pressed in. A drag applies `event.relative / pt` to that zone only, even if the finger leaves it. Release clears the entry.
- BAS is held while its index stays down.
- Keys: A/D, W/S, Left/Right, Space for BAS (not in the design table), Esc for the ✕.
- `_input` marks the events handled while the set is on, so club.gd's people taps stay quiet.

**Crowd by band** (display hype eased at 2 per second, ±2 hysteresis), within **450 rects** for the floor:

| Band | What it does |
| --- | --- |
| cold | People stand still. 3 phones (a 2×3 white rect above the head). 2 walk toward the bar. Mati's hand-over-eyes pose. |
| polite | Every 3rd person nods 1 px on the beat. |
| moving | Everyone bobs 2 px. Arms go up on the bar's "1". |
| hot | People jump 3 px. 6 laser lines. A floor-wide white strobe at α 0.25 on the beat, which `Access.calm` turns off. A cheer on each phrase. |
| PIEC | Everything above, plus Kołek's nod. On `shades` his sunglasses come off for 1 s. |

**Rect budget.** About 1100 rects a frame: floor 450, lanes 360, desk 100, text 150. The check reads it from `Kit.rects`.

**Ghost hand** (a 6×8 px hand sprite moving on a looping path, with a chip of at most 4 words):
- Mix 1: jog ("ZGRAJ STOPY") until the first lock, then the fader ("TERAZ FADER") from blend start.
- Mix 2: the pitch ("RUSZ TEMPO").
- Mix 3: BAS ("TRZYMAJ BAS" from `S+56`, then "PUŚĆ!" at `S+64`).
- The hand shows only on the first set of a save (`decks_sets == 0`) and goes after the control is first used right. Later sets show the chip alone.

**Receipt** (as pong's `_draw_result`):
- A card of 200×150 px. SET; three rows "MIX n · GRADE"; the longest lock in bars (`longest/4`); the floor's average; the tier in gold at scale 2; "+TIP ZŁ" and "+R RESPEKT", or "WIZYTA OPŁACONA" when this visit already paid.
- Buttons JESZCZE RAZ / NA PARKIET (`Kit.button`, hit area ≥ 44 pt).
- The ✕ during a set ends it like the early return and shows the receipt.

**Signals and wiring.**
- Signals: `finished(result: Dictionary)` and `closed`.
- Fields set by club.gd: `pt`, `auto_skill`, `log_on`, `words: Callable(group, tag) -> String`, `sound: Callable(name)` (sfx.play), `cue: Callable(name)` (hud.cue). Haptics go through `Access.buzz(15, 0.5)` on `locked`.
- **Ticking:** an accumulator, at most 6 ticks a frame. On `NOTIFICATION_APPLICATION_PAUSED` the sim stops and `stream_paused = true`.
- **Idle:** with no set on, `set_process(false)`, the layer is hidden and the sim is null.

### 11.4 Audio
**Players.** Two `AudioStreamPlayer`s owned by decks_match.gd (a venue's own music, as padel's). Streams are `AudioStreamOggVorbis` with `loop = true`, `bpm = 132`, `beat_count = 64`; the check confirms the loop length. Headless runs make no players, as `club._music_on` does.

**Deck speed.** `pitch_scale = sim.speed[d] · (1 + nudge_d)`.

**Sync (each frame, both decks):**
1. Heard position in stream seconds: `get_playback_position() + AudioServer.get_time_since_last_mix()·pitch_scale`.
2. Sim position: `sim.pos[d]·60/132 + _acc·speed·…`, i.e. the accumulator remainder interpolated.
3. `e = wrapf(sim − heard, −L/2, L/2)` with `L = 29.0909 s`. The modular wrap makes a loop wrap harmless.
4. Smooth it: `ē = 0.8ē + 0.2e`.
5. **Within 4 ms:** `nudge = 0`.
6. **Over 4 ms:** `nudge = clamp(0.6·ē, ±0.006)`, at most ~10 cents and inaudible. 30 ms closes in about 5 s.
7. **Over 60 ms for 3 frames running** (a hitch, a start, a resume): `seek(fposmod(sim_s + AudioServer.get_time_to_next_mix(), L))`, then 6 frames with no measuring.

**Starting a deck.** On a `cue` event: `play(pos_s + get_time_to_next_mix())`.

**Hand-over.** Nothing moves between players. The old room deck fades out with `gA` and is stopped when its gain reaches 0. At the next `cue` it loads the next track.

**Buses.** `Sfx.deck_buses()` in sfx.gd (the owner) makes two buses lazily, once, at the first set:
- `Decks` → sends to `Music`, so the player's music slider holds. It carries an `AudioEffectHighPassFilter` (24 dB) for the bass cut, disabled at rest.
- `DeckCue` → sends to `Decks` (appended later, so it sends to a lower index). It carries a HPF at 700 Hz for the headphone pre-listen.

Player 0 and player 1 swap buses at hand-over: the room deck sits on `Decks`, the incoming deck on `DeckCue`.

**Pre-listen.** While `thin()`, B plays at −14 dB through the 700 Hz HPF: kick clicks and hats, so a gallop is heard as clatter. As `xf` goes from 0 to 0.12 the cutoff ramps from 700 to 20 Hz, and the effect is then disabled.

**Bass cut.** Held: the `Decks` HPF cutoff ramps 20→250 Hz over 40 ms. Released: it goes back in 20 ms.

**Cost.** Two biquads and two Vorbis decodes, about 2 % of one iPhone core. An idle bus does no effect work.

The rejected alternative was pre-rendered "thin" and "no bass" stems: that is four synced players and twice the files.

**Duck and one-shots.**
- The duck is the existing "club" (radio −60), held for the whole visit. During the set club.gd sets `_music.stream_paused = true` and does not call `_music_on("")`, so the duck is never released.
- One-shots through `sound`: `crowd_cheer` (2 takes) on a clean hand-over, on a drop and on hot phrases; `crowd_eee` on `eee`; `vinyl_spinback` on `dj_back`.
- Cues through `cue`: `tick` (lock), `win` (tier ≥ 2), `fail` (`dj_back`).

### 11.5 club.gd integration
- **main.gd, the one line**, in `_enter_club` inside `if club == null:` after `club.log_on = flags.rave_log`: `club.wire(_build_ctx(), sfx)`. `wire` copies `ctx.city_drawn`, `ctx.flags.decks_flag`, `decks_bot`, `decks_log` and `sfx`, and keeps no ctx.
- **The test start needs no other main.gd change.** In dev_flags.gd `--decks` sets `decks_flag = "on"` and `rave_flag = "club"`, so main.gd's existing `--rave-club` path enters the room. `enter()` then starts a set 1 s later, once per run.
- **Invite.** In `enter()`, if `not wallet.keep.get("decks_invited", false)`, set `_invite_t = 6.0`. `_process` counts it down only in the sala with no line up. `_invite()` shows the talk card with a `club_decks_invite` line and two `_button`s, ZA DECKI / NIE TERAZ. It then sets `keep.decks_invited = true` and calls `wallet.save()`.
- **Tile.** `_decks_btn` (a `_button` "ZA DECKI") is placed at `cam.unproject_position(PLACE + Vector3(0, 2.6, −ROOM.y/2 + 1.6))` in `_go("sala")` and on `size_changed`. It is visible when invited, in the sala and with no set on.
- **DJ tap.** When `pick` returns people[0], `_say` the invite line with the ZA DECKI button.
- **`start_set()`:** `_ui.visible = false`, `_music.stream_paused = true`, `city_drawn.call(false)`, `_decks_on = true` (`_process` returns at once: no lights or dancers posed), `_decks.start(seed, first = keep.decks_sets == 0)`.
- **`_on_set_finished(r)`:**
  - Pay once a visit: if not `_decks_paid`, `wallet.pay(TIP[t], RESPECT[t], "club_decks")`.
  - Saved values: `keep.decks_best = max(...)`, `keep.decks_sets += 1`.
  - First PIEC: `keep.decks_piec = true`, a pending `hud.show_note` shown at `leave()`, and the DJ line tagged `first_piec`.
  - Then `wallet.save()`, `_mood = r.avg/100`, and log `decks: over: <TIER> avg <x> paid <zł>/<resp>`.
- **`_on_closed()`:** `city_drawn.call(true)`, `_ui.visible = true`, the room loop resumed, a DJ line from `club_decks_dj_back` tagged by tier (or `early`).
- **Mood for the rest of the visit** (cleared in `enter()`):
  - `_dance()` hop × `lerp(0.4, 1.6, mood)`.
  - `_pose_lights()` colours × `lerp(0.55, 1.25, mood)`.
  - `_say` crowd group: `club_crowd_hot` when avg ≥ 60, `club_crowd_cold` when < 35, otherwise `club_crowd`.
  - `_say(person, tag := "")` gains the tag argument.
- **Words for the view:** `words = func(g, t): Lang.pick(dialogue.line(g, t, true)...)`.

### 11.6 Words (dialogue.json, `{"only": tag}` notes)
| Group | Lines |
| --- | --- |
| `club_decks_invite` | 4 |
| `club_decks_mati` | 2 each for cold, polite, moving, hot, piec (10) |
| `club_decks_dj_back` | 2 each for swietlica, rozgrzewka, dobry, piec, early ("Dobra, dobra, oddawaj."), plus 1 first_piec ("Ty, a ty gdzie grasz?") (11) |
| `club_decks_kolek` | 4 |
| `club_crowd_hot` | 5 |
| `club_crowd_cold` | 5 |
| `club_decks_ui` (needed, see risk 9) | One line per tag: the tiers, the grades, the help chips, the receipt labels, JESZCZE RAZ, NA PARKIET, TRACK ENDING, the track names, BAS (~30) |

Bubbles stay ≤ 90 characters and help chips ≤ 4 words. Tone follows the warsaw-tone skill: no drugs, no real names.

### 11.7 Bookkeeping
- `systems.md`: a row for `decks_sim.gd` and one for `decks_match.gd`, and extend the `club.gd` row.
- Archive flags table: a row for `--decks`, `--decks-bot=…`, `--decks-log`.
- `docs/changes/2026-11-2x-smola-decks.md`.
- `ci_steps.txt`: `decks quick` and `decks-run local slow`, sorted. `verify.sh` cases:
  - `decks) check decks '^check_decks:' --script res://tools/check_decks.gd`
  - `decks-run) game decks 12000 '^decks: over: PIEC' --decks --decks-bot=perfect --decks-log`
- `CREDITS.md`: a "Smoła's decks" table (4 tracks: "own: generated with ElevenLabs …" or "synthesised by tools/make_deck_tracks.py"), and change the "Music, sounds and art" sentence (some effects are ElevenLabs, per sources.json). `check_credits` reads only `radio.json`, so this is safe.
- check_sfx: no owner-list change (the files are outside audio/sfx). The new SHOTS rows are covered by its file loop.

### 11.8 make_deck_tracks.py
Usage: `python3 -I tools/make_deck_tracks.py TAKE ID [--start=S] [--dry]`, `--synth ID|all`, `--check`. Standard library only, ffmpeg external.
1. **Decode.** `ffmpeg -i TAKE -ac 1 -ar 11025 -f s16le -` → `array('h')`, plus a 44.1 kHz stereo decode for the cut.
2. **Onset function.** A one-pole low-pass at 150 Hz, energy in 64-sample hops (172.3 frames/s), `log1p(1000·e)`, half-wave rectified difference → `O[n]`.
3. **Coarse tempo.** Autocorrelation of O at lags of 16 beats for 126–138 BPM (lags ~1197–1310), with parabolic interpolation.
4. **Fine tempo and phase.** A comb DFT at the beat rate, `Z(bpm) = Σ O[n]·e^{−i2πn/P}`, over ±0.3 % in steps of 0.002 BPM. Take the bpm with the largest |Z|. `strength = |Z|/ΣO`, and `arg Z` gives the first kick. Refine each kick at 44.1 kHz to the steepest low-band rise within ±10 ms.
5. **Stretch.** `r = 132/bpm`. If |r−1| ≤ 2 %, varispeed (`asetrate=44100*r,aresample=44100`; keeps transients, ≤ 0.34 semitone). Else `rubberband=tempo=r` if `ffmpeg -filters` lists it. Else `atempo=r` up to 6 %. Beyond that the take is rejected.
6. **Cut.** From the chosen kick (the first kick after `--start`, default 8 s), take `N = round(64·60/132·44100) = 1282909` samples plus 441.
7. **Seam.** `out[i] = take[i]·g + take[N+i]·(1−g)` over 441 samples (10 ms), g a raised cosine. Measure the seam's largest step against the 99.9th-percentile step (the same rule as check_sfx).
8. **Normalise and write.** Peak −1 dBFS, RMS target −14 dBFS. `libvorbis -q:a 5` to OGG.
9. **Envelope.** RMS over 1/8-beat windows (2505.7 samples), mapped −40..0 dB → 0..255, 512 values into `decks_tracks.json`.

**Acceptance** (the output is measured again):
- strength ≥ 0.35 on the take;
- output tempo 132.000 ± 0.01;
- all 64 kicks within ±3 ms of the grid (95 % within ±2 ms) and the first at 0–3 ms;
- every beat's kick onset ≥ 0.3 × the median;
- length exactly N;
- seam step ≤ 1.5 × p99.9 + 0.01.

Any failure means the take is rejected (printed) and nothing is written.

**`--synth`.** Imports `make_club_loops.py`'s voices (`sys.path.insert(0, tools dir)`): kick, noise_hit, clap, saw_bass, stab, sub. It builds 16 bars at 132 per track recipe (BETON: driven kick and clang; MGŁA: dub stab with delay; SYRENA: an acid saw with the cutoff swept; TRAMWAJ ZERO: a rolling sub and a bell). It is on the grid by construction and goes through the same measuring.

### 11.9 check_decks.gd assertions
1. **Tracks.** 4 ids, each with names and a file. The OGG loads, loops, and `|get_length() − 29.090909| ≤ 0.001`. Envelope has 512 ints in 0..255, and the first slot of a beat is ≥ the median on ≥ 60 of 64 beats.
2. **Constants.** `64·60/BPM` equals the loop length. CUE + BLEND = 64.
3. **Determinism.** Same seed and bot give an identical digest (hype every beat plus the event names). A different seed gives a different `order`.
4. **Perfect bot.** 10 seeds: all PIEC, no early return, 3 clean hand-overs, a drop, `shades` at most once.
5. **No-input bot.** 10 seeds: ŚWIETLICA. DONE is reached with the `dj_back` event, the exit stays open, and the stand-in wallet gets +0 zł and +5 respect.
6. **Mid bot.** 30 seeds: at least 80 % in ROZGRZEWKA or DOBRY, at most 10 % in PIEC.
7. **Bounds.** For every tick of every bot run, 0 ≤ hype ≤ 100 and 0 ≤ avg ≤ 100.
8. **Forced rules:**
   - a locked beat gives +1.5, with the bonus reaching +2.5 at a streak of 8;
   - a gallop gives −3 and resets the streak, and the 4th gallop beat sends `eee`;
   - ENDING gives −2 a beat;
   - a clean hand-over gives +8 only at 48 or 64 within ±0.5, and gives nothing at 32;
   - a hard cut gives −8;
   - the drop gives +10 at ±0.24 and nothing at ±0.3;
   - the magnet snaps at 0.0014 and not at 0.002;
   - a 200 pt jog moves one beat ±1 % and keeps its place after release;
   - pitch is clamped at ±4 %.
9. **Early return.** Hype under 10 for 8 beats ends the set; 7 beats does not.
10. **Average.** After an early return the beats not played count as 0.
11. **Club with stand-ins** (Fakes.Wallet, Hud, Dialogue; `city_drawn` recorded):
    - the invite comes once, 6 s after entering;
    - the tile shows after the invite;
    - a set runs with the perfect bot: +120 zł/+50, best 3, sets 1, `city_drawn` false then true, `Sfx.ducked("club")` held the whole time;
    - JESZCZE RAZ pays nothing and sets becomes 2;
    - leave and enter again: it pays again;
    - the crowd group after a hot set is `club_crowd_hot`.
12. **Words.** Every group and tag the scripts ask for; each a [pl,en] pair, not empty, ≤ 90 characters; help ≤ 4 words; no word from the brand denylist or the drug-word list; every UI letter is in the 5x7 font.
13. **Flags.** `parse_with(["--decks","--decks-bot=mid","--decks-log"])` gives the values and `rave_flag == "club"`. `wants_harness()` stays false.
14. **View.** decks_match with `auto_skill = perfect` emits `finished` and then `closed` headless. Every zone is ≥ 44 pt and none overlap, at 2532×1170 @3 and 2048×1536 @2. `Kit.rects` per frame ≤ 1100.
15. **Buses.** `Sfx.deck_buses()` twice makes 2 buses once, with the right sends and the effects disabled.

**Tuning mode.** `-- --tune=N [--tune-set=key=value,…]` prints, per skill (perfect, mid, none): tier shares, average mean/p10/p90, early-return %, set length in seconds, and locked share per mix.

### 11.10 Build order ($GODOT; every game run passes `--nosave` and a quit flag)
1. **Tool and synth tracks.** `python3 -I tools/make_deck_tracks.py --synth all && python3 -I tools/make_deck_tracks.py --check && $GODOT --headless --path game --import`. Accept: 4 tracks pass the acceptance numbers.
2. **The sim, decks.json and check sections 1–10.** `$GODOT --headless --path game --script res://tools/check_decks.gd`, then `… -- --tune=200`. Tune decks.json until 4–6 pass, and paste the distribution into section 11.
3. **sfx.gd buses and the 3 SHOTS rows.** ElevenLabs sounds through `python3 -I tools/add_sfx.py SRC crowd_cheer --from="ElevenLabs Sound Effects v2" --prompt=…`. Run `tools/verify.sh --only=sfx,mixer,decks`.
4. **decks_match.gd.** Run check 14, then the shots: `$GODOT --path game --resolution 2532x1170 -- --nosave --notitle --decks --decks-bot=mid --shots=700,1500,2600,5200 --out=../shots/decks`, and again at `--resolution 2048x1536`. These are the harness's `--shots=` frames, as the pong's `--tapczan=pong` shots.
5. **dialogue.json.** `tools/verify.sh --only=decks,rave`.
6. **club.gd, the main.gd line, dev_flags.** `tools/verify.sh --only=decks,rave,devflags,architecture,decks-run`.
7. **ElevenLabs takes** (credits approved 2026-11-26): 2–3 takes a track (132 BPM, four-on-the-floor, A minor, no vocals, 60–90 s). Conform each and keep the ones that pass; otherwise synth stays. Repeat step 1's check.
8. **Docs and bookkeeping (11.7).** `python3 -I tools/check_architecture.py && python3 -I tools/changelog.py --check && python3 -I tools/ci_tier.py --check && tools/verify.sh --quick`.
9. **Full definition of done.** `tools/verify.sh --ios`. Bench in the set: decks_log prints the frame note (as `Room.frame_note`) 3 s in. Report bench before and after.

### 11.11 What only the phone can show
- Output latency (wired, speaker, AirPods ~150–250 ms) against the lanes.
- Two-thumb touch together with iOS edge gestures: the home indicator under the crossfader, and Control Centre at the top right near the ✕.
- Whether real audio drifts or seeks are audible on iOS.
- Vorbis decode cost and heat over a few sets.
- The haptic tick, and the silent switch.

### 11.12 Design risks
1. **Doing nothing earns ROZGRZEWKA by the table.** Hype rests at 55 through the cue and blend, then falls at −2 a beat, giving an average of ~45. The plan counts the 192 nominal beats, with the beats not played after an early return as 0, which gives ~22, ŚWIETLICA. Fable to accept, or else choose "blend with the fader still on A after 8 beats: −1".
2. **New buses go against extending.md.** The bass cut and the thin pre-listen need a filter on a bus, and extending.md's "not" column names a new AudioServer bus. The plan adds them inside the owner (`Sfx.deck_buses`); the owner must agree.
3. **Tempo snap at hand-over.** If the player never fixed the pitch, ramping B to 1.0 is an audible tempo jump of up to 2.5 % over 2 beats.
4. **Landing on beat 32 cannot be clean.** It is a cut at the blend's first beat, so only 48 and 64 count as clean.
5. **No notebook for the first PIEC.** MOJA WARSZAWA only holds places. The plan uses `hud.show_note` on leaving the club.
6. **A seventh words group.** `club_decks_ui` is needed for the tiers, help and receipt labels.
7. **The crossfader sits on the iOS home-gesture edge.** The strip is lifted 12 pt over the safe inset. Check whether the project defers system gestures.
8. **ElevenLabs takes may not conform.** Wandering tempo and intros without a kick are likely to fail the ±3 ms rule, so expect the synth fallback for some tracks.
9. **The ✕ is not defined by the design.** The plan treats it as an early end with a receipt and pay.
10. **The iPad needs its own minimum width.** pong's `MIN_W 384` would crop the desk on 4:3, so the decks use 288.

## 12. Critique of the plan (Fable) and what is built

Read section 11 with these changes; where they differ, this section wins.

1. **The tracks are done, with no stretching and no synthesised fallback.** Eight ElevenLabs
   takes were measured before the build: every one holds 132.00 BPM to a hundredth and does not
   drift (each 16-beat stretch matches the whole take within 2.5 ms). So `tools/make_deck_tracks.py`
   (already written, differs from 11.8) only finds where in the beat the kick starts (the click
   over 3 kHz that has the low band's swell after it), picks the fullest 64 beats with no
   breakdown, cuts them 4 ms before the kick, joins the seam and measures the result. Files:
   `game/audio/club/decks_{beton,mgla,syrena,tramwaj}.ogg`, 1 282 909 frames each, about 470 kB;
   rows in `game/data/decks_tracks.json` with `loud` and `kick` (512 values, 0 to 99). No
   `--synth`, no `--check` mode: the check script measures the files. Build steps 1 and 7 are done.
2. **No bass cut and no new audio buses in this version.** The bass cut needs a filter on a bus,
   which extending.md forbids outside the mixer, costs audio work on the phone, and is the one
   part closest to the hold-and-release game F turned down. Mix 3 is instead the hard one: B is
   2.5 % off the other way and starts further out. The pre-listen is deck B played quietly
   (-12 dB) on the same bus as the club's loop, with no filter: a gallop is heard well enough.
   The design's section 5 row for mix 3 and section 6's bass row are out; the drop can come
   back after F has played the set.
3. **Doing nothing is ŚWIETLICA by rule, not by arithmetic.** A set the DJ takes back early is
   tier 0 whatever its average; the average counts only the beats played.
4. **The ✕ leaves at once**: back to the room, no receipt, no pay, the set not counted.
5. **Hand-over glide.** The new room deck comes to speed 1.0 over 8 beats, not 2.
6. **main.gd grows by no line.** The existing `club.log_on = ...` line becomes the `club.wire(...)`
   call (wire sets log_on too); main.gd is at its line ceiling and another thread edits it.
7. **The lanes' latency offset** is `AudioServer.get_output_latency()` and nothing more (no 2.2
   factor); the phone decides if it needs a trim, and that trim is one constant.
8. **Tuning targets for the harness** (200 seeds each): perfect bot PIEC always; mid bot DOBRY
   SET or ROZGRZEWKA in at least 80 %, PIEC in at most 10 %; no-input bot ŚWIETLICA always, the
   DJ back within 50 s; a "poor" bot (delay 30 ticks, gain 0.15, never touches the pitch) below
   DOBRY SET in at least 90 % and never sent off before mix 2 starts. If hype saturates at 100
   in mix 1 for the mid bot, lower the streak bonus before touching anything else.
9. Accepted as planned: risks 4, 5, 6, 7, 10; `decks.json` for the numbers; the sim and view
   split; the check's sections (without the bass items of 8 and without 15).
