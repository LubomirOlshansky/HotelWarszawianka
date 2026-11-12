- The title screen now comes up a few seconds sooner when you open the game: the loading that used to sit behind a plain blue screen now happens behind the title.

## Backlog
- fixed: architecture TD-15, the whole game compiled before the first frame: `boot.tscn` is the main scene, shows the title in the first frames and loads the game's scene, with every script, on a thread behind it (`boot.gd`; in the cloud the title is up 0.26 s after the engine starts, where the plain blue screen stayed about 6.5 s in the debug engine and 3.5 s in a release build); a run with flags starts as before, `--boot` and the verify steps `boot` and `boot-run` cover the player's way
- fixed: "The engine's own start", and in the loading-lag item "the ~8 s before the engine's first frame, which no script can shorten": most of that wait was the game's scripts loading, which now happens behind the title; what is left is the engine starting itself, not measured on a phone (if it is still long there, the title's art as the boot splash image would hide it)
- found: the boot scene's numbers on a phone need one device run (parked in QUESTIONS), and one look on the Mac, with the real renderer, at the title handing over to the game
- found: architecture TD-22, the title's threaded load of the map's index (prebuilt city, since 2026-11-05) leaves 19 of the engine's own objects behind at exit, an engine warning line in a headless run; nothing is wrong while the game runs. First seen by `boot-run`, the first run to play a title on the prebuilt city, which lets that one line through up to its count

## Roadmap
- ticked: "Boot scene (F, 2026-11-12, architecture plan step 1; tech-debt TD-15)": the title is on screen in the first frames and the game's scripts load on a thread behind it (`boot.tscn`, `boot.gd`); test runs with flags start as before
