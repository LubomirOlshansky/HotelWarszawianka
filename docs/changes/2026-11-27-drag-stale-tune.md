- The drag takes the car's own stats for Tadek's time every time: the line can no longer pick up a tuned car left over from an earlier start, and the log now says which accel and top the run used.

## Backlog
- found: the Autopilot re-run showed Tadek's reference about 5 s slower than on 26 Nov; nothing in the drag model changed since e04211be (constants, gears and Tadek's table are identical), so the cause is the car's `accel`/`top_mult` at the line. This change guards the one in-code path that could leave the drag tune on the car (a second `_stage` without `_restore_car`) and logs the stats; the next Autopilot run's "stage: Tadek's run" line names the car if it is something else (the garage's car, a shop level).
