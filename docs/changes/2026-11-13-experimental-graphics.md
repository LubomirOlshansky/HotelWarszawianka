- Settings → Picture has an Experimental quality after Ultra: the sharpest picture the game can draw, with soft sun shadows, smooth edges and crisp roads, for testing on newer phones. It lasts for the session only and steps back to Ultra on its own if the phone can't keep up.

## Backlog
- found: Experimental graphics, Mac shots against Ultra at night and in the rain: do MSAA 4x, the post shader's depth outlines and the mirror reflections still agree (the trailer's `--trailer-aa=0` was the escape)?
- found: Experimental graphics, phone bench on the iPhone 16 against Ultra: fps and 1 % low, memory with the 8192 shadow map (128 MB), heat after 10 minutes; then pick which extras move into Ultra or a "High+" and which stay test-only
- found: Experimental graphics, give each extra its own switch if one proves cheap and good on the phone (today all five turn on together)

## Roadmap
- added: [x] Experimental graphics level after Ultra (F, 2026-11-10, "to test all this enhancements on the phone"): Settings → Obraz and U offer Experimental = Ultra plus the beta trailer's capture extras (the 3D image at the screen's own pixels, an 8192 sun shadow map with soft edges, MSAA 4x, 16x anisotropic filtering, every mesh at full detail; `--quality=experimental`); opt-in only (Auto never picks it, never saved), the governor's first GPU drop there steps the session back to Ultra with a toast; no shader code added (`check_tiers`; phone bench open)
