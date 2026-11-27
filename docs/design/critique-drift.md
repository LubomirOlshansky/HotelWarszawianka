# Critique: the drift side quest "Bokiem na Narodowym", section 0b (2026-11-27)

F: a hard, honest critique of the revised plan before Opus builds it. Design only, no game code.
Read: `drift-narodowy.md` 0b, `car.gd` (`_step`, l. 610-955), `skids.gd`, `street_meet.gd` (the
smoke recipe, the tandem), `club.gd`, `tapczan.gd` / `tapczan_room.gd`, `activity.gd`, `sfx.gd`
(what the tyre loop reads), main.gd's venue lines, `extending.md`. Format: `critique-padel.md`.

**Two limits of this critique.** This thread had no shell. So `critique-drag-race.md` (only on
`origin/claude/minigame-critique`) was not read, and the sim `docs/design/critique-drift-sim.py`
(pure Python, 0b.2's rules in 1-D with nine bots) was **written but not run**. Every number below
is a hand sum from 0b.2's own rates, given as a range where my guesses matter (crossovers 45 m,
the zones' places). The sim prints the hand value beside its own: run it first.

## 1. What it is

Darek calls, you drive to the Narodowy, a scene off the map opens. One thumb: hold is gas and
grows the slip angle, lift shrinks it, tap-tap kicks the tail out or flicks it across. The car
steers itself along the ideal line. Two qualifying runs of about 30 s, then two tandem runs
against a recording. Points are km/h × A(angle) × chain, unbanked until you straighten.

| Thing | Value (0b.2, 0b.5) |
| --- | --- |
| Kick | from 30 km/h, a bend within 30 m: to 30° in about 0.3 s |
| Gas held | 25°/s × (1 + 15 × curvature): 25 on a straight, 40.6 on the r 24 m sweeper, 45.8 on the r 18 m hairpin; × 0.35 inside 25-50° |
| Lift | 40°/s down; under 8° for 0.4 s is grip and banks |
| Spin | over 75° |
| Speed | 63 km/h at 40° with the gas held; with a real hold-and-lift rhythm about 50 km/h |
| A(angle) | 0 under 15°, 1 from 25° to 50°, 0.5 at 65° |
| Chain | +1 every 2.5 s and per transition, cap ×5 (reached 10 s after the kick) |
| Zones | 5, 300 × chain each; the tail within 1.5 m of a board that is 2.6 m from the line |
| Q_LINE | 4,500 |

## 2. The critique

| What the design says | What will actually happen |
| --- | --- |
| "A fixed rhythm leaves the band somewhere; the metronome fails 8 of 8" (0b.6-1) | The band's lower edge is an attractor. Under 25° the angle grows at the full rate, inside at 0.35 of it, so a fixed duty between `40 / (40 + R)` and `40 / (40 + 0.35 R)` parks the needle on 25°: crossover 0.615-0.821, sweeper 0.496-0.738, hairpin 0.466-0.714. **Any pulse with a duty of 0.62 to 0.71 holds the drift on the whole track.** Hold 0.40 s, lift 0.20 s: the needle sits at 21-30°, A about 0.9, about 50 km/h, the chain at ×5 from second 10: **5,000 to 6,300 points with no zone, no flick and no look at the screen. It passes Q_LINE.** Lena's own tip (1.5 s / 0.55 s, duty 0.73) passes too |
| "Keeping the needle in the band is the skill"; depth is a choice (0b.3) | A is flat from 25° to 50° and the drag grows with the angle: at one duty 25° runs 17.1 m/s, 50° runs 13.3 m/s. **Shallow pays 29 % more a second and is the furthest from the spin.** Only the two ZONA boards ask for depth |
| ZONA needs 30° (0b.2) | By the plan's own geometry it needs 33.4° (2.6 m − 2 m × sin β ≤ 1.5 m). A kick lands on 30° and misses by 0.1 m |
| The wall: 70 % of the speed, the chain lost; 6 m off the line; backwards; a pass halves the run; "≤ 3 m aside" | **None can happen with one thumb.** The tail reaches 2 m × sin 75° = 1.93 m at the spin, the board is 2.6 m away, and both cars are on the same line. The only way to fail is to over-hold for 0.6 s past 50°. Lena's retry line talks about a wall you cannot reach |
| "Bank or push" (0b.6-2) | Nothing outside the player threatens the pile, so the answer is never bank. One bank costs about 1,700 (the ×1 to ×5 ramp again, 1.2 s straight, a new kick). Bank-spam scores about 2,000, 15-20 % of a clean chain: B5 passes by a mile and proves nothing. Banking has one real home, the two crossovers (flick and keep ×5, or straighten and be safe), and the plan does not show it there |
| Q_LINE 4,500 | A follower with no skill (hold under 42°, lift over it, 0.2 s late, both flicks) scores **11,000 to 13,000**. The line is 35-40 % of that, equal to "bank at both crossovers and never flick" (4,500-5,500) and under the blind pulse above |
| Transitions: a 1.2 s window, +1 chain | (a) The spec never says what a missed flick does. As written the car slides into the next loop nose-out and **A(\|β\|) still pays in full**. (b) The chain is already ×5 before transition 1 (10-12 s after the kick), so both +1s are worth nothing and the STYL card has no transition points. (c) Anywhere in 1.2 s pays the same |
| "When to kick" is a choice | Earlier is always better (more seconds, the chain starts sooner), and the gate (30 m before the bend) is invisible: a reaction test against a hidden line, with ZA WOLNO as the only feedback |
| Tap-tap, "no added latency" | From a hold it is lift, tap, press: three edges in 0.6 s. A good thumb holds the needle with quick dabs, and two dabs of 0.18 s or less **are** a tap-tap: −5° outside the window, a full flip to the wrong side inside it. At the hairpin ("shorter" holds) the 0.18 s line cuts through the natural dab length. The control punishes fine control |
| "The angle reads: the chevron, the arc" (0b.6-7) | The camera squeezes depth by sin 40° = 0.64, so **one true angle reads differently round the loop: 20° as 13-30°, 40° as 28-53°, 60° as 48-70°.** A true 20° on one heading looks like a true 40° on another, and the chevron is squeezed with the car. The acceptance (shots at 20°, 40°, 60°) passes on one heading while the game fails on the next. That leaves the arc, 25 mm below a 7.6 mm car: the player watches a gauge. The tyre loop cannot help: `sfx.gd` saturates at `slip` 7.5 m/s, which is 31° at 52 km/h |
| The camera leads by velocity × 0.6 s (8 m) | Round a 300° loop the lead swings a full circle every 8.7 s: the frame orbits ±8 m in a 34 m view. And it need not move: the r 24 m loop is 48 × 31 m on screen and the view is 74 × 34 m |
| "The tandem is a battle" (0b.6-4) | **Hrabia's two-run total is one constant** (his recording, plus his recording × 1.3, my reading of "a fixed 60 % BLISKO share" at × 1.5) known before the final starts. In run 2 he is a puppet 3 m behind and nothing you do changes his score, a spin included: run 2 is a third qualifying run with a car in the mirror. In run 1 his line never reacts and he is the same every rematch |
| BLISKO 1-5 m behind; overlapping boxes is KONTAKT | On one line at one angle two 4.0 × 1.8 m boxes overlap under 4.26 m centre to centre at 25°, 2.80 m at 40°, 2.35 m at 50°. Measured between centres, **most of BLISKO is KONTAKT** (at 25° 0.74 m is left), and the follower "3 m back" stands inside your car. A touch on a recording that drives on untouched takes the whole pile |
| What is good in the tandem | The model couples speed to depth: shallow closes the gap, deep brakes, with about 2.5 s of lag. That is a real one-thumb chase. Keep it and say it in the tip |
| Fill rate: "close smoke is full-screen alpha", cover ≤ 1.5 screens (0b.6-6) | The camera is orthographic: a puff never grows on screen. 64 puffs of 3.75 m cover 707 m² of a 2,502 m² view: **0.28 screens, 0.50 at the largest size. The gate cannot fail.** The real trouble is opacity: 53 puffs a second at 14 m/s is one every 0.27 m, so a point 5 m behind the car lies under about 12 of them: 97 % opaque. The chaser sits 1-5 m behind, inside it, with his wedge and the marks |
| "The evening's marks stay": 6,144 marks, about 1,800 m | 6,144 at `skids.gd`'s 0.45 m on two wheels is 1,382 m of path. An evening is at least four player runs and two of Hrabia's, about 2,300 m: qualifying is erased during the final |
| "About 6 min"; P24 call to podium under 7 min | The stadium is 2.75 km in a straight line from the Palace: about 4 min of driving that the 6 does not count. Inside: about 120 s on track, 100 s of it sideways, 60 s of cards. The first drift of the player's life is a scored run. On a win the quest is "done and silent": about ten days of work is played for 100 s and can never be reached again |
| `drift_car.gd` "overrides `_step` only" | `_step` is 350 lines: the wall answer, pins, ghosting, the stall clock, kerbs, water, the lean. Replacing it drops all of that, and "keeps 70 %" is then a hit number outside `collide_rules.gd`, which `extending.md` rules out. With one thumb none of it is needed (the wall row above). Pure pursuit also cuts inside at every bend entry (my estimate 0.5-1 m), which moves the tail off a board placed there |
| Hrabia is a 40 KB recording, a recorder flag, check R1 | The decent bot already exists for B1. Stepped live it costs one model step a frame, varies by seed and can wobble in front of you |
| D1a: "the owner extending.md names for a scene off the map" | `extending.md` has no such row. The scenes are tested in seven functions of main.gd, not four (ten tests: l. 3248 `_shisha_secret`, 3406, 3539-3541, 3663 `_ev_free`, 5815 `rides.away`, 6640, 6989-7004), with three shapes (`club.inside`, `tapczan.inside()`, `padel.inside`). The stadium is a different case twice: its sound mode is the car, not "foot", and its camera moves, so `view` needs `dt` |
| The checks | M3 (from 30° with the gas held: 50° no sooner than 1.5 s, no spin before 3.0 s) contradicts the table on both loops: 1.41 s and 2.02 s on the sweeper, 1.25 s and 1.79 s on the hairpin; it holds only on a straight. The hairpin is 15 m in 0b.2 and 18 m in 0b.4. B4 ("hold-only spins") contradicts B6 ("no kick scores 0") unless it means one kick. "4-6 of 8": a true 50 % bot lands there 60 % of the time; on fixed seeds it is a fitted number |
| "No lights", the car's SpotLight off "in the lit stadium" | The quest runs 20:00-02:00. The floor and bowl are unshaded, the cars are in the actors' lit material: nothing in 0b says what lights them |

And:

- **On rails? Yes, as written.** The car's place is never in the player's hands. A run holds one
  kick (as early as allowed), two flicks (1.2 s windows) and one needle whose best spot is the
  safe edge. With smoke, sound and a crowd that carries a one-off quest of four runs. It does not
  carry Thursday practice, a second track or a rematch ladder. The depth has to come from what the
  angle is asked to do along the lap, not from more rules.
- **Doing nothing** scores 0 (the car stands for 45 s). Holding with no kick laps on rails at up
  to 100 km/h for 0. Neither is an exploit. The blind pulse is.
- **Unverified.** No bot has run. The decent bot is tuned against a line that a pulse passes.

Right and staying: the angle as a state (not tyre physics), points as the only currency, the
pure scripts with seeded bots, the sticky band as the assist, marks along the wheels' paths, WIDOK
Z GÓRY, the side quest under ZADANIA, your own car with a welded diff, the copied memes cut.

## 3. Build these changes (ranked; all numbers are guesses for the bots to tune)

| # | Change, written to go into 0b | Size |
| --- | --- | --- |
| 1 | **Depth pays.** A(β): 0 under 15°, 0.5 at 25°, linear to 1.0 at 45°, 1.0 to 55°, down to 0.5 at 70°; spin stays 75°; the sticky band stays 25-50°, so the best 5° are unassisted. Points a second become 31 at 25°, 41 at 35°, 50 at 45°, 46 at 55° (was 62, 55, 50, 46). ZONA's rule says 35° | S |
| 2 | **The wrong side pays nothing.** From 0.4 s after a sign change, a slip opposite to the bend scores A = 0 (ZŁA STRONA / WRONG SIDE), is pulled to 0 at 60°/s and ends in grip: the pile banks, the chain is back to ×1, a new kick is needed. A missed flick is a forced bank, never a free ride | S |
| 3 | **Set the lines from the bots, not by hand.** Q_LINE = 55 % of the follower bot's median over 32 seeds (expect about 6,500 after 1 and 2). B3 becomes: every fixed pulse from a sweep (hold 0.2-2.0 s × lift 0.1-0.8 s) scores under 60 % of Q_LINE. B5 becomes a band: bank at both crossovers scores 55-75 % of the follower. 32 seeds and rates, not "4-6 of 8". Fix M3 (name the bend: sweeper ≥ 1.3 s and ≥ 1.9 s), B4 (one kick, then hold), the hairpin's radius | S |
| 4 | **The angle on the floor, not on a gauge.** Replace the chevron and the bottom arc with a wedge painted on the floor under the car, turning with θ: a green sector from 25° to 50° on the bend's side, 6 m long, a bright rim at 45-55°, red past 65°. It is squeezed by the camera exactly as the car is, so "nose in the green" is true on every heading. The arc stays as a 2D copy only in WIDOK Z GÓRY. One mesh in the actors' material: +1 draw call. Shots: β 20°, 40°, 60° at four headings (0°, 90°, 180°, 270°), iso | M |
| 5 | **The angle in the ear and the hand.** The stadium car hands `sfx` a wheel speed, not the road speed: `v + 10 m/s × gas × min(1, β / 45°)`, so the revs climb with depth; a limiter stutter (SHOT `drift_limit`, 8 Hz) past 55°; `Access.buzz` light ticks at 6 Hz past 60°. A player can then hold 45-55° with his eyes on the car | S |
| 6 | **The camera frames the loop.** Target = the current loop's centre + 0.35 × (car − centre), no velocity lead; it slides to the next loop over 1.2 s at a crossover; straights keep the 34 m follow. The marks and the arc drawn so far stay in frame | S |
| 7 | **Hrabia is the bot, live.** `drift_bot.gd` (pure, the check's B1) stepped on `drift_model` with seed = the attempt's number, his needle at 44°, one over-hold wobble in one seed of four. Cut the recorder, `--drift-record`, `osemka_hrabia.json`, R1 | S |
| 8 | **A tandem you can lose and win on the track.** (a) Gap = along the line from his rear bumper to your nose (centres − 4.0 m). BLISKO 0.5-4 m, KONTAKT when the two boxes overlap (a pure box test in `drift_score`). (b) Run 2: he chases at no more than his own solo pace × 1.03 and scores BLISKO only while his gap is under 4 m. Drive shallow and fast and he drops off (UCIEKASZ! / PULLING AWAY!); drive deep and slow for points and he sits on you at × 1.5. Your spin gives him 500 (PREZENT! / A GIFT!). (c) A live bar on the top strip in both runs: TY 6 240 · HRABIA 5 900, his side filling as he scores. (d) The first KONTAKT costs two chain steps and 2 m/s, the second the pile. (e) The pass rule and "≤ 3 m aside" go | M |
| 9 | **Give the bank a place and a price.** Chain +1 every 4 s, cap ×6 (×6 at 20 s, two thirds of a run). A flick pays +1 and 400 × timing (1.0 within 0.15 s of the sign change, 0.5 elsewhere in the window: IDEALNIE! / PERFECT!). **Heat:** the sticky factor is 0.35 + 0.08 × (chain − 1), so at ×5 the hairpin's 35° to 50° takes 0.5 s, not 1.25 s: the bigger the pile, the livelier the car. Each crossover gets a painted gate with the unbanked pile above it, so "flick or bank" is a seen choice. Target: banking at both crossovers is 55-75 % of flicking both | M |
| 10 | **The kick you can see and time.** Paint the kick box (from 30 m before each bend to its start). Entry bonus WEJŚCIE: (km/h − 40) × 20, shown as „WEJŚCIE 72 km/h” (640 at 72, 100 at 45), so a late fast kick is a real option against an early one. In a drift, tap-tap outside a transition window does nothing (no −5°). A/B on the phone behind `--drift-kick=swipe`: a sideways flick of the held thumb, 40 pt in 0.12 s, towards the new side | S |
| 11 | **Teach it before it counts; keep it after.** ROZGRZEWKA / WARM-UP: one unscored lap after the paddock card, Lena's lines by state, ending early after a held 3 s drift and one flick. Unlimited PONÓW in qualifying. A rematch starts at the final. After the first visit QUESTS keeps "Bokiem: trening" (a free run, `bokiem_best_osemka` on the card): the `--drift=osemka` practice mode already exists. Tips become „Nos w zielonym klinie. Za płytko to jazda, za głęboko to bączek.” / "Nose in the green wedge. Too shallow is just driving, too deep is a spin." and „Płytko gonisz, głęboko hamujesz.” / "Shallow to catch him, deep to brake." Drop the retry line about the wall | S |
| 12 | **Smoke you can see through, marks that last.** One puff per 1.0 m of path from the outer rear wheel only, alpha 0.16, the same 64 cap. Replace the cover gate with a readable one: in the tandem shot at a 3 m gap the chaser's body and wedge are told apart (art-director's call). Marks every 0.70 m (the quad is 0.70 m long), `max_marks` 8,192: 2,870 m, an evening with retries | S |
| 13 | **The line back in the thumb (an experiment, flag `--drift-lane`).** While held, the thumb's sideways travel from where it landed (± 60 pt) moves the car ± 2.0 m off the line. Boards are offset curves of the line, so ZONA pays by the tail's real distance (300 at 1.5 m to 600 at 0.3 m) and a wall is `offset + 2 m × sin β > 2.6 m` inside the model: no collider. This is the answer if the phone says "on rails". It is not in the first PR's default | M |
| 14 | **Light.** Say what lights the cars at night: one venue-owned DirectionalLight with no shadow for the floor, or the cars in an unshaded copy. Bench it either way | S |

## 4. Scope: no, not one thread. The first PR and what is cut

0b is four PRs and by its own table 8-9 days, about 13 at its own × 1.5. The one unknown is whether
one thumb is fun; the bowl, the crowd, the event and the pay are known craft. So the first PR is a
**grey box that F can hold**: `drift_model`, `drift_score`, `drift_input`, `drift_line`,
`drift_bot`, `drift_tracks.json`; a flat floor with the line, the zones' boards, the kick boxes and
the wedge; one car; the loop camera and WIDOK Z GÓRY; the existing `skids.gd` with its two options;
`check_drift` M, I, S, B; changes 1 to 6 built in; `venues.gd` with the stadium alone (below);
`--drift=osemka` and a DEV-page button so it reaches the phone. No stories entry, no pay.

- **The car is posed, not simulated.** One thumb needs no `move_and_slide`: position = line(s),
  yaw = θ + β. `drift_car.gd` still extends `car.gd` for the look and the lean, but its `_step` is
  about 30 lines that write `global_transform`, `vel`, `forward_speed`, `slip`, `throttle`,
  `brakes_on` (what `skids.gd` and `sfx.gd` read). No colliders, no wall rule, no M7, no pursuit.
- **Cut from the first PR:** DWA KCIUKI with the pad's stick and B8; the walls; the TT row;
  ŚREDNIA and BRAK (a dev float instead); `settings.gd` `[drift]`; tiers; the bowl, crowd, LED
  ring and flames; the event, the paint, the pay; the recorder (gone for good, change 7).
- **D1a: only the stadium joins `venues.gd`.** `add(name, inside, view(cam, pitch, dt), sound_mode
  := "foot")`. main.gd gets one appended term in the existing chains and one first line in
  `_update_camera`: the least a parallel edit can collide with. The club, lounge, padel and
  tapczan are being edited by other threads now; padel has no Autopilot row to catch a "no
  behaviour change" that changed behaviour. Each moves when its own thread next touches it,
  tapczan first (it has the shape). One TD row lists the four and the seven functions. This is 0b.9
  item 6's alternative; take it.
- **Then:** PR 2 the stadium's look and FX (D1b); PR 3 the event with changes 7-9 and 11 (D2).
  PR 2 starts only after F has played the grey box.

Cost on the phone: the grey box is under 12 draw calls; change 4 adds one, change 7 one model
step, change 12 lowers the alpha fill. Nothing here raises 0b.4's budget.

## 5. Only the phone can show

- Whether 0.18 s and 0.25 s fit a thumb in landscape with iOS's touch delay, and tap-tap against swipe.
- Whether the wedge reads under a 7.6 mm car, and where the resting thumb hides it.
- Whether the ear and the buzz (change 5) let the eyes stay on the car.
- Whether 25 s of holding a needle is still good on the fourth run (ask F after three), and whether
  change 13 is needed.
- The 2.5 s lag of the chase: tense or mushy.
- Smoke at alpha 0.16: enough for the reel or too thin; 60 fps with two cars smoking.
- Whether the loop camera's 1.2 s slide at a crossover hides the flick it should show.

## Open questions (parked; the default is what section 3 specifies)

1. Depth pays (change 1) makes the safe shallow drift half-price. Default: built. Alternative: keep
   A flat and let only the zones ask for depth.
2. Heat (change 9) makes a long chain harder to hold. Default: built at 0.08 a step, off at PEŁNA
   if the clumsy bot passes under 2 of 8.
3. Hrabia live instead of recorded: he can wobble or spin in front of you. Default: yes, a wobble in
   one seed of four, never a spin in the first final.
4. Tap-tap or swipe for the kick. Default: tap-tap (F's reference), swipe behind the flag.
5. PREZENT! as the word for his bonus on your spin. Alternatives: „DZIĘKI!” / "THANKS!", or no word.
