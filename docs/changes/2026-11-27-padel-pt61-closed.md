- No visible change: padel's clean-hit timing was checked in a full test match and is right.

## Backlog
- closed: PT-61 does not reproduce. Autopilot on main 3ecbad99 with `--padel-log`: 30 hits, 13 clean, every clean one within ±60 ms; all early (+77 to +177 ms) and late (-73 to -107 ms) taps were clean false. The earlier report was a harness timing error (wall clock against game time), not the game
- note: free swings (the serve, no booked tap) log q 1.00 and never count as clean, as designed

## Roadmap
- none
