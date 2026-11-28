
## Backlog
- fixed: the `firstlife` verify step hit its time limit on slow GitHub runners (main run 02:43, 1500 s) although the game had printed "first life: OK"; it now logs when the OK line and the exit came, and a process still alive 60 s after the OK line is killed and reported as an exit hang, not a game failure
