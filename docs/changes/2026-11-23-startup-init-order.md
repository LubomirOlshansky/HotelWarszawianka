## Backlog
- fixed: PT-58, init-order errors on every start (traffic `_free_slots` read before its pools exist, ~600 times; pedestrians `_alive` read before its resize, 57; crowds `_cells` read before `_build_drawing`, 2). `setup()` awaits between steps while `_process` already runs; each `_process` now waits for the piece it reads (guards only, no behaviour change)
