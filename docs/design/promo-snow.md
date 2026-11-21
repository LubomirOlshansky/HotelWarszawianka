# Promo snow (showcase, F 2026-11-21)

For the Christmas market Reel at the Palace (Jarmark Warszawski). A switch, not a season: the game's
own winter is the seasons plan's W1 ([seasons-promo.md](seasons-promo.md) section 4, technique 2).

## How to turn it on

- Flag: `--snow=COVER,FALL` (0..1 each; one number sets both). Light snow for the Reel: `--snow=0.45,0.6`.
- Phone: Promo Mode panel, row SNOW: OFF, LIGHT (cover only), FALLING (cover + flakes), HEAVY.
  COPY adds the `--snow=` flag, so the Mac renders the same frame.
- Not saved; the game never turns it on by itself.

## What it draws (post.gdshader, one branch each, both off by default)

| Part | How | Real-life rule it follows |
| --- | --- | --- |
| Cover | every pixel whose neighbour-depth normal faces up (roof, stall top, crown, ledge, hat, lawn) turns to snow inside world-anchored noise patches | fresh light snow lies whole on roofs, lawns and tree tops, sides stay dark |
| Trodden ground | on flat ground the surface map lowers the cover: paving x0.55, roads x0.18, water none | the market's paths are slushy grey with white rims; roads are ploughed |
| Light | snow takes the light of what it covers, brighter: warm under string lights and stall fronts, blue-grey in the dark | snow at night glows in the colour of the nearest light |
| Flakes | three layers (1, 2, 3 px), slow fall with a sideways sway, drifting with the view; each flake mixes in the colour behind it | flakes show bright against dark sky and lamps, vanish against white |

Cost: two `if` branches in the post pass (unshaded budget), +0 draw calls. Not benched on the phone:
promo only (F: performance is not a concern for the showcase).
