- Padel on a 16:9 phone: the court is drawn a little smaller and higher, so the HIT and LOB buttons no longer hide a rival by the back glass. On a computer, P, Enter or Tab skips the warm-up.

## Backlog
- fixed: PT-62, at 16:9 (1920x1080) a rival in the near-right corner stood under UDERZ or LOB in about 3% of play frames; now 0 (19.5:9, 2532x1170, was already 0 and is unchanged)
- checked: PT-61, the CZYSTO window is right. New headless check: taps 0.05, 0.08 and 0.11 s early and late, at 60 fps and at a jittery 30-60 fps, book the error the tap really made; at 60 fps only the 0.05 s taps are CZYSTO, at 30 fps a 0.11 s tap never is. A likely reason Autopilot saw a clean 0.11 s tap: the match clamps a frame at 0.05 s, so below 20 fps (the editor on the Mac) the game runs slower than the wall clock and a tap measured on the wall clock looks earlier than it was in the game
- fixed: POMIŃ had no keyboard key (P, Enter, Tab now)
- found: a ring that first shows or jumps (the best contact moves as you run) is about 1-3% of taps at 60 fps; worth a look if players say the ring "pops"

## Roadmap
- none
