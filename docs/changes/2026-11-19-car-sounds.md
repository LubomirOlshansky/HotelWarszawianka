- Your car sounds real now: a recorded small engine, tyres on dry and wet roads, tyre squeal, and real bumps, guard-rail clangs and crashes instead of synthesised ones.

## Backlog
- fixed: the car's engine, tyres and collisions were 22 kHz synth sounds (sound engine review, 2026-11-12)
- found: Godot's QOA decoder clicked once per wrap on a loud, low loop seam (tyre_roll); tools/add_sfx.py --rotate moves the seam to a quiet zero crossing
