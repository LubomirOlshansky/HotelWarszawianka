- Roofs no longer sink inside their own walls: about 80 apartment blocks in the centre (Al. Jerozolimskie by Nowy Świat, Śródmieście's tenements) now have their roofs on top again.

## Backlog
- fixed: F's teaser shot (2026-11-19), the modelled street blocks that keep LoD2's measured roof had walls up to a storey taller than that roof (78 of 246 such blocks), so from above the roof was the floor of an open box. Each kept roof corner under its walls is now lifted flush to them, corner by corner so a pitched roof keeps its ridge (map_builder `_lift_block_roof`, the walls' tops from `tools/block_eaves.py`, verify step `blockeaves`).
- found: a few blocks' LoD2 outline is another building's (the walls stand 18-38 m over the kept roof: blocks 118254740, 853013401, 152199063); left as they are (lift capped at 6.5 m), each needs its own look.

## Roadmap
- adds: "Street blocks: walls and kept roofs meet on every block (F's teaser shot)" (done)
