- A first drift practice on the National Stadium's floor, for testers: one thumb, hold for gas, tap-tap to slide, a green wedge on the floor shows the angle, smoke and tyre marks, a score that piles up and banks.

## Backlog
- found: TD-39, the club, the lounge, the padel hall and THE TAPCZAN still OR'd by hand in main.gd beside the new venue owner (venues.gd); each moves when its own thread next touches it
- found: the drift grey box needs F's hands on the phone before PR 2 (the stadium's look and FX): the tap-tap timing, the wedge under the thumb, the ear and the buzz, the loop camera's slide (critique-drift.md section 5)
- found: the drift's own sounds (kick, bank, loss, the limiter) are the kit's cues and the engine loop for now; SHOTS `drift_kick`, `drift_bank`, `drift_lost`, `drift_limit` wait for make_sfx.py
- found: street_meet.gd's smoke has the same material as the stadium's had before its fix (alpha, render_priority 0), and the post-process quad paints such puffs over (beacon.gd, heli.gd); check it in a shot and give it render_priority 1
- found: (fixed) the drift's own smoke at render_priority 0 never showed; the stadium's tyre marks lay a quad apart along the path, so the trail is gapless

## Roadmap
- adds: "Side quest: Bokiem na Narodowym (grey box in; the stadium's look, then the event)"
