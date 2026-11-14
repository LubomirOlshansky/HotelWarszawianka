## Backlog
- found: the technical plans' review (docs/design/tech-plans-review.md): the collision preset is a command-line flag only, so it cannot be tried on a TestFlight build (a settings row would unblock the default's change)
- found: `soft_things.gd` (#776) writes the car's velocity itself, against the city objects plan's rule that the car applies a returned cost; no `WORKAROUND(arch)` mark and no tech-debt row yet
- found: races and chases have not been measured with a player who cuts through the soft fences (#776 leaves racers, traffic and police unchanged)
- found: the police soak and the race marks run only locally; the soak's dice come from the clock (one run in six fails on main)
- found: `main.gd` is 9,456 lines (9,325 when the target of under 6,000 was set) and `landmarks.gd` 42,830 (35,322 on 2026-11-12); the ratchets proposed in tech-debt.md are not built and TD-10 waits for a quiet moment that does not come
- found: ROADMAP lists the collision rework twice and the soft fences twice, and still has "Racer AI rebuild, steps 4a-6b" open though all eight steps are merged
- found: `walls-true-to-life.md` section 10 still names `barrier_kit.json` and the builder in `map_builder.gd`; `street_pass.py` and `object_types.py` both classify the same objects

## Roadmap
- ticked: "Racer AI rebuild, steps 4a-6b: a racing line, real overtakes and recovery, race links, personalities, one race session for every race"
