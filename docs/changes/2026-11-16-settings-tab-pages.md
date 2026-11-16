- Testing aid only: the Tips and DEV pages can now be opened straight from a test run.

## Backlog
- fixed: `--settings-tab=6..8` (credits, Tips, DEV) opened ACCESS instead, because the panel clamped a page asked for before it was built to the last tab; found by the T35 Autopilot run on the Mac (2026-11-16). check_hints now asks for both pages before the build.
- found: T35's Mac Autopilot runs can't reach the first hour's later beats: the editor's city build (~185 s) eats most of the 6-minute play budget. The pure parts are covered by check_hints/check_hud and cloud shots; a real-play pass waits for an Autopilot budget that starts after the build.

## Roadmap
- ticks: none (T35 test evidence for "First hour step 6")
