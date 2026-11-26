# Zamek Królewski (Plac Zamkowy): log

Spec: [specs/zamek.md](specs/zamek.md). Site key `zamek` (`old_town.gd` `_build_zamek` and its
`_zamek_*` parts; SKINS row `"model": true` in `fronts.gd`). The gardens and arcades are site `arkady`.

## 2026-11-26: LoD2 skin to a whole model (pass 3, F: "rebuilt with the newest agents and workflow")

- **Before:** LoD2's mass recoloured salmon, with the Clock Tower, the turrets, the Vistula front
  and the square front's windows as model parts on top. The roofs over the courtyard were broken
  and the south front had no gate.
- **References** (local only):
  - Google 3D Tiles: 8 orbits at -25, 4 faces and the top. The Clock Tower is under scaffolding
    there.
  - Street View from the column.
  - LoD2's heights rasterised over the castle.
  - Wikipedia for the plan.
- **Spec** (Opus):
  - the Saxon wing as one hipped block;
  - the U of the other four wings as matched outer and inner polylines, which give a single roof
    ring with hips at the outer corners and valleys at the courtyard;
  - shader windows on the courtyard faces and kit windows on the square, south and river fronts;
  - the Grodzka, north wing and SE towers with copper caps;
  - chimneys along the ridges and the new kit part `kit_dormer`.
- **Build:** object-modeler (Sonnet) in one pass, 22,484 triangles. All automatic checks were
  clean the first time.
- **Review:** art-director (Opus), photo first. It failed L3 on silhouette, proportions and facade
  rhythm, all at 3:
  - the SE tower was a second keep, about 1.35 times too wide;
  - the square front had 24 bays (the views show about 19);
  - the south front had 4 rows (the views show 3 rows over 13 bays);
  - the north courtyard face should be cream;
  - the roof read orange.
- **Fix round 1** (builder), 18,954 triangles, then 18,632 after the gate fix below:
  - the SE tower is 9.5 m square, with its cap under the south eave;
  - bays are 4.7 m on the square front and 5.6 m on the south front;
  - the south front has 3 rows, with the gate at the mapped notch (x -636.5);
  - the north courtyard face is cream, and the north tower is a cream risalit;
  - the roof is coral #a9534a, and the risalits' gables match it.
- **Kept against the review:** the oval's bell roof. F asked for it to be rebuilt the same day,
  and the earlier critique chose the bell; it still reads as a dome from the garden.
- **Still differs from the photos:**
  - the courtyard's setts and gate passages are not built;
  - the north wing has 8 dormers, not 9 (the tower is in the way);
  - the Clock Tower's helm is pass 2's.
- **City shot fix** (lane session): the outline's two short pilaster steps by the south gate had no
  wall, so two dark strips of the mass showed through. Short edges on the south front now get the
  wall with no window, at 18,632 triangles.
