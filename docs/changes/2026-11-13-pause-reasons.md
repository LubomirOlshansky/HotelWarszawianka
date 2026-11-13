- At Mirek's garage, opening the big map over the paint card and closing it no longer sets the city moving behind the card.

## Backlog
- fixed: architecture TD-20, the game's pause has one owner (`pause_reasons.gd`, main.gd's `_pause`): the loading bar, the settings card, the full map and the garage card each hold their own reason and let go of only that one, and the game runs when none is held. Nine lines in main.gd wrote `get_tree().paused` themselves; none does now, and step `pause` (`check_pause.gd`, CI's quick group) fails a script that does
- fixed: with the garage card open, a tap on the minimap under the card's dim opened the full map over it, and closing the map (✕, Esc, the pad's B) started the game under the open garage card: the city ran on and the car could be driven off with the card still up. Found while building TD-20; the map's close lets go of the map's reason only, so the game stays paused for the card. Step `pause-run` (CI's smoke group) plays it in the real game on the prebuilt city, through the real input
- found: the minimap still takes a tap while the garage card is up (`hud.gd` `_input` stops for the settings card and the full map, not for the garage card), so the full map opens over the card; harmless since TD-20 (the game stays paused, and the card is there again when the map closes). A fix gives `hud.gd` one "a card covers the HUD" test for the garage card too
- found: Autopilot's add-on (`addons/autopilot/playtest.gd`) pauses and un-pauses the tree itself, as a tool from outside the game; if it un-pauses while a card holds the game, the card stays up over a running game until it closes. Left as it is (a test tool on the Mac)

## Roadmap
- added: "Pause owner (F, 2026-11-12, architecture plan, background item; tech-debt TD-20)": ticked, `pause_reasons.gd` (verify steps `pause`, `pause-run`)
