## Backlog
- fixed: architecture TD-14, no error capture outside the engine's log: `error_trap.gd` keeps the errors (each kind with a count, its place and what the game was doing), the last printed lines and a session file, for our own debug runs; Settings → DŹWIĘK → RAPORT copies the report and a phone says once when the last session closed by itself, both in debug builds only (`--report`, `--crash-note`, verify step `errortrap`)
- found: architecture TD-21, a release build does not report a script's mistakes (three kinds end the app, the rest carry on with a wrong value and no line); F decided on 2026-11-12 that testers' builds stay on the release engine, unchanged, and script mistakes are found in debug runs
- found: the report's note and the after-crash note have not been looked at on a phone

## Roadmap
- ticked: "Error trap (F, 2026-11-12, architecture plan step 1; tech-debt TD-14)": in our own debug runs the game keeps its errors, the last printed lines and a session file that shows when the last session closed by itself (`error_trap.gd`, `check_error_trap.gd`)
