- Fixed a rare glitch where the car could jump back a few metres while the city was still loading around it.

## Backlog
- fixed: the NaN car ("From loop 3h slice 4"; the first-10 replay's `car: state not a number` at the first rescue, noted on #863). The map's ground told "a ground profile set this height" through a field both threads wrote; the runtime city builds sectors on the streamer's thread, so the car's height read on the main thread could come back NaN, and a NaN height set on the car made its whole position NaN. Now that flag is local (map_builder.gd `_fill_base`), and `heightthreads` (check_height_threads.gd) reads the heights against a second thread: 18 reads went wrong on the old code, none now.
- found: map_builder.gd height reads are shared by the main thread and the streamer's thread; any new member written inside a height function brings this back (the check catches it for drive, terrain and ground height).
