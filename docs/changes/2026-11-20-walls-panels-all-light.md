## Backlog
- fixed: W5 of the walls look, every light fence and hedge as panels, is built behind `barrier_look` `panels` (classic on main; nothing a tester sees changes): green fences with leaves, lawn guards, ball-stop nets, board fences, hoardings, tall hedges, chain posts, bollard rows, the stadium's railing and the iron panels between piers; sagging and leafy tops; a broken lawn guard leaves a gap, a broken board fence two boards on the ground, a broken hoarding lies flat; waits for F's look on the phone (docs/PHONE-CHECK.md 7f)
- fixed: a panel fence seen nearly end-on drew as a solid dark band (Pole Mokotowskie's lawn edge by the cycle path): W4's pixel rule floored every post, rail and bar to a pixel measured along the pixel's long side, which at a grazing view spans metres, so the floored bands filled the panel; the floors are now capped at twice the pixel's narrow side (panel_rule.gd GRAZE), which changes nothing seen at 45 degrees or more
- found: the three `bars_pier` lines sit inside the landmark guard, so they never break; their `down` look is only seen in a check
- found: at night the board fences and tall hedges are near black in `typed` and `panels` alike (the night lift of 0.15 does not reach them)

## Roadmap
- ticked: "Fences and hedges as see-through instanced panels that fall when broken, W3 to W5" (W3, W4, W5 and W6 built behind `barrier_look`; the key waits for F's phone look)
