# "Bokiem na Narodowym": the drift quest, the drift technique and the stadium scene (plan, 2026-11-22)

F (2026-11-22, the garage thread): after the garage, a drift quest at the National Stadium. Your
mate in the Bawarka calls: someone from his team dropped out, come and drift. You are moved into a
scene of its own (like the club), where our car can drift, and there is a drift competition. Work
out the drift technique for our arcade and our reality, test it well, invent the story, research
how other games do it. Then (22:37): "maybe a couple of tracks there, smoke, more drift physics",
"and they give us a drift Bawarka". F's reference pictures: the real Drift Masters layout on the
stadium floor (two grass islands, a figure-eight-like loop, smoke, flame jets, screens, the roof),
kept at `/mnt/project-files/refs/drift-narodowy/` (never in the repo). **A plan for F's approval;
nothing is built yet.** It builds on `docs/design/garage-and-cars.md` (the cars' feel, 4b).

## 0b. The vertical slice (2026-11-26, checked against main; this wins over section 0 and below)

F (2026-11-26): a **side quest under ZADANIA**, not a chapter (rivals and story are other threads):
a generic hook (Darek calls, any time after the first night meet), one `stories.add`. Parody names
only, no copied memes. Instagram #driftgame (read only): one-thumb "hold to drive, tap-tap to slide",
big smoke, marks that stay, a bright score that climbs and banks, night/snow variants, chase and top
cameras. Drawn on: FR Legends, CarX (phone layouts), Forza drift zones (chain, banking), one-tap 2D
drift games (hold/release rhythm); nothing copied.

### 0b.1 Section 0 against the code on main

| Section 0 | Now | Why (what main has) |
| --- | --- | --- |
| 1. `drift_mode` branch in `car.gd` | **Changed**: a subclass `drift_car.gd extends car.gd` that overrides `_step` only, on a second car in the stadium. `car.gd` is not edited | car.gd's drift is one line (`drift_grip` only under braking above 10 m/s, l. 729); `weighty` is GROUNDED's; the H1 slider is built. Its ground, water and kerbs are callables that default to flat and dry (l. 354-366), so a second car off the map needs no map. City checks stay untouched by construction |
| 2. RĘCZNY on BRAKE's plate, Point controls, "auto gas" | **Changed**: the default is **one thumb** (0b.3); RĘCZNY on the brake plate only in the DWA KCIUKI option | Classic is the only scheme since 2026-11-10 (settings.gd l. 43); Point is gone |
| 3. A venue owner | **Valid, more urgent**: built first (D1a) | none on main; four scenes are OR'd by hand in main.gd (`_sound_mode`, `_toggle_vehicle`, `_update_camera`; `_free_block` names only the club and lounge). `tapczan_room` already has the right shape (`inside()`, `room_view(cam, pitch)`) |
| 4. Short event | Valid: qualifying best of 2, a final tandem of 2 runs vs Hrabia's recording | |
| 5. One score | Valid, sharpened: **points are the only currency**. The 0-100 judges and "60 of 100" go; the three cards split the run's points | |
| 6. Numbers | Mostly valid; new table in 0b.2 (sticky band 25-50°, curvature-scaled rates, tiers) | |
| 7. Names | Valid: "Puchar Bokiem"; the copied memes stay cut (the kansei and Déjà vu lines in 3b and 3c are void). Sponsor: "Bycze Skrzydło" echoes the real slogan, so the default is **"Turbo Tur"** (Open Questions) | warsaw-tone rules 1 and 2 |
| 8. Prize: the Bawarka 325 drift setup | **Changed for the slice**: 800 zł, 150 respect, the paint "Bokiem" (a `garage.gd` PAINTS row, any car). The Bawarka waits for C1a/C1b | `upgrades.gd` CARS holds only the hatch and the TT; no per-car feel, no `check_car_feel` |
| Phases after C1a | **Changed**: D0 can start now (the stadium carries its own car table) | |

The story in the slice: Darek's Bawarka is at Mirek's without its diff, so **you drive your own car
with "spawany dyfer na wieczór"**. The setup belongs to the stadium, not the car. Hatch and TT get
rows; a Bawarka row comes in with its body.

### 0b.2 D0: the drift model (angle as a state, not tyre physics)

`drift_car.gd` keeps two angles: the **course** θ (where the car goes) and the **slip** β (body yaw
= θ + β, + left). It moves with `move_and_slide` along θ, so walls work. The car's look, box and
lights are car.gd's (`lights = 0`: its SpotLight is off in the lit stadium). The maths sit in a
pure static `drift_model.gd` (`step(state, input, params, dt)`). Modes: GRIP, DRIFT, SPIN.

| Rule | Number (all guesses, tuned by the bots in 0b.7) |
| --- | --- |
| Kick (tap-tap / RĘCZNY) | at ≥ 30 km/h with a bend within 30 m ahead (line \|κ\| ≥ 1/60 m⁻¹; two thumbs: steer ≥ 0.2); β opens to 30° on the bend's side, τ 0.10 s (95 % in 0.3 s). Below 30 km/h: "ZA WOLNO", no penalty |
| Gas held in DRIFT | β grows at R_GAS = 25°/s × (1 + 15 × \|κ\|) (×2 at a 15 m hairpin, ×1.6 on the 24 m sweeper) |
| Sticky band 25-50° (the assist) | inside the band R_GAS × 0.35 PEŁNA (default), × 0.7 ŚREDNIA, × 1 BRAK |
| Lift (not a tap) | β falls at 40°/s; \|β\| < 8° for 0.4 s: GRIP, the chain banks (40° to banked in about 1.2 s) |
| Transition (kick in a drift) | only inside a window from 0.8 s before to 0.4 s after the line's κ changes sign; β crosses zero in 0.6 s and lands at 30° on the other side. Outside the window: β −5°, nothing else |
| Spin | \|β\| > 75° (BRAK 70°), or v < 6 m/s with \|β\| > 45°: 1.5 s of rotation to a stop, the unbanked chain lost, the run goes on |
| Speed | dv/dt = 9 × gas × (1 − v/28) − 0.3 × v × sin\|β\| − 1.5 × (1 − gas): about 63 km/h held at 40°, about 100 km/h flat out in grip |
| Wall | keeps 70 % of the speed, the course slides along the wall, the drift ends, the chain is lost |
| One-thumb course | pure pursuit on the track's ideal line, look-ahead 6 + 0.4 v m. Zones sit where the line plus angle hits them: the line passes 2.6 m from the outer board, so the tail (2 m × sin β out) reaches 1.5 m at β ≥ 35° |
| Cars | hatch: these numbers. TT ("quattro"): kick 24°, R_GAS × 0.8, lift × 1.2. Bawarka later: R_GAS × 1.15, spin 80°, transition 0.5 s |

`drift_score.gd` (pure static). Points a second = km/h × A(β) × chain (× 1.5 BLISKO in a chase).
A is 0 under 15°, rises to 1 at 25°, stays 1 to 50°, falls to 0.5 at 65°. The chain starts at ×1,
gains +1 every 2.5 s unbroken and +1 per transition, and caps at ×5. Zones (ZONA: the tail within
1.5 m of an outer board; KLIP: the nose within 1.5 m of an inner cone) need \|β\| ≥ 30° and pay
300 × chain, once per zone per run. Points pile up **unbanked** and go into the total on a clean
end (lift, or the run's end while drifting); the chain then returns to ×1. A wall, a spin or a
contact loses them: PRZEPADŁO. **No points** when progress along the line is under 8 m/s, the
car is more than 6 m off the line, or it is going backwards. A run ends at the finish line or
after 45 s. The three cards: LINIA (zone points), KĄT (time-in-band points), STYL (chain and
transition points); together they make the run's total.

`drift_input.gd` (pure): touches to `gas` and `kick` (0b.3). `drift_line.gd` (pure): the track per
metre (position, tangent, κ, zones, κ sign changes), `project(p) → s, offset`, recorded lines (per
0.5 m: x, z, yaw, β, v); data `game/data/drift_tracks.json`. `--drift-record=osemka` (harness)
writes `game/data/drift_lines/osemka_hrabia.json` (decent bot, about 40 KB).

### 0b.3 The one-thumb scheme (phone default, JEDEN KCIUK)

- **The pad is the whole screen** under the top strip (18 % of the height: total, run and timer,
  ✕, WIDOK Z GÓRY). Only the first finger counts, so no left-handed mirror is needed.
- **Down = gas** (full in 0.15 s); **up = lift**. In DRIFT, holding grows the angle and lifting
  shrinks it. Keeping the needle in the band is the skill, a calm rhythm of roughly 1.5-2 s holds
  and 0.4-0.6 s lifts at PEŁNA, shorter at the hairpin.
- **Tap-tap = kick**: a tap is a press of 0.18 s or less; the kick fires **on the second press**
  if it comes within 0.25 s of the first tap's release (no added latency), and a finger that stays
  down is gas. In a drift, inside the transition window, it is PRZEKŁADKA. A lift of more than
  0.18 s is never a tap.
- Steering is the line (0b.2); the choices: when to kick, how deep to hold, when to bank, flick the S.
- On screen: an **angle arc** (120°, bottom centre, a green 25-50° band, a needle on β), a **travel
  chevron** painted on the floor 4 m ahead along θ (the nose against the chevron is the angle), the
  **unbanked points in gold** above the car with the chain chip (×3), climbing; on a bank they fly
  to the total in 0.35 s ("+2 340", cue, buzz); PRZEPADŁO in red on a loss. Labels: KLIP! /
  CLIP!, ZONA! / ZONE!, PRZEKŁADKA! / TRANSITION!, BLISKO! / CLOSE!, KONTAKT! / CONTACT!,
  ZAKSIĘGOWANE / BANKED, ZA WOLNO / TOO SLOW.
- Haptics through `Access.buzz`: kick light, zone medium, bank a double, loss heavy.
- **DWA KCIUKI** (the option, the city's Classic): the steering strip is the line; GAZ held; the
  brake plate becomes RĘCZNY (a single tap kicks); the same assist and scorer. Pad: RT gas, A kick,
  stick steers (two thumbs only). Keyboard: W gas, Space kick. Kept in settings.gd `[drift]` with
  the assist and the camera.
- First run: Lena's tip on the stadium's UI, never a bare "hold to drift" (that teaches the spin).

### 0b.4 D1: the stadium and Ósemka

- **D1a, the venue owner `venues.gd`** (no behaviour change, its own PR): `add(name, inside:
  Callable, view: Callable)`; main.gd asks `venues.view(cam, camera_pitch)` in `_update_camera` and
  `venues.inside_name()` in `_sound_mode`, `_toggle_vehicle`, `_free_block`; the OR chains go.
  `check_venues.gd`: each venue entered and left sets and clears the name, the camera and the HUD;
  the owner extending.md names for "a scene off the map".
- **D1b, `drift_stadium.gd`** (Node3D, club pattern, built on the first visit) at **PLACE (−9000,
  0, −9000)** (the other three corners are taken). The player's car waits at the gate (process
  off); the stadium's own `drift_car` and UI (CanvasLayer, UiKit tokens) drive; the HUD is hidden.
- **The floor** 150 × 90 m: two grass islands (30 × 20 m ellipses at x ±35), barriers, tyre walls,
  zone boards, cones, the start and finish lines as one mesh in the actors' vertex-colour material
  (floodlight pools baked in, no lights); colliders are boxes with `set_meta("solid", "barrier")`.
- **Ósemka** (about 465 m, about 30 s at 55-65 km/h): south straight 40 m, west loop (r 24 m,
  300°), crossover with transition 1, east hairpin loop the other way (r 18 m, 300°), crossover
  back with transition 2, half the west loop, north straight. Zones: west ZONA and KLIP, centre
  KLIP, east ZONA and KLIP.
- **The bowl**: tiers (near side cut away), the roof ring and the screen cube as one mesh; the LED
  ring as one emissive mesh (Turbo Tur, KEBAB FM 87,3); a crowd of 1,500 in one MultiMesh.
- **`drift_fx.gd`**: smoke as street_meet.gd's recipe (unshaded alpha puffs, one MultiMesh), 64
  puffs at High (2.5 m to 5 m, 1.2 s, alpha 0.35) from the rear wheels by sin\|β\| × v, plus a
  burst on a kick. Tyre marks: a second `skids.gd` with two small additions whose defaults keep the
  city as it is (`max_marks`, 6,144 here: about 1,800 m of trail, so **the evening's marks stay on
  the floor**; `along_velocity`: marks lie along the wheel's path, so the arcs read). Flame jets on
  the islands: one MultiMesh, shown 0.6 s on a zone.
- **Camera** (`room_view`): isometric orthographic, pitch 40°, view 34 m, yaw 45°, leading by
  velocity × 0.6 s (at most 8 m), plus 4 m of view above 30°. WIDOK Z GÓRY: pitch 85°, view 60 m.
  A chase camera needs a perspective view (decisions.md: the camera is orthographic), so it is not built.
- **Sound**: tyre and engine loops follow the stadium car (the venue swaps sfx.gd's car and puts it
  back; no private player); SHOTS `drift_kick`, `drift_bank`, `drift_lost`, `zone_flame`
  (`make_sfx.py`); `hud.cue` start/finish, `hud.tick_clock` the last 5 s; the radio plays on.
- **Flags** (dev_flags.gd + the archive's table): `--drift=osemka` (practice at once),
  `--drift-controls=one|two`, `--drift-assist=full|mid|off`, `--drift-cam=iso|top`, `--drift-log`;
  harness `--drift-bot=decent|clumsy|metronome|hold|bank|none`, `--drift-record=osemka`.
  **Tiers** (`tiers.gd`): smoke 64 / 40 / 24, crowd 1,500 / 900 / 400.

**Phone budget** (gate; `--drift=osemka --bench` and `--probe`, before and after D1b): 3D main pass
≤ 20 draw calls (floor, bowl, boards, crowd, smoke, marks, flames, chevron 1 each; two cars ≤ 10);
shadows the cars only, ≤ 8; all passes with the UI ≤ 45 (the city's spawn: about 150); ≤ 60k
triangles; **smoke cover** (the puffs' screen area ÷ the screen, logged by drift_fx) ≤ 1.5 screens
at High; stadium scripts ≤ 0.6 ms on the Mac, the city ticking under it measured, and if both are
over 2.0 ms the venue owner gets a `quiet` list (traffic and walkers off inside); iPhone 60 fps,
1 % low ≥ 55 at High with full smoke (PHONE-CHECK row).

### 0b.5 D2: the side quest ("Bokiem na Narodowym", ZADANIA)

- **`drift_event.gd`**, an activity on the kit (`extends activity.gd`; `install`, `setup_in`,
  `joined`; one `_join` line in `_build_world`; `rescue_calls = HOLD`; `run_hours` 20:00-02:00
  with the kit's clock jump). One `stories.add({"id": "bokiem", ...})`, whose `hello`, `closed`
  and name come from dialogue.json through the activity (no Polish literals in main.gd, the TD-19
  ratchet). QUESTS lists it by itself (`quest_book.gd`).
- **The gate**: no ring before the first night meet is done (`wallet.jobs` "meet_race" +
  "meet_drag" ≥ 1, read only; street_meet.gd is not edited). The times go in `pacing.json`
  "bokiem": first call 60-180 s after the gate opens, a refused call again after 600-900 s.
- **The flow** (about 6 min): Darek calls (JADĘ / NIE DZIŚ) → `set_target` "Parking pod Narodowym"
  (street_meet.gd `narodowy`) → stop in the ring: a roar, the scene opens (never in a chase:
  `may_start`; „Najpierw zgub ogon” / "Lose the tail first") → paddock card (Lena's tip, JEDEN / DWA
  KCIUKI, assist, START) → **qualifying**: 2 runs, the best counts, Q_LINE 4,500 (guess), PONÓW
  (instant) or DALEJ; Kaśka „Ścinka” and Bjørn on the board as a name, a number, a line (no cars) →
  **final**: run 1 Hrabia leads on his recording, you chase (BLISKO 1-5 m behind, ≤ 3 m aside;
  passing him in a drift halves the run; overlapping boxes is KONTAKT); run 2 you lead, he follows
  your progress 3 m back. Your two totals against his (his recording scored + a fixed 60 % BLISKO
  share); a draw is "jeszcze raz" → podium (flames, Lena) → back at the gate, `finish` pays.
- **Pay** (`pay(..., "bokiem")`, `save`): win 800 zł, 150 respect, the "Bokiem" paint (WNRC neon
  red), quest done and silent; lost final 250 zł and a rematch from QUESTS; out in qualifying 100
  zł, quest open. Best in `keep["bokiem_best_osemka"]`. ✕ inside: back at the gate, nothing paid.
- **Add-ons**: Dialogue Manager and Beehave not used (a two-button call and taps; Hrabia is a recording).
- **New lines** (group "bokiem" in dialogue.json, warsaw-tone; 3c's lines stay usable except the
  kansei line; Bjørn's becomes winter):

| Tag | Polish / English |
| --- | --- |
| call | „Lena wypadła: słoik ogórków babci wygrał z jej nadgarstkiem. Dziś Puchar Bokiem na Narodowym, team WNRC ma wolne miejsce. Wchodzisz?” / "Lena's out: gran's pickle jar beat her wrist. It's the Puchar Bokiem at the Narodowy tonight and team WNRC has a free seat. You in?" |
| car | „Bawarka stoi u Mirka bez dyfra, więc jedziesz swoim. Spawany dyfer dostaniesz na wieczór.” / "The Bawarka's at Mirek's with no diff, so you're driving yours. You get a welded diff for the night." |
| gate | „Pokaż ochronie opaskę. Nie masz? Powiedz, że od Darka.” / "Show security your wristband. None? Say Darek sent you." |
| tip | „Trzymasz: gaz. Stuk-stuk: bokiem. Puszczasz: prosto.” / "Hold: gas. Tap-tap: sideways. Let go: straight." |
| tip | „Igła w zielonym. Za mało to jazda, za dużo to bączek.” / "Needle in the green. Too little is driving, too much is a spin." |
| retry | „Za wcześnie puszczasz. Ściana nie gryzie. No, rzadko.” / "You let go too early. The wall doesn't bite. Well, rarely." |
| bank | „Zaksięgowane! Księgowa na trybunach płacze.” / "Banked! The accountant in the stands is crying." |
| transition | „Przekładka! Z lewej na prawą jak na Rondzie Dmowskiego.” / "Transition! Left to right, like on Rondo Dmowskiego." |
| zone | „Ogon przy bandzie, babcia przy telewizorze.” / "Tail on the wall, gran glued to the TV." |
| spin | „Bączek! Pełne trzysta sześćdziesiąt, gratis.” / "A spin! The full three-sixty, on the house." |
| bjorn | „U nas zimą wszyscy jeżdżą bokiem. Tu jeszcze dają puchar.” / "Back home everyone drives sideways in winter. Here they even give you a cup." |
| hrabia_lost | „Przegrałem z hatchbackiem. Nikomu ani słowa. Zwłaszcza moim oponom.” / "Lost to a hatchback. Not a word to anyone. Especially my tyres." |
| out | „Nic się nie stało. Jutro druga runda, a dyfer dalej spawany.” / "No harm done. Round two's tomorrow and the diff's still welded." |

### 0b.6 The eight attacks I fear most, and the answers

C-Xn is check_drift's test Xn (0b.7).

1. **A fixed rhythm wins (metronome).** Rates scale with κ, so one duty cycle leaves the band
   somewhere; the metronome bot fails in 8 of 8 (C-B3). If not: narrow the band or raise κ's factor,
   never add dice.
2. **Bank every second, safe and dull.** A bank resets the chain, so long chains pay about ×3;
   bank-spam < 75 % of the decent bot (C-B5), while the decent bot still passes 7 of 8 (greed is not a trap).
3. **Farming off the drive** (paddock donuts, cone circling, wall scraping for ZONA): no points
   without 8 m/s of progress or past 6 m off the line, zones once a run, a touch loses the chain, 45 s
   cap (C-S5, C-B7).
4. **A fake tandem** (sitting in the ghost; a fixed bar): BLISKO only 1-5 m behind, overlap is
   KONTAKT, passing halves the run; Hrabia's bar is his own run through the same scorer, on his cards;
   the decent bot wins 4-6 of 8 (C-B1).
5. **One thumb is on rails; the hint teaches the wrong thing** (critique-padel's lesson). Real
   choices: kick timing, depth (it decides the zones geometrically), bank or push, flick the S; DWA
   KCIUKI gives the line back with no multiplier (C-B8 ±15 %); the tip teaches the rhythm. P25 judges it.
6. **Fill rate**: close smoke is full-screen alpha. Tier caps, the cover metric (≤ 1.5 screens), no
   lights, an unshaded bowl, shadows on the cars only; the iPhone row decides and the caps are the lever.
7. **The angle does not read in iso.** The travel chevron, the arc, marks along the wheels' paths,
   WIDOK Z GÓRY. Acceptance: shots set `drift` at β 20°, 40°, 60°, iso and top, told apart at 2532×1170.
8. **Untestable feel.** Everything that can be pure is pure and seeded at 60 fps (3 skill and 4
   exploit bots); the hand's part goes to Autopilot **P24** (call to podium, < 7 min) and **P25**
   (time to a held 3 s drift, tap-tap found), then PHONE-CHECK (the 0.25 s gap, the arc, smoke at 60 fps).

### 0b.7 `check_drift.gd` (headless, `--fixed-fps 60`, verify step `drift`, `ci_steps.txt` line)

- **Model**: M1 a kick at 60 km/h on r 25 m reaches \|β\| 25-40° by 0.35 s · M2 a kick under 30
  km/h gives no drift (β < 5° at 1 s) · M3 PEŁNA with the gas held from 30°: ≤ 50° for ≥ 1.5 s,
  and no spin before 3.0 s · M4 a lift from 40°: < 8° by 0.9 s, GRIP and banked by 1.3 s · M5 a
  transition inside the window lands ≥ 20° on the other side by 0.7 s; outside it, no flip · M6
  BRAK with the gas held spins before 2.5 s, stopped by 1.5 s after · M7 a wall in a drift: 60-75 %
  of the speed kept, the drift over, never pinned more than 1.5 s · M8 the decent rhythm holds
  50-75 km/h on the sweeper · M9 the same inputs twice give the same state hash · M10 10,000 random
  frames give no NaN · M11 `car.gd`'s source names no drift script (the city stays clean).
- **Input**: I1 tap 0.1 s, gap 0.15 s, press: a kick on the second press, gas held after · I2 a
  0.3 s lift is no kick · I3 a 0.35 s gap is no kick · I4 a long hold then tap-tap kicks · I5 a
  second finger is ignored in JEDEN KCIUK.
- **Score**: S1 A(β) and points a second at known values · S2 the chain steps, the transition +1,
  the cap ×5 · S3 a bank adds the unbanked and resets the chain · S4 a wall, spin or contact loses
  the unbanked and leaves the total · S5 no points under 8 m/s of progress, past 6 m off, or
  backwards · S6 ZONA and KLIP at 1.5 m and ≥ 30°, once per zone · S7 the run's end while drifting
  banks · S8 BLISKO 1-5 m behind; a pass halves the run; overlapping boxes is KONTAKT.
- **Bots on Ósemka** (8 seeds): B1 decent (timing error σ 80 ms) passes Q_LINE in ≥ 7 and beats
  Hrabia in 4-6 · B2 clumsy (σ 200 ms) passes in 2-5 · B3 metronome passes in 0 · B4 hold-only
  spins every run and scores < 40 % of Q_LINE · B5 bank-spam < 75 % of B1 · B6 no kick scores 0 ·
  B7 donuts off the line score 0 · B8 the DWA KCIUKI decent bot is within ±15 % of B1 · B9 B1's runs
  last 28-40 s.
- **Recording**: R1 `osemka_hrabia.json` covers s 0 to L with no gap over 1.5 m, \|β\| ≤ 60°, and
  its total within 1 % of the stored one · R2 the follower stops at least 2 m behind a stopped player.
- **Event** (Fakes.Hud, Dialogue, Wallet): E1 no ring before a night meet, a ring after · E2 JADĘ
  sets the gate's target, and arriving calls the enter hook once · E3 two failed runs pay 100 zł and
  keep the quest open; a pass goes to the final · E4 a win pays 800 zł, 150 respect and the paint,
  the quest is done, `save` is called; a loss pays 250 zł and offers a rematch · E5 ✕ inside: back
  at the gate, nothing paid, the car's process restored · E6 `rescue_calls` HOLD; no start during
  a chase · E7 every spoken line comes from dialogue.json with both languages.
- Not here: the bench and probe (0b.4), shots set `drift`, `check_venues` (D1a), P24 and P25.

### 0b.8 Phases

| Phase | What | Owner, model | Size (×1.5 real) |
| --- | --- | --- | --- |
| **D0** | `drift_model`, `drift_score`, `drift_input`, `drift_line`, `drift_car`, `drift_tracks.json`, `check_drift` (M, I, S; B on a bare floor with Ósemka's line, no scene), the recorder | gameplay-dev, Opus (feel) | 1 PR, 2-3 days |
| **D1a** | `venues.gd` and the four scenes joined in main.gd, `check_venues`, no behaviour change | gameplay-dev, Sonnet | 1 small PR |
| **D1b** | `drift_stadium`, `drift_fx`, the `skids.gd` options, camera, UI, flags, tiers, bench, shots | gameplay-dev, Opus directs the look | 1 PR, 3 days |
| **D2** | `drift_event`, the stories entry, pacing, dialogue lines, the paint, the recorded Hrabia, E-checks | gameplay-dev, Sonnet on this spec | 1 PR, 2 days |
| **D3** | Autopilot P24/P25 (Mac), PHONE-CHECK rows, tuning from them | Opus on the Mac | an evening |
| Later | Wielka Pętla, Thursday practice from QUESTS, the Bawarka 3.2 Drift (after C1b), the night/snow cup (a white floor, rates × 1.2: one data row), the notebook page | | |

Touched only for rows or options: `skids.gd`, `tiers.gd`, `dev_flags.gd`, `dev_harness.gd`,
`settings.gd` `[drift]`, `sfx.gd` SHOTS, `garage.gd` PAINTS, `pacing.json`, `dialogue.json`,
systems.md, main.gd (the `_join`, the enter hook, the venue lines). Full definition of done (verify,
shots, bench, `--ios`) for D0, D1b, D2.

### 0b.9 Open defaults (built as written unless F says otherwise)

1. One thumb is the default and DWA KCIUKI the option, with no multiplier.
2. The sponsor parody "Turbo Tur" (alternatives: keep "Bycze Skrzydło", or no sponsor at all).
3. A spin costs the chain, not the run (strict option: a spin scores the run 0, as real judging does).
4. You drive your own car with the stadium's setup; the Bawarka drift car comes with its body after C1b.
5. The prize is 800 zł, 150 respect and the Bokiem paint.
6. Venue owner first (D1a) as a separate no-behaviour PR touching main.gd's lines of the other
   four scenes (alternative: only the stadium joins and the four move later, leaving a TD row).
7. The radio plays in the stadium until a Bokiem FM loop is made.

## 0. The revised plan (2026-11-22, after the Opus review)

**This section wins over everything below it; section 0b above wins over it.**

1. **A drift mode, only in the stadium**: a `drift_mode` branch in `car.gd` (like `weighty`), the maths in
   a pure static `drift_model.gd`, on only inside the scene. No drift state in city driving (lane
   assist, the wall rules and `check_lane_drive` stay untouched), no city practice pad yet.
2. **RĘCZNY takes BRAKE's plate**, not the nitro's: the thumb rocks GAS ↔ RĘCZNY without lifting
   (the existing GAS ↔ BRAKE roll), the left-handed layout mirrors it; BRAKE moves to the small slot.
   Pad: the shoulders. Point controls: the stick is the line, the full assist sets the angle. The
   assist setting has an "auto gas" choice.
3. **A venue owner** for scenes off the map (`inside`, `centre`, `view_size`, what stops while you are
   inside: streaming, traffic, police, the minimap) instead of a fourth copy of the club's pattern in
   main.gd; no entry during a chase.
4. **Shorter event**: qualifying (best of 2 runs, instant retry with a Lena line), then one final
   tandem against „Hrabia" (2 runs, his recorded line). About 6 minutes. Top 4, the second track
   (Wielka Pętla), Thursday practice, the notebook page and the replay camera come later.
5. **One score**: the chain with banking; the three judges' cards only show its three parts.
6. **Numbers**: RĘCZNY tap at 30 km/h or more with the wheel turned opens the angle in ~0.3 s; the
   full assist holds 20-45°, a spin at 75°; off the gas it straightens in 1.2 s; a transition 0.6 s;
   runs 30-35 s. Smoke at most 64 puffs (2.5 m, 1.2 s, alpha ~0.35, unshaded); a crowd of at most
   2,000 in one MultiMesh; about 15 draw calls with both cars (not 10).
7. **Names and jokes**: the event "Puchar Bokiem", the sponsor parody "Bycze Skrzydło" (no can of
   any shape); the copied memes (the anime inertia-drift line, the Eurobeat lyric) are cut by the
   warsaw-tone rule 1 (original writing only); kept: Lena's pierogi deliveries, the pickle jar,
   the commentator's wall line, the fan who paid to breathe tyres, our own Eurobeat-style loop. Bjørn's
   line is about winter, not his country.
8. **The prize**: the drift setup for the Bawarka 325 in Darek's WNRC colours (the road Bawarka 325
   can be bought at Mirek's).

Phases: D0 drift model + `drift_score.gd` + `check_drift` + a line recorder → D1 the venue owner,
the stadium and Ósemka (smoke, marks, camera; the near stands cut away) with a bench → D2 the short
event (the call, Hrabia's line, the prize). After the garage's C1a.

## 1. The real thing

- **Drift Masters Grand Finale at PGE Narodowy** (Red Bull, every September since 2019): a track laid
  on the stadium floor under the closed roof, about 50,000 people, smoke, pyro, the season's final.
  Sources: [Red Bull, Grand Finale 2026](https://www.redbull.com/pl-pl/red-bull-drift-masters-grand-finale-info-harmonogram-wiadomosci-2026),
  [the 2025 preview](https://www.redbull.com/pl-pl/red-bull-drift-masters-grand-finale-2025-zapowiedz-atrakcje-zawodnicy),
  [the rules of drifting explained](https://www.redbull.com/al-sq/rules-of-drifting-explained),
  [how the asphalt gets onto the pitch](https://www.eska.pl/motoryzacja/roboty-drogowe-na-pge-narodowym-ciezarowki-walce-i-tony-asfaltu-aa-P7Gm-SxFN-VADb.html).
- **The format**: qualifying (solo runs, judged on line, angle and style, with clipping points and
  zones marked on the track), then tandem battles from Top 32 to the final: two runs per battle,
  each driver leads once and chases once; a draw means "one more time".
- **The layout** in F's pictures: an asphalt loop round two grass islands (stages, screens, flame
  jets on them), a transition between the islands, walls with sponsor boards all round.
- Our version is a **parody**: "Bokiem Masters", an invented amateur Pro-Am night, invented drivers,
  sponsor parodies only ("Red Byk"); no real drivers or brands.

## 2. How the games do drifting (what we take)

| Game | How drift works | What we take |
| --- | --- | --- |
| FR Legends (mobile) | Left/right buttons, gas, a handbrake button; tap the handbrake to start, gas and steering hold the angle; scored on angle, speed and line, tandems with chase/lead | The phone layout: RĘCZNY (handbrake) button, tap to start; tandem chase/lead |
| CarX Drift Racing (mobile) | Physics drift with steering assist settings; points for angle × speed, zones | Assist levels (full / medium / off) |
| Forza Horizon drift zones | Points = speed × angle, a chain multiplier that grows while you keep sliding; points are "banked" only when the drift ends cleanly | Chain multiplier, banking, losing the chain on a wall |
| Need for Speed (Underground, Heat, Unbound) | Brake-tap or gas-and-turn starts a drift; points and multipliers on screen, transitions earn extra | Brake-flick entry in the city, "PRZEKŁADKA!" bonus for switching sides |
| Ridge Racer, Mario Kart | Drift is an assisted arcade state: you choose when, the game keeps it pretty | The full assist keeps the angle in a good band so a phone thumb can do it |
| Gran Turismo drift trial, real judging | Clipping points and zones on the track, judges for line, angle, style | Zones on our tracks and three judges' scores (Linia, Kąt, Styl) |

Sources: [VDrift drift scoring](https://raw.githubusercontent.com/VDrift/vdrift/master/docs/Drift_scoring.md),
[FR Legends scoring](https://loganhayes2.github.io/frlegnds),
[Forza drift zone scoring](https://forums.forza.net/t/what-makes-up-the-drift-score-for-drift-zones/84508),
[GT7 drift trial](https://gran-turismo.com/us/gt7/manual/worldcircuit/06).

## 3. The story

- **Who**: Darek „Bawarka" and Lena „Bokiem" from the night racing club (`street_meet.gd`): they are
  already the drift pair of the game (Lena spins donuts, Darek chases her in the tandem at meet 2).
  The quest opens after the first night meet.
- **The call** (at night; offered by day with the clock jump, like the other night quests):
  > Darek: „Mamy problem. Lena wypadła: skręciła nadgarstek, otwierając babci słoik ogórków. Dziś
  > na Narodowym runda Pro-Am Bokiem Masters i team WNRC nie odda miejsca. Widziałem, jak kręcisz
  > na parkingu. Bawarka drift czeka, klucze u mnie. Wchodzisz?"
  > ("Lena's out: sprained her wrist opening her gran's jar of pickles. Tonight there's the Pro-Am
  > round at the Narodowy and team WNRC won't give up the slot. I've seen you spin on the car park.
  > The drift Bawarka's waiting. You in?")
  WCHODZĘ / NIE DZIŚ. Mirek has a line too ("Lena's diff is in my shop anyway").
- **The way in**: drive to the stadium's gate (the night meet's spot "Parking pod Narodowym"), stop
  in the ring; a short fade with the crowd's roar; **you are in the paddock inside the stadium**.
  Your own car waits at the gate.
- **The paddock**: Darek with the **Bawarka 3.2 Drift** (his spare: welded diff, big steering lock,
  hydraulic handbrake, WNRC hot-neon red with "BOKIEM TEAM"), Lena with her arm in a sling giving
  tips, a mechanic, the screen with the bracket. Tap people for lines; pick the assist; START.
- **The event**: practice → qualifying → Top 8 → Top 4 → the final, each battle two runs (you lead
  once, chase once). Three invented rivals with their own cars and a line each (warsaw-tone): Kaśka
  „Ścinka" (a tiny Japanese-style coupe), Bjørn Bokvist (a Nordic estate, very calm), and the final's
  champion "Hrabia" (the Count) in a V8 coupe.
- **The end**: podium, flames, confetti, Lena's thanks. Prize: 1st 800 zł + 150 respect + **the
  Bawarka 3.2 Drift is yours** (Darek: "Lena i tak chce nowe auto"), plus a "Bokiem" livery for any
  car; 2nd 400 zł; 3rd 250 zł; out in qualifying 100 zł and "spróbuj w czwartek" (a retry the next
  night).
- **After**: "Trening na Narodowym" stays: Darek calls on Thursdays, or start it from MOJE AUTO; the
  second track opens after the final; your best per track is kept.

## 3b. Drift lore and memes (F 22:38: "add drift lore and memes, maybe some dialogues")

Drift has a big meme culture; we use it the warsaw-tone way: affectionate, our own words, parody
names, no real drivers, no real songs.

- **Where drift came from** (the paddock's lore card and Lena's tips): mountain passes in Japan in
  the 70s and 80s, kids sliding old rear-drive coupes at night, then the races, the films and the
  anime. In Poland: Beemki (old BMWs) with a **welded diff** ("spawany dyfer"), donuts on supermarket
  car parks after closing, winter practice on frozen lots, and now 50,000 people in the Narodowy.
- **The memes, as our jokes**:
  - **The tofu delivery** (the anime's hero learned to drive delivering tofu down a mountain): Lena
    learned to drift delivering her gran's **pierogi** from the bar on Ząbkowska before they went
    cold. "Pierogi muszą dojechać ciepłe. Zakręt musi być bokiem."
  - **"Did you just do a kansei dorifto?"** (the inertia-drift meme): the commentator, at a clean
    transition: "Czy to było... kansei dorifto? W Bawarce?!"
  - **"Déjà vu"** (the Eurobeat meme: "I've been in this place before"): a rival at the second lap
    of the same corner: "Déjà vu! Już tu byłem. Bokiem."
  - **Eurobeat**: the scene's music is our own fast Eurobeat-style loop (made like the club's
    loops), on a one-night radio "BOKIEM FM"; the crowd claps on its beat.
  - **"Grip is for cowards"** / **"Angle, not time"**: the team's mottos on the paddock banner:
    "Przyczepność jest dla tchórzy" and "Liczy się kąt, nie czas".
  - **"Tyres are currency"**: the drift world's money is tyres; Darek pays you in "opony" as a joke
    before the zł appear ("Wygrasz, to masz cztery nowe. No dobra, i kasę.").
  - **The welded diff**: the Bawarka Drift's spec sheet in the paddock: "Dyfer: spawany. Hamulec
    ręczny: hydrauliczny. Rozsądek: brak."
  - **The 'Janusz' with the Pasatini 1.9 TDJ** (our crazy driver) turns up at the practice pad in the
    city: "Ja też tak umiem. Na mokrym. Przypadkiem."
  - **The police** at the stadium gate: "Pan tu bokiem? A, to na tor. To jedź pan, tylko prosto do bramy."
- **Lore that stays**: a "BOKIEM" page in the notebook after the event: the team (Darek, Lena,
  Tadek), your best runs, the rivals and their quotes; the Bawarka Drift's plate "WB0K13M".

## 3c. Dialogue samples (Polish with English; final lines go through the warsaw-tone skill)

| Who | Line |
| --- | --- |
| Darek (the call) | „Mamy problem. Lena wypadła. Słoik ogórków babci wygrał z jej nadgarstkiem." / "We've got a problem. Lena's out. Gran's pickle jar beat her wrist." |
| Darek | „Bawarka drift czeka. Spawany dyfer, ręczny jak w autobusie. Pokochasz albo się pobijecie." / "The drift Bawarka's waiting. Welded diff, a handbrake like a bus's. You'll love it or you'll fight." |
| Lena (tip 1) | „Ręczny to nie hamulec. To zaproszenie." / "The handbrake isn't a brake. It's an invitation." |
| Lena (tip 2) | „Gaz trzyma kąt. Puścisz gaz, puścisz bokiem." / "The gas holds the angle. Let go of the gas, let go of the slide." |
| Lena (tip 3) | „Patrz tam, gdzie chcesz jechać. Nie tam, gdzie jest ściana. Ściana sama cię znajdzie." / "Look where you want to go, not at the wall. The wall will find you by itself." |
| Mirek (on the radio) | „Dyfer Leny mam u siebie w kawałkach. Ty mi tylko Bawarki nie przywieź w torebce." / "I've got Lena's diff here in pieces. Just don't bring me the Bawarka in a bag." |
| The commentator, Zbyszek Gumiak | „Panie i panowie, ten kąt jest nielegalny w trzech województwach!" / "Ladies and gentlemen, that angle is illegal in three provinces!" |
| Zbyszek Gumiak (a transition) | „Czy to było... kansei dorifto? W Bawarce?!" / "Was that... a kansei dorifto? In a Bawarka?!" |
| Zbyszek Gumiak (a wall) | „Ściana: jeden, kierowca: zero. Ściana nie ma licencji, a i tak wygrywa." / "Wall one, driver nil. The wall has no licence and still wins." |
| Judge (cards) | „Linia: 8. Kąt: 9. Styl: babcia by płakała. Ze wzruszenia." / "Line 8. Angle 9. Style: gran would cry. With joy." |
| Kaśka „Ścinka" | „Mam 120 koni i każdy jest wściekły." / "I've got 120 horses and every one is furious." |
| Bjørn Bokvist | „W Norwegii drift to transport. Tu to sport. Dziwne." / "In Norway drifting is transport. Here it's a sport. Strange." |
| „Hrabia" (the final) | „Moje opony kosztują więcej niż twoje auto. Ale twoje auto ma serce. I spawany dyfer." / "My tyres cost more than your car. But your car has heart. And a welded diff." |
| A fan | „Zrób dym! Mama ogląda!" / "Make smoke! Mum's watching!" |
| A fan | „Kupiłem bilet za trzy stówy, żeby wdychać opony. Najlepsze trzy stówy w życiu." / "Paid three hundred to breathe tyres. Best three hundred of my life." |
| Lena (the podium) | „Dobra, możesz zostać w teamie. Ale pierogi dalej wożę ja." / "Fine, you can stay on the team. But I still deliver the pierogi." |

## 4. The drift technique (more physics, still arcade)

A **drift state** in `car.gd`, on top of each car's feel (garage plan 4b), used in the scene and
(lighter) in the city, so the Bawarka's "drifts fill nitro" perk and city drift points use the same
rules.

- **The numbers that matter**: the slip angle β (between where the car points and where it goes),
  the speed, the steering, the gas, the handbrake.
- **Getting in**: (a) a **tap on RĘCZNY** (the handbrake, in the scene) with the wheel turned above
  30 km/h; (b) a **brake-flick** in a bend (a short brake under 0.4 s while steering, above 35 km/h);
  (c) **power-over** for rear-drive cars: full gas in a slow bend. The rear tyres let go (rear grip
  falls to the car's drift grip) and β opens in about 0.3 s.
- **Holding it**: the angle follows a target: about 30° plus up to 25° more when you steer into the
  bend, less when you steer out of it (counter-steer); the gas holds the angle and the speed (rear
  drive: more gas, more angle); off the gas β closes and the car straightens in about 1.2 s. The
  drift costs speed by sin β, the gas pays it back.
- **Transition** ("przekładka"): flick the steering the other way with a short lift: the weight
  swings, β crosses zero and opens on the other side in about 0.6 s. Big points.
- **Too much**: β over 80°, or slow with β over 50°: a spin (a fail in a run). A wall keeps 70 % of
  the speed and breaks the chain.
- **Assist** (in the scene, setting kept): **PEŁNA** (full: the game counter-steers for you and keeps β
  between 20° and 55°; you only choose the line: the phone default), **ŚREDNIA** (it helps only past
  60°), **BRAK** (off: points ×1.2). Point controls work with the full assist.
- **The Bawarka 3.2 Drift**: max angle 65° (others 50-55°), the strongest power-over, the quickest
  transitions. Other cars can drift too, by their feel: Bolonez and Bawarka M3 well, the TT badly
  (quattro), the Iżera quietly.
- **What you see and hear**: white smoke from the rear tyres by slip × speed (one small MultiMesh of
  puffs, capped), black tyre marks on the asphalt (a ring buffer), the front wheels counter-steering,
  the body leaning, the camera leading where the car *goes*, not where it points, and widening a
  little with the angle; tyre squeal pitched by slip, the engine bouncing on the limiter, the crowd
  roaring at a zone or a big chain.
- **Controls in the scene**: the nitro's place (above GAS) becomes **RĘCZNY** (no nitro in drift
  competitions, like the real ones); GAS, BRAKE and steering as always; pad: A/RT gas, X handbrake;
  keyboard: Space handbrake.

## 5. Scoring (readable on a phone)

- **Points a second** = speed (km/h) × angle factor (best between 35° and 55°) × closeness to the
  wall (within 1.5 m ×1.5) × the **chain** (×1 to ×5: +1 every 3 s of unbroken drift, +1 for each
  transition).
- **Zones** (the real clipping points): 4-6 per track, painted on the track: the nose near an inner
  marker ("KLIP!"), the tail near the outer wall ("ZONA!"): a flash, a flame jet on the island, +500 ×
  the chain.
- **Banking**: the chain's points wait in the middle of the screen and drop into the total when the
  drift ends cleanly; a wall or a spin loses them (the arcade tension).
- **The judges** turn a run into a score out of 100: **Linia** (zones hit), **Kąt** (the angle held in
  the band), **Styl** (speed, transitions, no wall). Three parody judges hold up cards.
- **Tandem**: chasing, staying within 3 m of the leader adds "BLISKO!" and copying his angle scores;
  passing him in a drift loses that run; leading, drive clean and fast. The judges compare the two runs.
- **Qualifying**: two runs, the best counts; 60 of 100 gets you into the Top 8.

## 6. The scene and the tracks

- **The scene**: the stadium's bowl as a cutaway diorama, far off the map like the club (`club.gd`
  PLACE): the two tiers of stands as one stepped mesh in the Narodowy's red and white, a crowd of
  tiny figures (one MultiMesh, phones lit at night), the roof ring with its membrane and the central
  spire with the hanging screen cube, a ring of LED boards with parody sponsors, the asphalt floor,
  the two grass islands with a stage, screens, flame jets and an inflatable "Red Byk" can, concrete
  barriers and tyre walls, the paddock tent. Target **≤ 10 draw calls** and about 25k triangles;
  smoke capped (alpha is the phone's fill-rate risk); a bench before the PR.
- **Tracks** (same floor and islands; a layout is a set of barriers, cones and zone marks, so a new
  track is cheap):
  1. **"Ósemka"** (the real 2025 layout from F's pictures): a start on the south straight, a long
     sweeper round the west island, the transition between the islands, the east island's hairpin,
     back to the line. About 550 m, a run about 35 s.
  2. **"Wielka Pętla"**: round the outside of both islands along the walls: long, fast, all outer
     zones. About 700 m, opens after the final.
  3. **"Kółko pod Narodowym"**: the free practice pad *in the city*, on the night meet's car park:
     a cone circle and a gymkhana, drift points with no scene change.
- **The camera: isometric, not top-down** (F 22:39 asked which). Default: our isometric follow
  camera, lower (about 40° instead of the city's pitch) and closer, leading where the car *goes*,
  so the angle of the drift reads as the car's side turning to the camera and the stands rise
  behind the track (the spectacle of F's pictures). A **WIDOK Z GÓRY** button switches to a high
  top-down view: the angle and the line read best from above (the old top-down drift games), good
  for learning the track; the choice is kept. Both are only the camera, so both are cheap; the
  broadcast camera from the stands is for the replay. Both are tested in the Autopilot rows and on the phone.
- **Scale**: the floor about 150 × 90 m; drift speeds 50-90 km/h (the real cars go faster; at our
  camera's 80 m view these read as fast). The camera sits lower and closer than in the city; a
  broadcast camera from the stands for the replay after a run.

## 7. How it plugs in (architecture)

- The questline: one `stories.add({...})` in main.gd `_build_stories`, started by Darek's call
  (the calls owner and pacing as every friend).
- The event: an activity on the Activity kit (`activity.gd`), the scene a Node3D like `club.gd`
  (built on the first visit, the pause owner and the camera's `inside` rules), the drift state in
  `car.gd`, the scoring in a new static `drift_score.gd` (testable without a map), the rivals in
  tandem as **recorded lines played back** (a path with an angle and speed per metre, smoke and all),
  not physics: reliable and cheap, as Lena and Darek's tandem at the meet already are.
- Add-ons: **Beehave not used** (the rivals follow recorded lines; nothing chooses between
  behaviours). **Dialogue Manager not used** for the call (two buttons, like every friend's call, in
  `dialogue.json`); the paddock's lines are taps. Revisit if the paddock gets branching talk.
- New flags: `--drift=narodowy`, `--drift-track=1|2`, `--drift-assist=full|mid|off`, `--drift-log`.

## 8. Testing (it has to feel good, so it is tested a lot)

1. **`check_drift.gd`** (headless, joins `verify.sh`, `--fixed-fps 60`), the real car script:
   a tap of RĘCZNY at 60 km/h with the wheel turned opens β to 25-50° within 0.6 s; with the full
   assist and the wheel held it stays in 20-55° for 5 s; off the gas it straightens within 1.5 s; a
   transition crosses to the other side within 0.8 s; with the assist off it can spin; the city's
   Cruise stays under F's G4 slip rule unless the player asks for a drift.
2. **Scoring tests** in the same check: the chain grows and breaks, banking, zones, the judges' 100,
   the tandem's closeness.
3. **A drift bot** follows each track's ideal line with a target angle: the Bawarka Drift with the
   full assist scores over the qualifying line on both tracks, the hatch over 40, a car driven
   straight and slow under 10. The rivals' recorded lines run clean.
4. **Bench and shots**: `--drift=narodowy --shots`, the scene's draw calls and frame time, the
   turntable sheet for the Bawarka Drift and a site sheet for the stadium interior.
5. **Autopilot on F's Mac** (docs/PLAYTEST.md, new rows): **P24** the whole quest from the call to
   the podium; **P25** free practice on both tracks: how long a new player takes to hold a 3 s drift,
   where it spins, whether RĘCZNY is found. One run under 6 minutes each.
6. **The phone**: the thumb on RĘCZNY, the assist's feel, smoke on the iPhone (fill rate), the crowd's
   cost; PHONE-CHECK rows.

## 9. Phases (after the garage's P0 nitro and P1a car feel)

| Phase | What | Model | Size |
| --- | --- | --- | --- |
| **D0** | The drift state, assist, entries, transitions, smoke and marks, `drift_score.gd`, `check_drift` | Opus (feel) | 1 PR, ~2 days |
| **D1** | The stadium scene and the two layouts, crowd, pyro, camera; Bawarka 3.2 Drift model | Sonnet modeler, Opus directs | 1-2 PRs, ~3 days |
| **D2** | The questline: the call, paddock, practice, qualifying, tandems with recorded rivals, judges, podium, prizes, the Thursday practice, the city pad | Opus | 1-2 PRs, ~3 days |
| **D3** | The drift bot, bench, Autopilot P24/P25, phone pass | Opus on the Mac | ~1 day + an evening |

About 9 thread-days. D0 can start right after the garage's P1a (the drift state uses the feel
presets); D1 can run beside D0.

## 10. Questions for F (defaults built if nobody answers)

1. The event's name "Bokiem Masters" (Pro-Am round) and the sponsor parody "Red Byk". *Default: yes.*
2. Lena drops out with a wrist sprained on gran's pickle jar. *Default: yes.*
3. The Bawarka 3.2 Drift: on loan for the event and **yours after winning the final** (default), or
   yours at once?
4. The assist on the phone: PEŁNA by default. *Default: yes.*
5. Two tracks in the stadium plus the practice pad in the city. *Default: yes.*
6. The garage plan's buyable BMW look-alike becomes **"Bawarka M3"** (the game already calls
   Darek's car Bawarka). *Default: yes.*
7. The camera: isometric (lower, closer) by default with a WIDOK Z GÓRY switch. *Default: yes.*
