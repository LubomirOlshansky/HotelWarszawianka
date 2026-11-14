- A street race's result card now stays until you press its OK, and comes back if another card covers it.
- Rivals no longer challenge you, Pani Halina no longer rolls up and the Trzy mosty start no longer shows while something else is under way: a tour, a bar crawl, the boat race, a rave night or a job.

## Backlog
- fixed: architecture TD-1, the street races are the fourteenth script on the kit (`rivals.gd` extends `activity.gd`; the six race states stay and sit on the kit's phases): their own card listener, ✕ listener, result-card handling, status line, flag and `busy()` are the kit's now, and main.gd's stand-in `JobsForRivals` (`WORKAROUND(arch)`), `rivals.meet` and the races' lines in `_free_block`, `_ev_free`, the stop assist, the target display and the helicopter's refusal are gone; they join the director; proved against the old script over 176,700 frames in 23 scenarios on the real map and traffic before it was replaced
- fixed: the kit grew what the races needed: `request_up` (another activity's request card that leaves the player free is up, the director's `offering()`: a challenge waits for it, as it waited for Podwózka's by name), `target_source()` (a race's new target gets no camera look) and `main_target(guide)` (the race is the main line's target during the guide and for the final or the next rung)
- fixed: no check played the races' states (`check_ladder`, `check_race_*` and `check_first10` test rules and numbers); the new `check_rivals` (verify step `rivals`, CI's quick group) plays a won and a lost race, the result card covered, the ✕, what holds a challenge back, Halina's roll-up, a locked rival and Trzy mosty against the shared stand-ins
- found: a race started in the 1.2 s a prompt outlives a take-off shows its arrow only once the helicopter is down (the director's branch of the target display has the air's gate; the old block for the races had none); kept
- found: the M key and the pad's A do not press a street race's result card (no activity of the kit takes them for it, and the rescue line they fall through to is paused under the race): only a tap closes it; as before the move, kept

## Roadmap
- added: "Activity kit: the street races on it (F, 2026-11-12, architecture plan step 2; tech-debt TD-1)": ticked, `rivals.gd` is an activity of the kit (verify step `rivals`); 14 of 15 activities moved
