- Syrenka nad Wisłą wróciła na swoje miejsce: w fontannie na skraju bulwaru przy Koperniku, a nocą prowadzą do niej światła w bruku i podświetlone fontanny. / The riverside Mermaid is back where she really stands: in her fountain at the boulevard's edge by the Copernicus Science Centre, and at night lamps in the paving and glowing fountains lead to her.
- The plaza round her has granite boulder benches, hedges in sandstone planters, and the metro's stair beside it with its lift and the M sign.

## Backlog
- fixed: the riverside Syrenka stood 48 m off, on the lower promenade by the water (the bake's guessed point)
- found: the game's 10 m terrain grid makes the boulevard's 3.4 m drop by the Syrenka a gentle slope, so her front wall stands about 1 m instead of 3 m (a finer ground there is a map change)
- found: the light-field and jet layout is drawn from one night photo; a daylight photo of the paving would settle the rows

## Roadmap
- added: "The Syrenka's plaza on the Vistula boulevard (F, 2026-11-20)": ticked

## Performance
- bench (cloud, lavapipe, runtime city, same route) before / after: draw calls 148 / 148, main pass 61 / 62 draws (traffic varies by one), shadow pass 41 / 41, scripts 11.73 / 11.70 ms. The site sits in its sector's mesh and the place is poured into the actors' mesh: +0 draw calls by construction. The bench route does not pass the plaza; the iPhone over the plaza is PHONE-CHECK 15zg.
